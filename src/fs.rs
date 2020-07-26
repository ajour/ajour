use crate::Result;
use crate::{error::ClientError, toc::addon::Addon};
use std::fs::remove_dir_all;

/// Deletes an Addon from disk.
pub fn delete_addon(addon: &Addon) -> Result<()> {
    remove_dir_all(addon.path.to_path_buf()).map_err(|e| ClientError::IoError(e))
}
