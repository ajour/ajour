use crate::{
    addon::{Addon, AddonFolder, AddonState},
    cache::{self, AddonCache, AddonCacheEntry, FingerprintCache},
    config::Flavor,
    error::{CacheError, DownloadError, ParseError, RepositoryError},
    fs::PersistentData,
    murmur2::calculate_hash,
    repository::{curse, tukui, wowi, RepositoryIdentifiers, RepositoryKind, RepositoryPackage},
};
use async_std::sync::{Arc, Mutex};
use fancy_regex::Regex;
use futures::future::join_all;
use isahc::http::Uri;
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs::File;
use std::io::{BufRead, BufReader, Read};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::SystemTime;

lazy_static::lazy_static! {
    static ref CACHED_GAME_INFO: Mutex<Option<curse::GameInfo>> = Mutex::new(None);
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Clone)]
pub struct Fingerprint {
    pub title: String,
    pub hash: Option<u32>,
    pub modified: SystemTime,
}

pub struct ParsingPatterns {
    pub initial_inclusion_regex: Regex,
    pub extra_inclusion_regex: Regex,
    pub file_parsing_regex: HashMap<String, (regex::Regex, Regex)>,
}

pub async fn read_addon_directory<P: AsRef<Path>>(
    addon_cache: Option<Arc<Mutex<AddonCache>>>,
    fingerprint_cache: Option<Arc<Mutex<FingerprintCache>>>,
    root_dir: P,
    flavor: Flavor,
) -> Result<Vec<Addon>, ParseError> {
    log::debug!("{} - parsing addons folder", flavor);

    let root_dir = root_dir.as_ref();

    // If the path does not exists or does not point on a directory we return an Error.
    if !root_dir.is_dir() {
        // Delete fingerprints if flavor addon folder no longer exists on filesystem
        if let Some(fingerprint_cache) = &fingerprint_cache {
            let mut cache = fingerprint_cache.lock().await;

            if cache.flavor_exists(flavor) {
                cache.delete_flavor(flavor);

                log::info!(
                    "{} - deleting cached fingerprints since AddOns folder doesn't exist",
                    flavor
                )
            }

            cache.save()?;
        }

        return Err(ParseError::MissingAddonDirectory {
            path: root_dir.to_owned(),
        });
    }

    // All addon dirs gathered in a `Vec<String>`.
    let all_dirs: Vec<String> = root_dir
        .read_dir()
        .unwrap()
        .filter_map(|entry| {
            let entry = entry.unwrap();
            if entry.file_type().unwrap().is_dir() {
                Some(entry.file_name().to_str().unwrap().to_string())
            } else {
                None
            }
        })
        .collect();

    log::debug!(
        "{} - {} folders in AddOns directory to parse",
        flavor,
        all_dirs.len()
    );

    // Return early if there are no directories to parse
    if all_dirs.is_empty() {
        // Delete all cached fingerprints for this flavor since there are no addon folders
        if let Some(fingerprint_cache) = &fingerprint_cache {
            let mut cache = fingerprint_cache.lock().await;

            if cache.flavor_exists(flavor) {
                cache.delete_flavor(flavor);

                log::info!(
                    "{} - deleting cached fingerprints since AddOns folder is empty",
                    flavor
                )
            }

            cache.save()?;
        }

        return Ok(vec![]);
    }

    // Get from cache / calculate fingerprints for all directories
    let fingerprints = fingerprint_all_dirs(root_dir, flavor, &all_dirs, fingerprint_cache).await?;

    // Parse all addon folders from `.toc` file in each directory and assign it's
    // respective fingerprint
    let mut addon_folders = parse_addon_folders(root_dir, flavor, &all_dirs, &fingerprints).await;

    // Get all cached entries
    let cache_entries = get_cache_entries(flavor, addon_cache, &addon_folders).await?;

    // Get fingerprint info for all non-cached addon folders
    let fingerprint_info =
        get_curse_fingerprint_info(flavor, &addon_folders, &cache_entries).await?;

    // Gets all unique repository packages from the cached ids, toc ids, and fingerprint exact / partial matches
    let mut all_repo_packages =
        get_all_repo_packages(flavor, &cache_entries, &addon_folders, &fingerprint_info).await?;

    // Build addons with repo packages & addon folders
    let known_addons = build_addons(
        flavor,
        &mut all_repo_packages,
        &mut addon_folders,
        &cache_entries,
    );

    // Any remaining addon folders are unknown, we will show them 1:1 in Ajour
    let unknown_addons = addon_folders
        .into_iter()
        // Blacklist this addon since it's created by Ajour / Companion app and
        // doesn't need to be managed
        .filter(|f| f.id != "WeakAurasCompanion")
        .map(|f| {
            let mut addon = Addon::empty(&f.id);
            addon.folders = vec![f];
            addon.state = AddonState::Unknown;

            addon
        })
        .collect::<Vec<_>>();

    log::debug!(
        "{} - {} unknown addon folders",
        flavor,
        unknown_addons.len()
    );

    // Concats the different repo addons, and returns.
    let concatenated = [&known_addons[..], &unknown_addons[..]].concat();

    log::debug!(
        "{} - {} addons successfully parsed",
        flavor,
        concatenated.len()
    );

    Ok(concatenated)
}

