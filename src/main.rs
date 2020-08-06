mod config;
mod error;
mod fs;
mod gui;
mod toc;
mod wowinterface_api;
mod tukui_api;

use crate::error::ClientError;

pub type Result<T> = std::result::Result<T, ClientError>;
pub fn main() {
    // Start the GUI
    gui::run();
}
