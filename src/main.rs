// Avoid spawning an console window for the program.
// This is ignored on other platforms.
// https://msdn.microsoft.com/en-us/library/4cc7ya5b.aspx for more information.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod cli;
mod command;
mod gui;

use ajour_core::fs::CONFIG_DIR;
use ajour_core::utility::{remove_file, rename};
use color_eyre::eyre::{Report, Result, WrapErr};

#[cfg(target_os = "linux")]
use std::env;
use std::path::{Path, PathBuf};

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn main() -> color_eyre::eyre::Result<()> {
    color_eyre::install()?;
    let opts_result = cli::get_opts();

    let is_debug = cfg!(debug_assertions);

    // If this is a clap error, we map to None since we are going to exit and display
    // an error message anyway and this value won't matter. If it's not an error,
    // the underlying `command` will drive this variable. If a `command` is passed
    // on the command line, Ajour functions as a CLI instead of launching the GUI.
    let is_cli = opts_result.as_ref().map(|o| &o.command).is_ok();

    // This function validates whether or not we need to exit and print any message
    // due to arguments passed on the command line. If not, it will return a
    // parsed `Opts` struct. This also handles setting up our windows release build
    // fix that allows us to print to the console when not using the GUI.
    let opts = cli::validate_opts_or_exit(opts_result, is_cli, is_debug);

    if let Some(data_dir) = &opts.data_directory {
        let mut config_dir = CONFIG_DIR.lock().unwrap();

        *config_dir = data_dir.clone();
    }

    setup_logger(is_cli, is_debug).expect("setup logging");

    // Called when we launch from the temp (new release) binary during the self update
    // process. We will rename the temp file (running process) to the original binary
    if let Some(cleanup_path) = &opts.self_update_temp {
        let self_update_status = handle_self_update_temp(cleanup_path);
        if let Err(e) = &self_update_status {
            log_error(&e);
        }
        self_update_status?; // exit if error with error message from self update
    }

    log::info!("Ajour {} has started.", VERSION);

    match opts.command {
        Some(command) => {
            // Process the command and exit
            match command {
                cli::Command::Backup {
                    backup_folder,
                    destination,
                    flavors,
                } => command::backup(backup_folder, destination, flavors),
                cli::Command::Update => command::update_both(),
                cli::Command::UpdateAddons => command::update_all_addons(),
                cli::Command::UpdateWeakauras => command::update_all_weakauras(),
                cli::Command::Install { url, flavor } => command::install_from_source(url, flavor),
            }?
        }
        None => {
            // We only log panics in gui mode as we let eyre report them strait to std_err in cli cases
            log_panics::init(); // TODO: Check if this is correct

            // Start the GUI
            gui::run(opts);
        }
    };
    Ok(())
}

/// Log any errors
pub fn log_error(error: &Report) {
    log::error!("{}", error);

    let mut causes = error.chain();
    // Remove first entry since it's same as top level error
    causes.next();

    for cause in causes {
        log::error!("caused by: {}", cause);
    }
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

    if !is_cli && is_debug {
        logger = logger.chain(std::io::stdout());
    }

    let config_dir = ajour_core::fs::config_dir();

    let log_file = std::fs::OpenOptions::new()
        .write(true)
        .create(true)
        .append(false)
        .truncate(true)
        .open(config_dir.join("ajour.log"))?;

    logger = logger.chain(log_file);

    logger.apply()?;
    Ok(())
}

fn handle_self_update_temp(cleanup_path: &Path) -> Result<()> {
    #[cfg(not(target_os = "linux"))]
    let current_bin = env::current_exe()?;

    #[cfg(target_os = "linux")]
    let current_bin =
        PathBuf::from(env::var("APPIMAGE").wrap_err("error getting APPIMAGE env variable")?);

    // Fix for self updating pre 0.5.4 to >= 0.5.4
    //
    // Pre 0.5.4, `cleanup_path` is actually the file name of the main bin name that
    // got passed via the CLI in the self update process. We want to rename the
    // current bin to that bin name. This was passed as a string of just the file
    // name, so we want to make an actual full path out of it first.
    if current_bin
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or_default()
        .starts_with("tmp_")
    {
        let main_bin_name = cleanup_path;

        let parent_dir = current_bin.parent().unwrap();

        let main_bin = parent_dir.join(&main_bin_name);

        rename(&current_bin, &main_bin)?;
    } else {
        remove_file(cleanup_path)?;
    }

    log::debug!("Ajour updated successfully");

    Ok(())
}
