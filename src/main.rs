// Avoid spawning an console window for the program.
// This is ignored on other platforms.
// https://msdn.microsoft.com/en-us/library/4cc7ya5b.aspx for more information.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod gui;

use ajour_core::Result;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn main() {
    // Setup the logger
    setup_logger().expect("setup logging");

    log_panics::init();

    log::debug!("Ajour {} has started.", VERSION);

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
        .level_for("panic", log::LevelFilter::Error)
        .level_for("ajour", log::LevelFilter::Trace);

    #[cfg(debug_assertions)]
    {
        logger = logger.chain(std::io::stdout());
    };

    #[cfg(not(debug_assertions))]
    {
        use std::fs::OpenOptions;

        let config_dir = ajour_core::fs::config_dir();

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
