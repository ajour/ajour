use crate::{addon::Addon, Result};
use std::fs::remove_dir_all;
use std::path::PathBuf;

/// Deletes an Addon from disk.
pub fn delete_addon(addon: &Addon) -> Result<()> {
    remove_dir_all(addon.path.to_path_buf())?;
    Ok(())
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
    let mut zip_file = std::fs::File::open(&zip_path)?;
    let mut archive = zip::ZipArchive::new(&mut zip_file)?;

    // TODO: Maybe remove old addon here, so we don't replace.
    for i in 0..archive.len() {
        let mut file = archive.by_index(i)?;
        let path = to_directory.join(file.sanitized_name());
        if (&*file.name()).ends_with('/') {
            std::fs::create_dir_all(&path).unwrap();
        } else {
            if let Some(p) = path.parent() {
                if !p.exists() {
                    std::fs::create_dir_all(&p).unwrap();
                }
            }
            let mut outfile = std::fs::File::create(&path).unwrap();
            std::io::copy(&mut file, &mut outfile).unwrap();
        }
    }

    // Cleanup
    std::fs::remove_file(&zip_path)?;

    Ok(())
}
