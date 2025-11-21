use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct Note {
    pub id: String,
    pub title: String,
    pub content: String,
    pub folder: Option<String>,
    pub is_pinned: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    /// Monotonically increasing version number for sync resolution
    pub version: i32,
    /// Soft delete flag
    pub is_deleted: bool,
}

impl Note {
    pub fn new(title: String, content: String, folder: Option<String>) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4().to_string(),
            title,
            content,
            folder,
            is_pinned: false,
            created_at: now,
            updated_at: now,
            version: 1,
            is_deleted: false,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct UserSettings {
    /// "system", "light", or "dark"
    pub theme_mode: String,
    /// 0 to 360
    pub accent_hue: u16,
    /// "sans", "serif", "mono"
    pub font_family: String,
    /// Base font size in px (e.g., 14, 16, 18)
    pub font_size: u8,
}

impl Default for UserSettings {
    fn default() -> Self {
        Self {
            theme_mode: "system".to_string(),
            accent_hue: 250, // Default Indigo/Purple
            font_family: "sans".to_string(),
            font_size: 14,
        }
    }
}

/// Message structure for WebSocket communication
#[derive(Debug, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", content = "payload")]
pub enum SyncMessage {
    /// Client asking server for changes since a specific version/timestamp
    PullRequest { since_version: i32 },
    /// Server sending updates to client
    PullResponse { changes: Vec<Note>, current_version: i32 },
    /// Client pushing local changes to server
    PushUpdates { changes: Vec<Note> },
    /// Server acknowledging receipt
    Ack,
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_note_creation() {
        let title = "Test Note".to_string();
        let content = "This is content".to_string();
        let note = Note::new(title.clone(), content.clone(), Some("Work".to_string()));

        assert_eq!(note.title, title);
        assert_eq!(note.folder, Some("Work".to_string()));
        assert_eq!(note.is_pinned, false);
        assert_eq!(note.content, content);
        assert_eq!(note.version, 1);
        assert_eq!(note.is_deleted, false);
        assert!(!note.id.is_empty());
    }

    #[test]
    fn test_sync_message_serialization() {
        // Test PullRequest
        let msg = SyncMessage::PullRequest { since_version: 5 };
        let json = serde_json::to_value(&msg).unwrap();

        assert_eq!(
            json,
            json!({
                "type": "PullRequest",
                "payload": {
                    "since_version": 5
                }
            })
        );

        // Test PushUpdates deserialization
        let note = Note::new("A".into(), "B".into(), Some("C".to_string()));
        let json_input = json!({
            "type": "PushUpdates",
            "payload": {
                "changes": [note]
            }
        });

        let deserialized: SyncMessage = serde_json::from_value(json_input).unwrap();
        match deserialized {
            SyncMessage::PushUpdates { changes } => {
                assert_eq!(changes.len(), 1);
                assert_eq!(changes[0].title, "A");
            }
            _ => panic!("Wrong variant deserialized"),
        }
    }
}
