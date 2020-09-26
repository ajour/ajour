use ajour_core::parse::parse_toc_path;
use std::env;
use std::path::PathBuf;

fn main() {
    let mut args = env::args();
    args.next();

    if args.len() != 1 {
        panic!("Usage: parse_toc <PATH>");
    }

    let path = PathBuf::from(args.next().unwrap());

    dbg!(&path);

    let addon = parse_toc_path(&path).unwrap();

    print!("{:?}", addon);
}
