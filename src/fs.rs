use crate::Result;
use std::path::PathBuf;
use crate::error::ClientError;
use std::fs::remove_dir_all;

/// Deletes an AddOn from disk.
pub fn delete_addon(path: PathBuf) -> Result<()> {
    remove_dir_all(path).map_err(|e| ClientError::IoError(e))
}
