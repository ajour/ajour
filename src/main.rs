use std::fs::File;
use std::ffi::OsStr;
use std::path::Path;
use walkdir::{DirEntry, WalkDir};
use std::io::{BufRead, BufReader};
use regex::Regex;

fn main() {
    let entries = get_toc_dir_entries("./test-data");
    let addons = parse_toc_dir_entries(entries);
    println!("{:?}", addons)
}

fn get_toc_dir_entries<P: AsRef<Path>>(path: P) -> Vec<DirEntry> {
    let mut vec: Vec<DirEntry> = Vec::new();
    for e in WalkDir::new(path)
        .max_depth(2)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if e.metadata().map_or(false, |m| m.is_file()) {
            let file_name = e.file_name();
            let file_extension = get_extension(file_name);
            if file_extension == Some("toc") {
                vec.push(e);
            }
        }
    }

    return vec;
}

// https://stackoverflow.com/a/45292067
fn get_extension(filename: &OsStr) -> Option<&str> {
    Path::new(filename).extension().and_then(OsStr::to_str)
}

#[derive(Debug)]
struct Addon {
    title: Option<String>
}

impl Addon {
    fn new() -> Self {
      return Addon { title: None }
    }

    fn set_title(&mut self, title: String) {
        self.title = Some(title);
    }
}

fn parse_toc_dir_entries(entries: Vec<DirEntry>) -> Vec<Addon> {
    let mut vec: Vec<Addon> = Vec::new();
    for e in entries {
        let file = File::open(e.path()).unwrap();
        let reader = BufReader::new(file);
        let mut addon: Addon = Addon::new();

        for line in reader.lines() {
            let l = line.unwrap();
            let re = Regex::new(r"##\s(?P<key>.*):\s(?P<value>.*)").unwrap();
            for cap in re.captures_iter(l.as_str()) {
                if &cap["key"] == "Title" {
                    let s = String::from(&cap["value"]);
                    addon.set_title(s);
                }
            }
        }

        vec.push(addon);
    }

    return vec;
}