async fn fingerprint_all_dirs(
    root_dir: &Path,
    flavor: Flavor,
    all_dirs: &[String],
    fingerprint_cache: Option<Arc<Mutex<FingerprintCache>>>,
) -> Result<Vec<Fingerprint>, ParseError> {
    let mut fingerprint_cache = if let Some(fingerprint_cache) = fingerprint_cache {
        Some(fingerprint_cache.lock_arc().await)
    } else {
        None
    };
    let mut fingerprints = fingerprint_cache
        .as_mut()
        .map(|c| c.get_mut_for_flavor(flavor));

    // Each addon dir mapped to fingerprint struct.
    let num_cached = AtomicUsize::new(0);
    let new_fingerprints: Vec<_> = all_dirs
        .par_iter() // Easy parallelization
        .map(|dir_name| {
            let addon_dir = root_dir.join(dir_name);
            let modified = if let Ok(metadata) = addon_dir.metadata() {
                metadata.modified().unwrap_or_else(|_| SystemTime::now())
            } else {
                SystemTime::now()
            };

            // If we have a stored fingerprint on disk, we use that.
            if let Some(fingerprint) = fingerprints
                .as_ref()
                .unwrap_or(&&mut vec![])
                .iter()
                .find(|f| &f.title == dir_name && f.modified == modified)
            {
                let _ = num_cached.fetch_add(1, Ordering::SeqCst);
                fingerprint.to_owned()
            } else {
                let hash_result = fingerprint_addon_dir(&addon_dir);

                let hash = match hash_result {
                    Ok(hash) => Some(hash),
                    Err(e) => {
                        log::error!("fingerprinting failed for {:?}: {}", addon_dir, e);
                        None
                    }
                };

                Fingerprint {
                    title: dir_name.to_owned(),
                    hash,
                    modified,
                }
            }
        })
        // Note: we filter out cases where hashing has failed.
        .filter(|f| f.hash.is_some())
        .collect();

    {
        let num_cached = num_cached.load(Ordering::Relaxed);
        let change = fingerprints.as_ref().map(|f| f.len()).unwrap_or_default() as isize
            - new_fingerprints.len() as isize;
        let removed = change.max(0);
        let added = change.min(0).abs();

        log::debug!(
            "{} - {} fingerprints: {} cached, {} calculated, {} added, {} removed",
            flavor,
            new_fingerprints.len(),
            num_cached,
            new_fingerprints.len() - num_cached,
            added,
            removed
        );
    }

    // Update our in memory collection. We must then drop it to get a reference
    // to our fingerprint cache as this currently holds a mutable reference.
    if let Some(fingerprints) = fingerprints.as_mut() {
        fingerprints.drain(..);
        fingerprints.extend(new_fingerprints.clone());
    }
    drop(fingerprints);

    // Persist cache changes to disk
    if let Some(fingerprint_cache) = fingerprint_cache.as_ref() {
        let _ = fingerprint_cache.save();
    }

    // Drop Mutex guard, cache is no longer needed.
    drop(fingerprint_cache);

    Ok(new_fingerprints)
}

async fn parse_addon_folders(
    root_dir: &Path,
    flavor: Flavor,
    all_dirs: &[String],
    fingerprints: &[Fingerprint],
) -> Vec<AddonFolder> {
    let mut addon_folders: Vec<_> = all_dirs
        .par_iter()
        .filter_map(|id| {
            // Generate .toc path.
            let toc_path = root_dir.join(&id).join(format!("{}.toc", id));
            if !toc_path.exists() {
                return None;
            }

            // We add fingerprint to the addon.
            let mut addon_folder = parse_toc_path(&toc_path)?;
            addon_folder.fingerprint = fingerprints
                .iter()
                .find(|f| &f.title == id)
                .map(|f| f.hash)
                .flatten();

            Some(addon_folder)
        })
        .collect();

    // Ensure addon folders are sorted alphabetically
    addon_folders.sort_by(|a, b| a.id.cmp(&b.id));

    log::debug!(
        "{} - {} addon folders successfully parsed from '.toc'",
        flavor,
        addon_folders.len()
    );

    addon_folders
}

