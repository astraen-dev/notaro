use notaro_core::{DatabaseConnection, Note, UserSettings};
use std::sync::Mutex;
use tauri::{Manager, State};

// 1. Define AppState to hold the database connection safely
struct AppState {
    db: Mutex<DatabaseConnection>,
}

// 2. Define Tauri Commands
#[tauri::command]
fn get_notes(state: State<AppState>) -> Result<Vec<Note>, String> {
    let db = state.db.lock().map_err(|_| "Failed to lock mutex")?;
    db.get_all_notes().map_err(|e| e.to_string())
}

#[tauri::command]
fn create_note(state: State<AppState>, title: String, content: String) -> Result<Note, String> {
    let db = state.db.lock().map_err(|_| "Failed to lock mutex")?;
    db.create_note(title, content).map_err(|e| e.to_string())
}

#[tauri::command]
fn update_note(
    state: State<AppState>,
    id: String,
    title: String,
    content: String,
) -> Result<Note, String> {
    let db = state.db.lock().map_err(|_| "Failed to lock mutex")?;
    db.update_note(&id, title, content).map_err(|e| e.to_string())
}

#[tauri::command]
fn delete_note(state: State<AppState>, id: String) -> Result<(), String> {
    let db = state.db.lock().map_err(|_| "Failed to lock mutex")?;
    db.delete_note(&id).map_err(|e| e.to_string())
}

#[tauri::command]
fn get_settings(state: State<AppState>) -> Result<UserSettings, String> {
    let db = state.db.lock().map_err(|_| "Failed to lock mutex")?;
    db.get_settings().map_err(|e| e.to_string())
}

#[tauri::command]
fn save_settings(state: State<AppState>, settings: UserSettings) -> Result<(), String> {
    let db = state.db.lock().map_err(|_| "Failed to lock mutex")?;
    db.update_settings(&settings).map_err(|e| e.to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            // 3. Initialize Database in AppData directory
            let app_handle = app.handle();
            let app_data_dir =
                app_handle.path().app_data_dir().expect("Failed to get app data dir");

            // Ensure directory exists
            if !app_data_dir.exists() {
                std::fs::create_dir_all(&app_data_dir).expect("Failed to create app data dir");
            }

            let db_path = app_data_dir.join("notaro.db");
            let db = DatabaseConnection::new(db_path).expect("Failed to initialize database");

            // 4. Manage State
            app.manage(AppState { db: Mutex::new(db) });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_notes,
            create_note,
            update_note,
            delete_note,
            get_settings,
            save_settings
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
