use {
    super::{Ajour, AjourState, Interaction, Message},
    crate::{
        addon::{Addon, AddonState},
        config::load_config,
        curse_api,
        error::ClientError,
        fs::{delete_addon, install_addon},
        network::download_addon,
        toc::read_addon_directory,
        tukui_api, wowinterface_api, Result,
    },
    iced::Command,
    rayon::prelude::*,
    std::path::PathBuf,
};

pub fn handle_message(ajour: &mut Ajour, message: Message) -> Result<Command<Message>> {
    match message {
        Message::Parse(config) => {
            // When we have the config, we parse the addon directory
            // which is provided by the config.
            ajour.config = config;
            let addon_directory = ajour.config.get_addon_directory();

            match addon_directory {
                Some(dir) => {
                    return Ok(Command::perform(
                        read_addon_directory(dir),
                        Message::PatchAddons,
                    ))
                }
                None => {
                    return Err(ClientError::Custom(
                        "World of Warcraft directory is not set.".to_owned(),
                    ))
                }
            }
        }
        Message::Interaction(Interaction::Refresh) => {
            // Re-parse addons.
            ajour.state = AjourState::Loading;
            ajour.addons = Vec::new();
            return Ok(Command::perform(load_config(), Message::Parse));
        }
        Message::Interaction(Interaction::Delete(id)) => {
            // Delete addon, and it's dependencies.
            // TODO: maybe just rewrite and assume it goes well and remove addon.
            let addons = &ajour.addons.clone();
            let target_addon = addons.iter().find(|a| a.id == id).unwrap();
            let combined_dependencies = target_addon.combined_dependencies(addons);
            let addons_to_be_deleted = addons
                .iter()
                .filter(|a| combined_dependencies.contains(&a.id))
                .collect::<Vec<_>>();

            // Loops the addons marked for deletion and remove them one by one.
            for addon in addons_to_be_deleted {
                let _ = delete_addon(addon);
            }
            // Refreshes the GUI by re-parsing the addon directory.
            // TODO: This can be done prettier.
            let addon_directory = ajour.config.get_addon_directory().unwrap();
            return Ok(Command::perform(
                read_addon_directory(addon_directory),
                Message::PatchAddons,
            ));
        }
        Message::Interaction(Interaction::Update(id)) => {
            let to_directory = ajour
                .config
                .get_temporary_addon_directory()
                .expect("Expected a valid path");
            for addon in &mut ajour.addons {
                if addon.id == id {
                    addon.state = AddonState::Downloading;
                    return Ok(Command::perform(
                        perform_download_addon(addon.clone(), to_directory),
                        Message::DownloadedAddon,
                    ));
                }
            }
        }
        Message::Interaction(Interaction::UpdateAll) => {
            // Update all pressed
            let mut commands = Vec::<Command<Message>>::new();
            for addon in &mut ajour.addons {
                if addon.state == AddonState::Updatable {
                    let to_directory = ajour
                        .config
                        .get_temporary_addon_directory()
                        .expect("Expected a valid path");
                    addon.state = AddonState::Downloading;
                    let addon = addon.clone();
                    commands.push(Command::perform(
                        perform_download_addon(addon, to_directory),
                        Message::DownloadedAddon,
                    ))
                }
            }
            return Ok(Command::batch(commands));
        }
        Message::PatchAddons(Ok(addons)) => {
            // Fetch packages for addons from the differen repositories.
            let tokens = ajour.config.tokens.clone();
            let flavor = ajour.config.wow.flavor.clone();
            let num_threads = ajour.config.num_threads;
            let pool = rayon::ThreadPoolBuilder::new()
                .num_threads(num_threads)
                .build()
                .unwrap();
            ajour.addons = addons;
            pool.scope(|_| {
                ajour.addons.par_iter_mut().for_each(|addon| {
                    if let (Some(wowi_id), Some(wowi_token)) =
                        (&addon.wowi_id, &tokens.wowinterface)
                    {
                        let packages =
                            wowinterface_api::fetch_remote_packages(&wowi_id[..], &wowi_token);
                        if let Ok(packages) = packages {
                            addon.apply_wowi_packages(&packages);
                        }
                    } else if let Some(curse_id) = &addon.curse_id {
                        let package = curse_api::fetch_remote_package(&curse_id);
                        if let Ok(package) = package {
                            addon.apply_curse_package(&package, &flavor);
                        };
                    } else if let Some(tukui_id) = &addon.tukui_id {
                        let package = tukui_api::fetch_remote_package(&tukui_id[..]);
                        if let Ok(package) = package {
                            addon.apply_tukui_package(&package);
                        }
                    }
                });
            });
            ajour.addons.sort();
            ajour.state = AjourState::Idle;
        }
        Message::DownloadedAddon((id, result)) => {
            // When an addon has been successfully downloaded we begin to
            // unpack it.
            // If it for some reason fails to download, we handle the error.
            let from_directory = ajour
                .config
                .get_temporary_addon_directory()
                .expect("Expected a valid path");
            let to_directory = ajour
                .config
                .get_addon_directory()
                .expect("Expected a valid path");
            let addon = ajour
                .addons
                .iter_mut()
                .find(|a| a.id == id)
                .expect("Expected addon for id to exist.");
            match result {
                Ok(_) => {
                    if addon.state == AddonState::Downloading {
                        addon.state = AddonState::Unpacking;
                        let addon = addon.clone();
                        return Ok(Command::perform(
                            perform_unpack_addon(addon, from_directory, to_directory),
                            Message::UnpackedAddon,
                        ));
                    }
                }
                Err(err) => {
                    ajour.state = AjourState::Error(err);
                }
            }
        }
        Message::UnpackedAddon((id, result)) => {
            let addon = ajour
                .addons
                .iter_mut()
                .find(|a| a.id == id)
                .expect("Expected addon for id to exist.");
            match result {
                Ok(_) => {
                    addon.state = AddonState::Ajour(Some("Completed".to_owned()));
                    addon.version = addon.remote_version.clone();
                }
                Err(err) => {
                    // TODO: Handle when addon fails to unpack.
                    ajour.state = AjourState::Error(err);
                    addon.state = AddonState::Ajour(Some("Error!".to_owned()));
                }
            }
        }
        Message::Error(error) | Message::PatchAddons(Err(error)) => {
            ajour.state = AjourState::Error(error);
        }
    }

    Ok(Command::none())
}

/// Downloads the newest version of the addon.
/// This is for now only downloading from warcraftinterface.
async fn perform_download_addon(addon: Addon, to_directory: PathBuf) -> (String, Result<()>) {
    (
        addon.id.clone(),
        download_addon(&addon, &to_directory).await.map(|_| ()),
    )
}

/// Unzips `Addon` at given `from_directory` and moves it `to_directory`.
async fn perform_unpack_addon(
    addon: Addon,
    from_directory: PathBuf,
    to_directory: PathBuf,
) -> (String, Result<()>) {
    (
        addon.id.clone(),
        install_addon(&addon, &from_directory, &to_directory)
            .await
            .map(|_| ()),
    )
}
