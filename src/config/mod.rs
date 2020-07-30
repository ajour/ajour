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

    /// Path to a folder which will store addons while they
    /// are downloaded. They will be removed from this
    /// location afterwards.
    #[serde(default = "default_tmp_directory")]
    pub tmp_directory: Option<PathBuf>,

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

/// Default Temp Directory
/// TODO: Add a temp directory
fn default_tmp_directory() -> Option<PathBuf> {
    None
}

/// Default Wowinterface Token
fn default_wow_interface_token() -> String {
    // TODO: Load a default token (from dotenv eg.)
    // https://github.com/dotenv-rs/dotenv
    "TODO_LOAD_TOKEN".to_owned()
}

impl Config {
    pub fn get_addon_directory(&self) -> Option<PathBuf> {
        match self.wow_directory.clone() {
            Some(dir) => {
                // We prepend and append `_` to the client_version so it
                // either becomes _retail_, or _classic_.
                let formatted_client_version = format!("_{}_", self.client_version.clone());

                // The path for the AddOns is expected to be located at
                // wow_directory/formatted_client_version/Interface/AddOns
                Some(dir.join(formatted_client_version).join("Interface/AddOns"))
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
