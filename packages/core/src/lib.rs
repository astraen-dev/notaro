pub mod database;
pub mod error;
pub mod models;

// Re-export for easier access
pub use database::DatabaseConnection;
pub use error::NotaroError;
pub use models::{Note, SyncMessage};

pub fn core_entrypoint() -> String {
    "Notaro Core initialized.".to_string()
}
