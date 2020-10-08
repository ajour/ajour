#![allow(clippy::type_complexity)]

use crate::log_error;

use ajour_core::addon::Addon;
use ajour_core::config::{load_config, Flavor};
use ajour_core::error::ClientError;
use ajour_core::fs::install_addon;
use ajour_core::network::download_addon;
use ajour_core::parse::{read_addon_directory, update_addon_fingerprint, FingerprintCollection};
use ajour_core::Result;

use async_std::sync::{Arc, Mutex};
use async_std::task;

use futures::future::join_all;

use isahc::config::RedirectPolicy;
use isahc::prelude::*;

use std::collections::HashMap;
use std::path::PathBuf;

pub fn update_all_addons() -> Result<()> {
    log::info!("Checking for addon updates...");

    task::block_on(async {
        let config = load_config().await?;

        // Fingerprint cache will be fetched during `read_addon_directory`
        let fingerprint_collection: Arc<Mutex<_>> = Default::default();

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

            if let Ok(addons) =
                read_addon_directory(fingerprint_collection.clone(), &addon_directory, *flavor)
                    .await
            {
                // Get any saved release channel preferences from config
                let default = HashMap::new();
                let release_channels = config
                    .addons
                    .release_channels
                    .get(flavor)
                    .unwrap_or(&default);

                for mut addon in addons {
                    // Apply release channel preference
                    if let Some(channel) = release_channels.get(&addon.id) {
                        addon.release_channel = *channel;
                    }

                    if let Some(package) = addon.relevant_release_package() {
                        // Directory to temporarily save downloaded addon
                        let temp_directory = config
                            .get_temporary_addon_directory(*flavor)
                            .expect("Expected a valid path");

                        // Only add addons that have an update available
                        if addon.is_updatable(package) {
                            addons_to_update.push((
                                shared_client.clone(),
                                fingerprint_collection.clone(),
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
            .for_each(|(_, _, flavor, addon, ..)| {
                let current_version = addon.version.as_deref().unwrap_or_default();
                let new_version = addon
                    .relevant_release_package()
                    .map(|p| p.version.clone())
                    .unwrap_or_default();

                log::info!(
                    "\t{} - {}, {} -> {}",
                    &addon.id,
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
    (shared_client, fingerprint_collection, flavor, addon, temp_directory, addon_directory): (
        Arc<HttpClient>,
        Arc<Mutex<Option<FingerprintCollection>>>,
        Flavor,
        Addon,
        PathBuf,
        PathBuf,
    ),
) -> Result<()> {
    // Download the update to the temp directory
    download_addon(&shared_client, &addon, &temp_directory).await?;

    // Extracts addon from the downloaded archive to the addon directory and removes the archive
    install_addon(&addon, &temp_directory, &addon_directory).await?;

    // Stores each folder name we need to fingerprint
    let mut folders_to_fingerprint = vec![];

    // Store main addon
    folders_to_fingerprint.push((
        fingerprint_collection.clone(),
        flavor,
        &addon_directory,
        addon.id.clone(),
    ));

    // Store all dependencies
    folders_to_fingerprint.extend(addon.dependencies.iter().map(|id| {
        (
            fingerprint_collection.clone(),
            flavor,
            &addon_directory,
            id.clone(),
        )
    }));

    // Call `update_addon_fingerprint` on each folder concurrently
    for result in join_all(folders_to_fingerprint.into_iter().map(
        |(fingerprint_collection, flavor, addon_dir, addon_id)| {
            update_addon_fingerprint(fingerprint_collection, flavor, addon_dir, addon_id)
        },
    ))
    .await
    {
        if let Err(e) = result {
            // Log any errors fingerprinting the folder
            log_error(&e);
        }
    }

    Ok(())
}
