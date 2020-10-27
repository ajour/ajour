use ajour_core::config::Flavor;
use ajour_core::parse::read_addon_directory;
use async_std::{
    sync::{Arc, Mutex},
    task,
};
use std::env;
use std::fs::File;

fn main() {
    fern::Dispatch::new()
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
        .level_for("ajour_core", log::LevelFilter::Trace)
        .chain(std::io::stdout())
        .apply()
        .unwrap();

    let mut args = env::args();
    args.next();

    if args.len() < 1 {
        panic!("Usage: parse_addon_directory <PATH> [--fingerprints fingerprints.yml]");
    }

    let path = args.next().unwrap();
    let fingerprints_idx = args.position(|a| a == "--fingerprints");

    let fingerprint_cache = if let Some(idx) = fingerprints_idx {
        let path = args
            .nth(idx)
            .expect("--fingerprints must be followed by a path");

        let file = File::open(path).expect("fingerprints path doesn't exist");

        let collection = serde_yaml::from_reader(&file).expect("not a valid fingerprints file");

        Some(Arc::new(Mutex::new(collection)))
    } else {
        None
    };

    task::block_on(async move {
        let addons = read_addon_directory(fingerprint_cache, &path, Flavor::Classic)
            .await
            .unwrap();

        print!("{} addons parsed", addons.len());
    });
}
