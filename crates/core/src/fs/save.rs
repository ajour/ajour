use super::config_dir;
use crate::{bail, Result};
use serde::{de::DeserializeOwned, Serialize};

use std::fs;
use std::path::PathBuf;

/// Defines a serializable struct that should persist on the filesystem inside the
/// Ajour config directory.
pub trait PersistentData: DeserializeOwned + Serialize {
    /// Only method required to implement PersistentData on an object. Always relative to
    /// the config folder for Ajour.
    fn relative_path() -> PathBuf;

    /// Returns the full file path. Will create any parent directories that don't
    /// exist.
    fn path() -> Result<PathBuf> {
        let path = config_dir().join(Self::relative_path());

        if let Some(dir) = path.parent() {
            std::fs::create_dir_all(dir)?;
        }

        Ok(path)
    }

    /// Load from `PersistentData::path()`.
    fn load() -> Result<Self> {
        let path = Self::path()?;

        if path.exists() {
            let file = fs::File::open(&path)?;

            Ok(serde_yaml::from_reader(&file)?)
        } else {
            bail!("File does not exist: {:?}", path);
        }
    }

    /// Load from `PersistentData::path()`. If file doesn't exist, save it to the filesystem as `Default`
    /// and return that object.
    fn load_or_default<T: PersistentData + Default>() -> Result<T> {
        let load_result = <T as PersistentData>::load();

        match load_result {
            Ok(deser) => Ok(deser),
            _ => Ok(get_default_and_save()?),
        }
    }

    /// Save to `PersistentData::path()`
    fn save(&self) -> Result<()> {
        let contents = serde_yaml::to_string(&self)?;

        fs::write(Self::path()?, contents)?;

        Ok(())
    }
}

/// Get `Default` and save it.
fn get_default_and_save<T: PersistentData + Default>() -> Result<T> {
    let data = Default::default();

    <T as PersistentData>::save(&data)?;

    Ok(data)
}
