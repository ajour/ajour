#![allow(clippy::type_complexity)]

use crate::log_error;

use ajour_core::addon::{Addon, Repository};
use ajour_core::cache::{
    load_addon_cache, load_fingerprint_cache, update_addon_cache, AddonCache, AddonCacheEntry,
    FingerprintCache,
};
use ajour_core::config::{load_config, Flavor};
use ajour_core::error::ClientError;
use ajour_core::fs::install_addon;
use ajour_core::network::download_addon;
use ajour_core::parse::{read_addon_directory, update_addon_fingerprint};
use ajour_core::Result;

use async_std::sync::{Arc, Mutex};
use async_std::task;

use futures::future::join_all;

use isahc::config::RedirectPolicy;
use isahc::prelude::*;

use std::convert::TryFrom;
use std::path::PathBuf;

pub fn update_all_addons() -> Result<()> {
    log::info!("Checking for addon updates...");

    task::block_on(async {
        let config = load_config().await?;

        let fingerprint_cache: Arc<Mutex<_>> =
            Arc::new(Mutex::new(load_fingerprint_cache().await?));

        let addon_cache: Arc<Mutex<_>> = Arc::new(Mutex::new(load_addon_cache().await?));

        let mut addons_to_update = vec![];

        // API request will get limited to 6 per host
        let shared_client = Arc::new(
            HttpClient::builder()
                .redirect_policy(RedirectPolicy::Follow)
                .max_connections_per_host(6)
                .build()
                .unwrap(),
        );

        // Update addons for both flavors
        for flavor in Flavor::ALL.iter() {
            // Only returns None if the path isn't set in the config
            let addon_directory = config.get_addon_directory_for_flavor(flavor).ok_or_else(|| ClientError::Custom("No WoW directory set. Launch Ajour and make sure a WoW directory is set before using the command line.".to_string()))?;

            if let Ok(addons) = read_addon_directory(
                Some(addon_cache.clone()),
                Some(fingerprint_cache.clone()),
                &addon_directory,
                *flavor,
            )
            .await
            {
                // Get any saved release channel preferences from config
                let release_channels = config
                    .addons
                    .release_channels
                    .get(flavor)
                    .cloned()
                    .unwrap_or_default();

                // Get any ingnored addons from the config
                let ignored_ids = config
                    .addons
                    .ignored
                    .get(flavor)
                    .cloned()
                    .unwrap_or_default();

                // Filter out any ignored addons
                for mut addon in addons
                    .into_iter()
                    .filter(|a| !ignored_ids.iter().any(|i| i == &a.primary_folder_id))
                {
                    // Apply release channel preference
                    if let Some(channel) = release_channels.get(&addon.primary_folder_id) {
                        addon.release_channel = *channel;
                    }

                    if let Some(package) = addon.relevant_release_package() {
                        // Directory to temporarily save downloaded addon
                        let temp_directory = config
                            .get_download_directory_for_flavor(*flavor)
                            .expect("Expected a valid path");

                        // Only add addons that have an update available
                        if addon.is_updatable(package) {
                            addons_to_update.push((
                                shared_client.clone(),
                                addon_cache.clone(),
                                fingerprint_cache.clone(),
                                *flavor,
                                addon,
                                temp_directory,
                                addon_directory.clone(),
                            ));
                        }
                    }
                }
            }
        }

        let num_updates = addons_to_update.len();
        let mut num_errors = 0;

        log::info!("{} addons have an update available", num_updates);

        addons_to_update
            .iter()
            .for_each(|(_, _, _, flavor, addon, ..)| {
                let current_version = addon.version().unwrap_or_default();
                let new_version = addon
                    .relevant_release_package()
                    .map(|p| p.version.clone())
                    .unwrap_or_default();

                log::info!(
                    "\t{} - {}, {} -> {}",
                    &addon.primary_folder_id,
                    flavor,
                    current_version,
                    new_version
                );
            });

        if num_updates > 0 {
            log::info!("Updating... this may take a minute");
        }

        // Call `update_addon` on each addon concurrently
        for result in join_all(addons_to_update.into_iter().map(update_addon)).await {
            // Log any errors updating an addon
            if let Err(e) = result {
                log_error(&e);

                num_errors += 1;
            }
        }

        if num_errors > 0 {
            log::error!("{} addons failed to update", num_errors);
        } else if num_updates > 0 {
            log::info!("All addons updated successfully!");
        } else if num_updates == 0 {
            log::info!("All addons are up to date!");
        }

        Result::Ok(())
    })
}

/// Updates an addon
///
/// Downloads the latest file, extracts it and refingerprints the addon, saving it to the cache.
async fn update_addon(
    (
        shared_client,
        addon_cache,
        fingerprint_cache,
        flavor,
        mut addon,
        temp_directory,
        addon_directory,
    ): (
        Arc<HttpClient>,
        Arc<Mutex<AddonCache>>,
        Arc<Mutex<FingerprintCache>>,
        Flavor,
        Addon,
        PathBuf,
        PathBuf,
    ),
) -> Result<()> {
    // Download the update to the temp directory
    download_addon(&shared_client, &addon, &temp_directory).await?;

    // Extracts addon from the downloaded archive to the addon directory and removes the archive
    let mut installed_folders = install_addon(&addon, &temp_directory, &addon_directory).await?;

    // Update addon based on installed folders
    if !installed_folders.is_empty() {
        installed_folders.sort_by(|a, b| a.id.cmp(&b.id));

        // Assign the primary folder id based on the first folder alphabetically with
        // a matching repository identifier otherwise just the first
        // folder alphabetically
        let primary_folder_id = if let Some(folder) = installed_folders.iter().find(|f| {
            if let Some(repo) = addon.active_repository {
                match repo {
                    Repository::Curse => {
                        addon.repository_id()
                            == f.repository_identifiers.curse.as_ref().map(i32::to_string)
                    }
                    Repository::Tukui => addon.repository_id() == f.repository_identifiers.tukui,
                    Repository::WowI => addon.repository_id() == f.repository_identifiers.wowi,
                }
            } else {
                false
            }
        }) {
            folder.id.clone()
        } else {
            // Wont fail since we already checked if vec is empty
            installed_folders.get(0).map(|f| f.id.clone()).unwrap()
        };
        addon.primary_folder_id = primary_folder_id;
        addon.folders = installed_folders;
    }

    // Stores each folder name we need to fingerprint
    let mut folders_to_fingerprint = vec![];

    // Store all folder names
    folders_to_fingerprint.extend(addon.folders.iter().map(|f| {
        (
            fingerprint_cache.clone(),
            flavor,
            &addon_directory,
            f.id.clone(),
        )
    }));

    // Call `update_addon_fingerprint` on each folder concurrently
    for result in join_all(folders_to_fingerprint.into_iter().map(
        |(fingerprint_cache, flavor, addon_dir, addon_id)| {
            update_addon_fingerprint(fingerprint_cache, flavor, addon_dir, addon_id)
        },
    ))
    .await
    {
        if let Err(e) = result {
            // Log any errors fingerprinting the folder
            log_error(&e);
        }
    }

    // Update cache for addon
    if addon.active_repository == Some(Repository::Tukui)
        || addon.active_repository == Some(Repository::WowI)
    {
        if let Ok(entry) = AddonCacheEntry::try_from(&addon) {
            update_addon_cache(addon_cache, entry, flavor).await?;
        }
    }

    Ok(())
}
