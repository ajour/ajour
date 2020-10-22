use crate::{
    addon::{Addon, AddonFolder, AddonState, RepositoryIdentifiers},
    config::Flavor,
    curse_api::{
        fetch_game_info, fetch_remote_packages_by_fingerprint, fetch_remote_packages_by_ids,
        GameInfo,
    },
    error::ClientError,
    fs::PersistentData,
    murmur2::calculate_hash,
    tukui_api::fetch_remote_package,
    Result,
};
use async_std::sync::{Arc, Mutex};
use fancy_regex::Regex;
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

#[derive(Serialize, Deserialize, Default)]
pub struct FingerprintCollection(HashMap<Flavor, Vec<Fingerprint>>);

impl FingerprintCollection {
    fn get_mut_for_flavor(&mut self, flavor: Flavor) -> &mut Vec<Fingerprint> {
        self.0.entry(flavor).or_default()
    }
}

impl PersistentData for FingerprintCollection {
    fn relative_path() -> PathBuf {
        PathBuf::from("fingerprints.yml")
    }
}

async fn load_fingerprint_collection() -> Result<FingerprintCollection> {
    Ok(FingerprintCollection::load_or_default()?)
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
    fingerprint_collection: Arc<Mutex<Option<FingerprintCollection>>>,
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

    if all_dirs.is_empty() {
        return Ok(vec![]);
    }

    let ParsingPatterns {
        initial_inclusion_regex,
        extra_inclusion_regex,
        file_parsing_regex,
    } = file_parsing_regex().await?;

    // Load fingerprint collection from memory else disk.
    let mut collection_guard = fingerprint_collection.lock().await;

    if collection_guard.is_none() {
        *collection_guard = Some(load_fingerprint_collection().await?);
    }

    let fingerprint_collection = collection_guard.as_mut().unwrap();
    let fingerprints = fingerprint_collection.get_mut_for_flavor(flavor);

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
        let change = fingerprints.len() as isize - new_fingerprints.len() as isize;
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

    // Update our in memory collection and save to disk.
    fingerprints.drain(..);
    fingerprints.extend(new_fingerprints.clone());
    let _ = fingerprint_collection.save();

    // Maps each `Fingerprint` to `AddonFolder`.
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
            addon_folder.fingerprint = new_fingerprints
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

    // Drop Mutex guard, collection is no longer needed
    drop(collection_guard);

    // Filters the Tukui ids.
    let tukui_ids: Vec<_> = addon_folders
        .iter()
        .filter_map(|folder| {
            if let Some(tukui_id) = folder.repository_identifiers.tukui.clone() {
                Some(tukui_id)
            } else {
                None
            }
        })
        .collect();

    log::debug!("{} - {} addons with tukui id", flavor, tukui_ids.len());

    let mut tukui_addons = vec![];
    // Loops each tukui_id and fetch a remote package from their api.
    for id in tukui_ids {
        if let Ok(package) = fetch_remote_package(&id, &flavor).await {
            let addon = Addon::from_tukui_package(id.clone(), &addon_folders, &package);

            tukui_addons.push(addon);
        }
    }

    log::debug!(
        "{} - {} addons from tukui package metadata",
        flavor,
        tukui_addons.len()
    );

    // Filter out addons with fingerprints.
    let mut fingerprint_hashes: Vec<_> = addon_folders
        .iter()
        .filter_map(|folder| {
            // Removes any addon which has tukui_id.
            if folder.repository_identifiers.tukui.is_some() {
                None
            } else if let Some(hash) = folder.fingerprint {
                Some(hash)
            } else {
                None
            }
        })
        .collect();
    fingerprint_hashes.dedup();

    log::debug!(
        "{} - {} unique fingerprints to check against curse api",
        flavor,
        fingerprint_hashes.len()
    );

    // Fetches fingerprint package from curse_api
    let mut fingerprint_package = fetch_remote_packages_by_fingerprint(&fingerprint_hashes).await?;

    // We had a case where a addon hash returned a minecraft addon.
    // So we filter out all matches which does not have a valid flavor.
    fingerprint_package
        .partial_matches
        .retain(|a| a.file.game_version_flavor.is_some());

    fingerprint_package
        .exact_matches
        .retain(|a| a.file.game_version_flavor.is_some());

    // Log info about partial matches
    {
        for addon in fingerprint_package.partial_matches.iter() {
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

    log::debug!(
        "{} - {} exact fingerprint matches against curse api",
        flavor,
        fingerprint_package.exact_matches.len()
    );

    // Converts the excat matches into our `Addon` struct.
    let mut fingerprint_addons: Vec<_> = fingerprint_package
        .exact_matches
        .iter()
        .map(|info| Addon::from_curse_fingerprint_info(info.id, &info, flavor, &addon_folders))
        .collect();

    log::debug!(
        "{} - {} addons from fingerprint metadata",
        flavor,
        fingerprint_addons.len()
    );

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
        .filter(|f| {
            fingerprint_addons
                .iter()
                .any(|fa| fa.primary_folder_id != f.id)
        })
        .filter(|f| {
            f.repository_identifiers.tukui.is_none() && f.repository_identifiers.curse.is_some()
        })
        .map(|f| f.repository_identifiers.curse.unwrap())
        .filter(|id| !curse_ids_from_match.contains(id))
        .collect();
    curse_ids_from_nonmatch.dedup();

    // Addons that were partial matches that we can get the curse id from. This might return
    // id's where `curse_ids_from_nonmatch` may not, if the `AddonFolder` `.toc` didn't
    // contain a Curse ID, but we can get it from the partial match data
    let mut curse_ids_from_partial: Vec<_> = fingerprint_package
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

    // We will store any addons that weren't an exact fingerprint match to curse
    // but we could still figure out from a curse id
    let mut curse_id_only_addons = vec![];

    // Fetches the curse packages based on the ids.
    let curse_id_packages_result = fetch_remote_packages_by_ids(&combined_curse_ids).await;
    if let Ok(curse_id_packages) = curse_id_packages_result {
        let mut updated = 0;
        let mut created = 0;

        // Loops the packages, and updates or creates Addons with the information.
        for package in curse_id_packages {
            // Update fingerprint addons that have a curse id
            if let Some(addon) = fingerprint_addons
                .iter_mut()
                .find(|a| a.repository_id() == Some(package.id.to_string()))
            {
                addon.repository_metadata.title = Some(package.name.clone());
                addon.repository_metadata.website_url = Some(package.website_url.clone());

                updated += 1;
            }

            // Create an addon from the curse id packages that had no / partial fingerprint match
            if curse_ids_from_nonmatch.contains(&package.id)
                || curse_ids_from_partial.contains(&package.id)
            {
                let addon = Addon::from_curse_package(&package, flavor, &addon_folders);
                if let Some(addon) = addon {
                    curse_id_only_addons.push(addon);
                    created += 1;
                }
            }
        }

        log::debug!(
            "{} - {} addons updated with curse id package metadata",
            flavor,
            updated
        );

        log::debug!(
            "{} - {} addons created from curse id package metadata",
            flavor,
            created
        );
    }

    // Concats the different repo addons, and returns.
    let mut concatenated = [
        &tukui_addons[..],
        &fingerprint_addons[..],
        &curse_id_only_addons[..],
    ]
    .concat();

    log::debug!(
        "{} - {} addons successfully parsed",
        flavor,
        concatenated.len()
    );

    let mapped_folder_ids = concatenated
        .iter()
        .map(|a| a.folders.iter().map(|f| f.id.clone()).collect::<Vec<_>>())
        .flatten()
        .collect::<Vec<_>>();

    let unmapped_folders = addon_folders
        .iter()
        .filter(|f| !mapped_folder_ids.contains(&f.id))
        .cloned();

    let unknown_addons = unmapped_folders
        .map(|f| {
            let mut addon = Addon::empty(&f.id);
            addon.folders = vec![f];
            addon.state = AddonState::Unknown;

            addon
        })
        .collect::<Vec<_>>();

    log::debug!("{} - {} unknown addons", flavor, unknown_addons.len());

    concatenated.extend(unknown_addons);

    // We do a extra clean up here to ensure that we dont display any addons which is a module.
    // Idea is that we loop the addon.folders and mark all "dependencies".
    // We then retain them from the concatenated Vec. If there is any.
    let mut marked = vec![];
    for addon in &concatenated {
        for folder in &addon.folders {
            if folder.id != addon.primary_folder_id {
                marked.push(folder.id.clone());
            }
        }
    }

    // Remove dependency addons.
    concatenated.retain(|addon| !marked.iter().any(|id| &addon.primary_folder_id == id));

    Ok(concatenated)
}

pub async fn update_addon_fingerprint(
    fingerprint_collection: Arc<Mutex<Option<FingerprintCollection>>>,
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
            // Lock Mutex ensuring this is the only operation that can update the collection.
            // This is needed since during `Update All` we can have concurrent operations updating
            // this collection and we need to ensure they don't overwrite eachother.
            let mut collection_guard = fingerprint_collection.lock().await;

            if collection_guard.is_none() {
                *collection_guard = Some(load_fingerprint_collection().await?);
            }

            let fingerprint_collection = collection_guard.as_mut().unwrap();
            let fingerprints = fingerprint_collection.get_mut_for_flavor(flavor);
            let modified = if let Ok(metadata) = addon_path.metadata() {
                metadata.modified().unwrap_or_else(|_| SystemTime::now())
            } else {
                SystemTime::now()
            };

            fingerprints.iter_mut().for_each(|fingerprint| {
                if fingerprint.title == addon_id {
                    fingerprint.hash = Some(hash);
                    fingerprint.modified = modified;
                }
            });

            // Persist collection to disk
            let _ = fingerprint_collection.save();

            // Mutex guard is dropped, allowing other operations to work on FingerprintCollection
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
    let re_title = regex::Regex::new(r"\|[a-fA-F\d]{9}([^|]+)\|r?").unwrap();

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
