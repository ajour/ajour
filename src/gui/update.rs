use {
    super::{
        Ajour, AuraColumnKey, BackupFolderKind, CatalogCategory, CatalogColumnKey, CatalogRow,
        CatalogSource, ColumnKey, DirectoryType, DownloadReason, ExpandType, GlobalReleaseChannel,
        InstallAddon, InstallKind, InstallStatus, Interaction, Message, Mode, ReleaseChannel,
        SelfUpdateStatus, SortDirection, State,
    },
    crate::log_error,
    ajour_core::{
        addon::{Addon, AddonFolder, AddonState},
        backup::{backup_folders, latest_backup, BackupFolder},
        cache::{
            remove_addon_cache_entry, update_addon_cache, AddonCache, AddonCacheEntry,
            FingerprintCache,
        },
        catalog,
        config::{ColumnConfig, ColumnConfigV2, Flavor},
        error::{DownloadError, FilesystemError, ParseError, RepositoryError},
        fs::{delete_addons, delete_saved_variables, install_addon, PersistentData},
        network::download_addon,
        parse::{read_addon_directory, update_addon_fingerprint},
        repository::{RepositoryKind, RepositoryPackage},
        utility::{download_update_to_temp_file, get_latest_release, wow_path_resolution},
    },
    ajour_weak_auras::{Aura, AuraStatus},
    ajour_widgets::header::ResizeEvent,
    async_std::sync::{Arc, Mutex},
    chrono::{NaiveTime, Utc},
    color_eyre::eyre::{Report, Result, WrapErr},
    fuzzy_matcher::{
        skim::{SkimMatcherV2, SkimScoreConfig},
        FuzzyMatcher,
    },
    iced::{Command, Length},
    isahc::http::Uri,
    native_dialog::*,
    std::collections::{hash_map::DefaultHasher, HashMap},
    std::convert::TryFrom,
    std::hash::Hasher,
    std::path::{Path, PathBuf},
};

