use ajour_core::config::{load_config, Flavor};
use ajour_weak_auras::{get_aura_updates, parse_auras, write_updates};

use async_std::task;
use color_eyre::eyre::{bail, eyre, Result, WrapErr};

pub fn update_all_weakauras() -> Result<()> {
    log::info!("Checking for WeakAura updates...");

    task::block_on(async {
        let config = load_config().await?;

        let mut flavors_setup = 0usize;

        for flavor in &Flavor::ALL[..] {
            if let Some(account) = config.weak_auras_account.get(flavor).cloned() {
                flavors_setup += 1;

                log::info!("{} - Parsing WeakAuras for account {}", flavor, &account);

                let wtf_path = config.get_wtf_directory_for_flavor(flavor).ok_or_else(|| eyre!("No WoW directory set. Launch Ajour and make sure a WoW directory is set before using the command line."))?;
                let addon_dir = config.get_addon_directory_for_flavor(flavor).ok_or_else(|| eyre!("No WoW directory set. Launch Ajour and make sure a WoW directory is set before using the command line."))?;

                let auras = parse_auras(wtf_path, account.clone())
                    .await
                    .wrap_err(format!(
                        "{} - Failed to parse WeakAuras for account {}",
                        flavor, &account
                    ))?;

                if auras.is_empty() {
                    log::info!("{} - No auras installed", flavor);
                    continue;
                } else {
                    log::info!("{} - {} auras installed", flavor, auras.len());
                }

                let updates = get_aura_updates(&auras).await.wrap_err(format!(
                    "{} - Failed to fetch updates for account {}",
                    flavor, &account
                ))?;

                if updates.is_empty() {
                    log::info!("{} - No updates available", flavor);
                    continue;
                } else {
                    log::info!("{} - {} updates available", flavor, updates.len());
                }

                let updated_slugs = write_updates(addon_dir, &updates).await.wrap_err(format!(
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
                            "{} - \t{} - {} -> {}",
                            flavor,
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
                "No accounts have been specified for WeakAuras. Launch Ajour and make sure to specify an account for each flavor you want WeakAuras updates for."
            );
        }

        Ok(())
    })
}
