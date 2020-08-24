use serde_derive::{Deserialize, Serialize};
use std::path::PathBuf;

/// Struct for settings related to World of Warcraft.
#[serde(default)]
#[derive(Deserialize, Serialize, Clone, Debug, PartialEq, Eq)]
pub struct Wow {
    #[serde(default)]
    pub directory: Option<PathBuf>,

    // TODO: Consider changing this to an enum.
    #[serde(default)]
    pub flavor: String,
}

impl Default for Wow {
    fn default() -> Self {
        Wow {
            directory: None,
            flavor: "retail".to_owned(),
        }
    }
}
