use crate::{
    addon::{Addon, AddonFolder, Repository},
    parse::parse_toc_path,
    Result,
};
use std::collections::HashSet;
use std::fs::remove_dir_all;
use std::path::PathBuf;

/// Deletes an Addon and all dependencies from disk.
pub fn delete_addons(addon_folders: &[AddonFolder]) -> Result<()> {
    for folder in addon_folders {
        let path = &folder.path;
        if path.exists() {
            remove_dir_all(path)?;
        }
    }

    Ok(())
}

/// Unzips an `Addon` archive, and once that is done, it moves the content
/// to the `to_directory`.
/// At the end it will cleanup and remove the archive.
pub async fn install_addon(
    addon: &Addon,
    from_directory: &PathBuf,
    to_directory: &PathBuf,
) -> Result<Vec<AddonFolder>> {
    let zip_path = from_directory.join(&addon.primary_folder_id);
    let mut zip_file = std::fs::File::open(&zip_path)?;
    let mut archive = zip::ZipArchive::new(&mut zip_file)?;

    // Remove old top level addon folders
    // Currently we only do this if its a curse addon because we are guaranteed which folders each
    // addon has as a dependency.
    if addon.active_repository == Some(Repository::Curse) {
        for folder in addon.folders.iter() {
            let _ = std::fs::remove_dir_all(&folder.path);
        }
    }

    // Get all new top level folders
    let new_top_level_folders = archive
        .file_names()
        .filter_map(|name| name.split('/').next())
        .collect::<HashSet<_>>();

    // Remove all new top level addon folders. This seems redundant because of
    // the remove old expression above, but that one doesn't work on new addons
    // installed from the Catalog.
    for folder in new_top_level_folders {
        let path = to_directory.join(&folder);

        if path.exists() {
            let _ = std::fs::remove_dir_all(path);
        }
    }

    let mut toc_files = vec![];

    for i in 0..archive.len() {
        let mut file = archive.by_index(i)?;
        let path = to_directory.join(file.sanitized_name());

        if let Some(ext) = path.extension() {
            if let Ok(remainder) = path.strip_prefix(to_directory) {
                if ext == "toc" && remainder.components().count() == 2 {
                    toc_files.push(path.clone());
                }
            }
        }

        if file.is_dir() {
            std::fs::create_dir_all(&path)?;
        } else {
            if let Some(p) = path.parent() {
                if !p.exists() {
                    std::fs::create_dir_all(&p)?;
                }
            }
            let mut outfile = std::fs::File::create(&path)?;
            std::io::copy(&mut file, &mut outfile)?;
        }
    }

    // Cleanup
    std::fs::remove_file(&zip_path)?;

    let addon_folders = toc_files.iter().filter_map(parse_toc_path).collect();

    Ok(addon_folders)
}
