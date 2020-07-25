use {
    super::{Ajour, AjourState, Interaction, Message},
    crate::{
        config::load_config, error::ClientError, fs::delete_addon,
        toc::read_addon_directory, Result,
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
            let addon = &ajour.addons.clone().into_iter().find(|a| a.id == id).unwrap();
            let dependency_paths = addon.dependency_paths(&ajour.addons);
            for dependency in dependency_paths {
                let _ = delete_addon(dependency);
            }

            let addon_directory = ajour.config.get_addon_directory().unwrap();
            return Ok(Command::perform(read_addon_directory(addon_directory), Message::Loaded))
        }
        Message::Interaction(Interaction::UpdateAll) => {
            println!("Update all pressed.");
        }
        Message::Loaded(Ok(addons)) => {
            ajour.state = AjourState::Idle;
            ajour.addons = addons;
            return Ok(Command::none());
        }
        Message::Error(error) | Message::Loaded(Err(error)) => {
            println!("error: {:?}", &error);
            ajour.state = AjourState::Error(error);
        }
    }

    Ok(Command::none())
}
