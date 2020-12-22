use crate::{log_error, Result};

use ajour_core::addon::Addon;
use ajour_core::cache::{
    load_addon_cache, load_fingerprint_cache, update_addon_cache, AddonCacheEntry,
};
use ajour_core::config::{load_config, Flavor};
use ajour_core::fs::install_addon;
use ajour_core::network::download_addon;
use ajour_core::parse::update_addon_fingerprint;
use ajour_core::repository::RepositoryPackage;

use async_std::sync::{Arc, Mutex};
use async_std::task;
use eyre::{eyre, WrapErr};
use futures::future::join_all;
use isahc::http::Uri;

use std::collections::hash_map::DefaultHasher;
use std::convert::TryFrom;
use std::hash::Hasher;

pub fn install_from_source(url: Uri, flavor: Flavor) -> Result<()> {
    task::block_on(async {
        log::debug!("Fetching remote info for {:?}", &url);

        // Will use hash of url as temp name to download zip as
        let mut hasher = DefaultHasher::new();
        hasher.write(url.to_string().as_bytes());
        let url_hash = hasher.finish();

        let config = load_config().await?;
        let global_release_channel = config.addons.global_release_channel;

        let addon_cache = Arc::new(Mutex::new(load_addon_cache().await?));
        let fingerprint_cache = Arc::new(Mutex::new(load_fingerprint_cache().await?));

        // Fetch the remote repo metadata
        let mut repo_package = RepositoryPackage::from_source_url(Flavor::Retail, url)?;
        repo_package.resolve_metadata().await?;

        // Build an addon using this repo package
        let mut addon = Addon::empty(&format!("{}", url_hash));
        addon.set_repository(repo_package);

        log::debug!("Installing {} for {:?}", addon.title(), flavor);

        let download_directory = config.get_download_directory_for_flavor(flavor).ok_or_else(|| eyre!("No WoW directory set. Launch Ajour and make sure a WoW directory is set before using the command line."))?;
        let addon_directory = config.get_addon_directory_for_flavor(&flavor).ok_or_else(|| eyre!("No WoW directory set. Launch Ajour and make sure a WoW directory is set before using the command line."))?;

        // Download the addon
        download_addon(&addon, global_release_channel, &download_directory).await?;
        log::debug!("Addon downloaded");

        // Install the addon and update Addon with the unpacked folders
        let addon_folders = install_addon(&addon, &download_directory, &addon_directory).await?;
        log::debug!("Addon unpacked");

        addon.update_addon_folders(addon_folders);

        // Update cache with new entry
        if let Ok(entry) = AddonCacheEntry::try_from(&addon) {
            update_addon_cache(addon_cache.clone(), entry, flavor).await?;
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
        for (addon_dir, result) in join_all(folders_to_fingerprint.into_iter().map(
            |(fingerprint_cache, flavor, addon_dir, addon_id)| async move {
                (
                    addon_dir,
                    update_addon_fingerprint(fingerprint_cache, flavor, addon_dir, addon_id).await,
                )
            },
        ))
        .await
        {
            if let Err(e) = result.context(format!("failed to fingerprint folder: {:?}", addon_dir))
            {
                // Log any errors fingerprinting the folder
                log_error(&e);
            }
        }

        log::debug!("Addon successfully installed!");

        Result::Ok(())
    })
}
