use crate::cli::BackupFolder;
use crate::Result;

use ajour_core::backup::{self, backup_folders};
use ajour_core::config::{load_config, Flavor};
use ajour_core::repository::CompressionFormat;
use anyhow::format_err;

use async_std::task;
use std::fs::create_dir;
use std::path::PathBuf;

pub fn backup(
    backup_folder: BackupFolder,
    destination: PathBuf,
    flavors: Vec<Flavor>,
    compression_format: CompressionFormat,
    zstd_level: i32,
) -> Result<()> {
    task::block_on(async {
        let config = load_config().await?;

        let flavors = if flavors.is_empty() {
            Flavor::ALL.to_vec()
        } else {
            flavors
        };

        if !destination.exists() {
            create_dir(destination.clone())?;
        }

        if !destination.is_dir() {
            return Err(format_err!("destination must be a folder, not a file"));
        }

        if config.wow.directories.keys().next().is_none() {
            return Err(format_err!("No WoW directories set. Launch Ajour and make sure a WoW directory is set before using the command line."));
        }

        log::info!(
            "Backing up:\n\tbackup folders: {:?}\n\tflavors: {:?}\n\tdestination: {:?}\n\tcompression format: {:?}",
            backup_folder,
            flavors,
            destination,
            compression_format,
        );

        let mut src_folders = vec![];

        for flavor in flavors {
            let wow_directory = match config.get_root_directory_for_flavor(&flavor) {
                Some(path) => path,
                None => continue,
            };
            let addon_directory = match config.get_addon_directory_for_flavor(&flavor) {
                Some(path) => path,
                None => continue,
            };
            let wtf_directory = match config.get_wtf_directory_for_flavor(&flavor) {
                Some(path) => path,
                None => continue,
            };

            let screenshot_directory = match config.get_screenshots_directory_for_flavor(&flavor) {
                Some(path) => path,
                None => continue,
            };

            let addons_folder = backup::BackupFolder::new(&addon_directory, &wow_directory);
            let wtf_folder = backup::BackupFolder::new(&wtf_directory, &wow_directory);
            let screenshots_folder =
                backup::BackupFolder::new(&screenshot_directory, &wow_directory);

            match backup_folder {
                BackupFolder::All => {
                    if addon_directory.exists() && wtf_directory.exists() {
                        src_folders.push(addons_folder);
                        src_folders.push(wtf_folder);
                        src_folders.push(screenshots_folder);
                    }
                }
                BackupFolder::AddOns => {
                    if addon_directory.exists() {
                        src_folders.push(addons_folder);
                    }
                }
                BackupFolder::Wtf => {
                    if wtf_directory.exists() {
                        src_folders.push(wtf_folder);
                    }
                }
                BackupFolder::Screenshots => {
                    if screenshot_directory.exists() {
                        src_folders.push(screenshots_folder);
                    }
                }
                _ => {}
            }
        }

        match backup_folder {
            BackupFolder::Config | BackupFolder::All => {
                let config_path = ajour_core::fs::config_dir();
                if let Some(config_prefix) = config_path.parent() {
                    src_folders.push(backup::BackupFolder::new(&config_path, config_prefix));
                }
            }
            _ => {}
        }

        backup_folders(src_folders, destination, compression_format, zstd_level).await?;

        log::info!("Backup complete!");

        Ok(())
    })
}
