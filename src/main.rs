mod config;
mod error;
mod fs;
mod gui;
mod toc;

use crate::error::ClientError;

pub type Result<T> = std::result::Result<T, ClientError>;
pub fn main() {
    // Start the GUI
    gui::run();
}