async fn get_cache_entries(
    flavor: Flavor,
    addon_cache: Option<Arc<Mutex<AddonCache>>>,
    addon_folders: &[AddonFolder],
) -> Result<Vec<AddonCacheEntry>, CacheError> {
    let cache_entries = if let Some(addon_cache) = addon_cache {
        // Remove any cached entries for folders that no longer exist
        // on the filesystem
        {
            let num_removed = cache::remove_addon_entries_with_missing_folders(
                addon_cache.clone(),
                flavor,
                addon_folders,
                true,
            )
            .await?;

            if num_removed > 0 {
                log::debug!(
                    "{} - {} cached entries removed due to missing addon folders",
                    flavor,
                    num_removed
                );
            }
        }

        let mut addon_cache = addon_cache.lock().await;
        let addon_cache_entries = addon_cache.get_mut_for_flavor(flavor);

        addon_cache_entries.to_vec()
    } else {
        vec![]
    };

    log::debug!(
        "{} - {} valid cache entries retrieved",
        flavor,
        cache_entries.len()
    );

    Ok(cache_entries)
}

async fn get_curse_fingerprint_info(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
    cache_entries: &[AddonCacheEntry],
) -> Result<curse::FingerprintInfo, ParseError> {
    // Get all fingerprint hashes
    let mut fingerprint_hashes: Vec<_> = addon_folders
        .iter()
        // Remove all addon folders that exist in the cache, since we
        // will extract the proper repository to query from the cache entry
        .filter(|folder| {
            cache_entries
                .iter()
                .map(|e| &e.folder_names)
                .flatten()
                .position(|name| name == &folder.id)
                .is_none()
        })
        .filter_map(|folder| folder.fingerprint)
        .collect();
    fingerprint_hashes.dedup();

    log::debug!(
        "{} - {} unique fingerprints to check against curse api",
        flavor,
        fingerprint_hashes.len()
    );

    // Fetches fingerprint package from curse_api
    let mut fingerprint_info =
        curse::fetch_remote_packages_by_fingerprint(&fingerprint_hashes).await?;

    // We had a case where a addon hash returned a minecraft addon.
    // So we filter out all matches which does not have a valid flavor.
    fingerprint_info
        .partial_matches
        .retain(|a| a.file.game_version_flavor.is_some());

    fingerprint_info
        .exact_matches
        .retain(|a| a.file.game_version_flavor.is_some());

    // Log info about partial matches
    {
        for addon in fingerprint_info.partial_matches.iter() {
            let curse_id = addon.file.id;

            let file_name = addon
                .file
                .file_name
                .strip_suffix(".zip")
                .unwrap_or(&addon.file.file_name);

            let mut modules_log = String::new();
            for module in addon.file.modules.iter() {
                let local_fingerprint = addon_folders
                    .iter()
                    .find(|f| f.id == module.foldername)
                    .map(|f| f.fingerprint.unwrap_or_default())
                    .unwrap_or_default();

                modules_log.push_str(&format!(
                    "\n\t{} - {} - {}",
                    module.foldername, local_fingerprint, module.fingerprint
                ));
            }

            log::trace!(
                "{} - partial fingerprint found:\n\tCurse ID: {}\n\tFile Name: {}\n\tModules (Name - Local Fingerprint - Remote Fingerprint){}",
                flavor,
                curse_id,
                file_name,
                modules_log
            );
        }
    }

    Ok(fingerprint_info)
}

