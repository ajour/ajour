use glob::MatchOptions;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

mod addons;
mod wow;

use crate::fs::PersistentData;
use crate::Result;

pub use crate::config::addons::Addons;
pub use crate::config::wow::{Flavor, Wow};

/// Config struct.
#[derive(Deserialize, Serialize, Debug, PartialEq, Default, Clone)]
pub struct Config {
    #[serde(default)]
    pub wow: Wow,

    #[serde(default)]
    pub addons: Addons,

    pub theme: Option<String>,

    #[serde(default)]
    pub column_config: ColumnConfig,

    pub window_size: Option<(u32, u32)>,

    pub scale: Option<f64>,

    pub backup_directory: Option<PathBuf>,

    #[serde(default)]
    pub backup_addons: bool,

    #[serde(default)]
    pub backup_wtf: bool,

    #[serde(default)]
    pub hide_ignored_addons: bool,
}

impl Config {
    /// Returns a `Option<PathBuf>` to the directory containing the addons.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_addon_directory_for_flavor(&self, flavor: &Flavor) -> Option<PathBuf> {
        match &self.wow.directory {
            Some(dir) => {
                // The path to the directory containing the addons
                let mut addon_dir = dir.join(&flavor.folder_name()).join("Interface/AddOns");

                // If path doesn't exist, it could have been modified by the user.
                // Check for a case-insensitive version and use that instead.
                if !addon_dir.exists() {
                    let options = MatchOptions {
                        case_sensitive: false,
                        ..Default::default()
                    };

                    // For some reason the case insensitive pattern doesn't work
                    // unless we add an actual pattern symbol, hence the `?`.
                    let pattern = format!(
                        "{}/?nterface/?ddons",
                        dir.join(&flavor.folder_name()).display()
                    );

                    for entry in glob::glob_with(&pattern, options).unwrap() {
                        if let Ok(path) = entry {
                            addon_dir = path;
                        }
                    }
                }

                Some(addon_dir)
            }
            None => None,
        }
    }

    /// Returns a `Option<PathBuf>` to the directory which will hold the
    /// temporary zip archives.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_download_directory_for_flavor(&self, flavor: Flavor) -> Option<PathBuf> {
        match self.get_addon_directory_for_flavor(&flavor) {
            Some(dir) => {
                // The path to the directory which hold the temporary zip archives
                let dir = dir.parent().expect("Expected Addons folder has a parent.");
                Some(dir.to_path_buf())
            }
            None => None,
        }
    }

    /// Returns a `Option<PathBuf>` to the WTF directory.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_wtf_directory_for_flavor(&self, flavor: &Flavor) -> Option<PathBuf> {
        match &self.wow.directory {
            Some(dir) => {
                // The path to the WTF directory
                let mut addon_dir = dir.join(&flavor.folder_name()).join("WTF");

                // If path doesn't exist, it could have been modified by the user.
                // Check for a case-insensitive version and use that instead.
                if !addon_dir.exists() {
                    let options = MatchOptions {
                        case_sensitive: false,
                        ..Default::default()
                    };

                    // For some reason the case insensitive pattern doesn't work
                    // unless we add an actual pattern symbol, hence the `?`.
                    let pattern = format!("{}/?tf", dir.join(&flavor.folder_name()).display());

                    for entry in glob::glob_with(&pattern, options).unwrap() {
                        if let Ok(path) = entry {
                            addon_dir = path;
                        }
                    }
                }

                Some(addon_dir)
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

#[derive(Deserialize, Serialize, Debug, PartialEq, Clone)]
pub enum ColumnConfig {
    V1 {
        local_version_width: u16,
        remote_version_width: u16,
        status_width: u16,
    },
    V2 {
        columns: Vec<ColumnConfigV2>,
    },
    V3 {
        my_addons_columns: Vec<ColumnConfigV2>,
        catalog_columns: Vec<ColumnConfigV2>,
    },
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Clone)]
pub struct ColumnConfigV2 {
    pub key: String,
    pub width: Option<u16>,
    pub hidden: bool,
}

impl Default for ColumnConfig {
    fn default() -> Self {
        ColumnConfig::V1 {
            local_version_width: 150,
            remote_version_width: 150,
            status_width: 85,
        }
    }
}

/// Returns a Config.
///
/// This functions handles the initialization of a Config.
pub async fn load_config() -> Result<Config> {
    log::debug!("loading config");

    Ok(Config::load_or_default()?)
}
