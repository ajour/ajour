use ajour_weak_auras::{
    ensure_companion_addon_exists, get_aura_updates, list_accounts, parse_auras, write_updates,
};
use async_std::{path::PathBuf, task};
use structopt::StructOpt;

#[derive(StructOpt)]
struct Opts {
    #[structopt(subcommand)]
    command: Command,
}

#[derive(StructOpt)]
enum Command {
    Parse {
        wtf_path: PathBuf,
        account: String,
    },
    ListUpdates {
        wtf_path: PathBuf,
        account: String,
    },
    ListAccounts {
        wtf_path: PathBuf,
    },
    CreateCompanion {
        addon_dir: PathBuf,
    },
    WriteUpdates {
        wtf_path: PathBuf,
        account: String,
        addon_dir: PathBuf,
    },
}

fn main() {
    let opts: Opts = Opts::from_args();

    task::block_on(async move {
        match opts.command {
            Command::Parse { wtf_path, account } => {
                let auras = parse_auras(wtf_path, account).await.expect("parsing auras");

                dbg!(&auras);
            }
            Command::ListUpdates { wtf_path, account } => {
                let auras = parse_auras(wtf_path, account).await.expect("parsing auras");

                let updates = get_aura_updates(&auras).await.expect("getting updates");

                dbg!(&updates);
            }
            Command::ListAccounts { wtf_path } => {
                let accounts = list_accounts(wtf_path).await.expect("listing accounts");

                dbg!(accounts);
            }
            Command::CreateCompanion { addon_dir } => ensure_companion_addon_exists(addon_dir)
                .await
                .expect("creating companion addon"),
            Command::WriteUpdates {
                wtf_path,
                account,
                addon_dir,
            } => {
                let auras = parse_auras(wtf_path, account).await.expect("parsing auras");

                let updates = get_aura_updates(&auras).await.expect("getting updates");

                let updated_slugs = write_updates(addon_dir, &updates)
                    .await
                    .expect("writing aura updates");

                dbg!(updated_slugs);
            }
        }
    });
}
