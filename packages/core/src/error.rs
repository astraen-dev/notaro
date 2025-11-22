use thiserror::Error;

#[derive(Error, Debug)]
pub enum NotaroError {
    #[error("Database error: {0}")]
    Db(#[from] rusqlite::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Unknown error occurred")]
    Unknown,
}

pub type Result<T> = std::result::Result<T, NotaroError>;

#[cfg(test)]
mod tests {
    use super::*;
    use std::io;

    #[test]
    fn test_io_error_conversion() {
        let io_err = io::Error::new(io::ErrorKind::NotFound, "File not found");
        let err: NotaroError = io_err.into();

        match err {
            NotaroError::Io(e) => assert_eq!(e.kind(), io::ErrorKind::NotFound),
            _ => panic!("Expected Io error variant"),
        }
    }

    #[test]
    fn test_serialization_error_conversion() {
        // Trigger a serde error by parsing invalid JSON
        let err_result = serde_json::from_str::<serde_json::Value>("{invalid_json");
        let serde_err = err_result.unwrap_err();
        let err: NotaroError = serde_err.into();

        match err {
            NotaroError::Serialization(_) => assert!(true),
            _ => panic!("Expected Serialization error variant"),
        }
    }

    #[test]
    fn test_error_display_formatting() {
        let io_err = io::Error::new(io::ErrorKind::PermissionDenied, "Access denied");
        let err: NotaroError = io_err.into();

        let display_msg = format!("{}", err);
        assert_eq!(display_msg, "IO error: Access denied");
    }
}
