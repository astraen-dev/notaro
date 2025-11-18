use crate::error::Result;
use crate::models::Note;
use chrono::{DateTime, Utc};
use rusqlite::{Connection, OptionalExtension, params};
use std::path::Path;

pub struct DatabaseConnection {
    conn: Connection,
}

impl DatabaseConnection {
    /// Initializes the database connection and runs migrations
    /// To use an in-memory database for testing, pass ":memory:"
    pub fn new<P: AsRef<Path>>(path: P) -> Result<Self> {
        let conn = Connection::open(path)?;
        let db = Self { conn };
        db.migrate()?;
        Ok(db)
    }

    /// Creates the necessary tables
    fn migrate(&self) -> Result<()> {
        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS notes (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                version INTEGER NOT NULL,
                is_deleted BOOLEAN NOT NULL DEFAULT 0
            )",
            [],
        )?;
        Ok(())
    }

    // --- CRUD Operations ---

    pub fn create_note(&self, title: String, content: String) -> Result<Note> {
        let note = Note::new(title, content);
        self.conn.execute(
            "INSERT INTO notes (id, title, content, created_at, updated_at, version, is_deleted)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            params![
                note.id,
                note.title,
                note.content,
                note.created_at.to_rfc3339(),
                note.updated_at.to_rfc3339(),
                note.version,
                note.is_deleted
            ],
        )?;
        Ok(note)
    }

    pub fn get_all_notes(&self) -> Result<Vec<Note>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, content, created_at, updated_at, version, is_deleted
             FROM notes
             WHERE is_deleted = 0
             ORDER BY updated_at DESC",
        )?;

        let note_iter = stmt.query_map([], |row| {
            Ok(Note {
                id: row.get(0)?,
                title: row.get(1)?,
                content: row.get(2)?,
                created_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(3)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                updated_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(4)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                version: row.get(5)?,
                is_deleted: row.get(6)?,
            })
        })?;

        let mut notes = Vec::new();
        for note in note_iter {
            notes.push(note?);
        }
        Ok(notes)
    }

    pub fn update_note(&self, id: &str, title: String, content: String) -> Result<Note> {
        let now = Utc::now();

        // We bump version by 1 locally.
        self.conn.execute(
            "UPDATE notes
             SET title = ?1, content = ?2, updated_at = ?3, version = version + 1
             WHERE id = ?4",
            params![title, content, now.to_rfc3339(), id],
        )?;

        // Retrieve the updated note to return it
        self.get_note_by_id(id)
    }

    pub fn delete_note(&self, id: &str) -> Result<()> {
        let now = Utc::now();
        // Soft delete, bump version for sync
        self.conn.execute(
            "UPDATE notes
             SET is_deleted = 1, updated_at = ?1, version = version + 1
             WHERE id = ?2",
            params![now.to_rfc3339(), id],
        )?;
        Ok(())
    }

    fn get_note_by_id(&self, id: &str) -> Result<Note> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, content, created_at, updated_at, version, is_deleted
             FROM notes WHERE id = ?1",
        )?;

        stmt.query_row(params![id], |row| {
            Ok(Note {
                id: row.get(0)?,
                title: row.get(1)?,
                content: row.get(2)?,
                created_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(3)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                updated_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(4)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                version: row.get(5)?,
                is_deleted: row.get(6)?,
            })
        })
        .map_err(Into::into)
    }

    // --- Sync Logic ---

    /// Get all notes (including deleted ones) that have a version higher than the provided version.
    pub fn get_changes_since(&self, version: i32) -> Result<Vec<Note>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, content, created_at, updated_at, version, is_deleted
             FROM notes
             WHERE version > ?1",
        )?;

        let note_iter = stmt.query_map(params![version], |row| {
            Ok(Note {
                id: row.get(0)?,
                title: row.get(1)?,
                content: row.get(2)?,
                created_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(3)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                updated_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(4)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                version: row.get(5)?,
                is_deleted: row.get(6)?,
            })
        })?;

        let mut notes = Vec::new();
        for note in note_iter {
            notes.push(note?);
        }
        Ok(notes)
    }

    /// Merges remote changes into the local database.
    /// Strategy: Last Write Wins based on Version number.
    pub fn merge_changes(&mut self, remote_changes: Vec<Note>) -> Result<()> {
        let tx = self.conn.transaction()?;

        for remote_note in remote_changes {
            // check if we have this note
            let local_version: Option<i32> = tx
                .query_row(
                    "SELECT version FROM notes WHERE id = ?1",
                    params![remote_note.id],
                    |row| row.get(0),
                )
                .optional()?;

            match local_version {
                Some(v) => {
                    // If remote version is higher, we overwrite local
                    if remote_note.version > v {
                        tx.execute(
                            "UPDATE notes
                             SET title = ?1, content = ?2, created_at = ?3, updated_at = ?4, version = ?5, is_deleted = ?6
                             WHERE id = ?7",
                            params![
                                remote_note.title,
                                remote_note.content,
                                remote_note.created_at.to_rfc3339(),
                                remote_note.updated_at.to_rfc3339(),
                                remote_note.version,
                                remote_note.is_deleted,
                                remote_note.id
                            ]
                        )?;
                    }
                    // If local version is higher or equal, we ignore the remote change
                }
                None => {
                    // We don't have it, insert it
                    tx.execute(
                        "INSERT INTO notes (id, title, content, created_at, updated_at, version, is_deleted)
                         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                        params![
                            remote_note.id,
                            remote_note.title,
                            remote_note.content,
                            remote_note.created_at.to_rfc3339(),
                            remote_note.updated_at.to_rfc3339(),
                            remote_note.version,
                            remote_note.is_deleted
                        ],
                    )?;
                }
            }
        }

        tx.commit()?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn get_mem_db() -> DatabaseConnection {
        DatabaseConnection::new(":memory:").expect("Failed to create memory db")
    }

    #[test]
    fn test_crud_lifecycle() {
        let db = get_mem_db();

        // 1. Create
        let note = db.create_note("Hello".into(), "World".into()).unwrap();
        assert_eq!(note.title, "Hello");
        assert_eq!(note.version, 1);

        // 2. Read
        let fetched = db.get_note_by_id(&note.id).unwrap();
        assert_eq!(fetched.title, "Hello");

        // 3. Update
        let updated = db.update_note(&note.id, "Hello 2".into(), "Updated".into()).unwrap();
        assert_eq!(updated.title, "Hello 2");
        assert_eq!(updated.version, 2); // Version should bump

        // 4. Soft Delete
        db.delete_note(&note.id).unwrap();
        let deleted = db.get_note_by_id(&note.id).unwrap();
        assert!(deleted.is_deleted);
        assert_eq!(deleted.version, 3); // Version should bump on delete

        // 5. Verify get_all_notes excludes deleted
        let all = db.get_all_notes().unwrap();
        assert_eq!(all.len(), 0);
    }

    #[test]
    fn test_sync_get_changes() {
        let db = get_mem_db();
        let note1 = db.create_note("A".into(), "Content A".into()).unwrap(); // v1
        let _note2 = db.create_note("B".into(), "Content B".into()).unwrap(); // v1

        // Get changes since version 0 (should get both)
        let changes = db.get_changes_since(0).unwrap();
        assert_eq!(changes.len(), 2);

        // Update note1 -> becomes v2
        db.update_note(&note1.id, "A2".into(), "C2".into()).unwrap();

        // Get changes since version 1 (should get only note1)
        let changes_since_1 = db.get_changes_since(1).unwrap();
        assert_eq!(changes_since_1.len(), 1);
        assert_eq!(changes_since_1[0].id, note1.id);
        assert_eq!(changes_since_1[0].version, 2);
    }

    #[test]
    fn test_merge_remote_newer_wins() {
        let mut db = get_mem_db();
        let note = db.create_note("Local".into(), "Local".into()).unwrap(); // v1

        // Create a remote note object that represents a newer version of the same note
        let mut remote_note = note.clone();
        remote_note.title = "Remote".into();
        remote_note.version = 10; // Remote is much newer

        db.merge_changes(vec![remote_note]).unwrap();

        let current = db.get_note_by_id(&note.id).unwrap();
        assert_eq!(current.title, "Remote"); // Remote should overwrite
        assert_eq!(current.version, 10);
    }

    #[test]
    fn test_merge_remote_stale_ignored() {
        let mut db = get_mem_db();
        let note = db.create_note("Local".into(), "Local".into()).unwrap(); // v1

        // Bump local to v2
        db.update_note(&note.id, "Local V2".into(), "C".into()).unwrap();

        // Create a remote note that is stale (v1)
        let mut remote_note = note.clone(); // copy of v1
        remote_note.title = "Stale Remote".into();

        db.merge_changes(vec![remote_note]).unwrap();

        let current = db.get_note_by_id(&note.id).unwrap();
        assert_eq!(current.title, "Local V2"); // Local should persist
        assert_eq!(current.version, 2);
    }

    #[test]
    fn test_merge_new_note() {
        let mut db = get_mem_db();
        let remote_note = Note::new("New Remote".into(), "Content".into());

        db.merge_changes(vec![remote_note.clone()]).unwrap();

        let current = db.get_note_by_id(&remote_note.id).unwrap();
        assert_eq!(current.title, "New Remote");
    }
}