pub fn handle_message(ajour: &mut Ajour, message: Message) -> Result<Command<Message>> {
    match message {
        Message::CachesLoaded(result) => {
            log::debug!("Message::CachesLoaded(error: {})", result.is_err());

            if let Ok((fingerprint_cache, addon_cache)) = result {
                ajour.fingerprint_cache = Some(Arc::new(Mutex::new(fingerprint_cache)));
                ajour.addon_cache = Some(Arc::new(Mutex::new(addon_cache)));
            }

            return Ok(Command::perform(async {}, Message::Parse));
        }
        Message::Parse(_) => {
            log::debug!("Message::Parse");

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

                    // Builds a Vec of valid flavors.
                    if addon_directory.exists() {
                        ajour.valid_flavors.push(*flavor);
                        ajour.valid_flavors.dedup();
                    }

                    // Sets loading
                    ajour.state.insert(Mode::MyAddons(*flavor), State::Loading);

                    // Add commands
                    commands.push(Command::perform(
                        perform_read_addon_directory(
                            ajour.addon_cache.clone(),
                            ajour.fingerprint_cache.clone(),
                            addon_directory.clone(),
                            *flavor,
                        ),
                        Message::ParsedAddons,
                    ));

                    // Check if Weak Auras is installed for each flavor. If any of them returns
                    // true, we will show the My WeakAuras button
                    commands.push(Command::perform(
                        is_weak_auras_installed(*flavor, addon_directory),
                        Message::CheckWeakAurasInstalled,
                    ));
                } else {
                    log::debug!("addon directory is not set, showing welcome screen");

                    // Assume we are welcoming a user because directory is not set.
                    let flavor = ajour.config.wow.flavor;
                    ajour.state.insert(Mode::MyAddons(flavor), State::Start);

                    break;
                }
            }

            let flavor = ajour.config.wow.flavor;
            // If we dont have current flavor in valid flavors we select a new.
            if !ajour.valid_flavors.iter().any(|f| *f == flavor) {
                // Find new flavor.
                if let Some(flavor) = ajour.valid_flavors.first() {
                    // Set nye flavor.
                    ajour.config.wow.flavor = *flavor;
                    // Set mode.
                    ajour.mode = Mode::MyAddons(*flavor);
                    // Persist the newly updated config.
                    ajour.config.save()?;
                }
            }

            return Ok(Command::batch(commands));
        }
        Message::Interaction(Interaction::Refresh(mode)) => {
            log::debug!("Interaction::Refresh({})", &mode);

            match mode {
                Mode::MyAddons(flavor) => {
                    // Close details if shown.
                    ajour.expanded_type = ExpandType::None;

                    // Cleans the addons.
                    ajour.addons = HashMap::new();

                    // Prepare state for loading.
                    ajour.state.insert(Mode::MyAddons(flavor), State::Loading);

                    return Ok(Command::perform(async {}, Message::Parse));
                }
                Mode::MyWeakAuras(flavor) => {
                    let state = ajour.weak_auras_state.entry(flavor).or_default();

                    if let Some(account) = state.chosen_account.clone() {
                        if let Some(wtf_path) = ajour.config.get_wtf_directory_for_flavor(&flavor) {
                            state.auras.drain(..);

                            // Prepare state for loading.
                            ajour
                                .state
                                .insert(Mode::MyWeakAuras(flavor), State::Loading);

                            return Ok(Command::perform(
                                parse_auras(flavor, wtf_path, account),
                                Message::ParsedAuras,
                            ));
                        }
                    }
                }
                _ => {}
            }
        }
        Message::Interaction(Interaction::Ignore(id)) => {
            log::debug!("Interaction::Ignore({})", &id);

            // Close details if shown.
            ajour.expanded_type = ExpandType::None;

            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();
            let addon = addons.iter_mut().find(|a| a.primary_folder_id == id);

            if let Some(addon) = addon {
                addon.state = AddonState::Ignored;

                // Update the config.
                ajour
                    .config
                    .addons
                    .ignored
                    .entry(flavor)
                    .or_default()
                    .push(addon.primary_folder_id.clone());

                // Persist the newly updated config.
                let _ = &ajour.config.save();
            }
        }
        Message::Interaction(Interaction::Unignore(id)) => {
            log::debug!("Interaction::Unignore({})", &id);

            // Update ajour state.
            let flavor = ajour.config.wow.flavor;
            let global_release_channel = ajour.config.addons.global_release_channel;
            let addons = ajour.addons.entry(flavor).or_default();
            if let Some(addon) = addons.iter_mut().find(|a| a.primary_folder_id == id) {
                // Check if addon is updatable.
                if let Some(package) = addon.relevant_release_package(global_release_channel) {
                    if addon.is_updatable(&package) {
                        addon.state = AddonState::Updatable;
                    } else {
                        addon.state = AddonState::Idle;
                    }
                }
            };

            // Update the config.
            let ignored_addon_ids = ajour.config.addons.ignored.entry(flavor).or_default();
            ignored_addon_ids.retain(|i| i != &id);

            // Persist the newly updated config.
            let _ = &ajour.config.save();
        }
        Message::Interaction(Interaction::OpenDirectory(path)) => {
            log::debug!("Interaction::OpenDirectory({:?})", path);
            let _ = open::that(path);
        }
        Message::Interaction(Interaction::SelectDirectory(dir_type)) => {
            log::debug!("Interaction::SelectDirectory({:?})", dir_type);

            let message = match dir_type {
                DirectoryType::Wow => Message::UpdateWowDirectory,
                DirectoryType::Backup => Message::UpdateBackupDirectory,
            };

            return Ok(Command::perform(select_directory(), message));
        }
        Message::Interaction(Interaction::ResetColumns) => {
            log::debug!("Interaction::ResetColumns");

            ajour.column_settings = Default::default();
            ajour.catalog_column_settings = Default::default();

            ajour.header_state = Default::default();
            ajour.catalog_header_state = Default::default();
            ajour.aura_header_state = Default::default();

            save_column_configs(ajour);
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
        Message::UpdateWowDirectory(chosen_path) => {
            log::debug!("Message::UpdateWowDirectory(Chosen({:?}))", &chosen_path);
            let path = wow_path_resolution(chosen_path);
            log::debug!("Message::UpdateWowDirectory(Resolution({:?}))", &path);

            if path.is_some() {
                // Clear addons.
                ajour.addons = HashMap::new();
                // Update the path for World of Warcraft.
                ajour.config.wow.directory = path;
                // Persist the newly updated config.
                let _ = &ajour.config.save();
                // Set loading state.
                let state = ajour.state.clone();
                for (mode, _) in state {
                    if matches!(mode, Mode::MyAddons(_)) {
                        ajour.state.insert(mode, State::Loading);
                    }
                }

                return Ok(Command::perform(async {}, Message::Parse));
            }
        }
        Message::Interaction(Interaction::FlavorSelected(flavor)) => {
            log::debug!("Interaction::FlavorSelected({})", flavor);
            // Close details if shown.
            ajour.expanded_type = ExpandType::None;
            // Update the game flavor
            ajour.config.wow.flavor = flavor;
            // Persist the newly updated config.
            let _ = &ajour.config.save();

            match ajour.mode {
                Mode::MyAddons(_) => {
                    // Update flavor on MyAddons if thats our current mode.
                    ajour.mode = Mode::MyAddons(flavor);
                }
                Mode::MyWeakAuras(_) => {
                    // Update flavor on MyWeakAuras if thats our current mode.
                    ajour.mode = Mode::MyWeakAuras(flavor);
                }
                _ => {}
            }
            // Update catalog
            query_and_sort_catalog(ajour);
        }
        Message::Interaction(Interaction::ModeSelected(mode)) => {
            log::debug!("Interaction::ModeSelected({:?})", mode);

            // Toggle off About or Settings if button is clicked again
            if ajour.mode == mode && (mode == Mode::About || mode == Mode::Settings) {
                ajour.mode = Mode::MyAddons(ajour.config.wow.flavor);
            }
            // Set mode
            else {
                ajour.mode = mode;
            }
        }

        Message::Interaction(Interaction::Expand(expand_type)) => {
            // An addon can be exanded in two ways.
            match &expand_type {
                ExpandType::Details(a) => {
                    log::debug!("Interaction::Expand(Details({:?}))", &a.primary_folder_id);
                    let should_close = match &ajour.expanded_type {
                        ExpandType::Details(ea) => a.primary_folder_id == ea.primary_folder_id,
                        _ => false,
                    };

                    if should_close {
                        ajour.expanded_type = ExpandType::None;
                    } else {
                        ajour.expanded_type = expand_type.clone();
                    }
                }
                ExpandType::None => {
                    log::debug!("Interaction::Expand(ExpandType::None)");
                }
            }
        }
        Message::Interaction(Interaction::Delete(id)) => {
            log::debug!("Interaction::Delete({})", &id);

            // Close details if shown.
            ajour.expanded_type = ExpandType::None;

            let flavor = ajour.config.wow.flavor;
            let addons = ajour.addons.entry(flavor).or_default();

            if let Some(addon) = addons.iter().find(|a| a.primary_folder_id == id).cloned() {
                // Remove from local state.
                addons.retain(|a| a.primary_folder_id != addon.primary_folder_id);

                // Delete addon(s) from disk.
                let _ = delete_addons(&addon.folders);

                // Delete SavedVariable(s) if enabled.
                if ajour.config.addons.delete_saved_variables {
                    let wtf_path = &ajour
                        .config
                        .get_wtf_directory_for_flavor(&flavor)
                        .expect("No World of Warcraft directory set.");
                    let _ = delete_saved_variables(&addon.folders, wtf_path);
                }

                // Remove addon from cache
                if let Some(addon_cache) = &ajour.addon_cache {
                    if let Ok(entry) = AddonCacheEntry::try_from(&addon) {
                        match addon.repository_kind() {
                            // Delete the entry for this cached addon
                            Some(RepositoryKind::Tukui)
                            | Some(RepositoryKind::WowI)
                            | Some(RepositoryKind::Git(_)) => {
                                return Ok(Command::perform(
                                    remove_addon_cache_entry(addon_cache.clone(), entry, flavor),
                                    Message::AddonCacheEntryRemoved,
                                ));
                            }
                            _ => {}
                        }
                    }
                }
            }
        }
        Message::Interaction(Interaction::Update(id)) => {
            log::debug!("Interaction::Update({})", &id);

            // Close details if shown.
            ajour.expanded_type = ExpandType::None;

            let flavor = ajour.config.wow.flavor;
            let global_release_channel = ajour.config.addons.global_release_channel;
            let addons = ajour.addons.entry(flavor).or_default();
            let to_directory = ajour
                .config
                .get_download_directory_for_flavor(flavor)
                .expect("Expected a valid path");
            for addon in addons.iter_mut() {
                if addon.primary_folder_id == id {
                    addon.state = AddonState::Downloading;
                    return Ok(Command::perform(
                        perform_download_addon(
                            DownloadReason::Update,
                            flavor,
                            global_release_channel,
                            addon.clone(),
                            to_directory,
                        ),
                        Message::DownloadedAddon,
                    ));
                }
            }
        }
        Message::Interaction(Interaction::UpdateAll(mode)) => {
            log::debug!("Interaction::UpdateAll({})", &mode);

            match mode {
                Mode::MyAddons(flavor) => {
                    // Close details if shown.
                    ajour.expanded_type = ExpandType::None;

                    // Update all updatable addons, expect ignored.
                    let global_release_channel = ajour.config.addons.global_release_channel;
                    let ignored_ids = ajour.config.addons.ignored.entry(flavor).or_default();
                    let mut addons: Vec<_> = ajour
                        .addons
                        .entry(flavor)
                        .or_default()
                        .iter_mut()
                        .filter(|a| !ignored_ids.iter().any(|i| i == &a.primary_folder_id))
                        .collect();

                    let mut commands = vec![];
                    for addon in addons.iter_mut() {
                        if addon.state == AddonState::Updatable {
                            if let Some(to_directory) =
                                ajour.config.get_download_directory_for_flavor(flavor)
                            {
                                addon.state = AddonState::Downloading;
                                let addon = addon.clone();
                                commands.push(Command::perform(
                                    perform_download_addon(
                                        DownloadReason::Update,
                                        flavor,
                                        global_release_channel,
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
                Mode::MyWeakAuras(flavor) => {
                    if let Some(addon_dir) = ajour.config.get_addon_directory_for_flavor(&flavor) {
                        let state = ajour.weak_auras_state.entry(flavor).or_default();

                        state.is_updating = true;

                        let auras = state.auras.clone();

                        return Ok(Command::perform(
                            update_auras(flavor, auras, addon_dir),
                            Message::AurasUpdated,
                        ));
                    }
                }
                _ => {}
            }
        }
        Message::ParsedAddons((flavor, result)) => {
            let global_release_channel = ajour.config.addons.global_release_channel;

            // if our selected flavor returns (either ok or error) - we change to idle.
            ajour.state.insert(Mode::MyAddons(flavor), State::Ready);

            match result.wrap_err("Failed to parse addons") {
                Ok(addons) => {
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
                            if let Some(release_channel) =
                                release_channels.get(&a.primary_folder_id)
                            {
                                a.release_channel = *release_channel;
                            } else {
                                // Else we set it to the default release channel.
                                a.release_channel = ReleaseChannel::Default;
                            }

                            // Check if addon is updatable based on release channel.
                            if let Some(package) =
                                a.relevant_release_package(global_release_channel)
                            {
                                if a.is_updatable(&package) {
                                    a.state = AddonState::Updatable;
                                }
                            }

                            if ignored_ids.iter().any(|ia| &a.primary_folder_id == ia) {
                                a.state = AddonState::Ignored;
                            };

                            a
                        })
                        .collect::<Vec<Addon>>();

                    // Sort the addons.
                    sort_addons(
                        &mut addons,
                        global_release_channel,
                        SortDirection::Desc,
                        ColumnKey::Status,
                    );
                    ajour.header_state.previous_sort_direction = Some(SortDirection::Desc);
                    ajour.header_state.previous_column_key = Some(ColumnKey::Status);

                    // Sets the flavor state to ready.
                    ajour.state.insert(Mode::MyAddons(flavor), State::Ready);

                    // Insert the addons into the HashMap.
                    ajour.addons.insert(flavor, addons);
                }
                Err(error) => {
                    log_error(&error);
                }
            }
        }
        Message::DownloadedAddon((reason, flavor, id, result)) => {
            log::debug!(
                "Message::DownloadedAddon(({}, {}, error: {}))",
                flavor,
                &id,
                result.is_err()
            );

            let addons = ajour.addons.entry(flavor).or_default();
            let install_addons = ajour.install_addons.entry(flavor).or_default();

            let mut addon = None;

            match result.wrap_err("Failed to download addon") {
                Ok(_) => match reason {
                    DownloadReason::Update => {
                        if let Some(_addon) = addons.iter_mut().find(|a| a.primary_folder_id == id)
                        {
                            addon = Some(_addon);
                        }
                    }
                    DownloadReason::Install => {
                        if let Some(install_addon) = install_addons
                            .iter_mut()
                            .find(|a| a.addon.as_ref().map(|a| &a.primary_folder_id) == Some(&id))
                        {
                            install_addon.status = InstallStatus::Unpacking;

                            if let Some(_addon) = install_addon.addon.as_mut() {
                                addon = Some(_addon);
                            }
                        }
                    }
                },
                Err(error) => {
                    log_error(&error);
                    ajour.error = Some(error);

                    match reason {
                        DownloadReason::Update => {
                            if let Some(_addon) =
                                addons.iter_mut().find(|a| a.primary_folder_id == id)
                            {
                                _addon.state = AddonState::Retry;
                            }
                        }
                        DownloadReason::Install => {
                            if let Some(install_addon) =
                                install_addons.iter_mut().find(|a| a.id == id)
                            {
                                install_addon.status = InstallStatus::Retry;
                            }
                        }
                    }
                }
            }

            if let Some(addon) = addon {
                let from_directory = ajour
                    .config
                    .get_download_directory_for_flavor(flavor)
                    .expect("Expected a valid path");
                let to_directory = ajour
                    .config
                    .get_addon_directory_for_flavor(&flavor)
                    .expect("Expected a valid path");

                if addon.state == AddonState::Downloading {
                    addon.state = AddonState::Unpacking;

                    return Ok(Command::perform(
                        perform_unpack_addon(
                            reason,
                            flavor,
                            addon.clone(),
                            from_directory,
                            to_directory,
                        ),
                        Message::UnpackedAddon,
                    ));
                }
            }
        }
        Message::UnpackedAddon((reason, flavor, id, result)) => {
            log::debug!(
                "Message::UnpackedAddon(({}, error: {}))",
                &id,
                result.is_err()
            );

            let addons = ajour.addons.entry(flavor).or_default();
            let install_addons = ajour.install_addons.entry(flavor).or_default();

            let mut addon = None;
            let mut folders = None;

            match result.wrap_err("Failed to unpack addon") {
                Ok(_folders) => match reason {
                    DownloadReason::Update => {
                        if let Some(_addon) = addons.iter_mut().find(|a| a.primary_folder_id == id)
                        {
                            addon = Some(_addon);
                            folders = Some(_folders);
                        }
                    }
                    DownloadReason::Install => {
                        if let Some(install_addon) = install_addons
                            .iter_mut()
                            .find(|a| a.addon.as_ref().map(|a| &a.primary_folder_id) == Some(&id))
                        {
                            if let Some(_addon) = install_addon.addon.as_mut() {
                                // If we are installing from the catalog, remove any existing addon
                                // that has the same folders and insert this new one
                                addons.retain(|a| a.folders != _folders);
                                addons.push(_addon.clone());

                                addon = addons.iter_mut().find(|a| a.primary_folder_id == id);
                                folders = Some(_folders);
                            }
                        }

                        // Remove install addon since we've successfully installed it and
                        // added to main addon vec
                        install_addons.retain(|a| {
                            a.addon.as_ref().map(|a| &a.primary_folder_id) != Some(&id)
                        });
                    }
                },
                Err(error) => {
                    log_error(&error);
                    ajour.error = Some(error);

                    match reason {
                        DownloadReason::Update => {
                            if let Some(_addon) =
                                addons.iter_mut().find(|a| a.primary_folder_id == id)
                            {
                                _addon.state = AddonState::Retry;
                            }
                        }
                        DownloadReason::Install => {
                            if let Some(install_addon) =
                                install_addons.iter_mut().find(|a| a.id == id)
                            {
                                install_addon.status = InstallStatus::Retry;
                            }
                        }
                    }
                }
            }

            let global_release_channel = ajour.config.addons.global_release_channel;
            let mut commands = vec![];

            if let (Some(addon), Some(folders)) = (addon, folders) {
                addon.update_addon_folders(folders);

                addon.state = AddonState::Fingerprint;

                let mut version = None;
                if let Some(package) = addon.relevant_release_package(global_release_channel) {
                    version = Some(package.version);
                }
                if let Some(version) = version {
                    addon.set_version(version);
                }

                // If we are updating / installing a Tukui / WowI
                // addon, we want to update the cache. If we are installing a Curse
                // addon, we want to make sure cache entry exists for those folders
                if let Some(addon_cache) = &ajour.addon_cache {
                    if let Ok(entry) = AddonCacheEntry::try_from(addon as &_) {
                        match addon.repository_kind() {
                            // Remove any entry related to this cached addon
                            Some(RepositoryKind::Curse) => {
                                commands.push(Command::perform(
                                    remove_addon_cache_entry(addon_cache.clone(), entry, flavor),
                                    Message::AddonCacheEntryRemoved,
                                ));
                            }
                            // Update the entry for this cached addon
                            Some(RepositoryKind::Tukui)
                            | Some(RepositoryKind::WowI)
                            | Some(RepositoryKind::Git(_)) => {
                                commands.push(Command::perform(
                                    update_addon_cache(addon_cache.clone(), entry, flavor),
                                    Message::AddonCacheUpdated,
                                ));
                            }
                            None => {}
                        }
                    }
                }

                // Submit all addon folders to be fingerprinted
                if let Some(cache) = ajour.fingerprint_cache.as_ref() {
                    for folder in &addon.folders {
                        commands.push(Command::perform(
                            perform_hash_addon(
                                ajour
                                    .config
                                    .get_addon_directory_for_flavor(&flavor)
                                    .expect("Expected a valid path"),
                                folder.id.clone(),
                                cache.clone(),
                                flavor,
                            ),
                            Message::UpdateFingerprint,
                        ));
                    }
                }
            }

            if !commands.is_empty() {
                return Ok(Command::batch(commands));
            }
        }
        Message::UpdateFingerprint((flavor, id, result)) => {
            log::debug!(
                "Message::UpdateFingerprint(({:?}, {}, error: {}))",
                flavor,
                &id,
                result.is_err()
            );

            let addons = ajour.addons.entry(flavor).or_default();
            if let Some(addon) = addons.iter_mut().find(|a| a.primary_folder_id == id) {
                if result.is_ok() {
                    addon.state = AddonState::Completed;
                } else {
                    addon.state = AddonState::Error("Error".to_owned());
                }
            }
        }
        Message::LatestRelease(release) => {
            log::debug!(
                "Message::LatestRelease({:?})",
                release.as_ref().map(|r| &r.tag_name)
            );

            ajour.self_update_state.latest_release = release;
        }
        Message::Interaction(Interaction::SortColumn(column_key)) => {
            // Close details if shown.
            ajour.expanded_type = ExpandType::None;

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
            let global_release_channel = ajour.config.addons.global_release_channel;
            let mut addons = ajour.addons.entry(flavor).or_default();

            sort_addons(
                &mut addons,
                global_release_channel,
                sort_direction,
                column_key,
            );

            ajour.header_state.previous_sort_direction = Some(sort_direction);
            ajour.header_state.previous_column_key = Some(column_key);
        }
        Message::Interaction(Interaction::SortCatalogColumn(column_key)) => {
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
            // Exception for the date released
            if ajour.catalog_header_state.previous_column_key.is_none()
                && column_key == CatalogColumnKey::DateReleased
            {
                sort_direction = SortDirection::Desc;
            }

            log::debug!(
                "Interaction::SortCatalogColumn({:?}, {:?})",
                column_key,
                sort_direction
            );

            ajour.catalog_header_state.previous_sort_direction = Some(sort_direction);
            ajour.catalog_header_state.previous_column_key = Some(column_key);

            query_and_sort_catalog(ajour);
        }
        Message::Interaction(Interaction::SortAuraColumn(column_key)) => {
            // First time clicking a column should sort it in Ascending order, otherwise
            // flip the sort direction.
            let mut sort_direction = SortDirection::Asc;

            if let Some(previous_column_key) = ajour.aura_header_state.previous_column_key {
                if column_key == previous_column_key {
                    if let Some(previous_sort_direction) =
                        ajour.aura_header_state.previous_sort_direction
                    {
                        sort_direction = previous_sort_direction.toggle()
                    }
                }
            }

            // Exception would be first time ever sorting and sorting by title.
            // Since its already sorting in Asc by default, we should sort Desc.
            if ajour.aura_header_state.previous_column_key.is_none()
                && column_key == AuraColumnKey::Title
            {
                sort_direction = SortDirection::Desc;
            }

            log::debug!(
                "Interaction::SortAuraColumn({:?}, {:?})",
                column_key,
                sort_direction
            );

            ajour.aura_header_state.previous_sort_direction = Some(sort_direction);
            ajour.aura_header_state.previous_column_key = Some(column_key);

            let flavor = ajour.config.wow.flavor;
            let state = ajour.weak_auras_state.entry(flavor).or_default();

            sort_auras(&mut state.auras, sort_direction, column_key);
        }

        Message::ReleaseChannelSelected(release_channel) => {
            log::debug!("Message::ReleaseChannelSelected({:?})", release_channel);

            let global_release_channel = ajour.config.addons.global_release_channel;
            if let ExpandType::Details(expanded_addon) = &ajour.expanded_type {
                let flavor = ajour.config.wow.flavor;
                let addons = ajour.addons.entry(flavor).or_default();
                if let Some(addon) = addons
                    .iter_mut()
                    .find(|a| a.primary_folder_id == expanded_addon.primary_folder_id)
                {
                    // Update config with the newly changed release channel.
                    // if we are selecting Default, we ensure we remove it from config.
                    if release_channel == ReleaseChannel::Default {
                        ajour
                            .config
                            .addons
                            .release_channels
                            .entry(flavor)
                            .or_default()
                            .remove(&addon.primary_folder_id);
                    } else {
                        ajour
                            .config
                            .addons
                            .release_channels
                            .entry(flavor)
                            .or_default()
                            .insert(addon.primary_folder_id.clone(), release_channel);
                    }

                    // Persist the newly updated config.
                    let _ = &ajour.config.save();

                    addon.release_channel = release_channel;

                    // Check if addon is updatable.
                    if let Some(package) = addon.relevant_release_package(global_release_channel) {
                        if addon.is_updatable(&package) {
                            addon.state = AddonState::Updatable;
                        } else {
                            addon.state = AddonState::Idle;
                        }
                    }
                }
            }
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
        Message::Interaction(Interaction::ResizeColumn(column_type, event)) => match event {
            ResizeEvent::ResizeColumn {
                left_name,
                left_width,
                right_name,
                right_width,
            } => match column_type {
                Mode::MyAddons(_) => {
                    let left_key = ColumnKey::from(left_name.as_str());
                    let right_key = ColumnKey::from(right_name.as_str());

                    if let Some(column) = ajour
                        .header_state
                        .columns
                        .iter_mut()
                        .find(|c| c.key == left_key && left_key != ColumnKey::Title)
                    {
                        column.width = Length::Units(left_width);
                    }

                    if let Some(column) = ajour
                        .header_state
                        .columns
                        .iter_mut()
                        .find(|c| c.key == right_key && right_key != ColumnKey::Title)
                    {
                        column.width = Length::Units(right_width);
                    }
                }
                Mode::Install => {}
                Mode::Settings => {}
                Mode::About => {}
                Mode::MyWeakAuras(_) => {
                    let left_key = AuraColumnKey::from(left_name.as_str());
                    let right_key = AuraColumnKey::from(right_name.as_str());

                    if let Some(column) = ajour
                        .aura_header_state
                        .columns
                        .iter_mut()
                        .find(|c| c.key == left_key && left_key != AuraColumnKey::Title)
                    {
                        column.width = Length::Units(left_width);
                    }

                    if let Some(column) = ajour
                        .aura_header_state
                        .columns
                        .iter_mut()
                        .find(|c| c.key == right_key && right_key != AuraColumnKey::Title)
                    {
                        column.width = Length::Units(right_width);
                    }
                }
                Mode::Catalog => {
                    let left_key = CatalogColumnKey::from(left_name.as_str());
                    let right_key = CatalogColumnKey::from(right_name.as_str());

                    if let Some(column) = ajour
                        .catalog_header_state
                        .columns
                        .iter_mut()
                        .find(|c| c.key == left_key && left_key != CatalogColumnKey::Title)
                    {
                        column.width = Length::Units(left_width);
                    }

                    if let Some(column) = ajour
                        .catalog_header_state
                        .columns
                        .iter_mut()
                        .find(|c| c.key == right_key && right_key != CatalogColumnKey::Title)
                    {
                        column.width = Length::Units(right_width);
                    }
                }
            },
            ResizeEvent::Finished => {
                // Persist changes to config
                save_column_configs(ajour);
            }
        },
        Message::Interaction(Interaction::ScaleUp) => {
            let prev_scale = ajour.scale_state.scale;

            ajour.scale_state.scale = ((prev_scale + 0.1).min(2.0) * 10.0).round() / 10.0;

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

            ajour.scale_state.scale = ((prev_scale - 0.1).max(0.5) * 10.0).round() / 10.0;

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
                if ajour.config.backup_addons {
                    let addon_dir = ajour.config.get_addon_directory_for_flavor(flavor).unwrap();

                    // Backup starting with `Interface` folder as some users save
                    // custom data here that they would like retained
                    if let Some(interface_dir) = addon_dir.parent() {
                        if interface_dir.exists() {
                            src_folders.push(BackupFolder::new(interface_dir, wow_dir));
                        }
                    }
                }

                if ajour.config.backup_wtf {
                    let wtf_dir = ajour.config.get_wtf_directory_for_flavor(flavor).unwrap();

                    if wtf_dir.exists() {
                        src_folders.push(BackupFolder::new(&wtf_dir, wow_dir));
                    }
                }
            }

            return Ok(Command::perform(
                backup_folders(src_folders, dest.to_owned()),
                Message::BackupFinished,
            ));
        }
        Message::Interaction(Interaction::ToggleBackupFolder(is_checked, folder)) => {
            log::debug!(
                "Interaction::ToggleBackupFolder({:?}, checked: {})",
                folder,
                is_checked
            );

            match folder {
                BackupFolderKind::AddOns => {
                    ajour.config.backup_addons = is_checked;
                }
                BackupFolderKind::WTF => {
                    ajour.config.backup_wtf = is_checked;
                }
            }

            let _ = ajour.config.save();
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
        Message::BackupFinished(error @ Err(_)) => {
            let error = error.wrap_err("Failed to backup folders").unwrap_err();

            log_error(&error);
            ajour.error = Some(error);

            ajour.backup_state.backing_up = false;
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
            save_column_configs(ajour);
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
                save_column_configs(ajour);
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
                save_column_configs(ajour);
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
        Message::Interaction(Interaction::ToggleCatalogColumn(is_checked, key)) => {
            // We can't untoggle the addon title column
            if key == CatalogColumnKey::Title {
                return Ok(Command::none());
            }

            log::debug!(
                "Interaction::ToggleCatalogColumn({}, {:?})",
                is_checked,
                key
            );

            if is_checked {
                if let Some(column) = ajour
                    .catalog_header_state
                    .columns
                    .iter_mut()
                    .find(|c| c.key == key)
                {
                    column.hidden = false;
                }
            } else if let Some(column) = ajour
                .catalog_header_state
                .columns
                .iter_mut()
                .find(|c| c.key == key)
            {
                column.hidden = true;
            }

            // Persist changes to config
            save_column_configs(ajour);
        }
        Message::Interaction(Interaction::MoveCatalogColumnLeft(key)) => {
            log::debug!("Interaction::MoveCatalogColumnLeft({:?})", key);

            // Update header state ordering and save to config
            if let Some(idx) = ajour
                .catalog_header_state
                .columns
                .iter()
                .position(|c| c.key == key)
            {
                ajour.catalog_header_state.columns.swap(idx, idx - 1);

                ajour
                    .catalog_header_state
                    .columns
                    .iter_mut()
                    .enumerate()
                    .for_each(|(idx, column)| column.order = idx);

                // Persist changes to config
                save_column_configs(ajour);
            }

            // Update column ordering in settings
            if let Some(idx) = ajour
                .catalog_column_settings
                .columns
                .iter()
                .position(|c| c.key == key)
            {
                ajour.catalog_column_settings.columns.swap(idx, idx - 1);
            }
        }
        Message::Interaction(Interaction::MoveCatalogColumnRight(key)) => {
            log::debug!("Interaction::MoveCatalogColumnRight({:?})", key);

            // Update header state ordering and save to config
            if let Some(idx) = ajour
                .catalog_header_state
                .columns
                .iter()
                .position(|c| c.key == key)
            {
                ajour.catalog_header_state.columns.swap(idx, idx + 1);

                ajour
                    .catalog_header_state
                    .columns
                    .iter_mut()
                    .enumerate()
                    .for_each(|(idx, column)| column.order = idx);

                // Persist changes to config
                save_column_configs(ajour);
            }

            // Update column ordering in settings
            if let Some(idx) = ajour
                .catalog_column_settings
                .columns
                .iter()
                .position(|c| c.key == key)
            {
                ajour.catalog_column_settings.columns.swap(idx, idx + 1);
            }
        }
        Message::CatalogDownloaded(Ok(catalog)) => {
            log::debug!(
                "Message::CatalogDownloaded({} addons in catalog)",
                catalog.addons.len()
            );

            ajour.catalog_last_updated = Some(Utc::now());

            let mut categories_per_source =
                catalog
                    .addons
                    .iter()
                    .fold(HashMap::new(), |mut map, addon| {
                        map.entry(addon.source.to_string())
                            .or_insert_with(Vec::new)
                            .append(
                                &mut addon
                                    .categories
                                    .clone()
                                    .iter()
                                    .map(|c| CatalogCategory::Choice(c.to_string()))
                                    .collect(),
                            );
                        map
                    });
            categories_per_source.iter_mut().for_each(move |s| {
                s.1.sort();
                s.1.dedup();
                s.1.insert(0, CatalogCategory::All);
            });

            ajour.catalog_categories_per_source_cache = categories_per_source;

            ajour.catalog_search_state.categories = ajour
                .catalog_categories_per_source_cache
                .get(&ajour.catalog_search_state.source.to_string())
                .cloned()
                .unwrap_or_default();

            ajour.catalog = Some(catalog);

            ajour.state.insert(Mode::Catalog, State::Ready);

            query_and_sort_catalog(ajour);
        }
        Message::Interaction(Interaction::CatalogQuery(query)) => {
            // Catalog search query
            ajour.catalog_search_state.query = if query.is_empty() {
                None
            } else {
                // Always set sort config to None when a new character is typed
                // so the sort will be off fuzzy match score.
                ajour.catalog_header_state.previous_column_key.take();
                ajour.catalog_header_state.previous_sort_direction.take();

                Some(query)
            };

            query_and_sort_catalog(ajour);
        }
        Message::Interaction(Interaction::InstallAddon(flavor, id, kind)) => {
            log::debug!("Interaction::InstallAddon({}, {:?})", flavor, &kind);

            let install_addons = ajour.install_addons.entry(flavor).or_default();

            // Remove any existing status for this addon since we are going
            // to try and download it again. For InstallKind::Source, we should only
            // ever have one entry here so we just remove it
            install_addons.retain(|a| match kind {
                InstallKind::Catalog { .. } => !(id == a.id && a.kind == kind),
                InstallKind::Source => a.kind != kind,
            });

            // Add new status for this addon as Downloading
            install_addons.push(InstallAddon {
                id: id.clone(),
                kind,
                status: InstallStatus::Downloading,
                addon: None,
            });

            return Ok(Command::perform(
                perform_fetch_latest_addon(kind, id, flavor),
                Message::InstallAddonFetched,
            ));
        }
        Message::Interaction(Interaction::CatalogCategorySelected(category)) => {
            log::debug!("Interaction::CatalogCategorySelected({})", &category);

            // Select category
            ajour.catalog_search_state.category = category;

            query_and_sort_catalog(ajour);
        }
        Message::Interaction(Interaction::CatalogResultSizeSelected(size)) => {
            log::debug!("Interaction::CatalogResultSizeSelected({:?})", &size);

            // Catalog result size
            ajour.catalog_search_state.result_size = size;

            query_and_sort_catalog(ajour);
        }
        Message::Interaction(Interaction::CatalogSourceSelected(source)) => {
            log::debug!("Interaction::CatalogResultSizeSelected({:?})", source);

            // Catalog source
            ajour.catalog_search_state.source = source;

            ajour.catalog_search_state.categories = ajour
                .catalog_categories_per_source_cache
                .get(&source.to_string())
                .cloned()
                .unwrap_or_default();

            ajour.catalog_search_state.category = CatalogCategory::All;

            query_and_sort_catalog(ajour);
        }
        Message::InstallAddonFetched((flavor, id, result)) => {
            let install_addons = ajour.install_addons.entry(flavor).or_default();

            if let Some(install_addon) = install_addons.iter_mut().find(|a| a.id == id) {
                match result {
                    Ok(mut addon) => {
                        log::debug!(
                            "Message::CatalogInstallAddonFetched({:?}, {:?})",
                            flavor,
                            &id,
                        );

                        addon.state = AddonState::Downloading;
                        install_addon.addon = Some(addon.clone());

                        let global_release_channel = ajour.config.addons.global_release_channel;
                        let to_directory = ajour
                            .config
                            .get_download_directory_for_flavor(flavor)
                            .expect("Expected a valid path");

                        return Ok(Command::perform(
                            perform_download_addon(
                                DownloadReason::Install,
                                flavor,
                                global_release_channel,
                                addon,
                                to_directory,
                            ),
                            Message::DownloadedAddon,
                        ));
                    }
                    Err(error) => {
                        // Dont use `wrap_err` here to convert to eyre::Report since
                        // we actually want to show the underlying RepositoryError
                        // message
                        let error = Report::new(error);

                        log_error(&error);

                        match install_addon.kind {
                            InstallKind::Catalog { .. } => {
                                install_addon.status = InstallStatus::Unavilable;
                            }
                            InstallKind::Source => {
                                install_addon.status = InstallStatus::Error(error.to_string());
                            }
                        }
                    }
                }
            }
        }
        Message::Interaction(Interaction::UpdateAjour) => {
            log::debug!("Interaction::UpdateAjour");

            if let Some(release) = &ajour.self_update_state.latest_release {
                let bin_name = bin_name().to_owned();

                ajour.self_update_state.status = Some(SelfUpdateStatus::InProgress);

                return Ok(Command::perform(
                    download_update_to_temp_file(bin_name, release.clone()),
                    Message::AjourUpdateDownloaded,
                ));
            }
        }
        Message::AjourUpdateDownloaded(result) => {
            log::debug!("Message::AjourUpdateDownloaded");

            match result.wrap_err("Failed to update Ajour") {
                Ok((relaunch_path, cleanup_path)) => {
                    // Remove first arg, which is path to binary. We don't use this first
                    // arg as binary path because it's not reliable, per the docs.
                    let mut args = std::env::args();
                    args.next();
                    let mut args: Vec<_> = args.collect();

                    // Remove the `--self-update-temp` arg from args if it exists,
                    // since we need to pass it cleanly. Otherwise new process will
                    // fail during arg parsing.
                    if let Some(idx) = args.iter().position(|a| a == "--self-update-temp") {
                        args.remove(idx);
                        // Remove path passed after this arg
                        args.remove(idx);
                    }

                    match std::process::Command::new(&relaunch_path)
                        .args(args)
                        .arg("--self-update-temp")
                        .arg(&cleanup_path)
                        .spawn()
                        .wrap_err("Failed to update Ajour")
                    {
                        Ok(_) => std::process::exit(0),
                        Err(error) => {
                            log_error(&error);
                            ajour.error = Some(error);
                            ajour.self_update_state.status = Some(SelfUpdateStatus::Failed);
                        }
                    }
                }
                Err(error) => {
                    log_error(&error);
                    ajour.error = Some(error);
                    ajour.self_update_state.status = Some(SelfUpdateStatus::Failed);
                }
            }
        }
        Message::AddonCacheUpdated(Ok(entry)) => {
            log::debug!("Message::AddonCacheUpdated({})", entry.title);
        }
        Message::AddonCacheEntryRemoved(maybe_entry) => {
            match maybe_entry.wrap_err("Failed to remove cache entry") {
                Ok(Some(entry)) => log::debug!("Message::AddonCacheEntryRemoved({})", entry.title),
                Ok(None) => {}
                Err(e) => {
                    log_error(&e);
                }
            }
        }
        Message::Interaction(Interaction::InstallSCMQuery(query)) => {
            // install from scm search query
            ajour.install_from_scm_state.query = Some(query);

            // Remove the status if it's an error and user typed into
            // text input
            {
                let install_addons = ajour
                    .install_addons
                    .entry(ajour.config.wow.flavor)
                    .or_default();

                if let Some((idx, install_addon)) = install_addons
                    .iter()
                    .enumerate()
                    .find(|(_, a)| a.kind == InstallKind::Source)
                {
                    if matches!(install_addon.status, InstallStatus::Error(_)) {
                        install_addons.remove(idx);
                    }
                }
            }
        }
        Message::Interaction(Interaction::InstallSCMURL) => {
            if let Some(url) = ajour.install_from_scm_state.query.clone() {
                if !url.is_empty() {
                    return handle_message(
                        ajour,
                        Message::Interaction(Interaction::InstallAddon(
                            ajour.config.wow.flavor,
                            url,
                            InstallKind::Source,
                        )),
                    );
                }
            }
        }
        Message::RefreshCatalog(_) => {
            if let Some(last_updated) = &ajour.catalog_last_updated {
                let now = Utc::now();
                let now_time = now.time();
                let refresh_time = NaiveTime::from_hms(0, 40, 0);

                if last_updated.date() < now.date() && now_time > refresh_time {
                    log::debug!("Message::RefreshCatalog: catalog needs to be refreshed");

                    return Ok(Command::perform(
                        catalog::get_catalog(),
                        Message::CatalogDownloaded,
                    ));
                }
            }
        }
        Message::Interaction(Interaction::ToggleHideIgnoredAddons(is_checked)) => {
            log::debug!("Interaction::ToggleHideIgnoredAddons({})", is_checked);

            ajour.config.hide_ignored_addons = is_checked;
            let _ = ajour.config.save();
        }
        Message::Interaction(Interaction::ToggleDeleteSavedVariables(is_checked)) => {
            log::debug!("Interaction::ToggleDeleteSavedVariables({})", is_checked);

            ajour.config.addons.delete_saved_variables = is_checked;
            let _ = ajour.config.save();
        }
        Message::CatalogDownloaded(error @ Err(_)) => {
            let error = error.wrap_err("Failed to download catalog").unwrap_err();
            log_error(&error);
            ajour.error = Some(error);
        }
        Message::AddonCacheUpdated(error @ Err(_)) => {
            let error = error.wrap_err("Failed to update addon cache").unwrap_err();
            log_error(&error);
            ajour.error = Some(error);
        }
        Message::Interaction(Interaction::PickSelfUpdateChannel(channel)) => {
            log::debug!("Interaction::PickSelfUpdateChannel({:?})", channel);

            ajour.config.self_update_channel = channel;

            let _ = ajour.config.save();

            return Ok(Command::perform(
                get_latest_release(ajour.config.self_update_channel),
                Message::LatestRelease,
            ));
        }
        Message::Interaction(Interaction::PickGlobalReleaseChannel(channel)) => {
            log::debug!("Interaction::PickGlobalReleaseChannel({:?})", channel);

            // Update all addon states, expect ignored, if needed.
            let flavors = &Flavor::ALL[..];
            for flavor in flavors {
                let ignored_ids = ajour.config.addons.ignored.entry(*flavor).or_default();
                let mut addons: Vec<_> = ajour
                    .addons
                    .entry(*flavor)
                    .or_default()
                    .iter_mut()
                    .filter(|a| !ignored_ids.iter().any(|i| i == &a.primary_folder_id))
                    .collect();
                for addon in addons.iter_mut() {
                    // Check if addon is updatable.
                    if let Some(package) = addon.relevant_release_package(channel) {
                        if addon.is_updatable(&package) {
                            addon.state = AddonState::Updatable;
                        } else {
                            addon.state = AddonState::Idle;
                        }
                    }
                }
            }

            ajour.config.addons.global_release_channel = channel;
            let _ = ajour.config.save();
        }
        Message::CheckLatestRelease(_) => {
            log::debug!("Message::CheckLatestRelease");

            return Ok(Command::perform(
                get_latest_release(ajour.config.self_update_channel),
                Message::LatestRelease,
            ));
        }
        Message::CheckWeakAurasInstalled((flavor, is_installed)) => {
            log::debug!(
                "Message::CheckWeakAurasInstalled({}, is_installed: {})",
                flavor,
                is_installed
            );

            if is_installed {
                ajour.weak_auras_is_installed = true;

                if let Some(wtf_folder) = ajour.config.get_wtf_directory_for_flavor(&flavor) {
                    return Ok(Command::perform(
                        list_accounts(flavor, wtf_folder),
                        Message::ListWeakAurasAccounts,
                    ));
                }
            }
        }
        Message::ListWeakAurasAccounts((flavor, result)) => match result {
            Ok(accounts) => {
                log::debug!(
                    "Message::ListWeakAurasAccounts({}, num_accounts: {})",
                    flavor,
                    accounts.len(),
                );

                let state = ajour.weak_auras_state.entry(flavor).or_default();
                state.accounts = accounts;

                // If we have an account already selected, use that as the picklist selection
                // and trigger a parse for this without user interaction
                if let Some(account) = ajour.config.weak_auras_account.get(&flavor) {
                    if let Some(wtf_path) = ajour.config.get_wtf_directory_for_flavor(&flavor) {
                        state.chosen_account = Some(account.clone());

                        return Ok(Command::perform(
                            parse_auras(flavor, wtf_path, account.clone()),
                            Message::ParsedAuras,
                        ));
                    }
                }
            }
            error @ Err(_) => {
                let error = error
                    .wrap_err("Failed to get list of Accounts")
                    .unwrap_err();

                log_error(&error);
                ajour.error = Some(error);
            }
        },
        Message::WeakAurasAccountSelected(account) => {
            log::debug!("Message::WeakAurasAccountSelected({})", &account,);

            if let Mode::MyWeakAuras(flavor) = ajour.mode {
                let state = ajour.weak_auras_state.entry(flavor).or_default();

                if state.chosen_account.as_ref() != Some(&account) {
                    state.chosen_account = Some(account.clone());

                    // Persist to config
                    ajour
                        .config
                        .weak_auras_account
                        .insert(flavor, account.clone());
                    let _ = ajour.config.save();

                    if let Some(wtf_path) = ajour.config.get_wtf_directory_for_flavor(&flavor) {
                        state.auras.drain(..);

                        // Prepare state for loading.
                        ajour
                            .state
                            .insert(Mode::MyWeakAuras(flavor), State::Loading);

                        return Ok(Command::perform(
                            parse_auras(flavor, wtf_path, account),
                            Message::ParsedAuras,
                        ));
                    }
                }
            }
        }
        Message::ParsedAuras((flavor, result)) => match result {
            Ok(mut auras) => {
                log::debug!(
                    "Message::ParsedAuras({}, num_auras: {})",
                    flavor,
                    auras.len(),
                );

                // Sort the addons.
                sort_auras(&mut auras, SortDirection::Desc, AuraColumnKey::Status);
                ajour.aura_header_state.previous_sort_direction = Some(SortDirection::Desc);
                ajour.aura_header_state.previous_column_key = Some(AuraColumnKey::Status);

                let state = ajour.weak_auras_state.entry(flavor).or_default();

                state.auras = auras;

                // Sets the flavor state to ready.
                ajour.state.insert(Mode::MyWeakAuras(flavor), State::Ready);
            }
            error @ Err(_) => {
                let error = error.wrap_err("Failed to parse WeakAuras").unwrap_err();

                log_error(&error);
                ajour.error = Some(error);
            }
        },
        Message::AurasUpdated((flavor, result)) => match result {
            Ok(slugs) => {
                log::debug!(
                    "Message::AurasUpdated({}, num_auras: {})",
                    flavor,
                    slugs.len(),
                );

                let state = ajour.weak_auras_state.entry(flavor).or_default();

                for slug in slugs.iter() {
                    if let Some(aura) = state.auras.iter_mut().find(|a| a.slug() == slug) {
                        aura.set_status(AuraStatus::UpdateQueued);
                    }
                }

                state.is_updating = false;
            }
            error @ Err(_) => {
                let error = error.wrap_err("Failed to update WeakAuras").unwrap_err();

                log_error(&error);
                ajour.error = Some(error);
            }
        },
        Message::Interaction(Interaction::AlternatingRowColorToggled(is_set)) => {
            log::debug!(
                "Interaction::AlternatingRowColorToggled(is_set: {})",
                is_set,
            );

            ajour.config.alternating_row_colors = is_set;
            let _ = ajour.config.save();
        }
        Message::Error(error) => {
            log_error(&error);
            ajour.error = Some(error);
        }
        Message::RuntimeEvent(iced_native::Event::Window(
            iced_native::window::Event::Resized { width, height },
        )) => {
            let width = (width as f64 * ajour.scale_state.scale) as u32;
            let height = (height as f64 * ajour.scale_state.scale) as u32;

            // Minimizing Ajour on Windows will call this function with 0, 0.
            // We don't want to save that in config, because then it will start with zero size.
            if width > 0 && height > 0 {
                ajour.config.window_size = Some((width, height));
                let _ = ajour.config.save();
            }
        }
        Message::RuntimeEvent(iced_native::Event::Keyboard(
            iced_native::keyboard::Event::KeyReleased { key_code, .. },
        )) => {
            if key_code == iced_native::keyboard::KeyCode::Escape
                && (ajour.mode == Mode::Settings || ajour.mode == Mode::About)
            {
                ajour.mode = Mode::MyAddons(ajour.config.wow.flavor);
            }
        }
        Message::RuntimeEvent(_) => {}
        Message::None(_) => {}
    }

    Ok(Command::none())
}

async fn select_directory() -> Option<PathBuf> {
    let dialog = OpenSingleDir { dir: None };
    if let Ok(show) = dialog.show() {
        return show;
    }

    None
}

async fn perform_read_addon_directory(
    addon_cache: Option<Arc<Mutex<AddonCache>>>,
    fingerprint_cache: Option<Arc<Mutex<FingerprintCache>>>,
    root_dir: PathBuf,
    flavor: Flavor,
) -> (Flavor, Result<Vec<Addon>, ParseError>) {
    (
        flavor,
        read_addon_directory(addon_cache, fingerprint_cache, root_dir, flavor).await,
    )
}

/// Downloads the newest version of the addon.
/// This is for now only downloading from warcraftinterface.
async fn perform_download_addon(
    reason: DownloadReason,
    flavor: Flavor,
    global_release_channel: GlobalReleaseChannel,
    addon: Addon,
    to_directory: PathBuf,
) -> (DownloadReason, Flavor, String, Result<(), DownloadError>) {
    (
        reason,
        flavor,
        addon.primary_folder_id.clone(),
        download_addon(&addon, global_release_channel, &to_directory).await,
    )
}

/// Rehashes a `Addon`.
async fn perform_hash_addon(
    addon_dir: impl AsRef<Path>,
    addon_id: String,
    fingerprint_cache: Arc<Mutex<FingerprintCache>>,
    flavor: Flavor,
) -> (Flavor, String, Result<(), ParseError>) {
    (
        flavor,
        addon_id.clone(),
        update_addon_fingerprint(fingerprint_cache, flavor, addon_dir, addon_id).await,
    )
}

/// Unzips `Addon` at given `from_directory` and moves it `to_directory`.
async fn perform_unpack_addon(
    reason: DownloadReason,
    flavor: Flavor,
    addon: Addon,
    from_directory: PathBuf,
    to_directory: PathBuf,
) -> (
    DownloadReason,
    Flavor,
    String,
    Result<Vec<AddonFolder>, FilesystemError>,
) {
    (
        reason,
        flavor,
        addon.primary_folder_id.clone(),
        install_addon(&addon, &from_directory, &to_directory).await,
    )
}

async fn perform_fetch_latest_addon(
    install_kind: InstallKind,
    id: String,
    flavor: Flavor,
) -> (Flavor, String, Result<Addon, RepositoryError>) {
    async fn fetch_latest_addon(
        flavor: Flavor,
        install_kind: InstallKind,
        id: String,
    ) -> Result<Addon, RepositoryError> {
        // Needed since id for source install is a URL and this id needs to be safe
        // when using as the temp path of the downloaded zip
        let mut hasher = DefaultHasher::new();
        hasher.write(format!("{:?}{}", install_kind, &id).as_bytes());
        let temp_id = hasher.finish();

        let mut addon = Addon::empty(&temp_id.to_string());

        let mut repo_package = match install_kind {
            InstallKind::Catalog { source } => {
                let kind = match source {
                    catalog::Source::Curse => RepositoryKind::Curse,
                    catalog::Source::Tukui => RepositoryKind::Tukui,
                    catalog::Source::WowI => RepositoryKind::WowI,
                };

                RepositoryPackage::from_repo_id(flavor, kind, id)?
            }
            InstallKind::Source => {
                let url = id
                    .parse::<Uri>()
                    .map_err(|_| RepositoryError::GitInvalidUrl { url: id.clone() })?;

                RepositoryPackage::from_source_url(flavor, url)?
            }
        };
        repo_package.resolve_metadata().await?;

        addon.set_repository(repo_package);

        Ok(addon)
    }

    (
        flavor,
        id.clone(),
        fetch_latest_addon(flavor, install_kind, id).await,
    )
}

async fn list_accounts(
    flavor: Flavor,
    wtf_path: PathBuf,
) -> (Flavor, Result<Vec<String>, ajour_weak_auras::Error>) {
    (flavor, ajour_weak_auras::list_accounts(&wtf_path).await)
}

async fn parse_auras(
    flavor: Flavor,
    wtf_path: PathBuf,
    account: String,
) -> (Flavor, Result<Vec<Aura>, ajour_weak_auras::Error>) {
    (
        flavor,
        ajour_weak_auras::parse_auras(wtf_path, account).await,
    )
}

async fn update_auras(
    flavor: Flavor,
    auras: Vec<Aura>,
    addon_dir: PathBuf,
) -> (Flavor, Result<Vec<String>, ajour_weak_auras::Error>) {
    async fn _update_auras(
        auras: Vec<Aura>,
        addon_dir: PathBuf,
    ) -> Result<Vec<String>, ajour_weak_auras::Error> {
        let updates = ajour_weak_auras::get_aura_updates(&auras).await?;

        ajour_weak_auras::write_updates(addon_dir, &updates).await
    }

    (flavor, _update_auras(auras, addon_dir).await)
}

async fn is_weak_auras_installed(flavor: Flavor, addon_dir: PathBuf) -> (Flavor, bool) {
    (
        flavor,
        ajour_weak_auras::is_weak_auras_installed(addon_dir).await,
    )
}

fn sort_addons(
    addons: &mut [Addon],
    global_release_channel: GlobalReleaseChannel,
    sort_direction: SortDirection,
    column_key: ColumnKey,
) {
    match (column_key, sort_direction) {
        (ColumnKey::Title, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.title().to_lowercase().cmp(&b.title().to_lowercase()));
        }
        (ColumnKey::Title, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.title()
                    .to_lowercase()
                    .cmp(&b.title().to_lowercase())
                    .reverse()
                    .then_with(|| {
                        a.relevant_release_package(global_release_channel)
                            .cmp(&b.relevant_release_package(global_release_channel))
                    })
            });
        }
        (ColumnKey::LocalVersion, SortDirection::Asc) => {
            addons.sort_by(|a, b| {
                a.version()
                    .cmp(&b.version())
                    .then_with(|| a.title().cmp(&b.title()))
            });
        }
        (ColumnKey::LocalVersion, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.version()
                    .cmp(&b.version())
                    .reverse()
                    .then_with(|| a.title().cmp(&b.title()))
            });
        }
        (ColumnKey::RemoteVersion, SortDirection::Asc) => {
            addons.sort_by(|a, b| {
                a.relevant_release_package(global_release_channel)
                    .cmp(&b.relevant_release_package(global_release_channel))
                    .then_with(|| a.cmp(&b))
            });
        }
        (ColumnKey::RemoteVersion, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.relevant_release_package(global_release_channel)
                    .cmp(&b.relevant_release_package(global_release_channel))
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
        (ColumnKey::Author, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.author().cmp(&b.author()))
        }
        (ColumnKey::Author, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.author().cmp(&b.author()).reverse())
        }
        (ColumnKey::GameVersion, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.game_version().cmp(&b.game_version()))
        }
        (ColumnKey::GameVersion, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.game_version().cmp(&b.game_version()).reverse())
        }
        (ColumnKey::DateReleased, SortDirection::Asc) => {
            addons.sort_by(|a, b| {
                a.relevant_release_package(global_release_channel)
                    .map(|p| p.date_time)
                    .cmp(
                        &b.relevant_release_package(global_release_channel)
                            .map(|p| p.date_time),
                    )
            });
        }
        (ColumnKey::DateReleased, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.relevant_release_package(global_release_channel)
                    .map(|p| p.date_time)
                    .cmp(
                        &b.relevant_release_package(global_release_channel)
                            .map(|p| p.date_time),
                    )
                    .reverse()
            });
        }
        (ColumnKey::Source, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.repository_kind().cmp(&b.repository_kind()))
        }
        (ColumnKey::Source, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.repository_kind().cmp(&b.repository_kind()).reverse())
        }
    }
}

