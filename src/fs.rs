use std::path::PathBuf;
use crate::Result;
use crate::{error::ClientError, toc::addon::Addon};
use std::fs::remove_dir_all;

/// Deletes an Addon from disk.
pub fn delete_addon(addon: &Addon) -> Result<()> {
    remove_dir_all(addon.path.to_path_buf()).map_err(|e| ClientError::IoError(e))
}

/// TBA.
/// An erro can happen, dunno why yet.
pub async fn install_addon(addon: &Addon) -> Result<()> {
    let zip_path = PathBuf::from("/tmp").join(addon.remote_filename.clone().unwrap());
    // TODO: This sometimes fails: No such file or directory (os error 2).
    let mut zip_file = std::fs::File::open(&zip_path)?;
    let mut archive = zip::ZipArchive::new(&mut zip_file)?;
    // TODO: Maybe remove old addon now here.

    for i in 1..archive.len() {
        let mut file = archive.by_index(i)?;
        let path = PathBuf::from("/tmp").join(file.sanitized_name());
        println!("path: {:?}", path);

        if file.is_dir() {
            std::fs::create_dir_all(path)?;
        } else {
            let mut target = std::fs::OpenOptions::new()
                .write(true)
                .create(true)
                .truncate(true)
                .open(path)?;

            std::io::copy(&mut file, &mut target)?;
        }
    }

    // Cleanup
    std::fs::remove_file(&zip_path)?;

    return Ok(())
}
