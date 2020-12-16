use ajour_weak_auras::{get_aura_updates, parse_auras};
use async_std::task;

use std::env;
use std::path::PathBuf;

fn main() {
    let mut args = env::args();
    args.next();

    if args.len() != 2 {
        panic!("Usage: parse_lua <WTF_PATH> <account>");
    }

    let path = PathBuf::from(args.next().unwrap());
    let account = args.next().unwrap();

    task::block_on(async {
        let auras = parse_auras(path, account).await;

        dbg!(&auras);

        let updates = get_aura_updates(&auras).await;

        dbg!(&updates);
    });
}
