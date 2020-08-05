use serde_derive::Deserialize;
use std::env;
use std::fs;
use std::path::PathBuf;

use crate::{error::ClientError, Result};

/// Config type.
#[derive(Debug, PartialEq, Default, Deserialize, Clone)]
pub struct Config {
    /// Path to World of Warcraft
    #[serde(default = "default_wow_directory")]
    pub wow_directory: Option<PathBuf>,

    /// Client Version
    #[serde(default = "default_client_version")]
    pub client_version: String,

    /// Wowinterface Token
    #[serde(default = "default_wow_interface_token")]
    pub wow_interface_token: String,
}

/// Default World of Warcraft directory value.
fn default_wow_directory() -> Option<PathBuf> {
    None
}

/// Default Client Version
fn default_client_version() -> String {
    "retail".to_owned()
}

/// Default Wowinterface Token
fn default_wow_interface_token() -> String {
    // If we don't have a token in the config file, we expect to find one
    // in the environment variables.
    env::var("WOW_INTERFACE_TOKEN").expect("Expected token in environment variables.")
}

impl Config {
    /// Returns a `Option<PathBuf>` to the directory containing the addons.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_addon_directory(&self) -> Option<PathBuf> {
        match self.wow_directory.clone() {
            Some(dir) => {
                // We prepend and append `_` to the client_version so it
                // either becomes _retail_, or _classic_.
                let formatted_client_version = format!("_{}_", self.client_version.clone());

                // The path to the directory containing the addons
                Some(dir.join(formatted_client_version).join("Interface/AddOns"))
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

/// Returns the location of the first found config file paths
/// according to the following order:
///
/// 1. $HOME/.config/ajour/ajour.yml
/// 2. $HOME/.ajour.yml
#[cfg(not(windows))]
fn installed_config() -> Option<PathBuf> {
    if let Ok(home) = env::var("HOME") {
        // Fallback path: $HOME/.config/ajour/ajour.yml.
        let fallback = PathBuf::from(&home).join(".config/ajour/ajour.yml");
        if fallback.exists() {
            return Some(fallback);
        }
        // Fallback path: $HOME/.ajour.yml.
        let fallback = PathBuf::from(&home).join(".ajour.yml");
        if fallback.exists() {
            return Some(fallback);
        }
    }

    None
}

/// Returns the location of the first found config file paths
/// according to the following order:
///
/// 1. %APPDATA%\ajour\ajour.yml
#[cfg(windows)]
fn installed_config() -> Option<PathBuf> {
    dirs::config_dir()
        .map(|path| path.join("ajour\\ajour.yml"))
        .filter(|new| new.exists())
}

/// Returns the config after the content of the file
/// has been read and correctly parsed.
fn parse_config(path: &PathBuf) -> Result<Config> {
    let contents = fs::read_to_string(path)?;
    match serde_yaml::from_str(&contents) {
        Err(error) => {
            // Prevent parsing error with an empty string and commented out file.
            if error.to_string() == "EOF while parsing a value" {
                Ok(Config::default())
            } else {
                Err(ClientError::YamlError(error))
            }
        }
        Ok(config) => Ok(config),
    }
}

/// Returns a Config.
///
/// This functions handles the initialization of a Config.
pub async fn load_config() -> Config {
    let path = installed_config();
    match path {
        Some(p) => parse_config(&p).unwrap_or(Config::default()),
        None => Config::default(),
    }
}
