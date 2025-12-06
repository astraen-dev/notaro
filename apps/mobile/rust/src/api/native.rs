use anyhow::{Context, Result};
use lazy_static::lazy_static;
use notaro_core::DatabaseConnection;
use std::sync::Mutex;

// Global singleton for the database connection
lazy_static! {
    static ref DB: Mutex<Option<DatabaseConnection>> = Mutex::new(None);
}

// --- DTOs (Mirrors of Core Models for FRB) ---

pub struct Note {
    pub id: String,
    pub title: String,
    pub content: String,
    pub folder: Option<String>,
    pub is_pinned: bool,
    pub created_at: String, // ISO 8601 String for safe transport
    pub updated_at: String,
    pub version: i32,
    pub is_deleted: bool,
}

impl From<notaro_core::Note> for Note {
    fn from(n: notaro_core::Note) -> Self {
        Self {
            id: n.id,
            title: n.title,
            content: n.content,
            folder: n.folder,
            is_pinned: n.is_pinned,
            created_at: n.created_at.to_rfc3339(),
            updated_at: n.updated_at.to_rfc3339(),
            version: n.version,
            is_deleted: n.is_deleted,
        }
    }
}

pub struct UserSettings {
    pub theme_mode: String,
    pub accent_hue: u16,
    pub font_family: String,
    pub font_size: u8,
}

impl From<notaro_core::UserSettings> for UserSettings {
    fn from(s: notaro_core::UserSettings) -> Self {
        Self {
            theme_mode: s.theme_mode,
            accent_hue: s.accent_hue,
            font_family: s.font_family,
            font_size: s.font_size,
        }
    }
}

impl From<UserSettings> for notaro_core::UserSettings {
    fn from(val: UserSettings) -> Self {
        notaro_core::UserSettings {
            theme_mode: val.theme_mode,
            accent_hue: val.accent_hue,
            font_family: val.font_family,
            font_size: val.font_size,
        }
    }
}

// --- Initialization ---

pub fn init_db(app_doc_dir: String) -> Result<()> {
    let path = std::path::Path::new(&app_doc_dir).join("notaro.db");
    let db =
        DatabaseConnection::new(path).map_err(|e| anyhow::anyhow!("Failed to init DB: {}", e))?;

    let mut global_db = DB.lock().map_err(|_| anyhow::anyhow!("Failed to acquire DB lock"))?;
    *global_db = Some(db);
    Ok(())
}

fn with_db<F, R>(f: F) -> Result<R>
where
    F: FnOnce(&DatabaseConnection) -> Result<R>,
{
    let lock = DB.lock().map_err(|_| anyhow::anyhow!("Failed to acquire DB lock"))?;
    let db = lock.as_ref().context("Database not initialized. Call init_db first.")?;
    f(db)
}

// --- API Methods ---

pub fn get_all_notes() -> Result<Vec<Note>> {
    with_db(|db| {
        let notes = db.get_all_notes()?;
        Ok(notes.into_iter().map(Note::from).collect())
    })
}

pub fn create_note(title: String, content: String, folder: Option<String>) -> Result<Note> {
    with_db(|db| {
        let note = db.create_note(title, content, folder)?;
        Ok(Note::from(note))
    })
}

pub fn update_note(
    id: String,
    title: String,
    content: String,
    folder: Option<String>,
    is_pinned: bool,
) -> Result<Note> {
    with_db(|db| {
        let note = db.update_note(&id, title, content, folder, is_pinned)?;
        Ok(Note::from(note))
    })
}

pub fn delete_note(id: String) -> Result<()> {
    with_db(|db| db.delete_note(&id).map_err(|e| e.into()))
}

pub fn restore_note(id: String) -> Result<()> {
    with_db(|db| db.restore_note(&id).map_err(|e| e.into()))
}

pub fn get_settings() -> Result<UserSettings> {
    with_db(|db| {
        let settings = db.get_settings()?;
        Ok(UserSettings::from(settings))
    })
}

pub fn update_settings(settings: UserSettings) -> Result<()> {
    with_db(|db| db.update_settings(&settings.into()).map_err(|e| e.into()))
}
