use regex::Regex;
use std::ffi::OsStr;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;
use uuid::Uuid;
use walkdir::{DirEntry, WalkDir};

use crate::{error::ClientError, Result};

#[derive(Debug, Clone)]
pub struct Addon {
    pub id: String,
    pub title: Option<String>,
    pub version: Option<String>,
    pub dir_entry: DirEntry,
    pub dependencies: Vec<String>,
    pub optional_dependencies: Vec<String>,
    pub required_dependencies: Vec<String>,

    pub delete_btn_state: iced::button::State,
}

/// Struct which stores information about a single Addon.
impl Addon {
    fn new(
        title: Option<String>,
        version: Option<String>,
        dir_entry: DirEntry,
        dependencies: Vec<String>,
        optional_dependencies: Vec<String>,
        required_dependencies: Vec<String>,
    ) -> Self {
        return Addon {
            id: Uuid::new_v4().to_simple().to_string(),
            title,
            version,
            dir_entry,
            dependencies,
            optional_dependencies,
            required_dependencies,
            delete_btn_state: Default::default(),
        };
    }
}

/// Return a Vec<Addon> parsed from TOC files in the given directory.
pub async fn read_addon_directory<P: AsRef<Path>>(path: P) -> Result<Vec<Addon>> {
    // TODO: Consider skipping DirEntry if we encounter a
    //       blizzard addon. Blizzard adddon starts with 'Blizzard_*'.

    // If the path does not exists or does not point on a directory we throw an Error.
    if !path.as_ref().is_dir() {
        return Err(ClientError::Custom(
            format!("Addon directory not found: {:?}", path.as_ref().to_owned()).to_owned(),
        ));
    }

    let mut vec: Vec<Addon> = Vec::new();
    for entry in WalkDir::new(path)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if entry.metadata().map_or(false, |m| m.is_file()) {
            let file_name = entry.file_name();
            let file_extension = get_extension(file_name).await;
            if file_extension == Some("toc") {
                let addon = parse_addon_dir_entry(entry).await;
                match addon {
                    Some(addon) => vec.push(addon),
                    None => (),
                }
            }
        }
    }

    return Ok(vec);
}

// Helper function to return str file extension.
//
// Source:
// https://stackoverflow.com/a/45292067
async fn get_extension(filename: &OsStr) -> Option<&str> {
    Path::new(filename).extension().and_then(OsStr::to_str)
}

// Helper function to parse a given TOC file
// (DirEntry) into a Addon struct.
//
// TOC format summary:
// https://wowwiki.fandom.com/wiki/TOC_format
async fn parse_addon_dir_entry(dir_entry: DirEntry) -> Option<Addon> {
    let file = File::open(dir_entry.path()).unwrap();
    let reader = BufReader::new(file);

    let mut title: Option<String> = None;
    let mut version: Option<String> = None;
    let mut dependencies: Vec<String> = Vec::new();
    let mut optional_dependencies: Vec<String> = Vec::new();
    let mut required_dependencies: Vec<String> = Vec::new();

    // It is an anti-pattern to compile the same regular expression in a loop,
    // which is why they are created here.
    //
    // https://docs.rs/regex/1.3.9/regex/#example-avoid-compiling-the-same-regex-in-a-loop
    let re_toc = Regex::new(r"##\s(?P<key>.*?):\s?(?P<value>.*)").unwrap();
    let re_title = Regex::new(r"\|[a-f\d]{9}([^|]+)\|?r?").unwrap();

    for line in reader.lines() {
        let l = line.unwrap();
        for cap in re_toc.captures_iter(l.as_str()) {
            match &cap["key"] {
                "Title" => {
                    // String - The name to display.
                    //
                    // Note: Coloring is possible via UI escape sequences.
                    // Since we don't want any color modifications, we will
                    // trim it away.
                    // Example 1: |cff1784d1ElvUI|r should be just ElvUI.
                    // Example 2: BigWigs [|cffeda55fUldir|r] should be BigWigs [Uldir].
                    title = Some(re_title.replace_all(&cap["value"], "$1").to_string())
                }
                "Version" => {
                    // String - The AddOn version
                    version = Some(String::from(&cap["value"]));
                }
                "Dependencies" => {
                    // String - A comma-separated list of addon (directory)
                    // names that must be loaded before this addon can be loaded.
                    dependencies = split_dependencies_into_vec(&cap["value"]);
                }
                "RequiredDeps" => {
                    // String - A comma-separated list of addon (directory)
                    // names that must be loaded before this addon can be loaded.
                    required_dependencies = split_dependencies_into_vec(&cap["value"])
                }
                "OptionalDeps" => {
                    // String - A comma-separated list of addon (directory)
                    // names that should be loaded before this addon if they
                    // can be loaded.
                    optional_dependencies = split_dependencies_into_vec(&cap["value"])
                }
                _ => (),
            }
        }
    }

    return Some(Addon::new(
        title,
        version,
        dir_entry,
        dependencies,
        optional_dependencies,
        required_dependencies,
    ));
}

/// Helper function to split a comma seperated string into Vec<String>.
fn split_dependencies_into_vec(value: &str) -> Vec<String> {
    value
        .split([','].as_ref())
        .map(|s| s.trim().to_string())
        .collect()
}
