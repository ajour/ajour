use {
    super::{Ajour, AjourState, Interaction, Message, SortDirection, SortKey},
    crate::{
        addon::{Addon, AddonState},
        config::{load_config, Flavor},
        curse_api,
        error::ClientError,
        fs::{delete_addons, install_addon, PersistentData},
        network::download_addon,
        parse::read_addon_directory,
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

            // Use theme from config. Set to "Dark" if not defined.
            ajour.theme_state.current_theme_name =
                ajour.config.theme.as_deref().unwrap_or("Dark").to_string();

            // Begin to parse addon folder.
            let addon_directory = ajour.config.get_addon_directory();
            let flavor = ajour.config.wow.flavor;
            if let Some(dir) = addon_directory {
                return Ok(Command::perform(
                    read_addon_directory(dir, flavor),
                    Message::ParsedAddons,
                ));
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
                let _ = &ajour.config.save();
            }
        }
        Message::Interaction(Interaction::Unignore(id)) => {
            // Update ajour state.
            ajour.ignored_addons.retain(|(a, _)| a.id != id);

            // Update the config.
            ajour.config.addons.ignored.retain(|i| i != &id);

            // Persist the newly updated config.
            let _ = &ajour.config.save();
        }
        Message::Interaction(Interaction::OpenDirectory) => {
            return Ok(Command::perform(open_directory(), Message::UpdateDirectory));
        }
        Message::Interaction(Interaction::OpenLink(link)) => {
            return Ok(Command::perform(
                async {
                    let _ = opener::open(link);
                },
                Message::None,
            ));
        }
        Message::UpdateDirectory(path) => {
            // Clear addons.
            ajour.addons = vec![];

            if path.is_some() {
                // Update the path for World of Warcraft.
                ajour.config.wow.directory = path;
                // Persist the newly updated config.
                let _ = &ajour.config.save();
                // Reload config.
                return Ok(Command::perform(load_config(), Message::Parse));
            }
        }
        Message::FlavorSelected(flavor) => {
            // Update the game flavor
            ajour.config.wow.flavor = flavor;
            // Persist the newly updated config.
            let _ = &ajour.config.save();
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
            if let Some(addon) = ajour.addons.iter().find(|a| a.id == id) {
                let addon_directory = ajour
                    .config
                    .get_addon_directory()
                    .expect("has to have addon directory");
                let _ = delete_addons(
                    &addon_directory,
                    &[&addon.dependencies[..], &[addon.id.clone()]].concat(),
                );

                let flavor = ajour.config.wow.flavor;
                return Ok(Command::perform(
                    read_addon_directory(addon_directory, flavor),
                    Message::ParsedAddons,
                ));
            }
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
            ajour.addons = unfiltred_addons;
            // let mut addons: Vec<Addon> = vec![];

            // // We are filtering out in the addons here.
            // // First we filter so we only have `is_parent`
            // let unfilted_addons_clone = unfiltred_addons.clone();
            // for addon in unfiltred_addons.iter_mut().collect::<Vec<&mut Addon>>() {
            //     // Ensure we have bidirectional dependencies from unfilrted list.
            //     addon.dependencies =
            //         bidirectional_addon_dependencies(addon, &unfilted_addons_clone);

            //     // Checks if a addon with same id already exsist in the Vec<Addon>.
            //     let curse_id_exist = addons.iter().any(|a| {
            //         a.repository_identifiers.curse.is_some()
            //             && a.repository_identifiers.curse == addon.repository_identifiers.curse
            //             && a.id != addon.id
            //     });

            //     let tukui_id_exist = addons.iter().any(|a| {
            //         a.repository_identifiers.tukui.is_some()
            //             && a.repository_identifiers.tukui == addon.repository_identifiers.tukui
            //             && a.id != addon.id
            //     });

            //     let wowi_id_exist = addons.iter().any(|a| {
            //         a.repository_identifiers.wowi.is_some()
            //             && a.repository_identifiers.wowi == addon.repository_identifiers.wowi
            //             && a.id != addon.id
            //     });

            //     // If we have a match, we find the addon.
            //     let target_addon: Option<&mut Addon> = if curse_id_exist {
            //         addons.iter_mut().find(|a| {
            //             a.repository_identifiers.curse == addon.repository_identifiers.curse
            //         })
            //     } else if tukui_id_exist {
            //         addons.iter_mut().find(|a| {
            //             a.repository_identifiers.tukui == addon.repository_identifiers.tukui
            //         })
            //     } else if wowi_id_exist {
            //         addons.iter_mut().find(|a| {
            //             a.repository_identifiers.wowi == addon.repository_identifiers.wowi
            //         })
            //     } else {
            //         None
            //     };

            //     // With the addon we tag the current addon as a bundle.
            //     if let Some(target_addon) = target_addon {
            //         target_addon.dependencies.push(addon.id.clone());
            //         target_addon.is_bundle = true;
            //         continue;
            //     } else {
            //         addons.push(addon.clone());
            //     }
            // }

            // // Lastly we remove non-parents.
            // let addons = addons
            //     .into_iter()
            //     .filter(|a| a.is_parent())
            //     .collect::<Vec<Addon>>();

            // // Once filtred, we set state.
            // ajour.addons = addons;

            // // Sort with state if sorting has been applied by user, otherwise use
            // // default sort.
            // if ajour.sort_state.previous_sort_key.is_some()
            //     && ajour.sort_state.previous_sort_direction.is_some()
            // {
            //     let sort_key = ajour.sort_state.previous_sort_key.unwrap();
            //     let sort_direction = ajour.sort_state.previous_sort_direction.unwrap();

            //     sort_addons(&mut ajour.addons, sort_direction, sort_key);
            // } else {
            //     ajour.addons.sort();
            // }

            // // Create a `Vec` of commands for fetching remote packages for each addon.
            // let mut commands = Vec::<Command<Message>>::new();
            // for addon in &mut ajour.addons {
            //     addon.state = AddonState::Loading;
            //     let addon = addon.to_owned();
            //     if let (Some(_), Some(token)) = (
            //         &addon.repository_identifiers.wowi,
            //         &ajour.config.tokens.wowinterface,
            //     ) {
            //         commands.push(Command::perform(
            //             fetch_wowinterface_packages(
            //                 ajour.shared_client.clone(),
            //                 addon,
            //                 token.to_string(),
            //             ),
            //             Message::WowinterfacePackages,
            //         ))
            //     } else if addon.repository_identifiers.tukui.is_some() {
            //         commands.push(Command::perform(
            //             fetch_tukui_package(
            //                 ajour.shared_client.clone(),
            //                 addon,
            //                 ajour.config.wow.flavor,
            //             ),
            //             Message::TukuiPackage,
            //         ))
            //     } else if addon.repository_identifiers.curse.is_some() {
            //         commands.push(Command::perform(
            //             fetch_curse_package(ajour.shared_client.clone(), addon),
            //             Message::CursePackage,
            //         ))
            //     } else {
            //         let retries = 4;
            //         commands.push(Command::perform(
            //             fetch_curse_packages(ajour.shared_client.clone(), addon, retries),
            //             Message::CursePackages,
            //         ))
            //     }
            // }

            // return Ok(Command::batch(commands));
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
                        let flavor = ajour.config.wow.flavor;
                        return Ok(Command::perform(
                            read_addon_directory(addon.path.clone(), flavor),
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
        Message::NeedsUpdate(Ok(newer_version)) => {
            ajour.needs_update = newer_version;
        }
        Message::Interaction(Interaction::SortColumn(sort_key)) => {
            // First time clicking a column should sort it in Ascending order, otherwise
            // flip the sort direction.
            let mut sort_direction = SortDirection::Asc;

            if let Some(previous_sort_key) = ajour.sort_state.previous_sort_key {
                if sort_key == previous_sort_key {
                    if let Some(previous_sort_direction) = ajour.sort_state.previous_sort_direction
                    {
                        sort_direction = previous_sort_direction.toggle()
                    }
                }
            }

            // Exception would be first time ever sorting and sorting by title.
            // Since its already sorting in Asc by default, we should sort Desc.
            if ajour.sort_state.previous_sort_key.is_none() && sort_key == SortKey::Title {
                sort_direction = SortDirection::Desc;
            }

            sort_addons(&mut ajour.addons, sort_direction, sort_key);

            ajour.sort_state.previous_sort_direction = Some(sort_direction);
            ajour.sort_state.previous_sort_key = Some(sort_key);
        }
        Message::ThemeSelected(theme_name) => {
            ajour.theme_state.current_theme_name = theme_name.clone();

            ajour.config.theme = Some(theme_name);
            let _ = ajour.config.save();
        }
        Message::ThemesLoaded(mut themes) => {
            themes.sort();

            for theme in themes {
                ajour.theme_state.themes.push((theme.name.clone(), theme));
            }
        }
        Message::Error(error)
        | Message::Parse(Err(error))
        | Message::ParsedAddons(Err(error))
        | Message::PartialParsedAddons(Err(error))
        | Message::NeedsUpdate(Err(error)) => {
            ajour.state = AjourState::Error(error);
        }
        Message::None(_) => {}
    }

    Ok(Command::none())
}

/// Function returns a `Vec<String>` which contains all combined dependencies.
///
/// Example:
/// `Foo` - dependencies: [`Bar`, `Baz`]
/// `Bar` - dependencies: [`Foo`]
/// `Baz` - dependencies: [`Foo`]
///
/// If `Baz` is self, we will return [`Foo`, `Bar`, `Baz`]
pub fn bidirectional_addon_dependencies(addon: &mut Addon, addons: &[Addon]) -> Vec<String> {
    let addons = &addons.to_owned();
    let mut dependencies: Vec<String> = Vec::new();

    // Loops dependencies of the target addon.
    for dependency in &addon.dependencies {
        // Find the addon.
        let target_addon = addons.iter().find(|a| &a.id == dependency);
        match target_addon {
            Some(target_addon) => {
                // If target_addon is a parent, and the dependency addon is a parent
                // we skip it.
                if addon.is_parent() && target_addon.is_parent() {
                    continue;
                }

                // Add dependency to dependencies.
                dependencies.push(dependency.clone());
                // Loops the dependencies of the found addon.
                for dependency in &addon.dependencies {
                    dependencies.push(dependency.clone());
                }
            }
            // If we can't find the addon, we will just skip it.
            None => continue,
        };
    }

    dependencies.sort();
    dependencies.dedup();
    dependencies
}

async fn open_directory() -> Option<PathBuf> {
    let dialog = OpenSingleDir { dir: None };
    if let Ok(show) = dialog.show() {
        return show;
    }

    None
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
    flavor: Flavor,
) -> (String, Result<tukui_api::TukuiPackage>) {
    (
        addon.id.clone(),
        tukui_api::fetch_remote_package(
            &shared_client,
            &addon
                .repository_identifiers
                .tukui
                .expect("Expected to have tukui identifier on Addon."),
            &flavor,
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

fn sort_addons(addons: &mut [Addon], sort_direction: SortDirection, sort_key: SortKey) {
    match (sort_key, sort_direction) {
        (SortKey::Title, SortDirection::Asc) => {
            addons.sort();
        }
        (SortKey::Title, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.title
                    .cmp(&b.title)
                    .reverse()
                    .then_with(|| a.remote_version.cmp(&b.remote_version))
            });
        }
        (SortKey::LocalVersion, SortDirection::Asc) => {
            addons.sort_by(|a, b| {
                a.version
                    .cmp(&b.version)
                    .then_with(|| a.title.cmp(&b.title))
            });
        }
        (SortKey::LocalVersion, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.version
                    .cmp(&b.version)
                    .reverse()
                    .then_with(|| a.title.cmp(&b.title))
            });
        }
        (SortKey::RemoteVersion, SortDirection::Asc) => {
            addons.sort_by(|a, b| {
                a.remote_version
                    .cmp(&b.remote_version)
                    .then_with(|| a.cmp(&b))
            });
        }
        (SortKey::RemoteVersion, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.remote_version
                    .cmp(&b.remote_version)
                    .reverse()
                    .then_with(|| a.cmp(&b))
            });
        }
        (SortKey::Status, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.state.cmp(&b.state).then_with(|| a.cmp(&b)));
        }
        (SortKey::Status, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.state.cmp(&b.state).reverse().then_with(|| a.cmp(&b)));
        }
    }
}