async fn get_all_repo_packages(
    flavor: Flavor,
    cache_entries: &[AddonCacheEntry],
    addon_folders: &[AddonFolder],
    fingerprint_info: &curse::FingerprintInfo,
) -> Result<Vec<RepositoryPackage>, DownloadError> {
    let mut curse_ids = vec![];
    let mut tukui_ids = vec![];
    let mut wowi_ids = vec![];
    let mut git_urls = vec![];

    let cached_folder_names: Vec<_> = cache_entries
        .iter()
        .map(|e| &e.folder_names)
        .flatten()
        .collect();

    // Get all possible curse ids
    {
        curse_ids.extend(fingerprint_info.exact_matches.iter().map(|i| i.id));
        curse_ids.extend(fingerprint_info.partial_matches.iter().map(|i| i.id));
        curse_ids.extend(
            addon_folders
                .iter()
                // Remove all addon folders that exist in the cache, since we
                // will extract the proper repository to query from the cache entry
                .filter(|folder| !cached_folder_names.contains(&&folder.id))
                .filter_map(|f| f.repository_identifiers.curse),
        );
        curse_ids.dedup();
    }

    // Get all possible tukui ids
    {
        tukui_ids.extend(
            cache_entries
                .iter()
                .filter(|e| e.repository == RepositoryKind::Tukui)
                .map(|e| e.repository_id.clone()),
        );
        tukui_ids.extend(
            addon_folders
                .iter()
                // Remove all addon folders that exist in the cache, since we
                // will extract the proper repository to query from the cache entry
                .filter(|folder| !cached_folder_names.contains(&&folder.id))
                .filter_map(|f| f.repository_identifiers.tukui.clone()),
        );
        tukui_ids.dedup();
    }

    // Get all possible wowi ids
    {
        wowi_ids.extend(
            cache_entries
                .iter()
                .filter(|e| e.repository == RepositoryKind::WowI)
                .map(|e| e.repository_id.clone()),
        );
        wowi_ids.extend(
            addon_folders
                .iter()
                // Remove all addon folders that exist in the cache, since we
                // will extract the proper repository to query from the cache entry
                .filter(|folder| !cached_folder_names.contains(&&folder.id))
                .filter_map(|f| f.repository_identifiers.wowi.clone()),
        );
        wowi_ids.dedup();
    }

    // Get all possible git urls
    {
        git_urls.extend(
            cache_entries
                .iter()
                .filter(|e| e.repository.is_git())
                .map(|e| e.repository_id.clone()),
        );
        git_urls.dedup();
    }

    // Get all curse repo packages
    let curse_repo_packages = if !curse_ids.is_empty() {
        let mut curse_packages = curse::fetch_remote_packages_by_ids(&curse_ids).await?;

        let mut curse_repo_packages = vec![];

        // Get repo packages from fingerprint exact matches
        curse_repo_packages.extend(
            fingerprint_info
                .exact_matches
                .iter()
                .map(|info| {
                    (
                        info.id.to_string(),
                        curse::metadata_from_fingerprint_info(flavor, info),
                    )
                })
                .filter_map(|(id, metadata)| {
                    RepositoryPackage::from_repo_id(flavor, RepositoryKind::Curse, id)
                        .map(|r| r.with_metadata(metadata))
                        .ok()
                }),
        );

        // Remove any packages that match a fingerprint entry and update missing
        // metadata fields with that package info
        curse_repo_packages.iter_mut().for_each(|r| {
            if let Some(idx) = curse_packages.iter().position(|p| p.id.to_string() == r.id) {
                let package = curse_packages.remove(idx);

                r.metadata.title = Some(package.name.clone());
                r.metadata.website_url = Some(package.website_url.clone());
                r.metadata.changelog_url = Some(format!("{}/files", package.website_url));
            }
        });

        curse_repo_packages.extend(
            curse_packages
                .into_iter()
                .map(|package| {
                    (
                        package.id.to_string(),
                        curse::metadata_from_curse_package(flavor, package),
                    )
                })
                .filter_map(|(id, metadata)| {
                    RepositoryPackage::from_repo_id(flavor, RepositoryKind::Curse, id)
                        .map(|r| r.with_metadata(metadata))
                        .ok()
                }),
        );

        curse_repo_packages
    } else {
        vec![]
    };

    log::debug!(
        "{} - {} curse packages fetched",
        flavor,
        curse_repo_packages.len()
    );

    // Get all tukui repo packages
    let tukui_repo_packages = if !tukui_ids.is_empty() {
        let fetch_tasks: Vec<_> = tukui_ids
            .iter()
            .map(|id| tukui::fetch_remote_package(&id, &flavor))
            .collect();

        join_all(fetch_tasks)
            .await
            .into_iter()
            .filter_map(Result::ok)
            .map(|(id, package)| (id, tukui::metadata_from_tukui_package(package)))
            .filter_map(|(id, metadata)| {
                RepositoryPackage::from_repo_id(flavor, RepositoryKind::Tukui, id)
                    .ok()
                    .map(|r| r.with_metadata(metadata))
            })
            .collect::<Vec<_>>()
    } else {
        vec![]
    };

    log::debug!(
        "{} - {} tukui packages fetched",
        flavor,
        tukui_repo_packages.len()
    );

    // Get all wowi repo packages
    let wowi_repo_packages = if !wowi_ids.is_empty() {
        let wowi_packages = wowi::fetch_remote_packages(&wowi_ids).await?;

        wowi_packages
            .into_iter()
            .map(|package| {
                (
                    package.id.to_string(),
                    wowi::metadata_from_wowi_package(package),
                )
            })
            .filter_map(|(id, metadata)| {
                RepositoryPackage::from_repo_id(flavor, RepositoryKind::WowI, id)
                    .ok()
                    .map(|r| r.with_metadata(metadata))
            })
            .collect::<Vec<_>>()
    } else {
        vec![]
    };

    log::debug!(
        "{} - {} wowi packages fetched",
        flavor,
        wowi_repo_packages.len()
    );

    // Get all git repo packages
    let git_repo_packages = if !git_urls.is_empty() {
        let fetch_tasks = git_urls
            .iter()
            .map(|url| {
                let url = url
                    .parse::<Uri>()
                    .map_err(|_| RepositoryError::GitInvalidUrl { url: url.clone() })?;

                Result::<_, RepositoryError>::Ok(RepositoryPackage::from_source_url(flavor, url)?)
            })
            .filter_map(|result| match result {
                Ok(package) => Some(package),
                Err(e) => {
                    log::error!("{}", e);
                    None
                }
            })
            .map(|mut package| async {
                if let Err(e) = package.resolve_metadata().await {
                    log::error!("{}", e);
                    Err(e)
                } else {
                    Ok(package)
                }
            });

        join_all(fetch_tasks)
            .await
            .into_iter()
            .filter_map(Result::ok)
            .collect::<Vec<_>>()
    } else {
        vec![]
    };

    log::debug!(
        "{} - {} git packages fetched",
        flavor,
        git_repo_packages.len()
    );

    Ok([
        &curse_repo_packages[..],
        &tukui_repo_packages[..],
        &wowi_repo_packages[..],
        &git_repo_packages[..],
    ]
    .concat())
}

