use serde_derive::{Deserialize, Serialize};
use std::path::PathBuf;

/// Struct for settings related to World of Warcraft.
#[serde(default)]
#[derive(Deserialize, Serialize, Clone, Default, Debug, PartialEq, Eq)]
pub struct Wow {
    #[serde(default = "default_directory")]
    pub directory: Option<PathBuf>,

    // TODO: Consider changing this to an enum.
    #[serde(default = "default_flavor")]
    pub flavor: String,
}

fn default_directory() -> Option<PathBuf> {
    None
}

fn default_flavor() -> String {
    "retail".to_owned()
}
