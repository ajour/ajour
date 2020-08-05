mod config;
mod error;
mod fs;
mod gui;
mod toc;
mod wowinterface_api;

use dotenv::dotenv;
use crate::error::ClientError;

pub type Result<T> = std::result::Result<T, ClientError>;
pub fn main() {
    // Loads the .env file
    dotenv().ok();

    // Start the GUI
    gui::run();
}
