use crate::{
    addon::{Addon, AddonFolder, AddonState, Repository, RepositoryIdentifiers},
    cache::{addon_from_cache, AddonCache, FingerprintCache},
    config::Flavor,
    curse_api::{
        self, fetch_game_info, fetch_remote_packages_by_fingerprint, fetch_remote_packages_by_ids,
        FingerprintInfo, GameInfo,
    },
    error::ClientError,
    fs::PersistentData,
    murmur2::calculate_hash,
    tukui_api, wowi_api, Result,
};
use async_std::sync::{Arc, Mutex};
use fancy_regex::Regex;
use futures::future::join_all;
use isahc::config::RedirectPolicy;
use isahc::{prelude::Configurable, HttpClient};
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs::File;
use std::io::{BufRead, BufReader, Read};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::SystemTime;

lazy_static::lazy_static! {
    static ref CACHED_GAME_INFO: Mutex<Option<GameInfo>> = Mutex::new(None);
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

/// File parsing regexes used for parsing the addon files.
pub async fn file_parsing_regex() -> Result<ParsingPatterns> {
    // Fetches game_info from memory or API if not in memory
    // Used to get regexs for various operations.
    let game_info = {
        let cached_info = { CACHED_GAME_INFO.lock().await.clone() };

        if let Some(info) = cached_info {
            info
        } else {
            let info = fetch_game_info().await?;
            *CACHED_GAME_INFO.lock().await = Some(info.clone());

            info
        }
    };

    // Compile regexes
    let addon_cat = &game_info.category_sections[0];
    let initial_inclusion_regex =
        Regex::new(&addon_cat.initial_inclusion_pattern).expect("Error compiling inclusion regex");
    let extra_inclusion_regex = Regex::new(&addon_cat.extra_include_pattern)
        .expect("Error compiling extra inclusion regex");
    let file_parsing_regex = game_info
        .file_parsing_rules
        .iter()
        .map(|data| {
            let comment_strip_regex = regex::Regex::new(&data.comment_strip_pattern)
                .expect("Error compiling comment strip regex");
            let inclusion_regex =
                Regex::new(&data.inclusion_pattern).expect("Error compiling inclusion pattern");
            (
                data.file_extension.clone(),
                (comment_strip_regex, inclusion_regex),
            )
        })
        .collect();

    Ok(ParsingPatterns {
        initial_inclusion_regex,
        extra_inclusion_regex,
        file_parsing_regex,
    })
}

pub async fn read_addon_directory<P: AsRef<Path>>(
    addon_cache: Option<Arc<Mutex<AddonCache>>>,
    fingerprint_cache: Option<Arc<Mutex<FingerprintCache>>>,
    root_dir: P,
    flavor: Flavor,
) -> Result<Vec<Addon>> {
    log::debug!("{} - parsing addons folder", flavor);

    let root_dir = root_dir.as_ref();

    // If the path does not exists or does not point on a directory we return an Error.
    if !root_dir.is_dir() {
        return Err(ClientError::Custom(format!(
            "Addon directory not found: {:?}",
            root_dir
        )));
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
        return Ok(vec![]);
    }

    // Get from cache / calculate fingerprints for all directories
    let fingerprints = fingerprint_all_dirs(root_dir, flavor, &all_dirs, fingerprint_cache).await?;

    // Parse all addon folders from `.toc` file in each directory and assign it's
    // respective fingerprint
    let mut addon_folders = parse_addon_folders(root_dir, flavor, &all_dirs, &fingerprints).await;

    // Get cached addons. This is our first priority for assigning folders to addons.
    let mut cached_addons = get_cached_addons(flavor, addon_cache, &addon_folders).await;

    // Remove addon folders that were successfully grouped to cached addons
    addon_folders.retain(|f| {
        !cached_addons
            .iter()
            .any(|cached| cached.folders.contains(f))
    });

    // Get fingerprint info from curse API for all remaining addon folder fingerprints
    let fingerprint_info = get_curse_fingerprint_info(flavor, &addon_folders).await?;

    // Get fingerprint addons
    let mut fingerprint_addons =
        get_curse_fingerprint_addons(flavor, &addon_folders, &fingerprint_info).await?;

    // Remove addon folders that were successfully grouped to fingerprint addons
    addon_folders.retain(|f| {
        !fingerprint_addons
            .iter()
            .any(|fingerprint| fingerprint.folders.contains(f))
    });

    // Get package info for all curse ids. This package info is used to update missing
    // info on the fingerprint addons and then used as a fallback measure to create
    // addons for folders that failed fingerprinting, but we were able to get a
    // curse id from.
    let curse_packages = get_curse_package_info(
        flavor,
        &addon_folders,
        &fingerprint_addons,
        &fingerprint_info,
    )
    .await
    .unwrap_or_default();

    // Update the fingerprint addons with package info
    update_fingerprint_addons_with_package_info(flavor, &mut fingerprint_addons, &curse_packages)
        .await;

    // Create addons from the package info for all ids that are NOT from a fingerprint addon
    let curse_id_only_addons =
        get_curse_id_only_addons(flavor, &addon_folders, &fingerprint_addons, &curse_packages)
            .await;

    // Remove addon folders that were successfully grouped to curse id only addons
    addon_folders.retain(|f| {
        !curse_id_only_addons
            .iter()
            .any(|curse_id| curse_id.folders.contains(f))
    });

    // Get package info for all tukui ids. This package info is used to update
    // cached addons and then used as a fallback measure to create addons for
    // folders that are not cached, but we were able to get a tukui id from.
    let tukui_packages = get_tukui_package_info(flavor, &addon_folders, &cached_addons).await;

    // Update cached addons with tukui info
    update_cached_addons_with_tukui_info(flavor, &mut cached_addons, &tukui_packages);

    // Get tukui addons. We only create addons from ids that aren't from a cached addon.
    let tukui_addons =
        get_tukui_addons(flavor, &addon_folders, &cached_addons, &tukui_packages).await;

    // Remove addon folders that were successfully grouped to tukui addons
    addon_folders.retain(|f| !tukui_addons.iter().any(|tukui| tukui.folders.contains(f)));

    // Get package info for all wowi ids. This package info is used to update
    // cached addons and then used as a fallback measure to create addons for
    // folders that are not cached, but we were able to get a wowi id from.
    let wowi_packages = get_wowi_package_info(flavor, &addon_folders, &cached_addons).await;

    // Update cached addons with wowi info
    update_cached_addons_with_wowi_info(flavor, &mut cached_addons, &wowi_packages);

    // Get wowi addons. We only create addons from ids that aren't from a cached addon.
    let wowi_addons = get_wowi_addons(flavor, &addon_folders, &cached_addons, &wowi_packages).await;

    // Remove addon folders that were successfully grouped to wowi addons
    addon_folders.retain(|f| !wowi_addons.iter().any(|wowi| wowi.folders.contains(f)));

    // Any remaining addon folders are unknown, we will show them 1:1 in Ajour
    let unknown_addons = addon_folders
        .into_iter()
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
    let concatenated = [
        &cached_addons[..],
        &fingerprint_addons[..],
        &curse_id_only_addons[..],
        &tukui_addons[..],
        &wowi_addons[..],
        &unknown_addons[..],
    ]
    .concat();

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
) -> Result<Vec<Fingerprint>> {
    let ParsingPatterns {
        initial_inclusion_regex,
        extra_inclusion_regex,
        file_parsing_regex,
    } = file_parsing_regex().await?;

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
                let hash_result = fingerprint_addon_dir(
                    &addon_dir,
                    &initial_inclusion_regex,
                    &extra_inclusion_regex,
                    &file_parsing_regex,
                );

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
        "{} - {} successfully parsed from '.toc'",
        flavor,
        addon_folders.len()
    );

    addon_folders
}

