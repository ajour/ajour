use std::fs::remove_dir_all;
use crate::{toc::addon::Addon, error::ClientError};
use crate::Result;

/// Deletes an AddOn from disk.
pub fn delete_addon(addon: &Addon) -> Result<()>{
    let path = &addon.path;
    remove_dir_all(path).map_err(|e| ClientError::IoError(e))
}
