use regex::Regex;
use std::ffi::OsStr;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;
use walkdir::{DirEntry, WalkDir};

#[derive(Debug, Clone)]
pub enum Error {
    NotFound,
    Unknown,
}

#[derive(Debug, Clone)]
pub struct Addon {
    pub title: Option<String>,
    pub version: Option<String>,
    //pub dependencies: Option<Vec<String>>,
    pub dir_entry: DirEntry,

    pub delete_btn_state: iced::button::State,
}

/// Struct which stores information about a single Addon.
impl Addon {
    fn new(title: Option<String>, version: Option<String>, dir_entry: DirEntry) -> Self {
        return Addon {
            title,
            version,
            //dependencies,
            dir_entry,
            delete_btn_state: Default::default(),
        };
    }
}

/// Return a Vec<Addon> parsed from TOC files in the given directory.
pub async fn read_addon_dir<P: AsRef<Path>>(path: P) -> Result<Vec<Addon>, Error> {
    // TODO: Consider skipping DirEntry if we encounter a
    //       blizzard addon. Blizzard adddon starts with 'Blizzard_*'.
    //
    // TODO: We should handle errors here, if nothing is find eg.
    //
    let mut vec: Vec<Addon> = Vec::new();
    for e in WalkDir::new(path)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if e.metadata().map_or(false, |m| m.is_file()) {
            let file_name = e.file_name();
            let file_extension = get_extension(file_name).await;
            if file_extension == Some("toc") {
                let addon = parse_addon_dir_entry(e).await;
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
//
// TODO:
// - We should properly ignore 'Dependency' addons.
//
async fn parse_addon_dir_entry(dir_entry: DirEntry) -> Option<Addon> {
    let file = File::open(dir_entry.path()).unwrap();
    let reader = BufReader::new(file);

    let mut title: Option<String> = None;
    let mut version: Option<String> = None;

    // It is an anti-pattern to compile the same regular expression in a loop,
    // which is why they are created here.
    //
    // https://docs.rs/regex/1.3.9/regex/#example-avoid-compiling-the-same-regex-in-a-loop
    let re_toc = Regex::new(r"\##\s(?P<key>[^:]+)(:\s)(?P<value>.+)").unwrap();
    let re_title = Regex::new(r"\|[a-f\d]{9}([^|]+)\|?r?").unwrap();

    for line in reader.lines() {
        let l = line.unwrap();
        for cap in re_toc.captures_iter(l.as_str()) {
            if &cap["key"] == "Title" {
                // Title can include a color hex.
                // An example is: |cff1784d1ElvUI|r
                title = Some(re_title.replace_all(&cap["value"], "$1").to_string());
            }

            if &cap["key"] == "Version" {
                version = Some(String::from(&cap["value"]));
            }

            // TODO:
            // We should also check for RequiredDeps, or anything
            // starting with Deps
            // if &cap["key"] == "Dependencies" {
            //     let value = &cap["value"];
            //     let dependencies: Vec<_> = value.split([','].as_ref()).map(|s| s.trim().to_string()).collect();
            // }
        }
    }

    return Some(Addon::new(
        title,
        version,
        dir_entry,
    ));
}
