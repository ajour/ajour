use crate::Result;

use ajour_core::config::load_config;
use ajour_weak_auras::{get_aura_updates, parse_auras, write_updates};

use anyhow::{bail, Context};
use async_std::task;

pub fn update_all_auras() -> Result<()> {
    log::info!("Checking for WeakAura and Plater updates...");

    task::block_on(async {
        let config = load_config().await?;

        let mut flavors_setup = 0usize;

        let flavors = config.wow.directories.keys().collect::<Vec<_>>();
        for flavor in flavors {
            if let Some(account) = config.weak_auras_account.get(flavor).cloned() {
                flavors_setup += 1;

                log::info!(
                    "{} - Parsing WeakAura and Plater for account {}",
                    flavor,
                    &account
                );

                let wtf_path = match config.get_wtf_directory_for_flavor(flavor) {
                    Some(path) => path,
                    None => continue,
                };
                let addon_dir = match config.get_addon_directory_for_flavor(flavor) {
                    Some(path) => path,
                    None => continue,
                };

                let auras = parse_auras(wtf_path, account.clone())
                    .await
                    .context(format!(
                        "{} - Failed to parse WeakAuras for account {}",
                        flavor, &account
                    ))?;

                if auras.is_empty() {
                    log::info!("{} - No auras installed", flavor);
                    continue;
                } else {
                    log::info!("{} - {} auras installed", flavor, auras.len());
                }

                let updates = get_aura_updates(&auras).await.context(format!(
                    "{} - Failed to fetch updates for account {}",
                    flavor, &account
                ))?;

                if updates.is_empty() {
                    log::info!("{} - No updates available", flavor);
                    continue;
                } else {
                    log::info!("{} - {} updates available", flavor, updates.len());
                }

                let updated_slugs = write_updates(addon_dir, &updates).await.context(format!(
                    "{} - Failed to queue updates for account {}",
                    flavor, &account
                ))?;

                log::info!(
                    "{} - The following auras were successfully queued for update:",
                    flavor
                );

                for slug in updated_slugs.iter() {
                    if let Some(aura) = auras.iter().find(|a| a.slug() == slug) {
                        log::info!(
                            "{} - \t({}) {} ({} -> {})",
                            flavor,
                            aura.kind(),
                            aura.name(),
                            aura.installed_symver().unwrap_or_default(),
                            aura.remote_symver()
                        );
                    }
                }
            }
        }

        if flavors_setup == 0 {
            bail!(
                "No accounts have been specified for WeakAura and Plater. Launch Ajour and make sure to specify an account for each flavor you want updates for."
            );
        }

        Ok(())
    })
}
