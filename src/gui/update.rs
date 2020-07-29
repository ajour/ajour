use {
    super::{Ajour, AjourState, Interaction, Message},
    crate::{
        config::load_config, error::ClientError, fs::delete_addon,
        toc::addon::Addon, toc::read_addon_directory, wowinterface_api::get_addon_details, Result,
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
        Message::Interaction(Interaction::UpdateAll) => {
            println!("Update all pressed.");
        }
        Message::ParsedAddons(Ok(addons)) => {
            // When addons has been parsed, we update state.
            // Once that is done, we begin fetching patches for addons.
            ajour.state = AjourState::FetchingDetails;
            // ajour.addons = addons;
            // ajour.addons.sort();

            let wowi_token = ajour.config.wow_interface_token.clone();
            return Ok(Command::perform(
                apply_addon_details(addons, wowi_token),
                Message::PatchedAddons,
            ));
        }
        Message::PatchedAddons(Ok(addons)) => {
            // When addons has been patched, we update state.
            ajour.state = AjourState::Idle;
            ajour.addons = addons;
            ajour.addons.sort();
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
async fn apply_addon_details(mut addons: Vec<Addon>, wowi_token: String) -> Result<Vec<Addon>> {
    for addon in &mut addons {
        match &addon.wowi_id {
            Some(id) => {
                let details = get_addon_details(&id[..], &wowi_token).await?;
                match details.first() {
                    Some(details) => {
                        addon.apply_details(details);
                    }
                    None =>  continue ,
                };
            }
            None => continue,
        }
    }

    // Once the patches has been applied, we return the addons.
    Ok(addons)
}