fn sort_catalog_addons(
    addons: &mut [CatalogRow],
    sort_direction: SortDirection,
    column_key: CatalogColumnKey,
    flavor: &Flavor,
) {
    match (column_key, sort_direction) {
        (CatalogColumnKey::Title, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.addon.name.cmp(&b.addon.name));
        }
        (CatalogColumnKey::Title, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.addon.name.cmp(&b.addon.name).reverse());
        }
        (CatalogColumnKey::Description, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.addon.summary.cmp(&b.addon.summary));
        }
        (CatalogColumnKey::Description, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.addon.summary.cmp(&b.addon.summary).reverse());
        }
        (CatalogColumnKey::Source, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.addon.source.cmp(&b.addon.source));
        }
        (CatalogColumnKey::Source, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.addon.source.cmp(&b.addon.source).reverse());
        }
        (CatalogColumnKey::NumDownloads, SortDirection::Asc) => {
            addons.sort_by(|a, b| {
                a.addon
                    .number_of_downloads
                    .cmp(&b.addon.number_of_downloads)
            });
        }
        (CatalogColumnKey::NumDownloads, SortDirection::Desc) => {
            addons.sort_by(|a, b| {
                a.addon
                    .number_of_downloads
                    .cmp(&b.addon.number_of_downloads)
                    .reverse()
            });
        }
        (CatalogColumnKey::Install, SortDirection::Asc) => {}
        (CatalogColumnKey::Install, SortDirection::Desc) => {}
        (CatalogColumnKey::DateReleased, SortDirection::Asc) => {
            addons.sort_by(|a, b| a.addon.date_released.cmp(&b.addon.date_released));
        }
        (CatalogColumnKey::DateReleased, SortDirection::Desc) => {
            addons.sort_by(|a, b| a.addon.date_released.cmp(&b.addon.date_released).reverse());
        }
        (CatalogColumnKey::GameVersion, SortDirection::Asc) => addons.sort_by(|a, b| {
            let gv_a = a.addon.game_versions.iter().find(|gc| &gc.flavor == flavor);
            let gv_b = b.addon.game_versions.iter().find(|gc| &gc.flavor == flavor);
            gv_a.cmp(&gv_b)
        }),
        (CatalogColumnKey::GameVersion, SortDirection::Desc) => addons.sort_by(|a, b| {
            let gv_a = a.addon.game_versions.iter().find(|gc| &gc.flavor == flavor);
            let gv_b = b.addon.game_versions.iter().find(|gc| &gc.flavor == flavor);
            gv_a.cmp(&gv_b).reverse()
        }),
    }
}

