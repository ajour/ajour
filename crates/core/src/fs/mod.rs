use lazy_static::lazy_static;
#[cfg(not(windows))]
use std::env;
use std::sync::{Arc, Mutex};
use std::{fs, path::PathBuf};

mod addon;
pub mod backup;
mod save;
#[cfg(feature = "gui")]
mod theme;

pub use addon::{delete_addons, install_addon};
pub use save::PersistentData;
#[cfg(feature = "gui")]
pub use theme::load_user_themes;

lazy_static! {
    pub static ref CONFIG_DIR: Arc<Mutex<PathBuf>> = {
        // Returns the location of the config directory. Will create if it doesn't
        // exist.
        //
        // $HOME/.config/ajour
        #[cfg(not(windows))]
        {
            let home = env::var("HOME").expect("user home directory not found.");

            let config_dir = PathBuf::from(&home).join(".config/ajour");

            if !config_dir.exists() {
                fs::create_dir_all(&config_dir).expect("could not create folder $HOME/.config/ajour");
                log::debug!("config directory created");
            }

            Arc::new(Mutex::new(config_dir))

        }

        // Returns the location of the config directory. Will create if it doesn't
        // exist.
        //
        // %APPDATA%\ajour
        #[cfg(windows)]
        {
            let config_dir = dirs_next::config_dir()
                .map(|path| path.join("ajour"))
                .expect("user home directory not found.");

            if !config_dir.exists() {
                fs::create_dir(&config_dir).expect("could not create folder %APPDATA%\\ajour");
                log::debug!("config directory created");
            }

            Arc::new(Mutex::new(config_dir))
        }
    };
}

pub fn config_dir() -> PathBuf {
    CONFIG_DIR.lock().unwrap().clone()
}
