#[cfg(not(windows))]
use std::env;
use std::{fs, path::PathBuf};

mod addon;
mod save;
mod theme;

pub use addon::{delete_addons, install_addon};
pub use save::PersistentData;
pub use theme::load_user_themes;

/// Returns the location of the config directory. Will create if it doesn't
/// exist.
///
/// $HOME/.config/ajour
#[cfg(not(windows))]
fn config_dir() -> PathBuf {
    let home = env::var("HOME").expect("user home directory not found.");

    let config_dir = PathBuf::from(&home).join(".config/ajour");

    if !config_dir.exists() {
        fs::create_dir(&config_dir).expect("could not create folder $HOME/.config/ajour");
    }

    config_dir
}

/// Returns the location of the config directory. Will create if it doesn't
/// exist.
///
/// %APPDATA%\ajour
#[cfg(windows)]
fn config_dir() -> PathBuf {
    let config_dir = dirs::config_dir()
        .map(|path| path.join("ajour"))
        .expect("user home directory not found.");

    if !config_dir.exists() {
        fs::create_dir(&config_dir).expect("could not create folder %APPDATA%\\ajour");
    }

    config_dir
}