fn sort_auras(auras: &mut [Aura], sort_direction: SortDirection, column_key: AuraColumnKey) {
    match (column_key, sort_direction) {
        (AuraColumnKey::Title, SortDirection::Asc) => {
            auras.sort_by(|a, b| a.name().to_lowercase().cmp(&b.name().to_lowercase()));
        }
        (AuraColumnKey::Title, SortDirection::Desc) => {
            auras.sort_by(|a, b| {
                a.name()
                    .to_lowercase()
                    .cmp(&b.name().to_lowercase())
                    .reverse()
            });
        }
        (AuraColumnKey::LocalVersion, SortDirection::Asc) => {
            auras.sort_by(|a, b| {
                a.installed_symver()
                    .cmp(&b.installed_symver())
                    .then_with(|| a.name().cmp(&b.name()))
            });
        }
        (AuraColumnKey::LocalVersion, SortDirection::Desc) => {
            auras.sort_by(|a, b| {
                a.installed_symver()
                    .cmp(&b.installed_symver())
                    .reverse()
                    .then_with(|| a.name().cmp(&b.name()))
            });
        }
        (AuraColumnKey::RemoteVersion, SortDirection::Asc) => {
            auras.sort_by(|a, b| {
                a.remote_symver()
                    .cmp(&b.remote_symver())
                    .then_with(|| a.name().cmp(&b.name()))
            });
        }
        (AuraColumnKey::RemoteVersion, SortDirection::Desc) => {
            auras.sort_by(|a, b| {
                a.remote_symver()
                    .cmp(&b.remote_symver())
                    .reverse()
                    .then_with(|| a.name().cmp(&b.name()))
            });
        }
        (AuraColumnKey::Author, SortDirection::Asc) => {
            auras.sort_by(|a, b| a.author().cmp(&b.author()))
        }
        (AuraColumnKey::Author, SortDirection::Desc) => {
            auras.sort_by(|a, b| a.author().cmp(&b.author()).reverse())
        }
        // TODO: Add status and sort
        (AuraColumnKey::Status, SortDirection::Asc) => auras.sort_by(|a, b| {
            a.status()
                .cmp(&b.status())
                .then_with(|| a.name().to_lowercase().cmp(&b.name().to_lowercase()))
        }),
        (AuraColumnKey::Status, SortDirection::Desc) => auras.sort_by(|a, b| {
            a.status()
                .cmp(&b.status())
                .reverse()
                .then_with(|| a.name().to_lowercase().cmp(&b.name().to_lowercase()))
        }),
    }
}