fn build_addons(
    flavor: Flavor,
    repo_packages: &mut Vec<RepositoryPackage>,
    addon_folders: &mut Vec<AddonFolder>,
    cache_entries: &[AddonCacheEntry],
) -> Vec<Addon> {
    let cached_addons: Vec<_> = cache_entries
        .iter()
        .filter_map(|e| {
            // Get and remove any matching repo package
            let repo_idx = repo_packages
                .iter()
                .position(|r| r.id == e.repository_id && r.kind == e.repository)?;
            let repo_package = repo_packages.remove(repo_idx);

            // Get and remove all matching addon folders
            let folder_idxs: Vec<_> = addon_folders
                .iter()
                .enumerate()
                .filter(|(_, f)| e.folder_names.contains(&f.id))
                .map(|(idx, _)| idx)
                .collect();

            if folder_idxs.is_empty() {
                log::error!("No addon folders for cached entry: {}", e.title);
                return None;
            }

            let mut folders = vec![];

            for (offset, idx) in folder_idxs.iter().enumerate() {
                folders.push(addon_folders.remove(idx - offset));
            }

            if let Ok(mut addon) = Addon::build_with_repo_and_folders(repo_package, folders) {
                addon.primary_folder_id = e.primary_folder_id.clone();
                Some(addon)
            } else {
                None
            }
        })
        .collect();

    let curse_addons: Vec<_> = repo_packages
        .clone()
        .iter()
        .filter(|r| r.kind == RepositoryKind::Curse)
        .filter_map(|r| {
            // Get and remove all matching addon folders
            let module_names = r.metadata.modules();

            // Get and remove all matching addon folders
            let folder_idxs: Vec<_> = addon_folders
                .iter()
                .enumerate()
                .filter(|(_, f)| module_names.contains(&f.id))
                .map(|(idx, _)| idx)
                .collect();

            if folder_idxs.is_empty() {
                return None;
            }

            let mut folders = vec![];

            for (offset, idx) in folder_idxs.iter().enumerate() {
                folders.push(addon_folders.remove(idx - offset));
            }

            let repo_package = repo_packages.remove(
                repo_packages
                    .iter()
                    .position(|p| r.id == p.id && r.kind == p.kind)
                    .unwrap(),
            );

            Addon::build_with_repo_and_folders(repo_package, folders).ok()
        })
        .collect();

    let tukui_and_wowi_addons: Vec<_> = repo_packages
        .clone()
        .iter()
        .filter(|r| r.kind == RepositoryKind::Tukui || r.kind == RepositoryKind::WowI)
        .filter_map(|r| {
            let mut folders = vec![];

            // Get addon folder with matching repo id
            let matching_folder_idx = addon_folders.iter().position(|f| match r.kind {
                RepositoryKind::Tukui => f.repository_identifiers.tukui.as_ref() == Some(&r.id),
                RepositoryKind::WowI => f.repository_identifiers.wowi.as_ref() == Some(&r.id),
                _ => false,
            })?;

            let matching_folder = addon_folders.remove(matching_folder_idx);

            let dependency_idxs: Vec<_> = addon_folders
                .iter()
                .enumerate()
                .filter(|(_, f)| {
                    matching_folder.dependencies.contains(&f.id)
                        || f.dependencies.contains(&matching_folder.id)
                })
                .map(|(idx, _)| idx)
                .collect();

            folders.push(matching_folder);

            for (offset, idx) in dependency_idxs.iter().enumerate() {
                folders.push(addon_folders.remove(idx - offset));
            }

            let repo_package = repo_packages.remove(
                repo_packages
                    .iter()
                    .position(|p| r.id == p.id && r.kind == p.kind)
                    .unwrap(),
            );

            Addon::build_with_repo_and_folders(repo_package, folders).ok()
        })
        .collect();

    let concatenated_addons = [
        &cached_addons[..],
        &curse_addons[..],
        &tukui_and_wowi_addons[..],
    ]
    .concat();

    log::debug!(
        "{} - {} addons built from curse packages",
        flavor,
        concatenated_addons
            .iter()
            .filter(|a| a.repository_kind() == Some(RepositoryKind::Curse))
            .count()
    );

    log::debug!(
        "{} - {} addons built from tukui packages",
        flavor,
        concatenated_addons
            .iter()
            .filter(|a| a.repository_kind() == Some(RepositoryKind::Tukui))
            .count()
    );

    log::debug!(
        "{} - {} addons built from wowi packages",
        flavor,
        concatenated_addons
            .iter()
            .filter(|a| a.repository_kind() == Some(RepositoryKind::WowI))
            .count()
    );

    log::debug!(
        "{} - {} addons built from git packages",
        flavor,
        concatenated_addons
            .iter()
            .filter(|a| matches!(a.repository_kind(), Some(RepositoryKind::Git(_))))
            .count()
    );

    concatenated_addons
}

