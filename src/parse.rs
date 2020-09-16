use crate::{
    addon::Addon,
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
use serde_derive::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};

lazy_static::lazy_static! {
    static ref CACHED_GAME_INFO: Mutex<Option<GameInfo>> = Mutex::new(None);
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Clone)]
pub struct Fingerprint {
    pub title: String,
    pub hash: Option<u32>,
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

struct ParsingPatterns {
    initial_inclusion_regex: Regex,
    extra_inclusion_regex: Regex,
    file_parsing_regex: HashMap<String, (regex::Regex, Regex)>,
}

/// File parsing regexes used for parsing the addon files.
async fn file_parsing_regex() -> Result<ParsingPatterns> {
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
            // If we have a stored fingerprint on disk, we use that.
            if let Some(fingerprint) = fingerprints.iter().find(|f| &f.title == dir_name) {
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

    // Maps each `Fingerprint` to `Addon`.
    let unfiltred_addons: Vec<_> = new_fingerprints
        .par_iter()
        .filter_map(|fingerprint| {
            // Generate .toc path.
            let toc_path = root_dir
                .join(&fingerprint.title)
                .join(format!("{}.toc", fingerprint.title));
            if !toc_path.exists() {
                return None;
            }

            // We add fingerprint to the addon.
            let mut addon = parse_toc_path(&toc_path)?;
            addon.fingerprint = fingerprint.hash;

            Some(addon)
        })
        .collect();

    log::debug!(
        "{} - {} successfully parsed from '.toc'",
        flavor,
        unfiltred_addons.len()
    );

    // Drop Mutex guard, collection is no longer needed
    drop(collection_guard);

    // Filters the Tukui ids.
    let tukui_ids: Vec<_> = unfiltred_addons
        .iter()
        .filter_map(|addon| {
            if let Some(tukui_id) = addon.tukui_id.clone() {
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
        let package = fetch_remote_package(&id, &flavor).await;
        // Find the corresponding addon.
        if let Some(mut addon) = unfiltred_addons
            .iter()
            .find(|a| a.tukui_id == Some(id.clone()))
            .cloned()
        {
            // apply package to addon.
            if let Ok(package) = package {
                addon.apply_tukui_package(&package);
                tukui_addons.push(addon);
            }
        }
    }

    log::debug!(
        "{} - {} addons applied with tukui id package metadata",
        flavor,
        tukui_addons.len()
    );

    // Links dependencies. This is needed for tukui addons since they don't
    // tell which dependencies a addon has, so we use the information from toc.
    link_dependencies_bidirectional(&mut tukui_addons, &unfiltred_addons);

    // Filter out addons with fingerprints.
    let mut fingerprint_hashes: Vec<_> = unfiltred_addons
        .iter()
        .filter_map(|addon| {
            // Removes any addon which has tukui_id.
            if addon.tukui_id.is_some() {
                None
            } else if let Some(hash) = addon.fingerprint {
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
    let fingerprint_package = fetch_remote_packages_by_fingerprint(&fingerprint_hashes).await?;

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
                let local_fingerprint = unfiltred_addons
                    .iter()
                    .find(|a| a.id == module.foldername)
                    .map(|a| a.fingerprint.unwrap_or_default())
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
        .filter_map(|info| {
            // We try to find the addon matching the curse_id.
            let addon_by_id = unfiltred_addons
                .iter()
                .find(|a| a.curse_id == Some(info.id))
                .cloned();

            // Apply package.
            if let Some(mut addon) = addon_by_id {
                addon.apply_fingerprint_module(info, flavor);
                return Some(addon);
            }

            // Second is we try to find the matching addon by looking at the hash.
            let addon_by_fingerprint = unfiltred_addons
                .iter()
                .find(|a| {
                    info.file
                        .modules
                        .iter()
                        .any(|m| Some(m.fingerprint) == a.fingerprint)
                })
                .cloned();

            // Apply package.
            if let Some(mut addon) = addon_by_fingerprint {
                addon.apply_fingerprint_module(info, flavor);
                return Some(addon);
            }

            None
        })
        .collect();

    log::debug!(
        "{} - {} addons applied with fingerprint metadata",
        flavor,
        fingerprint_addons.len()
    );

    // Creates a `Vec` of curse_ids.
    let curse_ids: Vec<_> = fingerprint_addons
        .iter()
        .filter_map(|addon| {
            if let Some(curse_id) = addon.curse_id {
                Some(curse_id)
            } else {
                None
            }
        })
        .collect();

    log::debug!(
        "{} - {} addons with curse id",
        flavor,
        fingerprint_addons.len()
    );

    // Fetches the curse packages based on the ids.
    let curse_id_packages_result = fetch_remote_packages_by_ids(&curse_ids).await;
    if let Ok(curse_id_packages) = curse_id_packages_result {
        let mut updated = 0;

        // Loops the packages, and updates our Addons with information.
        for package in curse_id_packages {
            let addon = fingerprint_addons
                .iter_mut()
                .find(|a| a.curse_id == Some(package.id));
            if let Some(addon) = addon {
                addon.apply_curse_package(&package);
                updated += 1;
            }
        }

        log::debug!(
            "{} - {} addons applied with curse id package metadata",
            flavor,
            updated
        );
    }

    // Concats the different repo addons, and returns.
    let concatenated = [&fingerprint_addons[..], &tukui_addons[..]].concat();

    log::debug!(
        "{} - {} addons successfully parsed",
        flavor,
        concatenated.len()
    );

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

            fingerprints.iter_mut().for_each(|fingerprint| {
                if fingerprint.title == addon_id {
                    fingerprint.hash = Some(hash);
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

fn fingerprint_addon_dir(
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
                ClientError::FingerprintError(format!("ext no in file parsing regex: {:?}", ext))
            })?;
        let text = std::fs::read_to_string(&path).map_err(ClientError::fingerprint)?;
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
                let parent = path.parent().ok_or_else(|| {
                    ClientError::FingerprintError(format!("No parent directory for {:?}", path))
                })?;
                let file_to_find = parent.join(Path::new(&path_match));
                let real_path = find_file(&file_to_find).ok_or_else(|| {
                    ClientError::FingerprintError(format!(
                        "Unable to find file: {:?}",
                        file_to_find
                    ))
                })?;
                to_parse.push_back(real_path);
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

/// Helper function to run through all addons and
/// link all dependencies bidirectional.
///
/// Example: We download a Addon which upon unzipping has
/// three folders (addons): `Foo`, `Bar`, `Baz`.
/// `Foo` is the parent and `Bar` and `Baz` are two helper addons.
/// `Bar` and `Baz` are both dependent on `Foo`.
/// This we know because of their .toc file.
/// However we don't know anything about `Bar` and `Baz` when
/// only looking at `Foo`.
///
/// After reading TOC files:
/// `Foo` - dependencies: []
/// `Bar` - dependencies: [`Foo`]
/// `Baz` - dependencies: [`Foo`]
///
/// After bidirectional dependencies link:
/// `Foo` - dependencies: [`Bar`, `Baz`]
/// `Bar` - dependencies: [`Foo`]
/// `Baz` - dependencies: [`Foo`]
fn link_dependencies_bidirectional(sliced_addons: &mut [Addon], all_addons: &[Addon]) {
    for addon in sliced_addons {
        for unsorted_addon in all_addons {
            for dependency in &unsorted_addon.dependencies {
                if dependency == &addon.id {
                    addon.dependencies.push(unsorted_addon.id.clone());
                }
            }
        }

        addon.dependencies.dedup();
    }
}

/// Helper function to parse a given TOC file
/// (`DirEntry`) into a `Addon` struct.
///
/// TOC format summary:
/// https://wowwiki.fandom.com/wiki/TOC_format
fn parse_toc_path(toc_path: &PathBuf) -> Option<Addon> {
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

    // If we don't find title, we will fallback to id (foldername).
    let title = if let Some(title) = title {
        title
    } else {
        id.clone()
    };

    Some(Addon::new(
        id,
        title,
        author,
        notes,
        version,
        path,
        dependencies,
        wowi_id,
        tukui_id,
        curse_id,
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