fn query_and_sort_catalog(ajour: &mut Ajour) {
    if let Some(catalog) = &ajour.catalog {
        let query = ajour
            .catalog_search_state
            .query
            .as_ref()
            .map(|s| s.to_lowercase());
        let flavor = &ajour.config.wow.flavor;
        let source = &ajour.catalog_search_state.source;
        let category = &ajour.catalog_search_state.category;
        let result_size = ajour.catalog_search_state.result_size.as_usize();

        // Use default, can tweak if needed in future
        let fuzzy_match_config = SkimScoreConfig {
            ..Default::default()
        };
        let fuzzy_matcher = SkimMatcherV2::default().score_config(fuzzy_match_config);

        let mut catalog_rows_and_score = catalog
            .addons
            .iter()
            .filter(|a| !a.game_versions.is_empty())
            .filter_map(|a| {
                let title_and_summary = format!("{} {}", a.name, a.summary);

                if let Some(query) = &query {
                    if let Some(score) = fuzzy_matcher.fuzzy_match(&title_and_summary, &query) {
                        Some((a, score))
                    } else {
                        None
                    }
                } else {
                    Some((a, 0))
                }
            })
            .filter(|(a, _)| {
                a.game_versions
                    .iter()
                    .any(|gc| gc.flavor == flavor.base_flavor())
            })
            .filter(|(a, _)| match source {
                CatalogSource::Choice(source) => a.source == *source,
            })
            .filter(|(a, _)| match category {
                CatalogCategory::All => true,
                CatalogCategory::Choice(name) => a.categories.iter().any(|c| c == name),
            })
            .map(|(a, score)| (CatalogRow::from(a.clone()), score))
            .collect::<Vec<_>>();

        let mut catalog_rows = if query.is_some() {
            // If a query is defined, the default sort is the fuzzy match score
            catalog_rows_and_score.sort_by(|(addon_a, score_a), (addon_b, score_b)| {
                score_a.cmp(&score_b).reverse().then_with(|| {
                    addon_a
                        .addon
                        .number_of_downloads
                        .cmp(&addon_b.addon.number_of_downloads)
                        .reverse()
                })
            });

            catalog_rows_and_score
                .into_iter()
                .map(|(a, _)| a)
                .collect::<Vec<_>>()
        } else {
            catalog_rows_and_score
                .into_iter()
                .map(|(a, _)| a)
                .collect::<Vec<_>>()
        };

        // If no query is defined, use the column sorting configuration or default
        // sort of NumDownloads DESC.
        //
        // If a query IS defined, only sort if column has been sorted after query
        // has been typed. Sort direction / key are set to None anytime a character
        // is typed into the query box so results will sort by fuzzy match score.
        // Therefore they'll only be Some if the columns are sorted after the query
        // is input.
        if query.is_none()
            || (ajour.catalog_header_state.previous_sort_direction.is_some()
                && ajour.catalog_header_state.previous_column_key.is_some())
        {
            let sort_direction = ajour
                .catalog_header_state
                .previous_sort_direction
                .unwrap_or(SortDirection::Desc);
            let column_key = ajour
                .catalog_header_state
                .previous_column_key
                .unwrap_or(CatalogColumnKey::NumDownloads);

            sort_catalog_addons(&mut catalog_rows, sort_direction, column_key, flavor);
        }

        catalog_rows = catalog_rows
            .into_iter()
            .enumerate()
            .filter_map(|(idx, row)| if idx < result_size { Some(row) } else { None })
            .collect();

        ajour.catalog_search_state.catalog_rows = catalog_rows;
    }
}

