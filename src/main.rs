// Avoid spawning an console window for the program.
// This is ignored on other platforms.
// https://msdn.microsoft.com/en-us/library/4cc7ya5b.aspx for more information.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod cli;
mod gui;

use ajour_core::fs::CONFIG_DIR;
use ajour_core::Result;

use rust_embed::RustEmbed;

use i18n_embed::{gettext::GettextLanguageLoader,gettext::gettext_language_loader, DesktopLanguageRequester, LanguageRequester,
    DefaultLocalizer, Localizer, unic_langid::LanguageIdentifier};
use std::rc::Rc;
use lazy_static::lazy_static;

#[derive(RustEmbed)]
#[folder = "i18n/mo"] // path to the compiled localization resources
struct Translations;

const TRANSLATIONS: Translations = Translations {};

lazy_static! {
    static ref LANGUAGE_LOADER: GettextLanguageLoader = gettext_language_loader!();
}

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

    let localizer = DefaultLocalizer::new(&*LANGUAGE_LOADER, &TRANSLATIONS);

    let localizer_rc: Rc<dyn Localizer> = Rc::new(localizer);

    let mut language_requester = DesktopLanguageRequester::new();
    language_requester.add_listener(Rc::downgrade(&localizer_rc));

    // Manually check the currently requested system language,
    // and update the listeners. When the system language changes,
    // this will automatically be triggered.
    language_requester.poll().unwrap(); 

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
