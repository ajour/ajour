use ajour_core::parse::{file_parsing_regex, fingerprint_addon_dir, ParsingPatterns};
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
        let parsing_patterns = file_parsing_regex().await.unwrap();

        let ParsingPatterns {
            initial_inclusion_regex,
            extra_inclusion_regex,
            file_parsing_regex,
        } = parsing_patterns;

        let fingerprint = fingerprint_addon_dir(
            &path,
            &initial_inclusion_regex,
            &extra_inclusion_regex,
            &file_parsing_regex,
        )
        .unwrap();

        println!("Fingerprint is {}", fingerprint);
    });
}
