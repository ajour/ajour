use crate::VERSION;
use std::path::PathBuf;
use structopt::StructOpt;

pub fn get_opts() -> Opts {
    Opts::from_args()
}

#[derive(Debug, StructOpt)]
#[structopt(name = "Ajour",
            about = env!("CARGO_PKG_DESCRIPTION"),
            version = VERSION,
            author = env!("CARGO_PKG_AUTHORS"))]
pub struct Opts {
    #[structopt(long = "data", help = "Path to a custom data directory for the app")]
    pub data_directory: Option<PathBuf>,
    #[structopt(long = "aa", help = "Enable / Disable Anti-aliasing (true / false)")]
    pub antialiasing: Option<bool>,
}
