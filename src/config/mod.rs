use serde_derive::Deserialize;
#[cfg(not(windows))]
use std::env;
use std::fs;
use std::path::PathBuf;

mod tokens;
mod wow;

use crate::{error::ClientError, Result};

pub use crate::config::tokens::Tokens;
pub use crate::config::wow::Wow;

/// Config struct.
#[derive(Debug, PartialEq, Default, Deserialize, Clone)]
pub struct Config {
    #[serde(default = "default_wow")]
    pub wow: Wow,

    #[serde(default = "default_tokens")]
    pub tokens: Tokens,
}

fn default_wow() -> Wow {
    Wow::default()
}

fn default_tokens() -> Tokens {
    Tokens::default()
}

impl Config {
    /// Returns a `Option<PathBuf>` to the directory containing the addons.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_addon_directory(&self) -> Option<PathBuf> {
        match self.wow.directory.clone() {
            Some(dir) => {
                // We prepend and append `_` to the formatted_client_flavor so it
                // either becomes _retail_, or _classic_.
                let formatted_client_flavor = format!("_{}_", self.wow.flavor.clone());

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
/// 2. In the same directory as the executable
#[cfg(windows)]
fn installed_config() -> Option<PathBuf> {
    let fallback = dirs::config_dir()
        .map(|path| path.join("ajour\\ajour.yml"))
        .filter(|new| new.exists());
    if let Some(fallback) = fallback {
        return Some(fallback);
    }

    let fallback = std::env::current_exe();
    if let Ok(fallback) = fallback.as_ref().map(|p| p.parent()) {
        if let Some(fallback) = fallback.map(|f| f.join("ajour.yml")) {
            if fallback.exists() {
                return Some(fallback);
            }
        }
    }

    None
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
        Some(p) => parse_config(&p).unwrap_or_default(),
        None => Config::default(),
    }
}