pub async fn update_addon_fingerprint(
    fingerprint_cache: Arc<Mutex<FingerprintCache>>,
    flavor: Flavor,
    addon_dir: impl AsRef<Path>,
    addon_id: String,
) -> Result<(), ParseError> {
    log::debug!("{} - updating fingerprint for {}", flavor, &addon_id);

    let addon_path = addon_dir.as_ref().join(&addon_id);

    // Generate new hash, and update collection.
    match fingerprint_addon_dir(&addon_path) {
        Ok(hash) => {
            // Lock Mutex ensuring this is the only operation that can update the cache.
            // This is needed since during `Update All` we can have concurrent operations updating
            // this cache and we need to ensure they don't overwrite eachother.
            let mut fingerprint_cache = fingerprint_cache.lock().await;

            let fingerprints = fingerprint_cache.get_mut_for_flavor(flavor);
            let modified = if let Ok(metadata) = addon_path.metadata() {
                metadata.modified().unwrap_or_else(|_| SystemTime::now())
            } else {
                SystemTime::now()
            };

            // If already in cache, update it. Otherwise add entry to cache
            if let Some(fingerprint) = fingerprints.iter_mut().find(|f| f.title == addon_id) {
                fingerprint.hash = Some(hash);
                fingerprint.modified = modified;
            } else {
                let fingerprint = Fingerprint {
                    title: addon_id.clone(),
                    hash: Some(hash),
                    modified,
                };

                fingerprints.push(fingerprint);
            }

            // Persist cache to disk
            let _ = fingerprint_cache.save();

            // Mutex guard is dropped, allowing other operations to work on FingerprintCache
        }
        Err(e) => {
            log::error!("fingerprinting failed for {:?}: {}", addon_path, e);
        }
    }

    Ok(())
}

pub fn fingerprint_addon_dir(addon_dir: &PathBuf) -> Result<u32, ParseError> {
    let mut to_fingerprint = HashSet::new();
    let mut to_parse = VecDeque::new();
    let root_dir = addon_dir.parent().ok_or(ParseError::NoParentDirectory {
        dir: addon_dir.to_owned(),
    })?;

    // Add initial files
    let glob_pattern = format!(
        "{}/**/*.*",
        addon_dir.to_str().ok_or(ParseError::InvalidUTF8Path {
            path: addon_dir.to_owned(),
        })?
    );
    for path in glob::glob(&glob_pattern)? {
        let path = path?;
        if !path.is_file() {
            continue;
        }

        // Test relative path matches regexes
        let relative_path = path
            .strip_prefix(root_dir)?
            .to_str()
            .ok_or(ParseError::InvalidUTF8Path { path: path.clone() })?
            .to_ascii_lowercase()
            .replace("/", "\\"); // Convert to windows seperator
        if RE_PARSING_PATTERNS
            .initial_inclusion_regex
            .is_match(&relative_path)?
        {
            to_parse.push_back(path);
        } else if RE_PARSING_PATTERNS
            .extra_inclusion_regex
            .is_match(&relative_path)?
        {
            to_fingerprint.insert(path);
        }
    }

    // Parse additional files
    while let Some(path) = to_parse.pop_front() {
        if !path.exists() || !path.is_file() {
            return Err(ParseError::InvalidFile { path });
        }

        to_fingerprint.insert(path.clone());

        // Skip if no rules for extension
        let ext = format!(
            ".{}",
            path.extension()
                .ok_or(ParseError::InvalidExt { path: path.clone() })?
                .to_str()
                .ok_or(ParseError::InvalidUTF8Path { path: path.clone() })?
        );
        if !RE_PARSING_PATTERNS.file_parsing_regex.contains_key(&ext) {
            continue;
        }

        // Parse file for matches
        let (comment_strip_regex, inclusion_regex) = RE_PARSING_PATTERNS
            .file_parsing_regex
            .get(&ext)
            .ok_or(ParseError::ParsingRegexMissingExt { ext })?;
        let mut file = File::open(&path)?;

        let mut buf = vec![];
        file.read_to_end(&mut buf)?;

        let text = String::from_utf8_lossy(&buf);
        let text = comment_strip_regex.replace_all(&text, "");
        for line in text.lines() {
            let mut last_offset = 0;
            while let Some(inc_match) = inclusion_regex.captures_from_pos(line, last_offset)? {
                let prev_last_offset = last_offset;
                last_offset = inc_match
                    .get(0)
                    .ok_or(ParseError::InclusionRegexError {
                        group: 0,
                        pos: prev_last_offset,
                        line: line.to_string(),
                    })?
                    .end();
                let path_match = inc_match
                    .get(1)
                    .ok_or(ParseError::InclusionRegexError {
                        group: 1,
                        pos: prev_last_offset,
                        line: line.to_string(),
                    })?
                    .as_str();
                // Path might be case insensitive and have windows separators. Find it
                let path_match = path_match.replace("\\", "/");
                if let Some(parent) = path.parent() {
                    let file_to_find = parent.join(Path::new(&path_match));

                    if let Some(real_path) = find_file(&file_to_find) {
                        to_parse.push_back(real_path);
                    }
                }
            }
        }
    }

    // Calculate fingerprints
    let mut fingerprints = vec![];
    for path in to_fingerprint.iter() {
        let data: Vec<_> = std::fs::read(path)?
            .into_iter()
            .filter(|&b| b != b' ' && b != b'\n' && b != b'\r' && b != b'\t')
            .collect();

        let hash = calculate_hash(&data, 1);

        fingerprints.push(hash);
    }

    // Calculate overall fingerprint
    fingerprints.sort_unstable();
    let to_hash = fingerprints
        .iter()
        .map(|val| val.to_string())
        .collect::<Vec<_>>()
        .join("");

    Ok(calculate_hash(to_hash.as_bytes(), 1))
}

