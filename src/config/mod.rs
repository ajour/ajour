mod error;

use serde_derive::Deserialize;
use std::env;
use std::fs;
use std::path::PathBuf;

use error::Error;

/// Result from config loading.
pub type Result<T> = std::result::Result<T, Error>;

/// Config type.
#[derive(Debug, PartialEq, Default, Deserialize)]
pub struct Config {
    /// Path to World of Warcraft
    #[serde(default = "default_wow_directory")]
    wow_directory: Option<PathBuf>,
}

fn default_wow_directory() -> Option<PathBuf> {
    None
}

impl Config {}


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
                Err(Error::Yaml(error))
            }
        }
        Ok(config) => Ok(config),
    }
}


/// Returns a Config.
///
/// This functions handles the initialization of a Config.
pub fn load() -> Config {
    let path = installed_config();
    match path {
        Some(p) => parse_config(&p).unwrap_or(Config::default()),
        None => Config::default()
    }
}
