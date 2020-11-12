use ajour_core::parse::fingerprint_addon_dir;
use async_std::task;
use std::env;
use std::path::PathBuf;

fn main() {
    let mut args = env::args();
    args.next();

    if args.len() != 1 {
        panic!("Usage: parse_addon <PATH>");
    }

    let path = PathBuf::from(args.next().unwrap());

    task::block_on(async move {
        let fingerprint = fingerprint_addon_dir(&path).unwrap();

        println!("Fingerprint is {}", fingerprint);
    });
}
