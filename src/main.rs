// Avoid spawning an console window for the program.
// This is ignored on other platforms.
// https://msdn.microsoft.com/en-us/library/4cc7ya5b.aspx for more information.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod cli;
mod gui;

use ajour_core::fs::CONFIG_DIR;
use ajour_core::Result;

use rust_embed::RustEmbed;

use i18n_embed::{gettext::gettext_language_loader, DesktopLanguageRequester};

#[derive(RustEmbed)]
#[folder = "i18n/mo"] // path to the compiled localization resources
struct Translations;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn main() {
    let opts = cli::get_opts();

    if let Some(data_dir) = &opts.data_directory {
        let mut config_dir = CONFIG_DIR.lock().unwrap();

        *config_dir = data_dir.clone();
    }

    // Setup the logger
    setup_logger().expect("setup logging");

    log_panics::init();

    log::debug!("Ajour {} has started.", VERSION);

    let translations = Translations {};
    let language_loader = gettext_language_loader!();

    // Use the language requester for the desktop platform (linux, windows, mac).
    // There is also a requester available for the web-sys WASM platform called
    // WebLanguageRequester, or you can implement your own.
    let requested_languages = DesktopLanguageRequester::requested_languages();

    let _result = i18n_embed::select(&language_loader, &translations, &requested_languages);

    // Start the GUI
    gui::run(opts);
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
        .level_for("ajour", log::LevelFilter::Trace)
        .level_for("ajour_core", log::LevelFilter::Trace);

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
