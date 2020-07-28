use {
    super::{Ajour, AjourState, Interaction, Message},
    crate::{
        config::load_config, error::ClientError, fs::delete_addon, toc::read_addon_directory,
        wowinterface_api::get_addon_details, Result, toc::addon::Addon, config::Config,
    },
    iced::Command,
};

pub fn handle_message(ajour: &mut Ajour, message: Message) -> Result<Command<Message>> {
    let _ = ajour.config;
    match message {
        Message::Load(config) => {
            // When we have the config, we perform an action to read the addon directory
            // which is provided by the config.
            ajour.config = config;
            let addon_directory = ajour.config.get_addon_directory();

            match addon_directory {
                Some(dir) => {
                    return Ok(Command::perform(read_addon_directory(dir), Message::Loaded))
                }
                None => {
                    return Err(ClientError::Custom(
                        "World of Warcraft directory is not set.".to_owned(),
                    ))
                }
            }
        }
        Message::Interaction(Interaction::Refresh) => {
            // Refreshes the state.
            ajour.state = AjourState::Refreshing;
            ajour.addons = Vec::new();
            return Ok(Command::perform(load_config(), Message::Load));
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
                Message::Loaded,
            ));
        }
        Message::Interaction(Interaction::UpdateAll) => {
            println!("Update all pressed.");
        }
        Message::Loaded(Ok(addons)) => {
            ajour.state = AjourState::Idle;
            ajour.addons = addons;
            ajour.addons.sort();

            return Ok(Command::perform(get_all_details(ajour.addons.clone(), ajour.config.clone()), Message::AddonDetails));
        }
        Message::AddonDetails(Ok(addons)) => {
            ajour.addons = addons;
        }
        Message::Interaction(Interaction::Disabled) => {}
        Message::Error(error) | Message::Loaded(Err(error)) | Message::AddonDetails(Err(error)) => {
            println!("error: {:?}", &error);
            ajour.state = AjourState::Error(error);
        }
    }

    Ok(Command::none())
}

async fn get_all_details(mut addons: Vec<Addon>, config: Config) -> Result<Vec<Addon>> {
    for addon in &mut addons {
        if addon.wowi_id.clone().is_some() {
            let addon_patches = get_addon_details(addon.wowi_id.clone().unwrap(), config.clone()).await?;
            let patch = addon_patches.first().unwrap();
            addon.apply_patch(patch);
        }
    }

    Ok(addons)
}
