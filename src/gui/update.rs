use {
    super::{Ajour, AjourState, Interaction, Message},
    crate::{
        config::{load_config, Tokens},
        error::ClientError,
        fs::{delete_addon, install_addon},
        toc::{read_addon_directory, Addon, AddonState, AddonDetails},
        wowinterface_api, tukui_api, Result,
    },
    iced::Command,
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
                        Message::ParsedAddons,
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
            ajour.state = AjourState::Parsing;
            ajour.addons = Vec::new();
            return Ok(Command::perform(load_config(), Message::Parse));
        }
        Message::Interaction(Interaction::Delete(id)) => {
            // Delete addon, and it's dependencies.
            let addons = &ajour.addons.clone();
            let target_addon = addons.into_iter().find(|a| a.id == id).unwrap();
            let combined_dependencies = target_addon.combined_dependencies(addons);
            let addons_to_be_deleted = addons
                .into_iter()
                .filter(|a| combined_dependencies.contains(&a.id))
                .collect::<Vec<_>>();

            // Loops the addons marked for deletion and remove them one by one.
            for addon in addons_to_be_deleted {
                let _ = delete_addon(addon);
            }
            // Refreshes the GUI by reparsing the addon directory.
            let addon_directory = ajour.config.get_addon_directory().unwrap();
            return Ok(Command::perform(
                read_addon_directory(addon_directory),
                Message::ParsedAddons,
            ));
        }
        Message::Interaction(Interaction::Update(wowi_id)) => {
            let to_directory = ajour
                .config
                .get_temporary_addon_directory()
                .expect("Expected a valid path");
            for addon in &mut ajour.addons {
                if addon.state == AddonState::Updatable {
                    if addon.wowi_id.clone().unwrap() == wowi_id {
                        addon.state = AddonState::Downloading;
                        let addon = addon.clone();

                        return Ok(Command::perform(
                            download_addon(addon, to_directory),
                            Message::DownloadedAddon,
                        ));
                    }
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
                        download_addon(addon, to_directory),
                        Message::DownloadedAddon,
                    ))
                }
            }
            return Ok(Command::batch(commands));
        }
        Message::ParsedAddons(Ok(addons)) => {
            // When addons has been parsed, we update state.
            // Once that is done, we begin fetching patches for addons.
            ajour.state = AjourState::FetchingDetails;

            let tokens = ajour.config.tokens.clone();
            return Ok(Command::perform(
                    get_addon_details(addons, tokens),
                    Message::PatchedAddons,
            ));
        }
        Message::PatchedAddons(Ok(addons)) => {
            // When addons has been patched, we update state.
            ajour.state = AjourState::Idle;
            ajour.addons = addons;
            ajour.addons.sort();
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
                .expect("Expected addon for id to exsist.");
            match result {
                Ok(_) => {
                    if addon.state == AddonState::Downloading {
                        addon.state = AddonState::Unpacking;
                        let addon = addon.clone();
                        return Ok(Command::perform(
                            unpack_addon(addon, from_directory, to_directory),
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
                .expect("Expected addon for id to exsist.");
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
        Message::Error(error)
        | Message::ParsedAddons(Err(error))
        | Message::PatchedAddons(Err(error)) => {
            ajour.state = AjourState::Error(error);
        }
    }

    Ok(Command::none())
}

/// Function to fetch remote data (patches) from the different repositories:
/// - Warcraftinterface
/// - TukUI
async fn get_addon_details(mut addons: Vec<Addon>, tokens: Tokens) -> Result<Vec<Addon>> {
    for addon in &mut addons {
        // Wowinterface.
        // match (&addon.wowi_id, &tokens.wowinterface) {
        //     (Some(wowi_id), Some(wowi_token)) => {
        //         let all_details =
        //             wowinterface_api::fetch_addon_details(&wowi_id[..], &wowi_token).await?;
        //         let details = all_details.iter().find(|a| &a.id == wowi_id);
        //         match details {
        //             Some(details) => {
        //                 addon.apply_details(details);
        //             }
        //             _ => (),
        //         };
        //     }
        //     _ => (),
        // }

        // TukUI.
        match &addon.tukui_id {
            Some(tukui_id) => {
                let details = tukui_api::fetch_addon_details(&tukui_id[..]).await?;
                println!("details: {:?}", details);
            }
            _ => (),
        }
    }

    // Once the patches has been applied, we return the addons.
    Ok(addons)
}

/// Downloads the newest version of the addon.
/// This is for now only downloading from warcraftinterface.
async fn download_addon(addon: Addon, to_directory: PathBuf) -> (String, Result<()>) {
    (
        addon.id.clone(),
        wowinterface_api::download_addon(&addon, &to_directory)
            .await
            .map(|_| ()),
    )
}

/// Unzips `Addon` at given `from_directory` and moves it `to_directory`.
async fn unpack_addon(
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