/// Finds a case sensitive path from an insensitive path
/// Useful if, say, a WoW addon points to a local path in a different case but you're not on Windows
fn find_file<P>(path: P) -> Option<PathBuf>
where
    P: AsRef<Path>,
{
    let mut current = path.as_ref();
    let mut to_finds = Vec::new();

    // Find first parent that exists
    while !current.exists() {
        to_finds.push(current.file_name()?);
        current = current.parent()?;
    }

    // Match to finds
    let mut current = current.to_path_buf();
    to_finds.reverse();
    for to_find in to_finds {
        let mut children = current.read_dir().ok()?;
        let lower = to_find.to_str()?.to_ascii_lowercase();
        let found = children
            .find(|x| {
                if let Ok(x) = x.as_ref() {
                    if let Some(file_name) = x.file_name().to_str() {
                        return file_name.to_ascii_lowercase() == lower;
                    }

                    return false;
                }
                false
            })?
            .ok()?;
        current = found.path();
    }
    Some(current)
}

lazy_static::lazy_static! {
    static ref RE_TOC_LINE: regex::Regex = regex::Regex::new(r"^##\s*(?P<key>.*?)\s*:\s?(?P<value>.*)").unwrap();
    static ref RE_TOC_TITLE: regex::Regex = regex::Regex::new(r"\|(?:[a-fA-F\d]{9}|T[^|]*|t|r|$)").unwrap();
    static ref RE_PARSING_PATTERNS: ParsingPatterns = {
        let mut file_parsing_regex = HashMap::new();
        file_parsing_regex.insert(".xml".to_string(), (
            regex::Regex::new("(?s)<!--.*?-->").unwrap(),
            Regex::new("(?i)<(?:Include|Script)\\s+file=[\"\"']((?:(?<!\\.\\.).)+)[\"\"']\\s*/>").unwrap(),
        ));


        file_parsing_regex.insert(".toc".to_string(), (
            regex::Regex::new("(?m)\\s*#.*$").unwrap(),
            Regex::new("(?mi)^\\s*((?:(?<!\\.\\.).)+\\.(?:xml|lua))\\s*$").unwrap(),
        ));

        ParsingPatterns {
            extra_inclusion_regex: Regex::new("(?i)^[^/\\\\]+[/\\\\]Bindings\\.xml$").unwrap(),
            initial_inclusion_regex: Regex::new("(?i)^([^/]+)[\\\\/]\\1\\.toc$").unwrap(),
            file_parsing_regex,
        }
    };
}