fn save_column_configs(ajour: &mut Ajour) {
    let my_addons_columns: Vec<_> = ajour
        .header_state
        .columns
        .iter()
        .map(ColumnConfigV2::from)
        .collect();

    let catalog_columns: Vec<_> = ajour
        .catalog_header_state
        .columns
        .iter()
        .map(ColumnConfigV2::from)
        .collect();

    let aura_columns: Vec<_> = ajour
        .aura_header_state
        .columns
        .iter()
        .map(ColumnConfigV2::from)
        .collect();

    ajour.config.column_config = ColumnConfig::V3 {
        my_addons_columns,
        catalog_columns,
        aura_columns,
    };

    let _ = ajour.config.save();
}

/// Hardcoded binary names for each compilation target
/// that gets published to the Github Release
const fn bin_name() -> &'static str {
    #[cfg(all(target_os = "windows", feature = "opengl"))]
    {
        "ajour-opengl.exe"
    }

    #[cfg(all(target_os = "windows", feature = "wgpu"))]
    {
        "ajour.exe"
    }

    #[cfg(all(target_os = "macos", feature = "opengl"))]
    {
        "ajour-opengl"
    }

    #[cfg(all(target_os = "macos", feature = "wgpu"))]
    {
        "ajour"
    }

    #[cfg(all(target_os = "linux", feature = "opengl"))]
    {
        "ajour-opengl.AppImage"
    }

    #[cfg(all(target_os = "linux", feature = "wgpu"))]
    {
        "ajour.AppImage"
    }
}
