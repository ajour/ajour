// Avoid spawning an console window for the program.
// This is ignored on other platforms.
// https://msdn.microsoft.com/en-us/library/4cc7ya5b.aspx for more information.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod addon;
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
pub fn main() {
    // Start the GUI
    gui::run();
}
