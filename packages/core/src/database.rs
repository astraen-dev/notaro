use crate::error::Result;
use crate::models::{Note, UserSettings};
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

        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS settings (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                theme_mode TEXT NOT NULL,
                accent_hue INTEGER NOT NULL,
                font_family TEXT NOT NULL,
                font_size INTEGER NOT NULL
            )",
            [],
        )?;

        // MIGRATION: Add columns if they don't exist (safe for existing DBs)
        let _ = self.conn.execute("ALTER TABLE notes ADD COLUMN folder TEXT", []);
        let _ = self
            .conn
            .execute("ALTER TABLE notes ADD COLUMN is_pinned BOOLEAN NOT NULL DEFAULT 0", []);

        Ok(())
    }

    // --- CRUD Operations ---

    pub fn create_note(
        &self,
        title: String,
        content: String,
        folder: Option<String>,
    ) -> Result<Note> {
        let note = Note::new(title, content, folder);
        self.conn.execute(
            "INSERT INTO notes (id, title, content, folder, is_pinned, created_at, updated_at, version, is_deleted)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            params![
                note.id,
                note.title,
                note.content,
                note.folder,
                note.is_pinned,
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
            "SELECT id, title, content, folder, is_pinned, created_at, updated_at, version, is_deleted
             FROM notes
             ORDER BY is_pinned DESC, updated_at DESC",
        )?;

        let note_iter = stmt.query_map([], |row| {
            Ok(Note {
                id: row.get(0)?,
                title: row.get(1)?,
                content: row.get(2)?,
                folder: row.get(3)?,
                is_pinned: row.get(4)?,
                created_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(5)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                updated_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(6)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                version: row.get(7)?,
                is_deleted: row.get(8)?,
            })
        })?;

        let mut notes = Vec::new();
        for note in note_iter {
            notes.push(note?);
        }
        Ok(notes)
    }

    pub fn update_note(
        &self,
        id: &str,
        title: String,
        content: String,
        folder: Option<String>,
        is_pinned: bool,
    ) -> Result<Note> {
        let now = Utc::now();

        // Only allow updates if note is not deleted (optional safeguard, or allow editing trash)
        // For now, we allow updates, but usually UI blocks it.
        self.conn.execute(
            "UPDATE notes
             SET title = ?1, content = ?2, folder = ?3, is_pinned = ?4, updated_at = ?5, version = version + 1
             WHERE id = ?6",
            params![title, content, folder, is_pinned, now.to_rfc3339(), id],
        )?;

        self.get_note_by_id(id)
    }

    /// Deletes a note.
    /// 1. If the note is active, it is soft-deleted (moved to trash).
    /// 2. If the note is already soft-deleted, it is permanently removed.
    pub fn delete_note(&self, id: &str) -> Result<()> {
        let note = self.get_note_by_id(id)?;

        if note.is_deleted {
            // Hard Delete
            self.conn.execute("DELETE FROM notes WHERE id = ?1", params![id])?;
        } else {
            // Soft Delete
            let now = Utc::now();
            self.conn.execute(
                "UPDATE notes
                 SET is_deleted = 1, updated_at = ?1, version = version + 1
                 WHERE id = ?2",
                params![now.to_rfc3339(), id],
            )?;
        }
        Ok(())
    }

    pub fn restore_note(&self, id: &str) -> Result<()> {
        let now = Utc::now();
        self.conn.execute(
            "UPDATE notes
             SET is_deleted = 0, updated_at = ?1, version = version + 1
             WHERE id = ?2",
            params![now.to_rfc3339(), id],
        )?;
        Ok(())
    }

    fn get_note_by_id(&self, id: &str) -> Result<Note> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, content, folder, is_pinned, created_at, updated_at, version, is_deleted
             FROM notes WHERE id = ?1",
        )?;

        stmt.query_row(params![id], |row| {
            Ok(Note {
                id: row.get(0)?,
                title: row.get(1)?,
                content: row.get(2)?,
                folder: row.get(3)?,
                is_pinned: row.get(4)?,
                created_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(5)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                updated_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(6)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                version: row.get(7)?,
                is_deleted: row.get(8)?,
            })
        })
        .map_err(Into::into)
    }

    pub fn get_settings(&self) -> Result<UserSettings> {
        let mut stmt = self.conn.prepare(
            "SELECT theme_mode, accent_hue, font_family, font_size FROM settings WHERE id = 1",
        )?;

        let settings_iter = stmt.query_map([], |row| {
            Ok(UserSettings {
                theme_mode: row.get(0)?,
                accent_hue: row.get(1)?,
                font_family: row.get(2)?,
                font_size: row.get(3)?,
            })
        });

        // If table is empty or query fails, return default
        if let Ok(mut rows) = settings_iter
            && let Some(Ok(settings)) = rows.next()
        {
            return Ok(settings);
        }

        // Initialize default if missing
        let default = UserSettings::default();
        self.update_settings(&default)?;
        Ok(default)
    }

    pub fn update_settings(&self, settings: &UserSettings) -> Result<()> {
        self.conn.execute(
            "INSERT OR REPLACE INTO settings (id, theme_mode, accent_hue, font_family, font_size)
             VALUES (1, ?1, ?2, ?3, ?4)",
            params![
                settings.theme_mode,
                settings.accent_hue,
                settings.font_family,
                settings.font_size
            ],
        )?;
        Ok(())
    }

    // --- Sync Logic ---

    /// Get all notes (including deleted ones) that have a version higher than the provided version.
    pub fn get_changes_since(&self, version: i32) -> Result<Vec<Note>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, content, folder, is_pinned, created_at, updated_at, version, is_deleted
             FROM notes
             WHERE version > ?1",
        )?;

        let note_iter = stmt.query_map(params![version], |row| {
            Ok(Note {
                id: row.get(0)?,
                title: row.get(1)?,
                content: row.get(2)?,
                folder: row.get(3)?,
                is_pinned: row.get(4)?,
                created_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(5)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                updated_at: DateTime::parse_from_rfc3339(&row.get::<_, String>(6)?)
                    .map_err(|_| rusqlite::Error::ExecuteReturnedResults)?
                    .with_timezone(&Utc),
                version: row.get(7)?,
                is_deleted: row.get(8)?,
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
                        // UPDATE with new fields
                        tx.execute(
                            "UPDATE notes
                             SET title = ?1, content = ?2, folder = ?3, is_pinned = ?4, created_at = ?5, updated_at = ?6, version = ?7, is_deleted = ?8
                             WHERE id = ?9",
                            params![
                                remote_note.title,
                                remote_note.content,
                                remote_note.folder,
                                remote_note.is_pinned,
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
                    // INSERT with new fields
                    tx.execute(
                        "INSERT INTO notes (id, title, content, folder, is_pinned, created_at, updated_at, version, is_deleted)
                         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
                        params![
                            remote_note.id,
                            remote_note.title,
                            remote_note.content,
                            remote_note.folder,
                            remote_note.is_pinned,
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
        let note = db.create_note("Hello".into(), "World".into(), Some("Work".into())).unwrap();
        assert_eq!(note.title, "Hello");
        assert_eq!(note.folder, Some("Work".to_string()));
        assert_eq!(note.version, 1);

        // 2. Read
        let fetched = db.get_note_by_id(&note.id).unwrap();
        assert_eq!(fetched.title, "Hello");
        assert_eq!(fetched.folder, Some("Work".to_string()));

        // 3. Update
        let updated =
            db.update_note(&note.id, "Hello 2".into(), "Updated".into(), None, true).unwrap();
        assert_eq!(updated.title, "Hello 2");
        assert_eq!(updated.folder, None);
        assert_eq!(updated.is_pinned, true);
        assert_eq!(updated.version, 2); // Version should bump

        // 4. Soft Delete
        db.delete_note(&note.id).unwrap();
        let deleted = db.get_note_by_id(&note.id).unwrap();
        assert!(deleted.is_deleted);
        assert_eq!(deleted.version, 3); // Version should bump on delete

        // 5. Verify get_all_notes INCLUDES deleted notes (for Trash folder support)
        let all = db.get_all_notes().unwrap();
        assert_eq!(all.len(), 1);
        assert_eq!(all[0].id, note.id);
        assert!(all[0].is_deleted);
    }

    #[test]
    fn test_sync_get_changes() {
        let db = get_mem_db();
        let note1 = db.create_note("A".into(), "Content A".into(), None).unwrap(); // v1
        let _note2 = db.create_note("B".into(), "Content B".into(), None).unwrap(); // v1

        // Get changes since version 0 (should get both)
        let changes = db.get_changes_since(0).unwrap();
        assert_eq!(changes.len(), 2);

        // Update note1 -> becomes v2
        db.update_note(&note1.id, "A2".into(), "C2".into(), None, false).unwrap();

        // Get changes since version 1 (should get only note1)
        let changes_since_1 = db.get_changes_since(1).unwrap();
        assert_eq!(changes_since_1.len(), 1);
        assert_eq!(changes_since_1[0].id, note1.id);
        assert_eq!(changes_since_1[0].version, 2);
    }

    #[test]
    fn test_merge_remote_newer_wins() {
        let mut db = get_mem_db();
        let note = db.create_note("Local".into(), "Local".into(), None).unwrap(); // v1

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
        let note = db.create_note("Local".into(), "Local".into(), None).unwrap(); // v1

        // Bump local to v2
        db.update_note(&note.id, "Local V2".into(), "C".into(), None, false).unwrap();

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
        let remote_note = Note::new("New Remote".into(), "Content".into(), None);

        db.merge_changes(vec![remote_note.clone()]).unwrap();

        let current = db.get_note_by_id(&remote_note.id).unwrap();
        assert_eq!(current.title, "New Remote");
    }

    #[test]
    fn test_settings_persistence() {
        let db = get_mem_db();

        // Should get defaults initially
        let initial = db.get_settings().unwrap();
        assert_eq!(initial.accent_hue, 250);

        // Update settings
        let new_settings = UserSettings {
            theme_mode: "dark".to_string(),
            accent_hue: 120,
            font_family: "mono".to_string(),
            font_size: 18,
        };
        db.update_settings(&new_settings).unwrap();

        // Fetch again
        let fetched = db.get_settings().unwrap();
        assert_eq!(fetched.theme_mode, "dark");
        assert_eq!(fetched.accent_hue, 120);
        assert_eq!(fetched.font_family, "mono");
    }
}
