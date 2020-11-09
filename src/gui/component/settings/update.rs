use {
    super::{Interaction, Message},
    crate::gui::{self, update::save_column_configs, Ajour, CatalogColumnKey, ColumnKey},
    ajour_core::{
        backup::{backup_folders, BackupFolder},
        config::Flavor,
        fs::PersistentData,
        Result,
    },
    iced::Command,
};

pub fn update(ajour: &mut Ajour, message: Message) -> Result<Command<gui::Message>> {
    match message {
        Message::Interaction(Interaction::ThemeSelected(theme_name)) => {
            log::debug!("Message::ThemeSelected({:?})", &theme_name);

            ajour.theme_state.current_theme_name = theme_name.clone();

            ajour.config.theme = Some(theme_name);
            let _ = ajour.config.save();
        }
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
                gui::Message::BackupFinished,
            ));
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
    }

    Ok(Command::none())
}
