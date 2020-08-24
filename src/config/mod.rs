use serde_derive::{Deserialize, Serialize};
#[cfg(not(windows))]
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

mod addons;
mod tokens;
mod wow;

use crate::{error::ClientError, Result};

pub use crate::config::addons::Addons;
pub use crate::config::tokens::Tokens;
pub use crate::config::wow::Wow;

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

/// Creates file at location, and copies default `Config` into it.
/// This is used if user does not have a config file, Ajour will
/// autogenerate it.
fn create_default_config<P: AsRef<Path>>(path: P) -> Result<PathBuf> {
    // Ensure we have folders created for the file.
    let parent = path.as_ref().parent().expect("parent for config not found");
    fs::create_dir_all(parent)?;

    // Create the config file.
    fs::File::create(&path)?;

    // Default serialized config content.
    let config = Config::default();
    let default_config_content = serde_yaml::to_string(&config)?;

    // Write to config.
    fs::write(&path, &default_config_content)?;

    Ok(path.as_ref().to_path_buf())
}

/// Returns the location of the first found config file paths
/// according to the following order:
///
/// 1. $HOME/.config/ajour/ajour.yml
/// 2. $HOME/.ajour.yml
#[cfg(not(windows))]
fn find_or_create_config() -> Result<PathBuf> {
    let home = env::var("HOME").expect("user home directory not found.");

    // Primary location path: $HOME/.config/ajour/ajour.yml.
    let pri_location = PathBuf::from(&home).join(".config/ajour/ajour.yml");
    if pri_location.exists() {
        return Ok(pri_location);
    }
    // Secondary location path: $HOME/.ajour.yml.
    let sec_location = PathBuf::from(&home).join(".ajour.yml");
    if sec_location.exists() {
        return Ok(sec_location);
    }

    Ok(create_default_config(&pri_location)?)
}

/// Returns the location of the first found config file paths
/// according to the following order:
///
/// 1. %APPDATA%\ajour\ajour.yml
/// 2. In the same directory as the executable
#[cfg(windows)]
fn find_or_create_config() -> Result<PathBuf> {
    let pri_location = dirs::config_dir()
        .map(|path| path.join("ajour\\ajour.yml"))
        .filter(|new| new.exists());
    if let Some(pri_location) = pri_location {
        return Ok(pri_location);
    }

    let sec_location = std::env::current_exe();
    if let Ok(sec_location) = sec_location.as_ref().map(|p| p.parent()) {
        if let Some(sec_location) = sec_location.map(|f| f.join("ajour.yml")) {
            if sec_location.exists() {
                return Ok(sec_location);
            }
        }
    }

    // TODO: Fix this method for windows.
    // pri_location is option, because we filter pri_location for now.
    // Ok(create_default_config(&pri_location.expect(msg))?)
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
pub async fn load_config() -> Result<Config> {
    let path = find_or_create_config()?;
    Ok(parse_config(&path)?)
}