async fn get_cached_addons(
    flavor: Flavor,
    addon_cache: Option<Arc<Mutex<AddonCache>>>,
    addon_folders: &[AddonFolder],
) -> Vec<Addon> {
    let cached_addons = if let Some(addon_cache) = addon_cache {
        let mut addon_cache = addon_cache.lock().await;
        let addon_cache_entries = addon_cache.get_mut_for_flavor(flavor);

        addon_cache_entries
            .iter()
            .filter_map(|entry| addon_from_cache(flavor, entry, &addon_folders))
            .collect::<Vec<_>>()
    } else {
        vec![]
    };

    log::debug!(
        "{} - {} addons created from cache",
        flavor,
        cached_addons.len()
    );

    cached_addons
}

async fn get_curse_fingerprint_info(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
) -> Result<FingerprintInfo> {
    // Get all fingerprint hashes
    let mut fingerprint_hashes: Vec<_> = addon_folders
        .iter()
        .filter_map(|folder| folder.fingerprint)
        .collect();
    fingerprint_hashes.dedup();

    log::debug!(
        "{} - {} unique fingerprints to check against curse api",
        flavor,
        fingerprint_hashes.len()
    );

    // Fetches fingerprint package from curse_api
    let mut fingerprint_info = fetch_remote_packages_by_fingerprint(&fingerprint_hashes).await?;

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

async fn get_curse_fingerprint_addons(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
    fingerprint_info: &FingerprintInfo,
) -> Result<Vec<Addon>> {
    log::debug!(
        "{} - {} exact fingerprint matches against curse api",
        flavor,
        fingerprint_info.exact_matches.len()
    );

    // Converts the excat matches into our `Addon` struct.
    let fingerprint_addons: Vec<_> = fingerprint_info
        .exact_matches
        .iter()
        .map(|info| Addon::from_curse_fingerprint_info(info.id, &info, flavor, &addon_folders))
        .collect();

    log::debug!(
        "{} - {} addons from fingerprint metadata",
        flavor,
        fingerprint_addons.len()
    );

    Ok(fingerprint_addons)
}

async fn get_curse_package_info(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
    fingerprint_addons: &[Addon],
    fingerprint_info: &FingerprintInfo,
) -> Result<Vec<curse_api::Package>> {
    // Creates a `Vec` of curse_ids from addons that succeeded fingerprinting
    let mut curse_ids_from_match: Vec<_> = fingerprint_addons
        .iter()
        .filter_map(|addon| addon.repository_identifiers.curse)
        .collect();
    curse_ids_from_match.dedup();

    // Addon folders that failed fingerprinting, but we can still build an addon
    // using the curse id from the `.toc`
    let mut curse_ids_from_nonmatch: Vec<_> = addon_folders
        .iter()
        .filter(|f| f.repository_identifiers.curse.is_some())
        .map(|f| f.repository_identifiers.curse.unwrap())
        .collect();
    curse_ids_from_nonmatch.dedup();

    // Addons that were partial matches that we can get the curse id from. This might return
    // id's where `curse_ids_from_nonmatch` may not, if the `AddonFolder` `.toc` didn't
    // contain a Curse ID, but we can get it from the partial match data
    let mut curse_ids_from_partial: Vec<_> = fingerprint_info
        .partial_matches
        .iter()
        .map(|a| a.id)
        .collect();
    curse_ids_from_partial.dedup();

    // Combine all ids and query all at once
    let mut combined_curse_ids = [
        &curse_ids_from_match[..],
        &curse_ids_from_nonmatch[..],
        &curse_ids_from_partial[..],
    ]
    .concat();
    combined_curse_ids.dedup();

    log::debug!(
        "{} - {} addons with curse id",
        flavor,
        combined_curse_ids.len()
    );

    // Fetches the curse packages based on the ids.
    fetch_remote_packages_by_ids(&combined_curse_ids).await
}

async fn update_fingerprint_addons_with_package_info(
    flavor: Flavor,
    fingerprint_addons: &mut [Addon],
    packages: &[curse_api::Package],
) {
    let mut updated = 0;

    // Loops the packages and updates any fingerprint addon with matching id
    for package in packages {
        if let Some(addon) = fingerprint_addons
            .iter_mut()
            .find(|a| a.repository_id() == Some(package.id.to_string()))
        {
            addon.repository_metadata.title = Some(package.name.clone());
            addon.repository_metadata.website_url = Some(package.website_url.clone());

            updated += 1;
        }
    }

    log::debug!(
        "{} - {} addons updated with curse id package metadata",
        flavor,
        updated
    );
}

async fn get_curse_id_only_addons(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
    fingerprint_addons: &[Addon],
    packages: &[curse_api::Package],
) -> Vec<Addon> {
    let mut curse_id_only_addons = vec![];

    let mut created = 0;

    // Loops the packages and creates an addon from all ids that aren't from
    // a fingerprint addon
    for package in packages {
        let exists_in_fingerprint = fingerprint_addons.iter().any(|a| {
            a.folders
                .iter()
                .any(|f| f.repository_identifiers.curse == Some(package.id))
                || a.repository_id() == Some(package.id.to_string())
        });

        if !exists_in_fingerprint {
            let addon = Addon::from_curse_package(&package, flavor, &addon_folders);
            if let Some(addon) = addon {
                curse_id_only_addons.push(addon);
                created += 1;
            }
        }
    }

    log::debug!(
        "{} - {} addons created from curse id package metadata",
        flavor,
        created
    );

    curse_id_only_addons
}

async fn get_tukui_package_info(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
    cached_addons: &[Addon],
) -> Vec<(String, tukui_api::TukuiPackage)> {
    let ids_from_cached: Vec<_> = cached_addons
        .iter()
        .filter(|a| a.active_repository == Some(Repository::Tukui))
        .filter_map(|a| a.repository_id())
        .collect();

    let ids_from_remaining_folders: Vec<_> = addon_folders
        .iter()
        .filter(|f| f.repository_identifiers.tukui.is_some())
        .map(|f| f.repository_identifiers.tukui.clone().unwrap())
        .collect();

    let combined_ids = [&ids_from_cached[..], &ids_from_remaining_folders[..]].concat();

    log::debug!("{} - {} addons with tukui id", flavor, combined_ids.len());

    let client = Arc::new(
        HttpClient::builder()
            .redirect_policy(RedirectPolicy::Follow)
            .max_connections_per_host(6)
            .build()
            .unwrap(),
    );

    let fetch_tasks: Vec<_> = combined_ids
        .iter()
        .map(|id| tukui_api::fetch_remote_package(client.clone(), &id, &flavor))
        .collect();

    join_all(fetch_tasks)
        .await
        .into_iter()
        .filter_map(Result::ok)
        .collect()
}

fn update_cached_addons_with_tukui_info(
    flavor: Flavor,
    cached_addons: &mut [Addon],
    packages: &[(String, tukui_api::TukuiPackage)],
) {
    let mut updated = 0;

    // Loops the packages and updates any fingerprint addon with matching id
    for (id, package) in packages {
        if let Some(addon) = cached_addons
            .iter_mut()
            .find(|a| a.repository_id().as_ref() == Some(id))
        {
            addon.update_with_tukui_package(id.clone(), package, None);

            updated += 1;
        }
    }

    log::debug!(
        "{} - {} cached addons updated with tukui package metadata",
        flavor,
        updated
    );
}

async fn get_tukui_addons(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
    cached_addons: &[Addon],
    packages: &[(String, tukui_api::TukuiPackage)],
) -> Vec<Addon> {
    let mut tukui_addons = vec![];

    for (id, package) in packages {
        let exists_in_cache = cached_addons
            .iter()
            .any(|a| a.repository_id().as_ref() == Some(id));

        if !exists_in_cache {
            let mut addon = Addon::empty("");
            addon.update_with_tukui_package(id.clone(), package, Some(addon_folders));

            tukui_addons.push(addon);
        }
    }

    log::debug!(
        "{} - {} addons from tukui package metadata",
        flavor,
        tukui_addons.len()
    );

    tukui_addons
}

async fn get_wowi_package_info(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
    cached_addons: &[Addon],
) -> Vec<wowi_api::WowIPackage> {
    let ids_from_cached: Vec<_> = cached_addons
        .iter()
        .filter(|a| a.active_repository == Some(Repository::WowI))
        .filter_map(|a| a.repository_id())
        .collect();

    let ids_from_remaining_folders: Vec<_> = addon_folders
        .iter()
        .filter(|f| f.repository_identifiers.wowi.is_some())
        .map(|f| f.repository_identifiers.wowi.clone().unwrap())
        .collect();

    let combined_ids = [&ids_from_cached[..], &ids_from_remaining_folders[..]].concat();

    log::debug!("{} - {} addons with wowi id", flavor, combined_ids.len());

    wowi_api::fetch_remote_packages(combined_ids)
        .await
        .unwrap_or_default()
}

fn update_cached_addons_with_wowi_info(
    flavor: Flavor,
    cached_addons: &mut [Addon],
    packages: &[wowi_api::WowIPackage],
) {
    let mut updated = 0;

    // Loops the packages and updates any fingerprint addon with matching id
    for package in packages {
        if let Some(addon) = cached_addons
            .iter_mut()
            .find(|a| a.repository_id() == Some(package.id.to_string()))
        {
            addon.update_with_wowi_package(package.id, package, None);

            updated += 1;
        }
    }

    log::debug!(
        "{} - {} cached addons updated with wowi package metadata",
        flavor,
        updated
    );
}

async fn get_wowi_addons(
    flavor: Flavor,
    addon_folders: &[AddonFolder],
    cached_addons: &[Addon],
    packages: &[wowi_api::WowIPackage],
) -> Vec<Addon> {
    let mut wowi_addons = vec![];

    for package in packages {
        let exists_in_cache = cached_addons
            .iter()
            .any(|a| a.repository_id() == Some(package.id.to_string()));

        if !exists_in_cache {
            let mut addon = Addon::empty("");
            addon.update_with_wowi_package(package.id, package, Some(addon_folders));

            wowi_addons.push(addon);
        }
    }

    log::debug!(
        "{} - {} addons from wowi package metadata",
        flavor,
        wowi_addons.len()
    );

    wowi_addons
}

pub async fn update_addon_fingerprint(
    fingerprint_cache: Arc<Mutex<FingerprintCache>>,
    flavor: Flavor,
    addon_dir: impl AsRef<Path>,
    addon_id: String,
) -> Result<()> {
    log::debug!("{} - updating fingerprint for {}", flavor, &addon_id);

    // Regexes
    let ParsingPatterns {
        initial_inclusion_regex,
        extra_inclusion_regex,
        file_parsing_regex,
    } = file_parsing_regex().await?;

    let addon_path = addon_dir.as_ref().join(&addon_id);

    // Generate new hash, and update collection.
    match fingerprint_addon_dir(
        &addon_path,
        &initial_inclusion_regex,
        &extra_inclusion_regex,
        &file_parsing_regex,
    ) {
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

pub fn fingerprint_addon_dir(
    addon_dir: &PathBuf,
    initial_inclusion_regex: &Regex,
    extra_inclusion_regex: &Regex,
    file_parsing_regex: &HashMap<String, (regex::Regex, Regex)>,
) -> Result<u32> {
    let mut to_fingerprint = HashSet::new();
    let mut to_parse = VecDeque::new();
    let root_dir = addon_dir.parent().ok_or_else(|| {
        ClientError::FingerprintError(format!("No parent directory for {:?}", addon_dir))
    })?;

    // Add initial files
    let glob_pattern = format!(
        "{}/**/*.*",
        addon_dir
            .to_str()
            .ok_or_else(|| ClientError::FingerprintError(format!(
                "Invalid UTF8 path: {:?}",
                addon_dir
            )))?
    );
    for path in glob::glob(&glob_pattern).map_err(ClientError::fingerprint)? {
        let path = path.map_err(ClientError::fingerprint)?;
        if !path.is_file() {
            continue;
        }

        // Test relative path matches regexes
        let relative_path = path
            .strip_prefix(root_dir)
            .map_err(ClientError::fingerprint)?
            .to_str()
            .ok_or_else(|| ClientError::FingerprintError(format!("Invalid UTF8 path: {:?}", path)))?
            .to_ascii_lowercase()
            .replace("/", "\\"); // Convert to windows seperator
        if initial_inclusion_regex
            .is_match(&relative_path)
            .map_err(ClientError::fingerprint)?
        {
            to_parse.push_back(path);
        } else if extra_inclusion_regex
            .is_match(&relative_path)
            .map_err(ClientError::fingerprint)?
        {
            to_fingerprint.insert(path);
        }
    }

    // Parse additional files
    while let Some(path) = to_parse.pop_front() {
        if !path.exists() || !path.is_file() {
            return Err(ClientError::FingerprintError(format!(
                "Invalid file given to parse: {:?}",
                path.display()
            )));
        }

        to_fingerprint.insert(path.clone());

        // Skip if no rules for extension
        let ext = format!(
            ".{}",
            path.extension()
                .ok_or_else(|| ClientError::FingerprintError(format!(
                    "Invalid extension for path: {:?}",
                    path
                )))?
                .to_str()
                .ok_or_else(|| ClientError::FingerprintError(format!(
                    "Invalid UTF8 path: {:?}",
                    path
                )))?
        );
        if !file_parsing_regex.contains_key(&ext) {
            continue;
        }

        // Parse file for matches
        let (comment_strip_regex, inclusion_regex) =
            file_parsing_regex.get(&ext).ok_or_else(|| {
                ClientError::FingerprintError(format!("ext not in file parsing regex: {:?}", ext))
            })?;
        let mut file = File::open(&path).map_err(ClientError::fingerprint)?;

        let mut buf = vec![];
        file.read_to_end(&mut buf)
            .map_err(ClientError::fingerprint)?;

        let text = String::from_utf8_lossy(&buf);
        let text = comment_strip_regex.replace_all(&text, "");
        for line in text.split(&['\n', '\r'][..]) {
            let mut last_offset = 0;
            while let Some(inc_match) = inclusion_regex
                .captures_from_pos(line, last_offset)
                .map_err(ClientError::fingerprint)?
            {
                let prev_last_offset = last_offset;
                last_offset = inc_match
                    .get(0)
                    .ok_or_else(|| {
                        ClientError::FingerprintError(format!(
                            "Inclusion regex error for group 0 on pos {}, line: {:?}",
                            prev_last_offset, line
                        ))
                    })?
                    .end();
                let path_match = inc_match
                    .get(1)
                    .ok_or_else(|| {
                        ClientError::FingerprintError(format!(
                            "Inclusion regex error for group 1 on pos {}, line: {:?}",
                            prev_last_offset, line
                        ))
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
        let data: Vec<_> = std::fs::read(path)
            .map_err(ClientError::fingerprint)?
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
    let mut author: Option<String> = None;
    let mut notes: Option<String> = None;
    let mut version: Option<String> = None;
    let mut dependencies: Vec<String> = Vec::new();
    let mut wowi_id: Option<String> = None;
    let mut tukui_id: Option<String> = None;
    let mut curse_id: Option<u32> = None;

    // TODO: We should save these somewere so we don't keep creating them.
    let re_toc = regex::Regex::new(r"^##\s*(?P<key>.*?)\s*:\s?(?P<value>.*)").unwrap();
    let re_title = regex::Regex::new(r"\|[a-fA-F\d]{9}([^|]+)\|?r?|\.?\|T[^|]*\|t").unwrap();

    for line in reader.lines().filter_map(|l| l.ok()) {
        for cap in re_toc.captures_iter(line.as_str()) {
            match &cap["key"] {
                // Note: Coloring is possible via UI escape sequences.
                // Since we don't want any color modifications, we will trim it away.
                "Title" => {
                    title = Some(re_title.replace_all(&cap["value"], "$1").trim().to_string())
                }
                "Author" => author = Some(cap["value"].trim().to_string()),
                "Notes" => {
                    notes = Some(re_title.replace_all(&cap["value"], "$1").trim().to_string())
                }
                "Version" => version = Some(cap["value"].trim().to_owned()),
                // Names that must be loaded before this addon can be loaded.
                "Dependencies" | "RequiredDeps" => {
                    dependencies.append(&mut split_dependencies_into_vec(&cap["value"]));
                }
                "X-Tukui-ProjectID" => tukui_id = Some(cap["value"].to_string()),
                "X-WoWI-ID" => wowi_id = Some(cap["value"].to_string()),
                "X-Curse-Project-ID" => {
                    if let Ok(id) = cap["value"].to_string().parse::<u32>() {
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
    };

    Some(AddonFolder::new(
        id.clone(),
        title.unwrap_or(id),
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
