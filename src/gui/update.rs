use {
    super::{Ajour, AjourState, Interaction, Message},
    crate::{
        config::load_config, error::ClientError, fs::{delete_addon, install_addon}, toc::addon::{Addon, AddonState},
        toc::read_addon_directory, Result, wowinterface_api::{fetch_addon_details, download_addon}
    },
    iced::Command,
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
            for addon in &mut ajour.addons {
                if addon.state == AddonState::Updatable {
                    if addon.wowi_id.clone().unwrap() == wowi_id {
                        addon.state = AddonState::Downloading;
                        let addon = addon.clone();

                        return Ok(Command::perform(
                                perform_addon_update(addon),
                                Message::DownloadedAddon,
                        ));
                    }
                }
            }

        }
        Message::Interaction(Interaction::UpdateAll) => {
            // Update all pressed
        }
        Message::ParsedAddons(Ok(addons)) => {
            // When addons has been parsed, we update state.
            // Once that is done, we begin fetching patches for addons.
            ajour.state = AjourState::FetchingDetails;

            let wowi_token = ajour.config.wow_interface_token.clone();
            return Ok(Command::perform(
                get_addon_details(addons, wowi_token),
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
            let addon = ajour.addons.iter_mut().find(|a| a.id == id).expect("Expected addon for id to exsist.");
            match result {
                Ok(_) => {
                    if addon.state == AddonState::Downloading {
                        addon.state = AddonState::Unpacking;
                        let addon = addon.clone();
                        return Ok(Command::perform(unpack_addon(addon), Message::UnpackedAddon));
                    }
                },
                Err(err) => {
                    ajour.state = AjourState::Error(err);
                }

            }
        }
        Message::UnpackedAddon((id, result)) => {
            let addon = ajour.addons.iter_mut().find(|a| a.id == id).expect("Expected addon for id to exsist.");
            match result {
                Ok(_) => {
                    addon.state = AddonState::Ajour(Some("Completed".to_owned()));
                },
                Err(err) => {
                    // TODO: Handle when addon fails to unpack.
                    ajour.state = AjourState::Error(err);
                    addon.state = AddonState::Ajour(Some("Error!".to_owned()));
                }
            }
        }
        Message::Interaction(Interaction::Disabled) => {}
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
async fn get_addon_details(mut addons: Vec<Addon>, wowi_token: String) -> Result<Vec<Addon>> {
    for addon in &mut addons {
        match &addon.wowi_id {
            Some(id) => {
                let details = fetch_addon_details(&id[..], &wowi_token).await?;
                match details.first() {
                    Some(details) => {
                        addon.apply_details(details);
                    }
                    None => continue,
                };
            }
            None => continue,
        }
    }

    // Once the patches has been applied, we return the addons.
    Ok(addons)
}

/// TBA.
async fn perform_addon_update(addon: Addon) -> (String, Result<()>) {
    (addon.id.clone(), download_addon(&addon).await.map(|_| ()))
}

async fn unpack_addon(addon: Addon) -> (String, Result<()>) {
    (addon.id.clone(), install_addon(&addon).await.map(|_| ()))
}
