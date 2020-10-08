// Avoid spawning an console window for the program.
// This is ignored on other platforms.
// https://msdn.microsoft.com/en-us/library/4cc7ya5b.aspx for more information.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod cli;
mod gui;
mod update;

use ajour_core::error::ClientError;
use ajour_core::fs::CONFIG_DIR;
use ajour_core::Result;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn main() {
    let opts = cli::get_opts();

    if let Some(data_dir) = &opts.data_directory {
        let mut config_dir = CONFIG_DIR.lock().unwrap();

        *config_dir = data_dir.clone();
    }

    // Setup the logger
    {
        #[cfg(debug_assertions)]
        let is_debug = true;
        #[cfg(not(debug_assertions))]
        let is_debug = false;

        #[cfg(target_os = "windows")]
        let is_windows = true;
        #[cfg(not(target_os = "windows"))]
        let is_windows = false;

        let is_cli = opts.command.is_some();

        // Workaround to output to console even though we compile with windows_subsystem = "windows"
        // in release mode
        if is_windows && is_cli && !is_debug {
            use winapi::um::wincon::{AttachConsole, ATTACH_PARENT_PROCESS};

            unsafe {
                AttachConsole(ATTACH_PARENT_PROCESS);
            }
        }

        setup_logger(is_cli, is_debug).expect("setup logging");
    }

    log_panics::init();

    log::info!("Ajour {} has started.", VERSION);

    match opts.command {
        Some(command) => {
            // Process the command and exit
            if let Err(e) = match command {
                cli::Command::Update => update::update_all_addons(),
            } {
                log_error(&e);
            }
        }
        None => {
            // Start the GUI
            gui::run(opts);
        }
    }
}

/// Log any errors
pub fn log_error(e: &ClientError) {
    log::error!("{}", e);
}

#[allow(clippy::unnecessary_operation)]
fn setup_logger(is_cli: bool, is_debug: bool) -> Result<()> {
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

    if !is_cli {
        logger = logger.level_for("ajour_core", log::LevelFilter::Trace);
    }

    if is_cli || is_debug {
        logger = logger.chain(std::io::stdout());
    }

    if !is_cli && !is_debug {
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
