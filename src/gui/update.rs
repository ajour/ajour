use {
    super::{
        Ajour, AjourState, CatalogColumnKey, ColumnKey, DirectoryType, Interaction, Message,
        SortDirection,
    },
    ajour_core::{
        addon::{Addon, AddonState},
        backup::{backup_folders, latest_backup, BackupFolder},
        config::{load_config, ColumnConfig, ColumnConfigV2, Flavor},
        fs::{delete_addons, install_addon, PersistentData},
        network::download_addon,
        parse::{read_addon_directory, update_addon_fingerprint, FingerprintCollection},
        Result,
    },
    async_std::sync::{Arc, Mutex},
    iced::{Command, Length},
    isahc::HttpClient,
    native_dialog::*,
    std::collections::HashMap,
    std::path::{Path, PathBuf},
    widgets::header::ResizeEvent,
};

pub fn handle_message(ajour: &mut Ajour, message: Message) -> Result<Command<Message>> {
    match message {
        Message::Parse(Ok(config)) => {
            log::debug!("Message::Parse");
            log::debug!("config loaded:\n{:#?}", config);

            // When we have the config, we parse the addon directory
            // which is provided by the config.
            ajour.config = config;

            // Set column widths from the config
            match &ajour.config.column_config {
                ColumnConfig::V1 {
                    local_version_width,
                    remote_version_width,
                    status_width,
                } => {
                    ajour
                        .header_state
                        .columns
                        .get_mut(1)
                        .as_mut()
                        .unwrap()
                        .width = Length::Units(*local_version_width);
                    ajour
                        .header_state
                        .columns
                        .get_mut(2)
                        .as_mut()
                        .unwrap()
                        .width = Length::Units(*remote_version_width);
                    ajour
                        .header_state
                        .columns
                        .get_mut(3)
                        .as_mut()
                        .unwrap()
                        .width = Length::Units(*status_width);
                }
                ColumnConfig::V2 { columns } => {
                    ajour.header_state.columns.iter_mut().for_each(|a| {
                        if let Some((idx, column)) = columns
                            .iter()
                            .enumerate()
                            .filter_map(|(idx, column)| {
                                if column.key == a.key.as_string() {
                                    Some((idx, column))
                                } else {
                                    None
                                }
                            })
                            .next()
                        {
                            a.width = column.width.map_or(Length::Fill, Length::Units);
                            a.hidden = column.hidden;
                            a.order = idx;
                        }
                    });

                    ajour.column_settings.columns.iter_mut().for_each(|a| {
                        if let Some(idx) = columns
                            .iter()
                            .enumerate()
                            .filter_map(|(idx, column)| {
                                if column.key == a.key.as_string() {
                                    Some(idx)
                                } else {
                                    None
                                }
                            })
                            .next()
                        {
                            a.order = idx;
                        }
                    });

                    ajour.header_state.columns.sort_by_key(|c| c.order);
                    ajour.column_settings.columns.sort_by_key(|c| c.order);
                }
            }

            // Use theme from config. Set to "Dark" if not defined.
            ajour.theme_state.current_theme_name =
                ajour.config.theme.as_deref().unwrap_or("Dark").to_string();

            // Use scale from config. Set to 1.0 if not defined.
            ajour.scale_state.scale = ajour.config.scale.unwrap_or(1.0);

            // Begin to parse addon folder(s).
            let mut commands = vec![];

            // If a backup directory is selected, find the latest backup
            if let Some(dir) = &ajour.config.backup_directory {
                commands.push(Command::perform(
                    latest_backup(dir.to_owned()),
                    Message::LatestBackup,
                ));
            }

            let flavors = &Flavor::ALL[..];
            for flavor in flavors {
                if let Some(addon_directory) = ajour.config.get_addon_directory_for_flavor(flavor) {
                    log::debug!(
                        "preparing to parse addons in {:?}",
                        addon_directory.display()
                    );

                    commands.push(Command::perform(
                        perform_read_addon_directory(
                            ajour.fingerprint_collection.clone(),
                            addon_directory.clone(),
                            *flavor,
                        ),
                        Message::ParsedAddons,
                    ));
                } else {
                    log::debug!("addon directory is not set, showing welcome screen");

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
            // Close details if shown.
            ajour.expanded_addon = None;

            // Cleans the addons.
            ajour.addons = HashMap::new();

            // Prepare state for loading.
            ajour.state = AjourState::Loading;

            return Ok(Command::perform(load_config(), Message::Parse));
        }
        Message::Interaction(Interaction::Settings) => {
            log::debug!("Interaction::Settings");

            ajour.is_showing_settings = !ajour.is_showing_settings;

            // Remove the expanded addon.
            ajour.expanded_addon = None;
        }
        Message::Interaction(Interaction::Ignore(id)) => {
            log::debug!("Interaction::Ignore({})", &id);

            // Close settings if shown.
            ajour.is_showing_settings = false;
            // Close details if shown.
            ajour.expanded_addon = None;

            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();
            let addon = addons.iter_mut().find(|a| a.id == id);

            if let Some(addon) = addon {
                addon.state = AddonState::Ignored;

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
            let addons = ajour.addons.entry(flavor).or_default();
            if let Some(addon) = addons.iter_mut().find(|a| a.id == id) {
                // Check if addon is updatable.
                if let Some(package) = addon.relevant_release_package() {
                    if addon.is_updatable(package) {
                        addon.state = AddonState::Updatable;
                    } else {
                        addon.state = AddonState::Ajour(None);
                    }
                }
            };

            // Update the config.
            let ignored_addon_ids = ajour.config.addons.ignored.entry(flavor).or_default();
            ignored_addon_ids.retain(|i| i != &id);

            // Persist the newly updated config.
            let _ = &ajour.config.save();
        }
        Message::Interaction(Interaction::OpenDirectory(dir_type)) => {
            log::debug!("Interaction::OpenDirectory({:?})", dir_type);

            let message = match dir_type {
                DirectoryType::Wow => Message::UpdateWowDirectory,
                DirectoryType::Backup => Message::UpdateBackupDirectory,
            };

            return Ok(Command::perform(open_directory(), message));
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
        Message::UpdateWowDirectory(path) => {
            log::debug!("Message::UpdateWowDirectory({:?})", &path);

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
            // Close details if shown.
            ajour.expanded_addon = None;
            // Update the game flavor
            ajour.config.wow.flavor = flavor;
            // Persist the newly updated config.
            let _ = &ajour.config.save();
        }
        Message::Interaction(Interaction::ModeSelected(mode)) => {
            log::debug!("Interaction::ModeSelected({})", mode);

            // Set ajour mode.
            ajour.mode = mode;
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
            // Close details if shown.
            ajour.expanded_addon = None;

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
            // Close details if shown.
            ajour.expanded_addon = None;

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
            // Close details if shown.
            ajour.expanded_addon = None;

            // Update all updatable addons, expect ignored.
            let flavor = ajour.config.wow.flavor;
            let ignored_ids = ajour.config.addons.ignored.entry(flavor).or_default();
            let mut addons: Vec<_> = ajour
                .addons
                .entry(flavor)
                .or_default()
                .iter_mut()
                .filter(|a| !ignored_ids.iter().any(|i| i == &a.id))
                .collect();

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

            if let Ok(addons) = result {
                log::debug!("Message::ParsedAddons({}, {} addons)", flavor, addons.len(),);

                // Ignored addon ids.
                let ignored_ids = ajour.config.addons.ignored.entry(flavor).or_default();

                // Check if addons is updatable.
                let release_channels = ajour
                    .config
                    .addons
                    .release_channels
                    .entry(flavor)
                    .or_default();
                let mut addons = addons
                    .into_iter()
                    .map(|mut a| {
                        // Check if we have saved release channel for addon.
                        if let Some(release_channel) = release_channels.get(&a.id) {
                            a.release_channel = *release_channel;
                        } else {
                            // Else we try to determine the release_channel based of installed version.
                            for (release_channel, package) in &a.remote_packages {
                                if package.file_id == a.file_id {
                                    a.release_channel = release_channel.to_owned();
                                    break;
                                }
                            }
                        }

                        // Check if addon is updatable based on release channel.
                        if let Some(package) = a.relevant_release_package() {
                            if a.is_updatable(package) {
                                a.state = AddonState::Updatable;
                            }
                        }

                        if ignored_ids.iter().any(|ia| &a.id == ia) {
                            a.state = AddonState::Ignored;
                        };

                        a
                    })
                    .collect::<Vec<Addon>>();

                // Sort the addons.
                sort_addons(&mut addons, SortDirection::Desc, ColumnKey::Status);
                ajour.header_state.previous_sort_direction = Some(SortDirection::Desc);
                ajour.header_state.previous_column_key = Some(ColumnKey::Status);

                if flavor == ajour.config.wow.flavor {
                    // Set the state if flavor matches.
                    ajour.state = AjourState::Idle;
                }

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

                        if let Some(package) = addon.relevant_release_package() {
                            addon.version = Some(package.version.clone());
                        }

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
        Message::Interaction(Interaction::SortColumn(column_key)) => {
            // Close settings if shown.
            ajour.is_showing_settings = false;
            // Close details if shown.
            ajour.expanded_addon = None;

            // First time clicking a column should sort it in Ascending order, otherwise
            // flip the sort direction.
            let mut sort_direction = SortDirection::Asc;

            if let Some(previous_column_key) = ajour.header_state.previous_column_key {
                if column_key == previous_column_key {
                    if let Some(previous_sort_direction) =
                        ajour.header_state.previous_sort_direction
                    {
                        sort_direction = previous_sort_direction.toggle()
                    }
                }
            }

            // Exception would be first time ever sorting and sorting by title.
            // Since its already sorting in Asc by default, we should sort Desc.
            if ajour.header_state.previous_column_key.is_none() && column_key == ColumnKey::Title {
                sort_direction = SortDirection::Desc;
            }

            log::debug!(
                "Interaction::SortColumn({:?}, {:?})",
                column_key,
                sort_direction
            );

            let flavor = ajour.config.wow.flavor;
            let mut addons = ajour.addons.entry(flavor).or_default();

            sort_addons(&mut addons, sort_direction, column_key);

            ajour.header_state.previous_sort_direction = Some(sort_direction);
            ajour.header_state.previous_column_key = Some(column_key);
        }
        Message::Interaction(Interaction::SortCatalogColumn(column_key)) => {
            // Close settings if shown.
            ajour.is_showing_settings = false;

            // First time clicking a column should sort it in Ascending order, otherwise
            // flip the sort direction.
            let mut sort_direction = SortDirection::Asc;

            if let Some(previous_column_key) = ajour.catalog_header_state.previous_column_key {
                if column_key == previous_column_key {
                    if let Some(previous_sort_direction) =
                        ajour.catalog_header_state.previous_sort_direction
                    {
                        sort_direction = previous_sort_direction.toggle()
                    }
                }
            }

            // Exception would be first time ever sorting and sorting by title.
            // Since its already sorting in Asc by default, we should sort Desc.
            if ajour.catalog_header_state.previous_column_key.is_none()
                && column_key == CatalogColumnKey::Title
            {
                sort_direction = SortDirection::Desc;
            }

            log::debug!(
                "Interaction::SortCatalogColumn({:?}, {:?})",
                column_key,
                sort_direction
            );

            //let flavor = ajour.config.wow.flavor;
            //let mut addons = ajour.addons.entry(flavor).or_default();

            //sort_addons(&mut addons, sort_direction, column_key);

            ajour.catalog_header_state.previous_sort_direction = Some(sort_direction);
            ajour.catalog_header_state.previous_column_key = Some(column_key);
        }
        Message::ReleaseChannelSelected(release_channel) => {
            log::debug!("Message::ReleaseChannelSelected({:?})", release_channel);

            if let Some(expanded_addon) = &ajour.expanded_addon {
                let flavor = ajour.config.wow.flavor;
                let addons = ajour.addons.entry(flavor).or_default();
                if let Some(addon) = addons.iter_mut().find(|a| a.id == expanded_addon.id) {
                    addon.release_channel = release_channel;

                    // Check if addon is updatable.
                    if let Some(package) = addon.relevant_release_package() {
                        if addon.is_updatable(package) {
                            addon.state = AddonState::Updatable;
                        } else {
                            addon.state = AddonState::Ajour(None);
                        }
                    }

                    // Update config with the newly changed release channel.
                    ajour
                        .config
                        .addons
                        .release_channels
                        .entry(flavor)
                        .or_default()
                        .insert(addon.id.clone(), release_channel);

                    // Persist the newly updated config.
                    let _ = &ajour.config.save();
                }
            };
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
        Message::Interaction(Interaction::ResizeColumn(event)) => match event {
            ResizeEvent::ResizeColumn {
                left_name,
                left_width,
                right_name,
                right_width,
            } => {
                let left_key = ColumnKey::from(left_name.as_str());
                let right_key = ColumnKey::from(right_name.as_str());

                let column_config = &mut ajour.config.column_config;

                if let Some(column) = ajour
                    .header_state
                    .columns
                    .iter_mut()
                    .find(|c| c.key == left_key && left_key != ColumnKey::Title)
                {
                    column.width = Length::Units(left_width);

                    column_config.update_width(&left_name, left_width);
                }

                if let Some(column) = ajour
                    .header_state
                    .columns
                    .iter_mut()
                    .find(|c| c.key == right_key && right_key != ColumnKey::Title)
                {
                    column.width = Length::Units(right_width);

                    column_config.update_width(&right_name, right_width);
                }
            }
            ResizeEvent::Finished => {
                let _ = ajour.config.save();
            }
        },
        Message::Interaction(Interaction::ScaleUp) => {
            let prev_scale = ajour.scale_state.scale;

            ajour.scale_state.scale = (prev_scale + 0.1).min(2.0);

            ajour.config.scale = Some(ajour.scale_state.scale);
            let _ = ajour.config.save();

            log::debug!(
                "Interaction::ScaleUp({} -> {})",
                prev_scale,
                ajour.scale_state.scale
            );
        }
        Message::Interaction(Interaction::ScaleDown) => {
            let prev_scale = ajour.scale_state.scale;

            ajour.scale_state.scale = (prev_scale - 0.1).max(0.5);

            ajour.config.scale = Some(ajour.scale_state.scale);
            let _ = ajour.config.save();

            log::debug!(
                "Interaction::ScaleDown({} -> {})",
                prev_scale,
                ajour.scale_state.scale
            );
        }
        Message::UpdateBackupDirectory(path) => {
            log::debug!("Message::UpdateBackupDirectory({:?})", &path);

            if let Some(path) = path {
                // Update the backup directory path.
                ajour.config.backup_directory = Some(path.clone());
                // Persist the newly updated config.
                let _ = &ajour.config.save();

                // Check if a latest backup exists in path
                return Ok(Command::perform(latest_backup(path), Message::LatestBackup));
            }
        }

        Message::Interaction(Interaction::Backup) => {
            log::debug!("Interaction::Backup");

            // This will disable our backup button and show a message that the
            // app is processing the backup. We will unflag this on completion.
            ajour.backup_state.backing_up = true;

            let mut src_folders = vec![];

            // Shouldn't panic since button is only clickable if wow directory is chosen
            let wow_dir = ajour.config.wow.directory.as_ref().unwrap();

            // Shouldn't panic since button is only shown if backup directory is chosen
            let dest = ajour.config.backup_directory.as_ref().unwrap();

            // Backup WTF & AddOn directories for both flavors if they exist
            for flavor in Flavor::ALL.iter() {
                let addon_dir = ajour.config.get_addon_directory_for_flavor(flavor).unwrap();
                let wtf_dir = ajour.config.get_wtf_directory_for_flavor(flavor).unwrap();

                if addon_dir.exists() {
                    src_folders.push(BackupFolder::new(&addon_dir, wow_dir));
                }

                if wtf_dir.exists() {
                    src_folders.push(BackupFolder::new(&wtf_dir, wow_dir));
                }
            }

            return Ok(Command::perform(
                backup_folders(src_folders, dest.to_owned()),
                Message::BackupFinished,
            ));
        }
        Message::LatestBackup(as_of) => {
            log::debug!("Message::LatestBackup({:?})", &as_of);

            ajour.backup_state.last_backup = as_of;
        }
        Message::BackupFinished(Ok(as_of)) => {
            log::debug!("Message::BackupFinished({})", as_of.format("%H:%M:%S"));

            ajour.backup_state.backing_up = false;
            ajour.backup_state.last_backup = Some(as_of);
        }
        Message::BackupFinished(Err(error)) => {
            log::error!("{}", error);

            ajour.backup_state.backing_up = false;

            ajour.state = AjourState::Error(error);
        }
        Message::Interaction(Interaction::ToggleColumn(is_checked, key)) => {
            // We can't untoggle the addon title column
            if key == ColumnKey::Title {
                return Ok(Command::none());
            }

            log::debug!("Interaction::ToggleColumn({}, {:?})", is_checked, key);

            if is_checked {
                if let Some(column) = ajour.header_state.columns.iter_mut().find(|c| c.key == key) {
                    column.hidden = false;
                }
            } else if let Some(column) =
                ajour.header_state.columns.iter_mut().find(|c| c.key == key)
            {
                column.hidden = true;
            }

            // Persist changes to config
            {
                let columns: Vec<_> = ajour
                    .header_state
                    .columns
                    .iter()
                    .map(ColumnConfigV2::from)
                    .collect();

                ajour.config.column_config = ColumnConfig::V2 { columns };

                let _ = ajour.config.save();
            }
        }
        Message::Interaction(Interaction::MoveColumnLeft(key)) => {
            log::debug!("Interaction::MoveColumnLeft({:?})", key);

            // Update header state ordering and save to config
            if let Some(idx) = ajour.header_state.columns.iter().position(|c| c.key == key) {
                ajour.header_state.columns.swap(idx, idx - 1);

                ajour
                    .header_state
                    .columns
                    .iter_mut()
                    .enumerate()
                    .for_each(|(idx, column)| column.order = idx);

                // Persist changes to config
                {
                    let columns: Vec<_> = ajour
                        .header_state
                        .columns
                        .iter()
                        .map(ColumnConfigV2::from)
                        .collect();

                    ajour.config.column_config = ColumnConfig::V2 { columns };

                    let _ = ajour.config.save();
                }
            }

            // Update column ordering in settings
            if let Some(idx) = ajour
                .column_settings
                .columns
                .iter()
                .position(|c| c.key == key)
            {
                ajour.column_settings.columns.swap(idx, idx - 1);
            }
        }
        Message::Interaction(Interaction::MoveColumnRight(key)) => {
            log::debug!("Interaction::MoveColumnRight({:?})", key);

            // Update header state ordering and save to config
            if let Some(idx) = ajour.header_state.columns.iter().position(|c| c.key == key) {
                ajour.header_state.columns.swap(idx, idx + 1);

                ajour
                    .header_state
                    .columns
                    .iter_mut()
                    .enumerate()
                    .for_each(|(idx, column)| column.order = idx);

                // Persist changes to config
                {
                    let columns: Vec<_> = ajour
                        .header_state
                        .columns
                        .iter()
                        .map(ColumnConfigV2::from)
                        .collect();

                    ajour.config.column_config = ColumnConfig::V2 { columns };

                    let _ = ajour.config.save();
                }
            }

            // Update column ordering in settings
            if let Some(idx) = ajour
                .column_settings
                .columns
                .iter()
                .position(|c| c.key == key)
            {
                ajour.column_settings.columns.swap(idx, idx + 1);
            }
        }
        Message::CatalogDownloaded(Ok(catalog)) => {
            log::debug!(
                "Message::CatalogDownloaded({} addons in catalog)",
                catalog.addon_summary_list.len()
            );

            ajour.catalog = Some(catalog);
        }
        Message::Interaction(Interaction::CatalogQuery(query)) => {
            log::debug!("Interaction::CatalogQuery({})", &query);

            ajour.catalog_query_state.query = Some(query);
        }
        Message::Error(error)
        | Message::Parse(Err(error))
        | Message::NeedsUpdate(Err(error))
        | Message::CatalogDownloaded(Err(error)) => {
            log::error!("{}", error);

            ajour.state = AjourState::Error(error);
        }
        Message::RuntimeEvent(iced_native::Event::Window(
            iced_native::window::Event::Resized { width, height },
        )) => {
            let width = (width as f64 * ajour.scale_state.scale) as u32;
            let height = (height as f64 * ajour.scale_state.scale) as u32;

            ajour.config.window_size = Some((width, height));
            let _ = ajour.config.save();
        }
        Message::RuntimeEvent(_) => {}
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

fn sort_addons(addons: &mut [Addon], sort_direction: SortDirection, column_key: ColumnKey) {
    match (column_key, sort_direction) {
        (ColumnKey::Title, SortDirection::Asc) => {
            addons.sort();
        }
        (ColumnKey::Title, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.title.cmp(&b.title).reverse().then_with(|| {
                    a.relevant_release_package()
                        .cmp(&b.relevant_release_package())
                })
            });
        }
        (ColumnKey::LocalVersion, SortDirection::Asc) => {
            addons.sort_by(|a, b| {
                a.version
                    .cmp(&b.version)
                    .then_with(|| a.title.cmp(&b.title))
            });
        }
        (ColumnKey::LocalVersion, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.version
                    .cmp(&b.version)
                    .reverse()
                    .then_with(|| a.title.cmp(&b.title))
            });
        }
        (ColumnKey::RemoteVersion, SortDirection::Asc) => {
            addons.sort_by(|a, b| {
                a.relevant_release_package()
                    .cmp(&b.relevant_release_package())
                    .then_with(|| a.cmp(&b))
            });
        }
        (ColumnKey::RemoteVersion, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.relevant_release_package()
                    .cmp(&b.relevant_release_package())
                    .reverse()
                    .then_with(|| a.cmp(&b))
            });
        }
        (ColumnKey::Status, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.state.cmp(&b.state).then_with(|| a.cmp(&b)));
        }
        (ColumnKey::Status, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.state.cmp(&b.state).reverse().then_with(|| a.cmp(&b)));
        }
        (ColumnKey::Channel, SortDirection::Asc) => addons.sort_by(|a, b| {
            a.release_channel
                .to_string()
                .cmp(&b.release_channel.to_string())
        }),
        (ColumnKey::Channel, SortDirection::Desc) => addons.sort_by(|a, b| {
            a.release_channel
                .to_string()
                .cmp(&b.release_channel.to_string())
                .reverse()
        }),
        (ColumnKey::Author, SortDirection::Asc) => addons.sort_by(|a, b| a.author.cmp(&b.author)),
        (ColumnKey::Author, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.author.cmp(&b.author).reverse())
        }
        (ColumnKey::GameVersion, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.game_version.cmp(&b.game_version))
        }
        (ColumnKey::GameVersion, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.game_version.cmp(&b.game_version).reverse())
        }
    }
}
