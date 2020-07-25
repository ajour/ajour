pub mod addon;

use regex::Regex;
use std::ffi::OsStr;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;
use walkdir::{DirEntry, WalkDir};

use crate::{error::ClientError, Result};

/// Return a `Vec<Addon>` parsed from TOC files in the given directory.
pub async fn read_addon_directory<P: AsRef<Path>>(path: P) -> Result<Vec<addon::Addon>> {
    // TODO: Consider skipping DirEntry if we encounter a
    // blizzard addon. Blizzard adddon starts with 'Blizzard_*'.

    // If the path does not exists or does not point on a directory we throw an Error.
    if !path.as_ref().is_dir() {
        return Err(ClientError::Custom(
            format!("Addon directory not found: {:?}", path.as_ref().to_owned()).to_owned(),
        ));
    }

    let mut addons: Vec<addon::Addon> = Vec::new();
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
                match addon {
                    Some(addon) => addons.push(addon),
                    None => (),
                }
            }
        }
    }

    // Link all dependencies bidirectional
    link_dependencies_bidirectional(&mut addons);

    return Ok(addons);
}

/// Helper function to run through all addons and
/// link all dependencies bidirectional.
///
/// This ensures that for any Addon we always know all
/// dependencies to it.
///
/// Example: We download a Addon which upon unzipping has
/// three folders (addons): `Foo`, `Bar`, `Baz`.
/// `Foo` is the main addon, which will be shown in the GUI,
/// and `Bar` and `Baz` is two helper addons. `Bar` and `Baz`
/// both dependent on `Foo`. This we know because it is written
/// in their .toc file.
/// However we don't know anything about `Bar` and `Baz` when
/// only looking at `Foo`. This can cause a headache when we
/// want to delete `Foo` because we want to cleanup all folders
/// upon deletion.
///
/// TODO: This function could properly be optimized, however
/// for this given time, it works.
fn link_dependencies_bidirectional(addons: &mut Vec<addon::Addon>) {
    let clone_addons = addons.clone();

    for addon in addons {
        for clone_addon in &clone_addons {
            for dependency in &clone_addon.dependencies {
                if dependency == &addon.folder_title() {
                    addon.dependencies.push(clone_addon.folder_title());
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
async fn parse_toc_entry(toc_entry: DirEntry) -> Option<addon::Addon> {
    let file = File::open(toc_entry.path()).unwrap();
    let reader = BufReader::new(file);

    let path = toc_entry.path().parent()?.to_path_buf();
    let mut title: Option<String> = None;
    let mut version: Option<String> = None;
    let mut dependencies: Vec<String> = Vec::new();

    // It is an anti-pattern to compile the same regular expression in a loop,
    // which is why they are created here.
    //
    // https://docs.rs/regex/1.3.9/regex/#example-avoid-compiling-the-same-regex-in-a-loop
    let re_toc = Regex::new(r"##\s(?P<key>.*?):\s?(?P<value>.*)").unwrap();

    for line in reader.lines() {
        let l = line.unwrap();
        for cap in re_toc.captures_iter(l.as_str()) {
            match &cap["key"] {
                "Title" => {
                    // String - The title to display.
                    title = Some(String::from(&cap["value"]));
                }
                "Version" => {
                    // String - The AddOn version
                    version = Some(String::from(&cap["value"]));
                }
                "Dependencies" | "RequiredDeps" => {
                    // String - A comma-separated list of addon (directory)
                    // names that must be loaded before this addon can be loaded.
                    dependencies.append(&mut split_dependencies_into_vec(&cap["value"]));
                }
                _ => (),
            }
        }
    }

    return Some(addon::Addon::new(
        title?,
        version,
        path,
        dependencies,
    ));
}

/// Helper function to split a comma seperated string into `Vec<String>`.
fn split_dependencies_into_vec(value: &str) -> Vec<String> {
    value
        .split([','].as_ref())
        .map(|s| s.trim().to_string())
        .collect()
}
