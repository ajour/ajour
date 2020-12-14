use crate::addon::{Addon, AddonFolder};
use crate::config::Flavor;
use crate::error::{CacheError, FilesystemError};
use crate::fs::{config_dir, PersistentData};
use crate::parse::Fingerprint;
use crate::repository::RepositoryKind;

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

    pub(crate) fn flavor_exists(&self, flavor: Flavor) -> bool {
        self.0.contains_key(&flavor)
    }

    pub(crate) fn delete_flavor(&mut self, flavor: Flavor) {
        self.0.remove_entry(&flavor);
    }
}

impl PersistentData for FingerprintCache {
    fn relative_path() -> PathBuf {
        PathBuf::from("cache/fingerprints.yml")
    }
}

pub async fn load_fingerprint_cache() -> Result<FingerprintCache, CacheError> {
    // Migrate from the old location to the new location, if exists
    {
        let old_location = config_dir().join("fingerprints.yml");

        if old_location.exists() {
            let new_location = FingerprintCache::path()?;

            rename(old_location, new_location)
                .await
                .map_err(FilesystemError::IO)?;
        }
    }

    Ok(FingerprintCache::load_or_default()?)
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

pub async fn load_addon_cache() -> Result<AddonCache, CacheError> {
    Ok(AddonCache::load_or_default()?)
}

/// Update the cache with input entry. If an entry already exists in the cache,
/// with the same folder names as the input entry, that entry will be deleted
/// before inserting the input entry.
pub async fn update_addon_cache(
    addon_cache: Arc<Mutex<AddonCache>>,
    entry: AddonCacheEntry,
    flavor: Flavor,
) -> Result<AddonCacheEntry, CacheError> {
    // Lock mutex to get mutable access and block other tasks from trying to update
    let mut addon_cache = addon_cache.lock().await;

    // Get entries for flavor
    let entries = addon_cache.get_mut_for_flavor(flavor);

    // Remove old entry, if it exists. Will remove entry if either folder names or title match
    entries.retain(|e| !(e.folder_names == entry.folder_names || e.title == entry.title));

    // Add new entry
    entries.push(entry.clone());

    // Persist changes to filesystem
    addon_cache.save()?;

    Ok(entry)
}

/// Remove the cache entry that has the same folder names
/// as the input entry. Will return the removed entry, if applicable.
pub async fn remove_addon_cache_entry(
    addon_cache: Arc<Mutex<AddonCache>>,
    entry: AddonCacheEntry,
    flavor: Flavor,
) -> Result<Option<AddonCacheEntry>, CacheError> {
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
        addon_cache.save()?;

        Ok(Some(entry))
    } else {
        Ok(None)
    }
}

/// Removes addon cache entires that have folder
/// names that are missing in the input `folders`
///
/// Pass `false` to save_cache for testing purposes
pub async fn remove_addon_entries_with_missing_folders(
    addon_cache: Arc<Mutex<AddonCache>>,
    flavor: Flavor,
    folders: &[AddonFolder],
    save_cache: bool,
) -> Result<usize, CacheError> {
    // Name of all folders to check against
    let folder_names = folders.iter().map(|f| f.id.clone()).collect::<Vec<_>>();

    // Lock mutex to get mutable access and block other tasks from trying to update
    let mut addon_cache = addon_cache.lock().await;

    // Get entries for flavor
    let entries = addon_cache.get_mut_for_flavor(flavor);

    // Get the idx of any entry that has a folder name that's missing
    // from our input folders
    let entries_to_delete = entries
        .iter()
        .cloned()
        .enumerate()
        .filter(|(_, entry)| !entry.folder_names.iter().all(|f| folder_names.contains(&f)))
        .map(|(idx, _)| idx)
        .collect::<Vec<_>>();

    if !entries_to_delete.is_empty() {
        // Remove each entry, accounting for offset since items shift left on
        // each remove
        for (offset, idx) in entries_to_delete.iter().enumerate() {
            entries.remove(*idx - offset);
        }

        // Persist changes to filesystem
        if save_cache {
            addon_cache.save()?;
        }
    }

    // Return number of entries deleted
    Ok(entries_to_delete.len())
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
    type Error = CacheError;

    fn try_from(addon: &Addon) -> Result<Self, CacheError> {
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
            Err(CacheError::AddonMissingRepo {
                title: addon.title().to_owned(),
            })
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::repository::RepositoryIdentifiers;

    use async_std::task;

    #[test]
    fn test_remove_entries_with_missing_folders() {
        task::block_on(async {
            let flavor = Flavor::Retail;

            let addon_folders = (0..30)
                .map(|idx| AddonFolder {
                    id: format!("folder_{}", idx + 1),
                    title: format!("folder_{}", idx + 1),
                    interface: Default::default(),
                    path: Default::default(),
                    author: Default::default(),
                    notes: Default::default(),
                    version: Default::default(),
                    repository_identifiers: RepositoryIdentifiers {
                        curse: Some(idx as i32),
                        ..Default::default()
                    },
                    dependencies: Default::default(),
                    fingerprint: Default::default(),
                })
                .collect::<Vec<_>>();

            let cache = {
                let cache: Arc<Mutex<AddonCache>> = Default::default();
                let mut cache_lock = cache.lock_arc().await;

                let entries = cache_lock.get_mut_for_flavor(flavor);

                entries.extend(addon_folders.chunks(10).enumerate().map(|(idx, folders)| {
                    AddonCacheEntry {
                        title: format!("Test{}", idx + 1),
                        repository: RepositoryKind::Tukui,
                        repository_id: format!("{}", idx + 1),
                        primary_folder_id: folders.first().map(|f| f.id.clone()).unwrap(),
                        folder_names: folders.iter().map(|f| f.id.clone()).collect(),
                        modified: Utc::now(),
                    }
                }));

                cache
            };

            // Remove partial 1 folder from the first 10, then all folders of
            // the last 10. Only the middle 10 folders are fully in tact,
            // meaning on the 2nd entry should remain after this operation
            let num_deleted = remove_addon_entries_with_missing_folders(
                cache.clone(),
                flavor,
                &addon_folders[5..20],
                false,
            )
            .await
            .unwrap();

            assert_eq!(num_deleted, 2);

            let mut cache_lock = cache.lock().await;

            let entries = cache_lock.get_mut_for_flavor(flavor);

            let names = entries.iter().map(|e| e.title.clone()).collect::<Vec<_>>();

            assert_eq!(names, vec!["Test2".to_string()]);
        });
    }
}
