mod addon;
mod backup;
mod config;
mod curse_api;
mod error;
mod fs;
mod gui;
mod murmur2;
mod network;
mod parse;
mod theme;
mod tukui_api;
mod utility;

use crate::error::ClientError;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

pub type Result<T> = std::result::Result<T, ClientError>;

pub use gui::run;

pub mod exports {
    pub use crate::config::Flavor;
    pub use crate::fs::config_dir;
    pub use crate::parse::read_addon_directory;
}
