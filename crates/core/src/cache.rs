use crate::addon::Addon;
use crate::bail;
use crate::config::Flavor;
use crate::error::Error;
use crate::fs::{config_dir, PersistentData};
use crate::parse::Fingerprint;
use crate::repository::RepositoryKind;
use crate::Result;

use async_std::fs::rename;
use async_std::sync::{Arc, Mutex};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use std::collections::HashMap;
use std::convert::TryFrom;
use std::path::PathBuf;

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct FingerprintCache(HashMap<Flavor, Vec<Fingerprint>>);

impl FingerprintCache {
    pub(crate) fn get_mut_for_flavor(&mut self, flavor: Flavor) -> &mut Vec<Fingerprint> {
        self.0.entry(flavor).or_default()
    }
}

impl PersistentData for FingerprintCache {
    fn relative_path() -> PathBuf {
        PathBuf::from("cache/fingerprints.yml")
    }
}

pub(crate) async fn load_fingerprint_cache() -> Result<FingerprintCache> {
    // Migrate from the old location to the new location, if exists
    {
        let old_location = config_dir().join("fingerprints.yml");

        if old_location.exists() {
            let new_location = FingerprintCache::path()?;

            let _ = rename(old_location, new_location).await;
        }
    }

    FingerprintCache::load_or_default()
}

#[derive(Serialize, Deserialize, Debug)]
pub enum AddonCache {
    V1(HashMap<Flavor, Vec<AddonCacheEntry>>),
}

impl Default for AddonCache {
    fn default() -> Self {
        AddonCache::V1(Default::default())
    }
}

impl AddonCache {
    pub(crate) fn get_mut_for_flavor(&mut self, flavor: Flavor) -> &mut Vec<AddonCacheEntry> {
        match self {
            AddonCache::V1(cache) => cache.entry(flavor).or_default(),
        }
    }
}

impl PersistentData for AddonCache {
    fn relative_path() -> PathBuf {
        PathBuf::from("cache/addons.yml")
    }
}

pub(crate) async fn load_addon_cache() -> Result<AddonCache> {
    AddonCache::load_or_default()
}

/// Update the cache with input entry. If an entry already exists in the cache,
/// with the same folder names as the input entry, that entry will be deleted
/// before inserting the input entry.
pub(crate) async fn update_addon_cache(
    addon_cache: Arc<Mutex<AddonCache>>,
    entry: AddonCacheEntry,
    flavor: Flavor,
) -> Result<AddonCacheEntry> {
    // Lock mutex to get mutable access and block other tasks from trying to update
    let mut addon_cache = addon_cache.lock().await;

    // Get entries for flavor
    let entries = addon_cache.get_mut_for_flavor(flavor);

    // Remove old entry, if it exists. Will remove entry if either folder names or title match
    entries.retain(|e| !(e.folder_names == entry.folder_names || e.title == entry.title));

    // Add new entry
    entries.push(entry.clone());

    // Persist changes to filesystem
    let _ = addon_cache.save();

    Ok(entry)
}

/// Remove the cache entry that has the same folder names
/// as the input entry. Will return the removed entry, if applicable.
pub(crate) async fn remove_addon_cache_entry(
    addon_cache: Arc<Mutex<AddonCache>>,
    entry: AddonCacheEntry,
    flavor: Flavor,
) -> Option<AddonCacheEntry> {
    // Lock mutex to get mutable access and block other tasks from trying to update
    let mut addon_cache = addon_cache.lock().await;

    // Get entries for flavor
    let entries = addon_cache.get_mut_for_flavor(flavor);

    // Remove old entry, if it exists. Will remove entry if either folder names or title match
    if let Some(idx) = entries
        .iter()
        .position(|e| e.folder_names == entry.folder_names || e.title == entry.title)
    {
        let entry = entries.remove(idx);

        // Persist changes to filesystem
        let _ = addon_cache.save();

        Some(entry)
    } else {
        None
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct AddonCacheEntry {
    pub title: String,
    pub repository: RepositoryKind,
    pub repository_id: String,
    pub primary_folder_id: String,
    pub folder_names: Vec<String>,
    pub modified: DateTime<Utc>,
}

impl TryFrom<&Addon> for AddonCacheEntry {
    type Error = Error;

    fn try_from(addon: &Addon) -> Result<Self> {
        if let (Some(repository), Some(repository_id)) =
            (addon.repository_kind(), addon.repository_id())
        {
            let mut folder_names: Vec<_> = addon.folders.iter().map(|a| a.id.clone()).collect();
            folder_names.sort();

            Ok(AddonCacheEntry {
                title: addon.title().to_owned(),
                repository,
                repository_id: repository_id.to_owned(),
                primary_folder_id: addon.primary_folder_id.clone(),
                folder_names,
                modified: Utc::now(),
            })
        } else {
            bail!(
                "No repository information set for cache entry: {}",
                addon.title()
            );
        }
    }
}
