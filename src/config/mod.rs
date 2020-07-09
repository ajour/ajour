use serde::{Deserialize, Deserializer};
use serde_derive::Deserialize;
use serde_yaml::Value;
use std::env;
use std::fmt::{self, Display, Formatter};
use std::fs;
use std::io;
use std::path::PathBuf;

/// Result from config loading.
pub type Result<T> = std::result::Result<T, Error>;

/// Config type.
#[derive(Debug, PartialEq, Default, Deserialize)]
pub struct Config {
    /// Path to World of Warcraft
    #[serde(default, deserialize_with = "failure_default")]
    wow_directory: Option<PathBuf>,
}

impl Config {}

/// Errors occurring during config loading.
#[derive(Debug)]
pub enum Error {
    /// Config file not found.
    NotFound,

    /// io error reading file.
    Io(io::Error),

    /// Not valid yaml or missing parameters.
    Yaml(serde_yaml::Error),
}

impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Error::NotFound => None,
            Error::Io(err) => err.source(),
            Error::Yaml(err) => err.source(),
        }
    }
}

impl Display for Error {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Error::NotFound => write!(f, "Couldn't locate config file"),
            Error::Io(err) => write!(f, "Error reading config file: {}", err),
            Error::Yaml(err) => write!(f, "Problem with config: {}", err),
        }
    }
}

impl From<io::Error> for Error {
    fn from(val: io::Error) -> Self {
        if val.kind() == io::ErrorKind::NotFound {
            Error::NotFound
        } else {
            Error::Io(val)
        }
    }
}

impl From<serde_yaml::Error> for Error {
    fn from(val: serde_yaml::Error) -> Self {
        Error::Yaml(val)
    }
}

/// Returns the location of the first found config file paths
/// according to the following order:
///
/// 1. $HOME/.config/ajour/ajour.yml
/// 2. $HOME/.ajour.yml
#[cfg(not(windows))]
pub fn installed_config() -> Option<PathBuf> {
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

#[cfg(windows)]
pub fn installed_config() -> Option<PathBuf> {
    dirs::config_dir()
        .map(|path| path.join("ajour\\ajour.yml"))
        .filter(|new| new.exists())
}

fn parse_config(contents: &str) -> Result<Config> {
    match serde_yaml::from_str(contents) {
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

fn read_config(path: &PathBuf) -> Result<Config> {
    let contents = fs::read_to_string(path)?;

    parse_config(&contents)
}

pub fn load() -> Config {
    let path = installed_config();
    match path {
        Some(p) => read_config(&p).unwrap_or(Config::default()),
        None => Config::default()
    }
}

fn fallback_default<T, E>(err: E) -> T
where
    T: Default,
    E: Display,
{
    //error!(target: LOG_TARGET_CONFIG, "Problem with config: {}; using default value", err);
    println!("err {}", err);
    T::default()
}

pub fn failure_default<'a, D, T>(deserializer: D) -> std::result::Result<T, D::Error>
where
    D: Deserializer<'a>,
    T: Deserialize<'a> + Default,
{
    Ok(T::deserialize(Value::deserialize(deserializer)?).unwrap_or_else(fallback_default))
}

