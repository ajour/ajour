use serde_derive::Deserialize;
use std::path::PathBuf;

/// Struct for settings related to World of Warcraft.
#[serde(default)]
#[derive(Deserialize, Clone, Default, Debug, PartialEq, Eq)]
pub struct Wow {
    #[serde(default = "default_directory")]
    pub directory: Option<PathBuf>,

    #[serde(default = "default_version")]
    pub version: String,
}

fn default_directory() -> Option<PathBuf> {
    None
}

fn default_version() -> String {
    "retail".to_owned()
}
