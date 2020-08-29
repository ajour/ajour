use {
    super::{Ajour, AjourState, Interaction, Message},
    crate::{
        addon::{Addon, AddonState},
        config::{load_config, persist_config},
        curse_api,
        error::ClientError,
        fs::{delete_addons, install_addon},
        network::download_addon,
        toc::read_addon_directory,
        tukui_api, wowinterface_api, Result,
    },
    async_std::sync::Arc,
    iced::{button, Command},
    isahc::HttpClient,
    native_dialog::*,
    std::path::PathBuf,
};

pub fn handle_message(ajour: &mut Ajour, message: Message) -> Result<Command<Message>> {
    match message {
        Message::Parse(Ok(config)) => {
            // When we have the config, we parse the addon directory
            // which is provided by the config.
            ajour.config = config;
            // Reset state
            ajour.state = AjourState::Idle;

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
                        "Please open settings to set a path for World of Warcraft.".to_owned(),
                    ))
                }
            }
        }
        Message::Interaction(Interaction::Refresh) => {
            // Re-parse addons.
            ajour.addons = Vec::new();
            return Ok(Command::perform(load_config(), Message::Parse));
        }
        Message::Interaction(Interaction::Settings) => {
            // Toggle state.
            ajour.is_showing_settings = !ajour.is_showing_settings;

            // Prepare ignore_addons data.
            // We need to find the corresponding addons, and then save it to
            // the ajour state, with a new button::State attatched.
            if ajour.is_showing_settings {
                let ignored_strings = &ajour.config.addons.ignored;
                ajour.ignored_addons = ajour
                    .addons
                    .iter()
                    .filter(|a| ignored_strings.iter().any(|i| i == &a.id))
                    .map(|a| (a.clone(), button::State::new()))
                    .collect::<Vec<(Addon, button::State)>>();
            } else {
                ajour.ignored_addons = vec![];
            }
        }
        Message::Interaction(Interaction::Ignore(id)) => {
            let addon = ajour.addons.iter().find(|a| a.id == id);
            if let Some(addon) = addon {
                // Update ajour state
                ajour
                    .ignored_addons
                    .push((addon.clone(), button::State::new()));

                // Update the config.
                ajour.config.addons.ignored.push(addon.id.clone());

                // Persist the newly updated config.
                let _ = persist_config(&ajour.config);
            }
        }
        Message::Interaction(Interaction::Unignore(id)) => {
            // Update ajour state.
            ajour.ignored_addons.retain(|(a, _)| a.id != id);

            // Update the config.
            ajour.config.addons.ignored.retain(|i| i != &id);

            // Persist the newly updated config.
            let _ = persist_config(&ajour.config);
        }
        Message::Interaction(Interaction::OpenDirectory) => {
            return Ok(Command::perform(open_directory(), Message::UpdateDirectory));
        }
        Message::UpdateDirectory(path) => {
            if path.is_some() {
                // Update the path for World of Warcraft.
                ajour.config.wow.directory = path;
                // Persist the newly updated config.
                let _ = persist_config(&ajour.config);
                // Reload config.
                return Ok(Command::perform(load_config(), Message::Parse));
            }
        }
        Message::FlavorSelected(flavor) => {
            // Update the game flavor
            ajour.config.wow.flavor = flavor;
            // Persist the newly updated config.
            let _ = persist_config(&ajour.config);
            // Reload config.
            return Ok(Command::perform(load_config(), Message::Parse));
        }
        Message::Interaction(Interaction::Expand(id)) => {
            // Expand a addon.
            // If it's already expanded, we collapse it again.
            if let Some(addon) = ajour.addons.iter().find(|a| a.id == id) {
                if let Some(is_addon_expanded) =
                    &ajour.expanded_addon.as_ref().map(|a| a.id == addon.id)
                {
                    if *is_addon_expanded {
                        ajour.expanded_addon = None;
                        return Ok(Command::none());
                    }
                }

                ajour.expanded_addon = Some(addon.clone());
            }
        }
        Message::Interaction(Interaction::Delete(id)) => {
            // Delete addon, and it's dependencies.
            let addons = &ajour.addons.clone();
            let addon = addons.iter().find(|a| a.id == id).unwrap();
            let combined_dependencies = addon.combined_dependencies(addons);
            let addon_directory = ajour
                .config
                .get_addon_directory()
                .expect("has to have addon directory");
            let _ = delete_addons(&addon_directory, &combined_dependencies);

            return Ok(Command::perform(
                read_addon_directory(addon_directory),
                Message::ParsedAddons,
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
                        perform_download_addon(
                            ajour.shared_client.clone(),
                            addon.clone(),
                            to_directory,
                        ),
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
                    if let Some(to_directory) = ajour.config.get_temporary_addon_directory() {
                        addon.state = AddonState::Downloading;
                        let addon = addon.clone();
                        commands.push(Command::perform(
                            perform_download_addon(
                                ajour.shared_client.clone(),
                                addon,
                                to_directory,
                            ),
                            Message::DownloadedAddon,
                        ))
                    }
                }
            }
            return Ok(Command::batch(commands));
        }
        Message::PartialParsedAddons(Ok(addons)) => {
            if let Some(updated_addon) = addons.first() {
                if let Some(addon) = ajour.addons.iter_mut().find(|a| a.id == updated_addon.id) {
                    // Update the addon with the newly parsed information.
                    addon.update_addon(updated_addon);
                }
            }
        }
        Message::ParsedAddons(Ok(unfiltred_addons)) => {
            let mut addons: Vec<Addon> = vec![];

            // We are filtering out in the addons here.
            // First we filter so we only have `is_parent`
            //
            // TODO: This could easily be optimized, however the logic is working for now.
            for addon in unfiltred_addons
                .into_iter()
                .filter(|a| a.is_parent())
                .collect::<Vec<Addon>>()
            {
                // Check if we have curse id.
                if let Some(id) = &addon.repository_identifiers.curse {
                    // We check if another addon has already been added with the same id.
                    let is_added = addons
                        .iter()
                        .any(|a| a.repository_identifiers.curse == Some(*id) && a.id != addon.id);

                    // If another addon is already added, we find that addon and mark it as
                    // `is_bundle`. Else we add it to the array.
                    if is_added {
                        let addon = addons
                            .iter_mut()
                            .find(|a| a.repository_identifiers.curse == Some(*id));
                        if let Some(addon) = addon {
                            addon.is_bundle = true;
                            continue;
                        }
                    } else {
                        addons.push(addon);
                        continue;
                    }
                }

                // Check if we have tukui id.
                if let Some(id) = &addon.repository_identifiers.tukui {
                    // We check if another addon has already been added with the same id.
                    let is_added = addons.iter().any(|a| {
                        a.repository_identifiers.tukui == Some(id.clone()) && a.id != addon.id
                    });

                    // If another addon is already added, we find that addon and mark it as
                    // `is_bundle`. Else we add it to the array.
                    if is_added {
                        let addon = addons
                            .iter_mut()
                            .find(|a| a.repository_identifiers.tukui == Some(id.clone()));
                        if let Some(addon) = addon {
                            addon.is_bundle = true;
                            continue;
                        }
                    } else {
                        addons.push(addon);
                        continue;
                    }
                }

                // Check if we have wowi id.
                if let Some(id) = &addon.repository_identifiers.wowi {
                    // We check if another addon has already been added with the same id.
                    let is_added = addons.iter().any(|a| {
                        a.repository_identifiers.wowi == Some(id.clone()) && a.id != addon.id
                    });

                    // If another addon is already added, we find that addon and mark it as
                    // `is_bundle`. Else we add it to the array.
                    if is_added {
                        let addon = addons
                            .iter_mut()
                            .find(|a| a.repository_identifiers.wowi == Some(id.clone()));
                        if let Some(addon) = addon {
                            addon.is_bundle = true;
                            continue;
                        }
                    } else {
                        addons.push(addon);
                        continue;
                    }
                }

                // If we have no id's for any repository, we have to add it anyway.
                addons.push(addon);
            }

            // Once filtred, we set state.
            ajour.addons = addons;
            ajour.addons.sort();

            // Create a `Vec` of commands for fetching remote packages for each addon.
            let mut commands = Vec::<Command<Message>>::new();
            for addon in &mut ajour.addons {
                addon.state = AddonState::Loading;
                let addon = addon.to_owned();
                if let (Some(_), Some(token)) = (
                    &addon.repository_identifiers.wowi,
                    &ajour.config.tokens.wowinterface,
                ) {
                    commands.push(Command::perform(
                        fetch_wowinterface_packages(
                            ajour.shared_client.clone(),
                            addon,
                            token.to_string(),
                        ),
                        Message::WowinterfacePackages,
                    ))
                } else if addon.repository_identifiers.tukui.is_some() {
                    commands.push(Command::perform(
                        fetch_tukui_package(ajour.shared_client.clone(), addon),
                        Message::TukuiPackage,
                    ))
                } else if addon.repository_identifiers.curse.is_some() {
                    commands.push(Command::perform(
                        fetch_curse_package(ajour.shared_client.clone(), addon),
                        Message::CursePackage,
                    ))
                } else {
                    let retries = 4;
                    commands.push(Command::perform(
                        fetch_curse_packages(ajour.shared_client.clone(), addon, retries),
                        Message::CursePackages,
                    ))
                }
            }

            return Ok(Command::batch(commands));
        }
        Message::CursePackage((id, result)) => {
            if let Some(addon) = ajour.addons.iter_mut().find(|a| a.id == id) {
                addon.state = AddonState::Ajour(None);
                if let Ok(package) = result {
                    addon.apply_curse_package(&package, &ajour.config.wow.flavor);
                }
            }
        }
        Message::CursePackages((id, retries, result)) => {
            if let Some(addon) = ajour.addons.iter_mut().find(|a| a.id == id) {
                addon.state = AddonState::Ajour(None);
                if let Ok(packages) = result {
                    addon.apply_curse_packages(&packages, &ajour.config.wow.flavor);
                } else {
                    // FIXME: This could be improved quite a lot.
                    // Idea is that Curse API returns `NetworkError(CouldntResolveHost)` quite often,
                    // if called to quickly. So i've implemented a very basic retry functionallity
                    // which solves the problem for now.
                    let error = result.err().unwrap();
                    if matches!(
                        error,
                        ClientError::NetworkError(isahc::Error::CouldntResolveHost)
                    ) && retries > 0
                    {
                        return Ok(Command::perform(
                            fetch_curse_packages(
                                ajour.shared_client.clone(),
                                addon.clone(),
                                retries,
                            ),
                            Message::CursePackages,
                        ));
                    }
                }
            }
        }
        Message::TukuiPackage((id, result)) => {
            if let Some(addon) = ajour.addons.iter_mut().find(|a| a.id == id) {
                addon.state = AddonState::Ajour(None);
                if let Ok(package) = result {
                    addon.apply_tukui_package(&package);
                }
            }
        }
        Message::WowinterfacePackages((id, result)) => {
            if let Some(addon) = ajour.addons.iter_mut().find(|a| a.id == id) {
                addon.state = AddonState::Ajour(None);
                if let Ok(packages) = result {
                    addon.apply_wowi_packages(&packages);
                }
            }
        }
        Message::DownloadedAddon((id, result)) => {
            // When an addon has been successfully downloaded we begin to unpack it.
            // If it for some reason fails to download, we handle the error.
            let from_directory = ajour
                .config
                .get_temporary_addon_directory()
                .expect("Expected a valid path");
            let to_directory = ajour
                .config
                .get_addon_directory()
                .expect("Expected a valid path");
            if let Some(addon) = ajour.addons.iter_mut().find(|a| a.id == id) {
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
        }
        Message::UnpackedAddon((id, result)) => {
            if let Some(addon) = ajour.addons.iter_mut().find(|a| a.id == id) {
                match result {
                    Ok(_) => {
                        addon.state = AddonState::Ajour(Some("Completed".to_owned()));
                        // Re-parse the single addon.
                        return Ok(Command::perform(
                            read_addon_directory(addon.path.clone()),
                            Message::PartialParsedAddons,
                        ));
                    }
                    Err(err) => {
                        ajour.state = AjourState::Error(err);
                        addon.state = AddonState::Ajour(Some("Error".to_owned()));
                    }
                }
            }
        }
        Message::Error(error)
        | Message::Parse(Err(error))
        | Message::ParsedAddons(Err(error))
        | Message::PartialParsedAddons(Err(error)) => {
            ajour.state = AjourState::Error(error);
        }
    }

    Ok(Command::none())
}

