use {
    super::{Ajour, AjourState, Interaction, Message, SortDirection, SortKey},
    crate::{
        addon::{Addon, AddonState},
        config::{load_config, Flavor},
        fs::{delete_addons, install_addon, PersistentData},
        network::download_addon,
        parse::{read_addon_directory, update_addon_fingerprint, FingerprintCollection},
        theme::load_user_themes,
        utility::needs_update,
        Result,
    },
    async_std::sync::{Arc, Mutex},
    iced::{button, Command},
    isahc::HttpClient,
    native_dialog::*,
    std::collections::HashMap,
    std::path::{Path, PathBuf},
};

pub fn handle_message(ajour: &mut Ajour, message: Message) -> Result<Command<Message>> {
    match message {
        Message::ConfigDirExists(_) => {
            let commands = vec![
                Command::perform(load_config(), Message::Parse),
                Command::perform(needs_update(), Message::NeedsUpdate),
                Command::perform(load_user_themes(), Message::ThemesLoaded),
            ];

            return Ok(Command::batch(commands));
        }
        Message::Parse(Ok(config)) => {
            log::debug!("Message::Parse");

            // When we have the config, we parse the addon directory
            // which is provided by the config.
            ajour.config = config;

            // Use theme from config. Set to "Dark" if not defined.
            ajour.theme_state.current_theme_name =
                ajour.config.theme.as_deref().unwrap_or("Dark").to_string();

            // Begin to parse addon folder(s).
            let mut commands = vec![];
            let flavors = &Flavor::ALL[..];
            for flavor in flavors {
                if let Some(addon_directory) = ajour.config.get_addon_directory_for_flavor(flavor) {
                    commands.push(Command::perform(
                        perform_read_addon_directory(
                            ajour.fingerprint_collection.clone(),
                            addon_directory.clone(),
                            *flavor,
                        ),
                        Message::ParsedAddons,
                    ));
                } else {
                    // Assume we are welcoming a user because directory is not set.
                    ajour.state = AjourState::Welcome;
                    break;
                }
            }
            return Ok(Command::batch(commands));
        }
        Message::Interaction(Interaction::Refresh) => {
            log::debug!("Interaction::Refresh");

            // Close settings if shown.
            ajour.is_showing_settings = false;

            // Cleans the addons.
            ajour.addons = HashMap::new();

            // Prepare state for loading.
            ajour.state = AjourState::Loading;

            return Ok(Command::perform(load_config(), Message::Parse));
        }
        Message::Interaction(Interaction::Settings) => {
            log::debug!("Interaction::Settings");

            ajour.is_showing_settings = !ajour.is_showing_settings;
        }
        Message::Interaction(Interaction::Ignore(id)) => {
            log::debug!("Interaction::Ignore({})", &id);

            // Close settings if shown.
            ajour.is_showing_settings = false;

            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();
            let addon = addons.iter().find(|a| a.id == id);

            if let Some(addon) = addon {
                // Push addon to ignored addons.
                let ignored_addon = (addon.clone(), button::State::new());
                let ignored_addons = ajour.ignored_addons.entry(flavor).or_default();
                ignored_addons.push(ignored_addon);

                // Remove the expanded addon.
                ajour.expanded_addon = None;

                // Update the config.
                ajour
                    .config
                    .addons
                    .ignored
                    .entry(flavor)
                    .or_default()
                    .push(addon.id.clone());

                // Persist the newly updated config.
                let _ = &ajour.config.save();
            }
        }
        Message::Interaction(Interaction::Unignore(id)) => {
            log::debug!("Interaction::Unignore({})", &id);

            // Update ajour state.
            let flavor = ajour.config.wow.flavor;
            let ignored_addons = ajour.ignored_addons.entry(flavor).or_default();
            ignored_addons.retain(|(a, _)| a.id != id);

            // Update the config.
            let ignored_addon_ids = ajour.config.addons.ignored.entry(flavor).or_default();
            ignored_addon_ids.retain(|i| i != &id);

            // Persist the newly updated config.
            let _ = &ajour.config.save();
        }
        Message::Interaction(Interaction::OpenDirectory) => {
            log::debug!("Interaction::OpenDirectory");

            return Ok(Command::perform(open_directory(), Message::UpdateDirectory));
        }
        Message::Interaction(Interaction::OpenLink(link)) => {
            log::debug!("Interaction::OpenLink({})", &link);

            return Ok(Command::perform(
                async {
                    let _ = opener::open(link);
                },
                Message::None,
            ));
        }
        Message::UpdateDirectory(path) => {
            log::debug!("Message::UpdateDirectory({:?})", &path);

            // Clear addons.
            ajour.addons = HashMap::new();

            if path.is_some() {
                // Update the path for World of Warcraft.
                ajour.config.wow.directory = path;
                // Persist the newly updated config.
                let _ = &ajour.config.save();
                // Set loading state.
                ajour.state = AjourState::Loading;
                // Reload config.
                return Ok(Command::perform(load_config(), Message::Parse));
            }
        }
        Message::Interaction(Interaction::FlavorSelected(flavor)) => {
            log::debug!("Interaction::FlavorSelected({})", flavor);

            // Close settings if shown.
            ajour.is_showing_settings = false;
            // Update the game flavor
            ajour.config.wow.flavor = flavor;
            // Persist the newly updated config.
            let _ = &ajour.config.save();
        }
        Message::Interaction(Interaction::Expand(id)) => {
            log::debug!("Interaction::Expand({})", &id);

            // Close settings if shown.
            ajour.is_showing_settings = false;
            // Expand a addon. If it's already expanded, we collapse it again.
            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();
            if let Some(addon) = addons.iter().find(|a| a.id == id) {
                if let Some(is_addon_expanded) =
                    ajour.expanded_addon.as_ref().map(|a| a.id == addon.id)
                {
                    if is_addon_expanded {
                        ajour.expanded_addon = None;
                        return Ok(Command::none());
                    }
                }

                ajour.expanded_addon = Some(addon.clone());
            }
        }
        Message::Interaction(Interaction::Delete(id)) => {
            log::debug!("Interaction::Delete({})", &id);

            // Close settings if shown.
            ajour.is_showing_settings = false;

            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();

            if let Some(addon) = addons.iter().find(|a| a.id == id).cloned() {
                let addon_directory = ajour
                    .config
                    .get_addon_directory_for_flavor(&flavor)
                    .expect("has to have addon directory");

                // Remove from local state.
                addons.retain(|a| a.id != addon.id);

                // Foldernames to the addons which is to be deleted.
                let mut addons_to_be_deleted = [&addon.dependencies[..], &[addon.id]].concat();
                addons_to_be_deleted.dedup();

                // Delete addon(s) from disk.
                let _ = delete_addons(&addon_directory, &addons_to_be_deleted);
            }
        }
        Message::Interaction(Interaction::Update(id)) => {
            log::debug!("Interaction::Update({})", &id);

            // Close settings if shown.
            ajour.is_showing_settings = false;

            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();
            let to_directory = ajour
                .config
                .get_temporary_addon_directory()
                .expect("Expected a valid path");
            for addon in addons.iter_mut() {
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
            log::debug!("Interaction::UpdateAll");

            // Close settings if shown.
            ajour.is_showing_settings = false;

            // Update all pressed
            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();
            let mut commands = vec![];
            for addon in addons.iter_mut() {
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
        Message::ParsedAddons((flavor, result)) => {
            // if our selected flavor returns (either ok or error) - we change to idle.
            if flavor == ajour.config.wow.flavor {
                ajour.state = AjourState::Idle;
            }

            if let Ok(mut addons) = result {
                log::debug!("Message::ParsedAddons({}, {} addons)", flavor, addons.len(),);

                // Sort the addons.
                sort_addons(&mut addons, SortDirection::Desc, SortKey::Status);
                ajour.sort_state.previous_sort_direction = Some(SortDirection::Desc);
                ajour.sort_state.previous_sort_key = Some(SortKey::Status);

                if flavor == ajour.config.wow.flavor {
                    // Set the state if flavor matches.
                    ajour.state = AjourState::Idle;
                }

                // Find and push the ignored addons.
                let ignored_ids = ajour.config.addons.ignored.entry(flavor).or_default();
                let ignored_addons: Vec<_> = addons
                    .iter()
                    .filter(|a| ignored_ids.iter().any(|i| i == &a.id))
                    .map(|a| (a.clone(), button::State::new()))
                    .collect::<Vec<(Addon, button::State)>>();

                ajour.ignored_addons.insert(flavor, ignored_addons);

                // Insert the addons into the HashMap.
                ajour.addons.insert(flavor, addons);
            } else {
                log::error!(
                    "Message::ParsedAddons({}) - {}",
                    flavor,
                    result.err().unwrap(),
                );
            }
        }
        Message::DownloadedAddon((id, result)) => {
            log::debug!(
                "Message::DownloadedAddon(({}, error: {}))",
                &id,
                result.is_err()
            );

            // When an addon has been successfully downloaded we begin to unpack it.
            // If it for some reason fails to download, we handle the error.
            let from_directory = ajour
                .config
                .get_temporary_addon_directory()
                .expect("Expected a valid path");
            let flavor = ajour.config.wow.flavor;
            let to_directory = ajour
                .config
                .get_addon_directory_for_flavor(&flavor)
                .expect("Expected a valid path");
            let addons = ajour.addons.entry(flavor).or_default();
            if let Some(addon) = addons.iter_mut().find(|a| a.id == id) {
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
            log::debug!(
                "Message::UnpackedAddon(({}, error: {}))",
                &id,
                result.is_err()
            );

            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();
            if let Some(addon) = addons.iter_mut().find(|a| a.id == id) {
                match result {
                    Ok(_) => {
                        addon.state = AddonState::Fingerprint;
                        addon.version = addon.remote_version.clone();

                        let mut commands = vec![];
                        commands.push(Command::perform(
                            perform_hash_addon(
                                ajour
                                    .config
                                    .get_addon_directory_for_flavor(&flavor)
                                    .expect("Expected a valid path"),
                                addon.id.clone(),
                                ajour.fingerprint_collection.clone(),
                                ajour.config.wow.flavor,
                            ),
                            Message::UpdateFingerprint,
                        ));

                        for dep in &addon.dependencies {
                            if dep != &addon.id {
                                commands.push(Command::perform(
                                    perform_hash_addon(
                                        ajour
                                            .config
                                            .get_addon_directory_for_flavor(&flavor)
                                            .expect("Expected a valid path"),
                                        dep.clone(),
                                        ajour.fingerprint_collection.clone(),
                                        ajour.config.wow.flavor,
                                    ),
                                    Message::UpdateFingerprint,
                                ));
                            }
                        }

                        return Ok(Command::batch(commands));
                    }
                    Err(err) => {
                        ajour.state = AjourState::Error(err);
                        addon.state = AddonState::Ajour(Some("Error".to_owned()));
                    }
                }
            }
        }
        Message::UpdateFingerprint((id, result)) => {
            log::debug!(
                "Message::UpdateFingerprint(({}, error: {}))",
                &id,
                result.is_err()
            );

            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();
            if let Some(addon) = addons.iter_mut().find(|a| a.id == id) {
                if result.is_ok() {
                    addon.state = AddonState::Ajour(Some("Completed".to_owned()));
                } else {
                    addon.state = AddonState::Ajour(Some("Error".to_owned()));
                }
            }
        }
        Message::NeedsUpdate(Ok(newer_version)) => {
            log::debug!("Message::NeedsUpdate({:?})", &newer_version);

            ajour.needs_update = newer_version;
        }
        Message::Interaction(Interaction::SortColumn(sort_key)) => {
            // Close settings if shown.
            ajour.is_showing_settings = false;

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

            log::debug!(
                "Interaction::SortColumn({:?}, {:?})",
                sort_key,
                sort_direction
            );

            let flavor = ajour.config.wow.flavor;
            let mut addons = ajour.addons.entry(flavor).or_default();

            sort_addons(&mut addons, sort_direction, sort_key);

            ajour.sort_state.previous_sort_direction = Some(sort_direction);
            ajour.sort_state.previous_sort_key = Some(sort_key);
        }
        Message::ThemeSelected(theme_name) => {
            log::debug!("Message::ThemeSelected({:?})", &theme_name);

            ajour.theme_state.current_theme_name = theme_name.clone();

            ajour.config.theme = Some(theme_name);
            let _ = ajour.config.save();
        }
        Message::ThemesLoaded(mut themes) => {
            log::debug!("Message::ThemesLoaded({} themes)", themes.len());

            themes.sort();

            for theme in themes {
                ajour.theme_state.themes.push((theme.name.clone(), theme));
            }
        }
        Message::Error(error) | Message::Parse(Err(error)) | Message::NeedsUpdate(Err(error)) => {
            log::error!("{}", error);

            ajour.state = AjourState::Error(error);
        }
        Message::None(_) => {}
    }

    Ok(Command::none())
}

async fn open_directory() -> Option<PathBuf> {
    let dialog = OpenSingleDir { dir: None };
    if let Ok(show) = dialog.show() {
        return show;
    }

    None
}

async fn perform_read_addon_directory(
    fingerprint_collection: Arc<Mutex<Option<FingerprintCollection>>>,
    root_dir: PathBuf,
    flavor: Flavor,
) -> (Flavor, Result<Vec<Addon>>) {
    (
        flavor,
        read_addon_directory(fingerprint_collection, root_dir, flavor).await,
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
        download_addon(&shared_client, &addon, &to_directory).await,
    )
}

/// Rehashes a `Addon`.
async fn perform_hash_addon(
    addon_dir: impl AsRef<Path>,
    addon_id: String,
    fingerprint_collection: Arc<Mutex<Option<FingerprintCollection>>>,
    flavor: Flavor,
) -> (String, Result<()>) {
    (
        addon_id.clone(),
        update_addon_fingerprint(fingerprint_collection, flavor, addon_dir, addon_id).await,
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
        install_addon(&addon, &from_directory, &to_directory).await,
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
