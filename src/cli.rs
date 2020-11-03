use crate::VERSION;

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
    // If an error, we need to setup the AttachConsole fix for Windows release
    // so we can exit and display the error message to the user.
    let is_opts_error = opts_result.is_err();

    // Workaround to output to console even though we compile with windows_subsystem = "windows"
    // in release mode
    #[cfg(target_os = "windows")]
    {
        if (is_cli || is_opts_error) && !is_debug {
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
    pub self_update_temp: Option<String>,
}

#[derive(Debug, StructOpt)]
pub enum Command {
    /// Update all addons from the command line then exit
    Update,
    /// Install an addon from the command line
    Install {
        #[structopt(help = "source url (Github & Gitlab currently supported)")]
        url: Uri,
    },
}
