use regex::Regex;
use std::ffi::OsStr;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;
use walkdir::{DirEntry, WalkDir};

use crate::{addon::Addon, error::ClientError, Result};

/// Return a `Vec<Addon>` parsed from TOC files in the given directory.
pub async fn read_addon_directory<P: AsRef<Path>>(path: P) -> Result<Vec<Addon>> {
    // TODO: Consider skipping DirEntry if we encounter a
    // blizzard addon. Blizzard adddon starts with 'Blizzard_*'.

    // If the path does not exists or does not point on a directory we throw an Error.
    if !path.as_ref().is_dir() {
        return Err(ClientError::Custom(format!(
            "Addon directory not found: {:?}",
            path.as_ref().to_owned()
        )));
    }

    let mut addons: Vec<Addon> = Vec::new();
    for entry in WalkDir::new(path)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if entry.metadata().map_or(false, |m| m.is_file()) {
            let file_name = entry.file_name();
            let file_extension = get_extension(file_name).await;
            if file_extension == Some("toc") {
                let addon = parse_toc_entry(entry).await;
                if let Some(addon) = addon {
                    addons.push(addon)
                }
            }
        }
    }

    // Link all dependencies bidirectional
    link_dependencies_bidirectional(&mut addons);

    Ok(addons)
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

/// Helper function to return str file extension.
///
/// Source:
/// https://stackoverflow.com/a/45292067
async fn get_extension(filename: &OsStr) -> Option<&str> {
    Path::new(filename).extension().and_then(OsStr::to_str)
}

/// Helper function to parse a given TOC file
/// (`DirEntry`) into a `Addon` struct.
///
/// TOC format summary:
/// https://wowwiki.fandom.com/wiki/TOC_format
async fn parse_toc_entry(toc_entry: DirEntry) -> Option<Addon> {
    let file = File::open(toc_entry.path()).unwrap();
    let reader = BufReader::new(file);

    let path = toc_entry.path().parent()?.to_path_buf();
    let mut title: Option<String> = None;
    let mut version: Option<String> = None;
    let mut dependencies: Vec<String> = Vec::new();
    let mut wowi_id: Option<String> = None;
    let mut tukui_id: Option<String> = None;
    let mut curse_id: Option<u32> = None;

    // It is an anti-pattern to compile the same regular expression in a loop,
    // which is why they are created here.
    //
    // https://docs.rs/regex/1.3.9/regex/#example-avoid-compiling-the-same-regex-in-a-loop
    let re_toc = Regex::new(r"##\s(?P<key>.*?):\s?(?P<value>.*)").unwrap();
    let re_title = Regex::new(r"\|[a-fA-F\d]{9}([^|]+)\|r?").unwrap();

    for line in reader.lines() {
        let l = line.unwrap();
        for cap in re_toc.captures_iter(l.as_str()) {
            match &cap["key"] {
                // String - The title to display.
                //
                // Note: Coloring is possible via UI escape sequences.
                // Since we don't want any color modifications, we will
                // trim it away.
                // Example 1: |cff1784d1ElvUI|r should be just ElvUI.
                // Example 2: BigWigs [|cffeda55fUldir|r] should be BigWigs [Uldir].
                "Title" => title = Some(re_title.replace_all(&cap["value"], "$1").to_string()),
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
                    wowi_id = Some(cap["value"].to_string());
                }
                // String - Addon identifier for TukUI API.
                "X-Tukui-ProjectID" => {
                    tukui_id = Some(cap["value"].to_string());
                }
                // String - Addon identifier for Curse API.
                "X-Curse-Project-ID" => {
                    // Santize the id, so we only get a `u32`.
                    if let Ok(id) = cap["value"].to_string().parse::<u32>() {
                        curse_id = Some(id)
                    }
                }
                _ => (),
            }
        }
    }

    Some(Addon::new(
        title?,
        version,
        path,
        wowi_id,
        tukui_id,
        curse_id,
        dependencies,
    ))
}

/// Helper function to split a comma separated string into `Vec<String>`.
fn split_dependencies_into_vec(value: &str) -> Vec<String> {
    value
        .split([','].as_ref())
        .map(|s| s.trim().to_string())
        .collect()
}