async fn open_directory() -> Option<PathBuf> {
    // Should we use task::spawn_blocking here?
    // TODO: We should maybe make sure we can't spawn multiple windows here.
    let dialog = OpenSingleDir { dir: None };
    dialog.show().unwrap()
}

async fn fetch_curse_package(
    shared_client: Arc<HttpClient>,
    addon: Addon,
) -> (String, Result<curse_api::Package>) {
    (
        addon.id.clone(),
        curse_api::fetch_remote_package(
            &shared_client,
            &addon
                .repository_identifiers
                .curse
                .expect("Expected to have curse identifier on Addon."),
        )
        .await,
    )
}

async fn fetch_curse_packages(
    shared_client: Arc<HttpClient>,
    addon: Addon,
    retries: u32,
) -> (String, u32, Result<Vec<curse_api::Package>>) {
    (
        addon.id.clone(),
        retries - 1,
        curse_api::fetch_remote_packages(&shared_client, &addon.title).await,
    )
}

async fn fetch_tukui_package(
    shared_client: Arc<HttpClient>,
    addon: Addon,
) -> (String, Result<tukui_api::Package>) {
    (
        addon.id.clone(),
        tukui_api::fetch_remote_package(
            &shared_client,
            &addon
                .repository_identifiers
                .tukui
                .expect("Expected to have tukui identifier on Addon."),
        )
        .await,
    )
}

async fn fetch_wowinterface_packages(
    shared_client: Arc<HttpClient>,
    addon: Addon,
    token: String,
) -> (String, Result<Vec<wowinterface_api::Package>>) {
    (
        addon.id.clone(),
        wowinterface_api::fetch_remote_packages(
            &shared_client,
            &addon
                .repository_identifiers
                .wowi
                .expect("Expected to have wowinterface identifier on Addon."),
            &token,
        )
        .await,
    )
}

/// Downloads the newest version of the addon.
/// This is for now only downloading from warcraftinterface.
async fn perform_download_addon(
    shared_client: Arc<HttpClient>,
    addon: Addon,
    to_directory: PathBuf,
) -> (String, Result<()>) {
    (
        addon.id.clone(),
        download_addon(&shared_client, &addon, &to_directory)
            .await
            .map(|_| ()),
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
