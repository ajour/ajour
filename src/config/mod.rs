use serde_derive::{Deserialize, Serialize};
use std::path::PathBuf;

mod addons;
mod tokens;
mod wow;

use crate::fs::PersistentData;
use crate::Result;

pub use crate::config::addons::Addons;
pub use crate::config::tokens::Tokens;
pub use crate::config::wow::{Flavor, Wow};

/// Config struct.
#[derive(Deserialize, Serialize, Debug, PartialEq, Default, Clone)]
pub struct Config {
    #[serde(default)]
    pub wow: Wow,

    #[serde(default)]
    pub addons: Addons,

    #[serde(default)]
    pub tokens: Tokens,
}

impl Config {
    /// Returns a `Option<PathBuf>` to the directory containing the addons.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_addon_directory(&self) -> Option<PathBuf> {
        match self.wow.directory.clone() {
            Some(dir) => {
                // We prepend and append `_` to the formatted_client_flavor so it
                // either becomes _retail_, or _classic_.
                let formatted_client_flavor = format!("_{}_", self.wow.flavor.to_string());

                // The path to the directory containing the addons
                Some(dir.join(formatted_client_flavor).join("Interface/AddOns"))
            }
            None => None,
        }
    }

    /// Returns a `Option<PathBuf>` to the directory which will hold the
    /// temporary zip archives.
    /// For now it will use the parent of the Addons folder.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_temporary_addon_directory(&self) -> Option<PathBuf> {
        match self.get_addon_directory() {
            Some(dir) => {
                // The path to the directory which hold the temporary zip archives
                let dir = dir.parent().expect("Expected Addons folder has a parent.");
                Some(dir.to_path_buf())
            }
            None => None,
        }
    }
}

impl PersistentData for Config {
    fn relative_path() -> PathBuf {
        PathBuf::from("ajour.yml")
    }
}

/// Returns a Config.
///
/// This functions handles the initialization of a Config.
pub async fn load_config() -> Result<Config> {
    Ok(Config::load_or_default()?)
}
