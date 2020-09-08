use fancy_regex::Regex;
use rayon::prelude::*;
use serde_derive::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};

use crate::{
    addon::{Addon, Identity, RepositoryIdentifiers},
    curse_api::{fetch_game_info, fetch_remote_packages_by_fingerprint},
    error::ClientError,
    murmur2::calculate_hash,
    Result,
};

#[derive(Deserialize, Serialize, Debug, PartialEq, Clone)]
pub struct Fingerprint {
    pub title: String,
    pub hash: Option<u32>,
}

pub async fn read_addon_directory<P: AsRef<Path>>(root_dir: P) -> Result<Vec<Addon>> {
    // Fetches game_info.
    let game_info = fetch_game_info().await?;

    // If the path does not exists or does not point on a directory we throw an Error.
    if !root_dir.as_ref().is_dir() {
        return Err(ClientError::Custom(format!(
            "Addon directory not found: {:?}",
            root_dir.as_ref().to_owned()
        )));
    }
    let root_dir = root_dir.as_ref().to_owned();

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

    // Compile regexes
    let addon_cat = &game_info.category_sections[0];
    let initial_inclusion_regex =
        Regex::new(&addon_cat.initial_inclusion_pattern).expect("Error compiling inclusion regex");
    let extra_inclusion_regex = Regex::new(&addon_cat.extra_include_pattern)
        .expect("Error compiling extra inclusion regex");
    let file_parsing_regex: HashMap<String, (regex::Regex, Regex)> = game_info
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

    let mut fingerprints: Vec<Fingerprint> = Vec::with_capacity(all_dirs.len());
    all_dirs
        .par_iter() // Easy parallelization
        .map(|dir_name| {
            // TODO: We should properly save fingerprints to disk.
            // Use metadata - modified.
            let addon_dir = root_dir.join(dir_name);
            let hash = fingerprint_addon_dir(
                &addon_dir,
                &root_dir,
                &initial_inclusion_regex,
                &extra_inclusion_regex,
                &file_parsing_regex,
            );

            Fingerprint {
                title: dir_name.to_owned(),
                hash,
            }
        })
        .collect_into_vec(&mut fingerprints);

    let mut addons: Vec<Addon> = fingerprints
        .iter()
        .map(|fingerprint| {
            let toc_path = root_dir
                .join(&fingerprint.title)
                .join(format!("{}.toc", fingerprint.title));
            if !toc_path.exists() {
                return None;
            }

            let mut addon = parse_toc_path(&toc_path)?;
            if let (Identity::Unknown, Some(hash)) = (&addon.identity, fingerprint.hash) {
                addon.identity = Identity::Fingerprint(hash);
            }

            Some(addon)
        })
        .filter(|a| a.is_some())
        .map(|addon| addon.unwrap())
        .collect();

    let fingerprint_packages = fetch_remote_packages_by_fingerprint(vec![4175503321]).await;
    println!("fingerprints: {:?}", fingerprint_packages);

    // link_dependencies_bidirectional(&mut addons);
    Ok(addons)
}

fn fingerprint_addon_dir(
    addon_dir: &PathBuf,
    root_dir: &PathBuf,
    initial_inclusion_regex: &Regex,
    extra_inclusion_regex: &Regex,
    file_parsing_regex: &HashMap<String, (regex::Regex, Regex)>,
) -> Option<u32> {
    // TODO: If something goes wrong, we need to bail.

    let mut to_fingerprint = HashSet::new();
    let mut to_parse = VecDeque::new();
    // Add initial files
    let glob_pattern = format!("{}/**/*.*", addon_dir.to_str().unwrap());
    for path in glob::glob(&glob_pattern).expect("Glob pattern error") {
        let path = path.expect("Glob error");
        if !path.is_file() {
            continue;
        }

        // Test relative path matches regexes
        let relative_path = path
            .strip_prefix(root_dir)
            .unwrap()
            .to_str()
            .unwrap()
            .to_ascii_lowercase()
            .replace("/", "\\"); // Convert to windows seperator
        if initial_inclusion_regex.is_match(&relative_path).unwrap() {
            to_parse.push_back(path);
        } else if extra_inclusion_regex.is_match(&relative_path).unwrap() {
            to_fingerprint.insert(path);
        }
    }

    // Parse additional files
    while let Some(path) = to_parse.pop_front() {
        if !path.exists() || !path.is_file() {
            panic!("Invalid file given to parse");
        }

        to_fingerprint.insert(path.clone());

        // Skip if no rules for extension
        let ext = format!(".{}", path.extension().unwrap().to_str().unwrap());
        if !file_parsing_regex.contains_key(&ext) {
            continue;
        }

        // Parse file for matches
        // TODO: Parse line by line because regex is \n sensitive
        let (comment_strip_regex, inclusion_regex) = file_parsing_regex.get(&ext).unwrap();
        let text = std::fs::read_to_string(&path).expect("Error reading file");
        let text = comment_strip_regex.replace_all(&text, "");
        for line in text.split(&['\n', '\r'][..]) {
            let mut last_offset = 0;
            while let Some(inc_match) = inclusion_regex
                .captures_from_pos(line, last_offset)
                .unwrap()
            {
                last_offset = inc_match.get(0).unwrap().end();
                let path_match = inc_match.get(1).unwrap().as_str();
                // Path might be case insensitive and have windows separators. Find it
                let path_match = path_match.replace("\\", "/");
                let parent = path.parent().unwrap();
                let real_path = find_file(parent.join(Path::new(&path_match)));
                to_parse.push_back(real_path);
            }
        }
    }

    // Calculate fingerprints
    let mut fingerprints: Vec<u32> = to_fingerprint
        .iter()
        .map(|path| {
            // Read file, removing whitespace
            let data: Vec<u8> = std::fs::read(path)
                .expect("Error reading file for fingerprinting")
                .into_iter()
                .filter(|&b| b != b' ' && b != b'\n' && b != b'\r' && b != b'\t')
                .collect();
            calculate_hash(&data, 1)
        })
        .collect();

    // Calculate overall fingerprint
    fingerprints.sort();
    let to_hash = fingerprints
        .iter()
        .map(|val| val.to_string())
        .collect::<Vec<String>>()
        .join("");

    Some(calculate_hash(to_hash.as_bytes(), 1))
}

