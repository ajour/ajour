use super::Result;
use crate::{
    addon::{Addon, AddonFolder},
    parse::parse_toc_path,
};
use std::collections::HashSet;
use std::fs::{remove_dir_all, remove_file};
use std::path::Path;
use walkdir::WalkDir;

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

/// Deletes all saved varaible files correlating to `[AddonFolder]`.
pub fn delete_saved_variables(addon_folders: &[AddonFolder], wtf_path: &Path) -> Result<()> {
    for entry in WalkDir::new(&wtf_path)
        .into_iter()
        .filter_map(std::result::Result::ok)
    {
        let path = entry.path();
        let parent_name = path
            .parent()
            .and_then(|a| a.file_name())
            .and_then(|a| a.to_str());

        if parent_name == Some("SavedVariables") {
            let file_name = path
                .file_stem()
                .and_then(|a| a.to_str())
                .map(|a| a.trim_end_matches(".bak"));

            // NOTE: Will reject "Foobar_<invalid utf8>".
            if let Some(file_name_str) = file_name {
                for folder in addon_folders {
                    if file_name_str == folder.id {
                        remove_file(path)?;
                    }
                }
            }
        }
    }

    Ok(())
}

/// Unzips an `Addon` archive, and once that is done, it moves the content
/// to the `to_directory`.
/// At the end it will cleanup and remove the archive.
pub async fn install_addon(
    addon: &Addon,
    from_directory: &Path,
    to_directory: &Path,
) -> Result<Vec<AddonFolder>> {
    let zip_path = from_directory.join(&addon.primary_folder_id);
    let mut zip_file = std::fs::File::open(&zip_path)?;
    let mut archive = zip::ZipArchive::new(&mut zip_file)?;

    // Get all new top level folders
    let new_top_level_folders = archive
        .file_names()
        .filter_map(|name| name.split('/').next())
        .collect::<HashSet<_>>();

    // Remove all new top level addon folders.
    for folder in new_top_level_folders {
        let path = to_directory.join(&folder);

        if path.exists() {
            let _ = std::fs::remove_dir_all(path);
        }
    }

    let mut toc_files = vec![];

    for i in 0..archive.len() {
        let mut file = archive.by_index(i)?;
        #[allow(deprecated)]
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

    let mut addon_folders: Vec<_> = toc_files
        .iter()
        .filter_map(|p| parse_toc_path(&p))
        .collect();
    addon_folders.sort();

    Ok(addon_folders)
}
