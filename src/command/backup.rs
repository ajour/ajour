use crate::cli::BackupFolder;
use crate::Result;

use ajour_core::backup::{self, backup_folders};
use ajour_core::config::{load_config, Flavor};
use eyre::eyre;

use async_std::task;
use std::path::PathBuf;

pub fn backup(
    backup_folder: BackupFolder,
    destination: PathBuf,
    flavors: Vec<Flavor>,
) -> Result<()> {
    task::block_on(async {
        let config = load_config().await?;

        let flavors = if flavors.is_empty() {
            Flavor::ALL.to_vec()
        } else {
            flavors
        };

        if !destination.is_dir() {
            return Err(eyre!("destination must be a folder, not a file"));
        }

        let wow_dir = config.wow.directory.as_ref().ok_or_else(|| eyre!("No WoW directory set. Launch Ajour and make sure a WoW directory is set before using the command line."))?;

        log::info!(
            "Backing up:\n\tbackup folders: {:?}\n\tflavors: {:?}\n\tdestination: {:?}",
            backup_folder,
            flavors,
            destination
        );

        let mut src_folders = vec![];

        for flavor in flavors {
            let addon_directory = config.get_addon_directory_for_flavor(&flavor).ok_or_else(|| eyre!("No WoW directory set. Launch Ajour and make sure a WoW directory is set before using the command line."))?;
            let wtf_directory = config.get_wtf_directory_for_flavor(&flavor).ok_or_else(|| eyre!("No WoW directory set. Launch Ajour and make sure a WoW directory is set before using the command line."))?;

            let addons_folder = backup::BackupFolder::new(&addon_directory, &wow_dir);
            let wtf_folder = backup::BackupFolder::new(&wtf_directory, &wow_dir);

            match backup_folder {
                BackupFolder::Both => {
                    if addon_directory.exists() && wtf_directory.exists() {
                        src_folders.push(addons_folder);
                        src_folders.push(wtf_folder);
                    }
                }
                BackupFolder::AddOns => {
                    if addon_directory.exists() {
                        src_folders.push(addons_folder);
                    }
                }
                BackupFolder::WTF => {
                    if wtf_directory.exists() {
                        src_folders.push(wtf_folder);
                    }
                }
            }
        }

        backup_folders(src_folders, destination).await?;

        log::info!("Backup complete!");

        Ok(())
    })
}