/// Finds a case sensitive path from an insensitive path
/// Useful if, say, a WoW addon points to a local path in a different case but you're not on Windows
fn find_file<P>(path: P) -> PathBuf
where
    P: AsRef<Path>,
{
    let mut current = path.as_ref();
    let mut to_finds = Vec::new();

    // Find first parent that exists
    while !current.exists() {
        to_finds.push(current.file_name().unwrap());
        current = current.parent().unwrap();
    }

    // Match to finds
    let mut current = current.to_path_buf();
    to_finds.reverse();
    for to_find in to_finds {
        let mut children = current.read_dir().unwrap();
        let lower = to_find.to_str().unwrap().to_ascii_lowercase();
        let found = children
            .find(|x| {
                x.as_ref()
                    .unwrap()
                    .file_name()
                    .to_str()
                    .unwrap()
                    .to_ascii_lowercase()
                    == lower
            })
            .unwrap()
            .unwrap();
        current = found.path();
    }
    current
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
fn link_dependencies_bidirectional(addons: &mut Vec<Addon>) {
    let clone_addons = addons.clone();

    for addon in addons {
        for clone_addon in &clone_addons {
            for dependency in &clone_addon.dependencies {
                if dependency == &addon.id {
                    addon.dependencies.push(clone_addon.id.clone());
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
    let repository_identifiers = RepositoryIdentifiers {
        wowi: None,
        tukui: None,
        curse: None,
    };
    let mut identity = Identity::Unknown;

    // It is an anti-pattern to compile the same regular expression in a loop,
    // which is why they are created here.
    //
    // https://docs.rs/regex/1.3.9/regex/#example-avoid-compiling-the-same-regex-in-a-loop
    let re_toc = regex::Regex::new(r"^##\s(?P<key>.*?):\s?(?P<value>.*)").unwrap();
    let re_title = regex::Regex::new(r"\|[a-fA-F\d]{9}([^|]+)\|r?").unwrap();

    for line in reader.lines().filter_map(|l| l.ok()) {
        for cap in re_toc.captures_iter(line.as_str()) {
            match &cap["key"] {
                // String - The title to display.
                //
                // Note: Coloring is possible via UI escape sequences.
                // Since we don't want any color modifications, we will
                // trim it away.
                // Example 1: |cff1784d1ElvUI|r should be just ElvUI.
                // Example 2: BigWigs [|cffeda55fUldir|r] should be BigWigs [Uldir].
                "Title" => title = Some(re_title.replace_all(&cap["value"], "$1").to_string()),
                // String - Author
                "Author" => author = Some(cap["value"].to_string()),
                // String - Notes
                "Notes" => notes = Some(re_title.replace_all(&cap["value"], "$1").to_string()),
                // String - The AddOn version
                "Version" => {
                    version = Some(String::from(&cap["value"]));
                }
                // String - A comma-separated list of addon (directory)
                // names that must be loaded before this addon can be loaded.
                "Dependencies" | "RequiredDeps" => {
                    dependencies.append(&mut split_dependencies_into_vec(&cap["value"]));
                }
                // String - Addon identifier for Wowinterface API.
                "X-WoWI-ID" => {
                    // Deprecated
                    // repository_identifiers.wowi = Some(cap["value"].to_string());
                }
                // String - Addon identifier for TukUI API.
                "X-Tukui-ProjectID" => {
                    // Deprecated
                    // repository_identifiers.tukui = Some(cap["value"].to_string());
                    identity = Identity::Tukui(cap["value"].to_string())
                }
                // String - Addon identifier for Curse API.
                "X-Curse-Project-ID" => {
                    // Santize the id, so we only get a `u32`.
                    // if let Ok(id) = cap["value"].to_string().parse::<u32>() {
                    // identity = Identity::Curse(id)
                    // Deprecated
                    // repository_identifiers.curse = Some(id)
                    // }
                }
                _ => (),
            }
        }
    }

    Some(Addon::new(
        id,
        title?,
        author,
        notes,
        version,
        path,
        dependencies,
        None,
        repository_identifiers,
        identity,
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
