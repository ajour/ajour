// Avoid spawning an console window for the program.
// This is ignored on other platforms.
// https://msdn.microsoft.com/en-us/library/4cc7ya5b.aspx for more information.
#![windows_subsystem = "windows"]

mod addon;
mod config;
mod error;
mod fs;
mod gui;
mod network;
mod toc;
mod tukui_api;
mod wowinterface_api;

use crate::error::ClientError;

pub type Result<T> = std::result::Result<T, ClientError>;
pub fn main() {
    // Start the GUI
    gui::run();
}