/// Helper function to parse a given TOC file
/// (`DirEntry`) into a `Addon` struct.
///
/// TOC format summary:
/// https://wowwiki.fandom.com/wiki/TOC_format
pub fn parse_toc_path(toc_path: &PathBuf) -> Option<AddonFolder> {
    //direntry
    let file = if let Ok(file) = File::open(toc_path) {
        file
    } else {
        return None;
    };
    let reader = BufReader::new(file);

    let path = toc_path.parent()?.to_path_buf();
    let id = path.file_name()?.to_str()?.to_string();
    let mut title: Option<String> = None;
    let mut interface: Option<String> = None;
    let mut author: Option<String> = None;
    let mut notes: Option<String> = None;
    let mut version: Option<String> = None;
    let mut dependencies: Vec<String> = Vec::new();
    let mut wowi_id: Option<String> = None;
    let mut tukui_id: Option<String> = None;
    let mut curse_id: Option<i32> = None;

    for line in reader.lines().filter_map(|l| l.ok()) {
        for cap in RE_TOC_LINE.captures_iter(line.as_str()) {
            match &cap["key"] {
                // Note: Coloring is possible via UI escape sequences.
                // Since we don't want any color modifications, we will trim it away.
                "Title" => {
                    title = Some(
                        RE_TOC_TITLE
                            .replace_all(&cap["value"], "$1")
                            .trim()
                            .to_string(),
                    )
                }
                "Interface" => {
                    interface = Some(format_interface_into_game_version(cap["value"].trim()));
                }
                "Author" => author = Some(cap["value"].trim().to_string()),
                "Notes" => {
                    notes = Some(
                        RE_TOC_TITLE
                            .replace_all(&cap["value"], "$1")
                            .trim()
                            .to_string(),
                    )
                }
                "Version" => version = Some(cap["value"].trim().to_owned()),
                // Names that must be loaded before this addon can be loaded.
                "Dependencies" | "RequiredDeps" => {
                    dependencies.append(&mut split_dependencies_into_vec(&cap["value"]));
                }
                "X-Tukui-ProjectID" => tukui_id = Some(cap["value"].to_string()),
                "X-WoWI-ID" => wowi_id = Some(cap["value"].to_string()),
                "X-Curse-Project-ID" => {
                    if let Ok(id) = cap["value"].to_string().parse::<i32>() {
                        curse_id = Some(id)
                    }
                }
                _ => (),
            }
        }
    }

    let repository_identifiers = RepositoryIdentifiers {
        wowi: wowi_id,
        tukui: tukui_id,
        curse: curse_id,
        git: None,
    };

    Some(AddonFolder::new(
        id.clone(),
        title.unwrap_or(id),
        interface,
        path,
        author,
        notes,
        version,
        repository_identifiers,
        dependencies,
    ))
}

/// Helper function to split a comma separated string into `Vec<String>`.
fn split_dependencies_into_vec(value: &str) -> Vec<String> {
    if value == "" {
        return vec![];
    }

    value
        .split([','].as_ref())
        .map(|s| s.trim().to_string())
        .collect()
}

fn format_interface_into_game_version(interface: &str) -> String {
    if interface.len() == 5 {
        let major = interface[..1].parse::<u8>();
        let minor = interface[1..3].parse::<u8>();
        let patch = interface[3..5].parse::<u8>();
        if let (Ok(major), Ok(minor), Ok(patch)) = (major, minor, patch) {
            return format!("{}.{}.{}", major, minor, patch);
        }
    }

    interface.to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_toc_title() {
        let title = RE_TOC_TITLE.replace_all("Atlas |cFF0099FF[Foobar]|r", "$1");
        assert_eq!(title, "Atlas [Foobar]");

        let title = RE_TOC_TITLE.replace_all(
            "Foobar|TInterface\\Addons\\Sorted\\Textures\\Title:24:96|t",
            "$1",
        );
        assert_eq!(title, "Foobar");
        let title = RE_TOC_TITLE.replace_all(
            "|TInterface\\Addons\\Sorted\\Textures\\Title:24:96|tFoobar|TInterface\\Addons\\Sorted\\Textures\\Title:24:96|t",
            "$1",
        );
        assert_eq!(title, "Foobar");

        let title = RE_TOC_TITLE.replace_all("|cffffd200Deadly Boss Mods|r |cff69ccf0Core|", "$1");
        assert_eq!(title, "Deadly Boss Mods Core");

        let title = RE_TOC_TITLE.replace_all("Kui |cff9966ffNameplates", "$1");
        assert_eq!(title, "Kui Nameplates");

        let title = RE_TOC_TITLE.replace_all(
            "|cffffe00a<|r|cffff7d0aDBM|r|cffffe00a>|r |cff69ccf0Darkmoon Faire|r",
            "$1",
        );
        assert_eq!(title, "<DBM> Darkmoon Faire");

        let title =
            RE_TOC_TITLE.replace_all("BigWigs [|cffeda55fNy'alotha, the Waking City|r]", "$1");
        assert_eq!(title, "BigWigs [Ny'alotha, the Waking City]");

        let title = RE_TOC_TITLE.replace_all("|cff1784d1ElvUI |cff83F3F7Absorb Tags", "$1");
        assert_eq!(title, "ElvUI Absorb Tags");
    }

    #[test]
    fn test_interface() {
        let interface = "90001";
        assert_eq!("9.0.1", format_interface_into_game_version(interface));

        let interface = "11305";
        assert_eq!("1.13.5", format_interface_into_game_version(interface));

        let interface = "100000";
        assert_eq!("100000", format_interface_into_game_version(interface));
    }
}
