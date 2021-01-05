use crate::VERSION;

use ajour_core::config::Flavor;

use isahc::http::Uri;
use structopt::{
    clap::{self, AppSettings},
    StructOpt,
};

use std::env;
use std::path::PathBuf;

pub fn get_opts() -> Result<Opts, clap::Error> {
    let args = env::args_os();

    Opts::from_iter_safe(args)
}

#[allow(unused_variables)]
pub fn validate_opts_or_exit(
    opts_result: Result<Opts, clap::Error>,
    is_cli: bool,
    is_debug: bool,
) -> Opts {
    // Workaround to output to console even though we compile with windows_subsystem = "windows"
    // in release mode
    #[cfg(target_os = "windows")]
    {
        if is_cli && !is_debug {
            use winapi::um::wincon::{AttachConsole, ATTACH_PARENT_PROCESS};

            unsafe {
                AttachConsole(ATTACH_PARENT_PROCESS);
            }
        }
    }

    // Now that the windows fix is successfully setup, we can safely exit on the error
    // and it will display properly to the user, or carry forward with the program
    // and properly display our logging to the user. Since `e.exit()` returns a `!`,
    // we can return the Ok(Opts) and carry forward with our program.
    match opts_result {
        Ok(opts) => opts,
        Err(e) => {
            // Apparently on `--version`, there is no "error message" that gets displayed
            // like with `--help` and actual clap errors. It gets printed before we
            // ever hit our console fix for windows, so let's manually print it
            // before exiting
            #[cfg(target_os = "windows")]
            {
                if !is_debug && e.kind == clap::ErrorKind::VersionDisplayed {
                    print!("Ajour {}", VERSION);
                }
            }

            e.exit();
        }
    }
}

#[derive(Debug, StructOpt)]
#[structopt(name = "Ajour",
            about = env!("CARGO_PKG_DESCRIPTION"),
            version = VERSION,
            author = env!("CARGO_PKG_AUTHORS"),
            setting = AppSettings::DisableHelpSubcommand)]
pub struct Opts {
    #[structopt(long = "data", help = "Path to a custom data directory for the app")]
    pub data_directory: Option<PathBuf>,
    #[structopt(long = "aa", help = "Enable / Disable Anti-aliasing (true / false)")]
    pub antialiasing: Option<bool>,
    #[structopt(subcommand)]
    pub command: Option<Command>,
    #[structopt(long, hidden = true)]
    pub self_update_temp: Option<PathBuf>,
}

#[derive(Debug, StructOpt)]
pub enum Command {
    /// Update all addons and WeakAuras
    Update,
    /// Update all addons from the command line then exit
    UpdateAddons,
    /// Update all WeakAuras from the command line then exit
    UpdateWeakauras,
    /// Install an addon from the command line
    Install {
        #[structopt(parse(try_from_str = str_to_flavor), possible_values = &["retail","ptr","beta","classic","classic_ptr"])]
        /// flavor to install addon under
        flavor: Flavor,
        #[structopt()]
        /// source url [Github & Gitlab currently supported]
        url: Uri,
    },
    /// Backup your WTF and/or AddOns folders
    Backup {
        #[structopt(short, long, default_value = "both", parse(try_from_str = str_to_backup_folder), possible_values = &["both","wtf","addons"])]
        /// folder to backup
        backup_folder: BackupFolder,
        #[structopt(short, long, parse(try_from_str = str_to_flavor), possible_values = &["retail","ptr","beta","classic","classic_ptr"])]
        /// space separated list of flavors to include in backup. If ommited, all flavors will be included.
        flavors: Vec<Flavor>,
        #[structopt()]
        /// folder to save backups to
        destination: PathBuf,
    },
}

fn str_to_flavor(s: &str) -> Result<Flavor, &'static str> {
    match s {
        "retail" => Ok(Flavor::Retail),
        "beta" => Ok(Flavor::RetailBeta),
        "ptr" => Ok(Flavor::RetailPTR),
        "classic" => Ok(Flavor::Classic),
        "classic_ptr" => Ok(Flavor::ClassicPTR),
        _ => Err("valid values are ['retail','ptr','beta','classic','classic_ptr']"),
    }
}

#[derive(Debug, Clone, Copy)]
pub enum BackupFolder {
    Both,
    AddOns,
    WTF,
}

fn str_to_backup_folder(s: &str) -> Result<BackupFolder, &'static str> {
    match s {
        "both" => Ok(BackupFolder::Both),
        "wtf" => Ok(BackupFolder::WTF),
        "addons" => Ok(BackupFolder::AddOns),
        _ => Err("valid values are ['both','wtf','addons']"),
    }
}
