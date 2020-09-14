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
    // Setup the logger
    setup_logger().expect("setup logging");

    log::debug!("Ajour has started.");

    // Start the GUI
    gui::run();
}

#[allow(clippy::unnecessary_operation)]
fn setup_logger() -> Result<()> {
    let mut logger = fern::Dispatch::new()
        .format(|out, message, record| {
            out.finish(format_args!(
                "{} [{}][{}] {}",
                chrono::Local::now().format("%H:%M:%S%.3f"),
                record.target(),
                record.level(),
                message
            ))
        })
        .level(log::LevelFilter::Off)
        .level_for("ajour", log::LevelFilter::Debug);

    #[cfg(debug_assertions)]
    {
        logger = logger.chain(std::io::stdout());
    };

    #[cfg(not(debug_assertions))]
    {
        use std::fs::OpenOptions;

        let config_dir = fs::config_dir();

        let log_file = OpenOptions::new()
            .write(true)
            .create(true)
            .append(false)
            .truncate(true)
            .open(config_dir.join("ajour.log"))?;

        logger = logger.chain(log_file);
    };

    logger.apply()?;
    Ok(())
}
