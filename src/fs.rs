use crate::Result;
use crate::{error::ClientError, toc::Addon};
use std::fs::remove_dir_all;
use std::path::PathBuf;

/// Deletes an Addon from disk.
pub fn delete_addon(addon: &Addon) -> Result<()> {
    remove_dir_all(addon.path.to_path_buf()).map_err(|e| ClientError::IoError(e))
}

/// Unzips an `Addon` archive, and once that is done, it moves the content
/// to the `to_directory`.
/// At the end it will cleanup and remove the archive.
pub async fn install_addon(
    addon: &Addon,
    from_directory: &PathBuf,
    to_directory: &PathBuf,
) -> Result<()> {
    let zip_path = from_directory.join(addon.id.clone());
    // TODO: This sometimes fails: No such file or directory (os error 2).
    let mut zip_file = std::fs::File::open(&zip_path)?;
    let mut archive = zip::ZipArchive::new(&mut zip_file)?;

    // TODO: Maybe remove old addon here, so we dont replace.

    for i in 1..archive.len() {
        let mut file = archive.by_index(i)?;
        let path = to_directory.join(file.sanitized_name());

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

    return Ok(());
}
