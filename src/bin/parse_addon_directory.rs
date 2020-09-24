use ajour::exports::{read_addon_directory, Flavor};
use async_std::{
    sync::{Arc, Mutex},
    task,
};
use std::env;

fn main() {
    let mut args = env::args_os();

    if args.len() != 2 {
        panic!("Takes one arg: <path>");
    }

    let path = args.nth(1).unwrap();

    let collection = Arc::new(Mutex::new(None));

    task::block_on(async move {
        let addons = read_addon_directory(collection, &path, Flavor::Classic)
            .await
            .unwrap();

        print!("{} addons parsed", addons.len());
    });
}
