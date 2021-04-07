#![allow(clippy::too_many_arguments)]

use ajour_core::repository::CompressionFormat;

use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_HEADER_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{
        style, BackupFolderKind, BackupState, CatalogColumnKey, CatalogColumnSettings, ColumnKey,
        ColumnSettings, GlobalReleaseChannel, Interaction, Language, Message, ScaleState,
        SelfUpdateChannelState, ThemeState, WowDirectoryState,
    },
    crate::localization::localized_string,
    ajour_core::{config::Config, theme::ColorPalette},
    iced::{
        button, pick_list, scrollable, Align, Button, Checkbox, Column, Container, Element, Length,
        PickList, Row, Scrollable, Space, Text, VerticalAlignment,
    },
    std::collections::HashMap,
    strfmt::strfmt,
};

pub fn data_container<'a, 'b>(
    color_palette: ColorPalette,
    scrollable_state: &'a mut scrollable::State,
    config: &Config,
    theme_state: &'a mut ThemeState,
    scale_state: &'a mut ScaleState,
    backup_state: &'a mut BackupState,
    default_backup_compression_format: &'a mut pick_list::State<CompressionFormat>,
    column_settings: &'a mut ColumnSettings,
    column_config: &'b [(ColumnKey, Length, bool)],
    catalog_column_settings: &'a mut CatalogColumnSettings,
    catalog_column_config: &'b [(CatalogColumnKey, Length, bool)],
    open_config_dir_button_state: &'a mut button::State,
    self_update_channel_state: &'a mut SelfUpdateChannelState,
    default_addon_release_channel_picklist_state: &'a mut pick_list::State<GlobalReleaseChannel>,
    reset_columns_button_state: &'a mut button::State,
    localization_picklist_state: &'a mut pick_list::State<Language>,
    wow_directories: &'a mut Vec<WowDirectoryState>,
) -> Container<'a, Message> {
    let mut scrollable = Scrollable::new(scrollable_state)
        .spacing(1)
        .height(Length::FillPortion(1))
        .style(style::Scrollable(color_palette));

    let wow_directory_column = {
        let mut wow_dir_column = Column::new();
        for wow_dir_state in wow_directories {
            let flavor = wow_dir_state.flavor;
            let path_str = config
                .wow
                .directories
                .get(&flavor)
                .map(|p| p.to_str())
                .flatten()
                .unwrap_or("-");
            let flavor_text = Text::new(flavor.to_string())
                .size(14)
                .vertical_alignment(VerticalAlignment::Center);
            let flavor_text_container = Container::new(flavor_text)
                .width(Length::Units(75))
                .center_y();
            let flavor_button: Element<Interaction> =
                Button::new(&mut wow_dir_state.button_state, flavor_text_container)
                    .style(style::DefaultButton(color_palette))
                    .on_press(Interaction::SelectWowDirectory(Some(flavor)))
                    .into();
            let path_text = Text::new(path_str)
                .size(14)
                .vertical_alignment(VerticalAlignment::Center);
            let path_text_container = Container::new(path_text)
                .height(Length::Units(25))
                .center_y()
                .style(style::NormalBackgroundContainer(color_palette));
            let flavor_row = Row::new()
                .push(flavor_button.map(Message::Interaction))
                .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                .push(path_text_container);

            wow_dir_column = wow_dir_column.push(flavor_row);
        }

        wow_dir_column
    };

    let theme_column = {
        let title_container =
            Container::new(Text::new(localized_string("theme")).size(DEFAULT_FONT_SIZE))
                .style(style::NormalBackgroundContainer(color_palette));

        let theme_names = theme_state
            .themes
            .iter()
            .cloned()
            .map(|(name, _)| name)
            .collect::<Vec<_>>();
        let theme_pick_list = PickList::new(
            &mut theme_state.pick_list_state,
            theme_names,
            Some(theme_state.current_theme_name.clone()),
            Message::ThemeSelected,
        )
        .text_size(DEFAULT_FONT_SIZE)
        .width(Length::Units(120))
        .style(style::PickList(color_palette));

        // Data row for theme picker list.
        let theme_data_row = Row::new()
            .push(theme_pick_list)
            .align_items(Align::Center)
            .height(Length::Units(26));

        Column::new()
            .push(title_container)
            .push(Space::new(Length::Units(0), Length::Units(5)))
            .push(theme_data_row)
    };

    // Scale buttons for application scale factoring.
    let scale_column = {
        let title_container =
            Container::new(Text::new(localized_string("scale")).size(DEFAULT_FONT_SIZE))
                .style(style::NormalBackgroundContainer(color_palette));
        let scale_title_row = Row::new().push(title_container);

        let scale_down_button: Element<Interaction> = Button::new(
            &mut scale_state.down_btn_state,
            Text::new("  -  ").size(DEFAULT_FONT_SIZE),
        )
        .style(style::DefaultBoxedButton(color_palette))
        .on_press(Interaction::ScaleDown)
        .into();

        let scale_up_button: Element<Interaction> = Button::new(
            &mut scale_state.up_btn_state,
            Text::new("  +  ").size(DEFAULT_FONT_SIZE),
        )
        .style(style::DefaultBoxedButton(color_palette))
        .on_press(Interaction::ScaleUp)
        .into();

        let current_scale_text = Text::new(format!("  {:.2}  ", scale_state.scale))
            .size(DEFAULT_FONT_SIZE)
            .vertical_alignment(VerticalAlignment::Center);
        let current_scale_container = Container::new(current_scale_text)
            .height(Length::Fill)
            .center_y()
            .style(style::BrightBackgroundContainer(color_palette));

        // Data row for the World of Warcraft directory selection.
        let scale_buttons_row = Row::new()
            .push(scale_down_button.map(Message::Interaction))
            .push(current_scale_container)
            .push(scale_up_button.map(Message::Interaction))
            .align_items(Align::Center)
            .height(Length::Units(26));

        Column::new()
            .push(scale_title_row)
            .push(Space::new(Length::Units(0), Length::Units(5)))
            .push(scale_buttons_row)
    };

    let (backup_title_row, backup_directory_row, backup_now_row) = {
        // Title for the Backup section.
        let backup_title_text =
            Text::new(localized_string("backup")).size(DEFAULT_HEADER_FONT_SIZE);
        let backup_title_text_container = Container::new(backup_title_text)
            .style(style::BrightBackgroundContainer(color_palette));

        let checkbox_title = &localized_string("addons")[..];
        let addon_folder_checkbox: Element<_> = Container::new(
            Checkbox::new(config.backup_addons, checkbox_title, move |is_checked| {
                Interaction::ToggleBackupFolder(is_checked, BackupFolderKind::AddOns)
            })
            .text_size(DEFAULT_FONT_SIZE)
            .spacing(5)
            .style(style::DefaultCheckbox(color_palette)),
        )
        .style(style::BrightBackgroundContainer(color_palette))
        .into();

        let checkbox_title = &localized_string("wtf")[..];
        let wtf_folder_checkbox: Element<_> = Container::new(
            Checkbox::new(config.backup_wtf, checkbox_title, move |is_checked| {
                Interaction::ToggleBackupFolder(is_checked, BackupFolderKind::WTF)
            })
            .text_size(DEFAULT_FONT_SIZE)
            .spacing(5)
            .style(style::DefaultCheckbox(color_palette)),
        )
        .style(style::BrightBackgroundContainer(color_palette))
        .into();

        let backup_compr_fmt_pick_list: Element<_> = PickList::new(
            default_backup_compression_format,
            &CompressionFormat::ALL[..],
            Some(config.compression_format),
            Interaction::PickBackupCompressionFormat,
        )
        .text_size(14)
        .width(Length::Units(64))
        .style(style::PickList(color_palette))
        .into();

        // Directory button for Backup directory selection.
        let directory_button_title_container =
            Container::new(Text::new(localized_string("select-directory")).size(DEFAULT_FONT_SIZE))
                .width(Length::FillPortion(1))
                .center_x()
                .align_x(Align::Center);
        let directory_button: Element<Interaction> = Button::new(
            &mut backup_state.directory_btn_state,
            directory_button_title_container,
        )
        .style(style::DefaultBoxedButton(color_palette))
        .on_press(Interaction::SelectBackupDirectory())
        .into();

        // Directory text, written next to directory button to let the user
        // know what has been selected.
        let no_directory_str = &localized_string("no-directory")[..];
        let path_str = config
            .backup_directory
            .as_ref()
            .and_then(|p| p.to_str())
            .unwrap_or(no_directory_str);
        let directory_data_text = Text::new(path_str)
            .size(DEFAULT_FONT_SIZE)
            .vertical_alignment(VerticalAlignment::Center);
        let directory_data_text_container = Container::new(directory_data_text)
            .center_y()
            .style(style::NormalBackgroundContainer(color_palette));

        // Data row for the Backup directory selection.
        let backup_directory_row = Row::new()
            .align_items(Align::Center)
            .push(addon_folder_checkbox.map(Message::Interaction))
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
            .push(wtf_folder_checkbox.map(Message::Interaction))
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
            .push(backup_compr_fmt_pick_list.map(Message::Interaction))
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
            .push(directory_button.map(Message::Interaction))
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
            .push(directory_data_text_container);

        // Row to show actual backup button along with info about the latest
        // backup date/time. Will give a description of what Backup is when no
        // directory is chosen
        let mut backup_now_row = Row::new();

        // Show button / last backup info if directory is shown, otherwise
        // show description about the backup process
        if config.backup_directory.is_some() {
            let backup_button_title_container =
                Container::new(Text::new(localized_string("backup-now")).size(DEFAULT_FONT_SIZE))
                    .width(Length::FillPortion(1))
                    .center_x()
                    .align_x(Align::Center);
            let mut backup_button = Button::new(
                &mut backup_state.backup_now_btn_state,
                backup_button_title_container,
            )
            .style(style::DefaultBoxedButton(color_palette));

            // Only show button as clickable if it's not currently backing up and
            // the wow folder is chosen and at least one of the folders is selected
            // for backup
            if !backup_state.backing_up
                && config.wow.directories.keys().next().is_some()
                && (config.backup_addons || config.backup_wtf)
            {
                backup_button = backup_button.on_press(Interaction::Backup);
            }

            let backup_status_text = if backup_state.backing_up {
                Text::new(localized_string("backup-progress"))
                    .size(DEFAULT_FONT_SIZE)
                    .vertical_alignment(VerticalAlignment::Center)
            } else {
                let as_of = backup_state
                    .last_backup
                    .map(|d| d.format("%Y-%m-%d %H:%M:%S").to_string())
                    .unwrap_or_else(|| localized_string("backup-never"));

                let mut vars = HashMap::new();
                vars.insert("time".to_string(), &as_of);
                let fmt = localized_string("backup-latest");

                Text::new(strfmt(&fmt, &vars).unwrap())
                    .size(DEFAULT_FONT_SIZE)
                    .vertical_alignment(VerticalAlignment::Center)
            };

            let backup_status_text_container = Container::new(backup_status_text)
                .center_y()
                .height(Length::Units(25))
                .style(style::NormalBackgroundContainer(color_palette));

            let backup_button: Element<Interaction> = backup_button.into();

            backup_now_row = backup_now_row
                .push(backup_button.map(Message::Interaction))
                .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                .push(backup_status_text_container);
        } else {
            let backup_status_text = Text::new(localized_string("backup-description"))
                .size(DEFAULT_FONT_SIZE)
                .vertical_alignment(VerticalAlignment::Center);

            let backup_status_text_container = Container::new(backup_status_text)
                .center_y()
                .style(style::NormalBackgroundContainer(color_palette));

            backup_now_row = backup_now_row.push(backup_status_text_container);
        }

        (
            backup_title_text_container,
            backup_directory_row,
            backup_now_row,
        )
    };

    let auto_update_column = {
        let auto_update = config.auto_update;
        let checkbox = Checkbox::new(
            auto_update,
            localized_string("auto-update"),
            move |is_checked| Message::Interaction(Interaction::ToggleAutoUpdateAddons(is_checked)),
        )
        .style(style::DefaultCheckbox(color_palette))
        .text_size(DEFAULT_FONT_SIZE)
        .spacing(5);
        let checkbox_container =
            Container::new(checkbox).style(style::NormalBackgroundContainer(color_palette));
        Column::new().push(checkbox_container)
    };

    let hide_addons_column = {
        let hide_ignored_addons = config.hide_ignored_addons;
        let checkbox = Checkbox::new(
            hide_ignored_addons,
            localized_string("hide-addons"),
            move |is_checked| {
                Message::Interaction(Interaction::ToggleHideIgnoredAddons(is_checked))
            },
        )
        .style(style::DefaultCheckbox(color_palette))
        .text_size(DEFAULT_FONT_SIZE)
        .spacing(5);
        let checkbox_container =
            Container::new(checkbox).style(style::NormalBackgroundContainer(color_palette));
        Column::new().push(checkbox_container)
    };

    let delete_saved_variables_column = {
        let delete_saved_variables = config.addons.delete_saved_variables;
        let checkbox = Checkbox::new(
            delete_saved_variables,
            localized_string("delete-saved-variables"),
            move |is_checked| {
                Message::Interaction(Interaction::ToggleDeleteSavedVariables(is_checked))
            },
        )
        .style(style::DefaultCheckbox(color_palette))
        .text_size(DEFAULT_FONT_SIZE)
        .spacing(5);
        let checkbox_container =
            Container::new(checkbox).style(style::NormalBackgroundContainer(color_palette));
        Column::new().push(checkbox_container)
    };

    let global_release_channel_column = {
        let title_container = Container::new(
            Text::new(localized_string("global-release-channel")).size(DEFAULT_FONT_SIZE),
        )
        .style(style::NormalBackgroundContainer(color_palette));

        let pick_list: Element<_> = PickList::new(
            default_addon_release_channel_picklist_state,
            &GlobalReleaseChannel::ALL[..],
            Some(config.addons.global_release_channel),
            Interaction::PickGlobalReleaseChannel,
        )
        .text_size(14)
        .width(Length::Units(120))
        .style(style::PickList(color_palette))
        .into();

        // Data row for release channel picker list.
        let data_row = Row::new().push(pick_list.map(Message::Interaction));

        Column::new()
            .push(title_container)
            .push(Space::new(Length::Units(0), Length::Units(5)))
            .push(data_row)
    };

    let config_column = {
        let config_dir = ajour_core::fs::config_dir();
        let config_dir_string = config_dir.as_path().display().to_string();

        let open_config_button_title_container = Container::new(
            Text::new(localized_string("open-data-directory")).size(DEFAULT_FONT_SIZE),
        )
        .center_x()
        .align_x(Align::Center);
        let open_config_button: Element<Interaction> = Button::new(
            open_config_dir_button_state,
            open_config_button_title_container,
        )
        .style(style::DefaultBoxedButton(color_palette))
        .on_press(Interaction::OpenDirectory(config_dir))
        .into();

        let open_config_description = Text::new(config_dir_string)
            .size(DEFAULT_FONT_SIZE)
            .vertical_alignment(VerticalAlignment::Center);
        let open_config_description_container = Container::new(open_config_description)
            .height(Length::Units(25))
            .center_y()
            .style(style::NormalBackgroundContainer(color_palette));

        let open_config_row = Row::new()
            .push(open_config_button.map(Message::Interaction))
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
            .push(open_config_description_container);

        Column::new().push(open_config_row)
    };

    let addon_title = Text::new(localized_string("addons")).size(DEFAULT_HEADER_FONT_SIZE);
    let addon_title_container =
        Container::new(addon_title).style(style::BrightBackgroundContainer(color_palette));

    let general_settings_title =
        Text::new(localized_string("settings-general")).size(DEFAULT_HEADER_FONT_SIZE);
    let general_settings_title_container = Container::new(general_settings_title)
        .style(style::BrightBackgroundContainer(color_palette));

    let directories_settings_title =
        Text::new(localized_string("wow-directories")).size(DEFAULT_HEADER_FONT_SIZE);
    let directories_settings_title_container = Container::new(directories_settings_title)
        .style(style::BrightBackgroundContainer(color_palette));

    let theme_scale_row = Row::new()
        .push(theme_column)
        .push(scale_column)
        .spacing(DEFAULT_PADDING);

    let alternate_row_color_column = {
        let checkbox = Checkbox::new(
            config.alternating_row_colors,
            localized_string("alternate-row-colors"),
            Interaction::AlternatingRowColorToggled,
        )
        .style(style::DefaultCheckbox(color_palette))
        .text_size(DEFAULT_FONT_SIZE)
        .spacing(5);

        let checkbox: Element<Interaction> = checkbox.into();

        let checkbox_container = Container::new(checkbox.map(Message::Interaction))
            .style(style::NormalBackgroundContainer(color_palette));
        Column::new().push(checkbox_container)
    };

    let self_update_channel_container = {
        let channel_title = Container::new(
            Text::new(localized_string("ajour-update-channel")).size(DEFAULT_FONT_SIZE),
        )
        .style(style::NormalBackgroundContainer(color_palette));
        let channel_picklist: Element<_> = PickList::new(
            &mut self_update_channel_state.picklist,
            &self_update_channel_state.options[..],
            Some(config.self_update_channel),
            Interaction::PickSelfUpdateChannel,
        )
        .text_size(14)
        .width(Length::Fill)
        .style(style::PickList(color_palette))
        .into();

        let channel_container = Container::new(channel_picklist.map(Message::Interaction))
            .center_y()
            .width(Length::Units(120))
            .style(style::NormalForegroundContainer(color_palette));

        Column::new()
            .push(channel_title)
            .push(Space::new(Length::Units(0), Length::Units(5)))
            .push(channel_container)
    };

    let language_container = {
        let title = Container::new(Text::new(localized_string("language")).size(DEFAULT_FONT_SIZE))
            .style(style::NormalBackgroundContainer(color_palette));
        let pick_list: Element<_> = PickList::new(
            localization_picklist_state,
            &Language::ALL[..],
            Some(config.language),
            Interaction::PickLocalizationLanguage,
        )
        .text_size(14)
        .width(Length::Units(120))
        .style(style::PickList(color_palette))
        .into();
        let container = Container::new(pick_list.map(Message::Interaction))
            .center_y()
            .width(Length::Units(120))
            .style(style::NormalForegroundContainer(color_palette));

        Column::new()
            .push(title)
            .push(Space::new(Length::Units(0), Length::Units(5)))
            .push(container)
    };

    #[cfg(target_os = "windows")]
    let close_to_tray_column = {
        let checkbox = Checkbox::new(
            config.close_to_tray,
            localized_string("close-to-tray"),
            Interaction::ToggleCloseToTray,
        )
        .style(style::DefaultCheckbox(color_palette))
        .text_size(DEFAULT_FONT_SIZE)
        .spacing(5);

        let checkbox: Element<Interaction> = checkbox.into();

        let checkbox_container = Container::new(checkbox.map(Message::Interaction))
            .style(style::NormalBackgroundContainer(color_palette));
        Column::new().push(checkbox_container)
    };

    // General
    scrollable = scrollable
        .push(general_settings_title_container)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(language_container)
        .push(Space::new(Length::Units(0), Length::Units(10)))
        .push(theme_scale_row)
        .push(Space::new(Length::Units(0), Length::Units(10)))
        .push(alternate_row_color_column)
        .push(Space::new(Length::Units(0), Length::Units(10)))
        .push(self_update_channel_container)
        .push(Space::new(Length::Units(0), Length::Units(10)))
        .push(config_column);

    #[cfg(target_os = "windows")]
    {
        scrollable = scrollable
            .push(Space::new(Length::Units(0), Length::Units(10)))
            .push(close_to_tray_column)
    }

    scrollable = scrollable.push(Space::new(Length::Units(0), Length::Units(30)));

    // Directories
    scrollable = scrollable
        .push(directories_settings_title_container)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(wow_directory_column)
        .push(Space::new(Length::Units(0), Length::Units(20)));

    // Backup
    scrollable = scrollable
        .push(backup_title_row)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(backup_now_row)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(backup_directory_row)
        .push(Space::new(Length::Units(0), Length::Units(30)));

    // Addons
    scrollable = scrollable
        .push(addon_title_container)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(global_release_channel_column)
        .push(Space::new(Length::Units(0), Length::Units(10)))
        .push(hide_addons_column)
        .push(Space::new(Length::Units(0), Length::Units(10)))
        .push(delete_saved_variables_column)
        .push(Space::new(Length::Units(0), Length::Units(10)))
        .push(auto_update_column);

    let columns_title_text = Text::new(localized_string("columns")).size(DEFAULT_HEADER_FONT_SIZE);
    let columns_title_text_container =
        Container::new(columns_title_text).style(style::BrightBackgroundContainer(color_palette));
    scrollable = scrollable
        .push(Space::new(Length::Units(0), Length::Units(30)))
        .push(columns_title_text_container);

    let my_addons_columns_container = {
        let title_container =
            Container::new(Text::new(localized_string("my-addons")).size(DEFAULT_FONT_SIZE))
                .style(style::NormalBackgroundContainer(color_palette));
        let mut my_addons_column = Column::new()
            .push(title_container)
            .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)));

        // Add each column to scrollable as checkbox + label + up / down buttons
        let columns_len = column_settings.columns.len();
        for (idx, column) in column_settings.columns.iter_mut().enumerate() {
            let is_first = idx == 0;
            let is_last = idx == columns_len - 1;

            let title = column.key.title();

            let column_key = column.key;

            let is_checked = column_config
                .iter()
                .any(|(key, _, hidden)| key == &column.key && !hidden)
                || column_key == ColumnKey::Title;

            let mut left_button = Button::new(
                &mut column.up_btn_state,
                Text::new(" ▲ ").size(11).color(if !is_first {
                    color_palette.bright.primary
                } else {
                    color_palette.normal.primary
                }),
            )
            .style(style::DefaultButton(color_palette));
            if !is_first {
                left_button = left_button.on_press(Interaction::MoveColumnLeft(column_key));
            }

            let mut right_button = Button::new(
                &mut column.down_btn_state,
                Text::new(" ▼ ").size(11).color(if !is_last {
                    color_palette.bright.primary
                } else {
                    color_palette.normal.primary
                }),
            )
            .style(style::DefaultButton(color_palette));
            if !is_last {
                right_button = right_button.on_press(Interaction::MoveColumnRight(column_key));
            }

            let left_button: Element<Interaction> = left_button.into();
            let right_button: Element<Interaction> = right_button.into();

            let left_button_container = Container::new(left_button.map(Message::Interaction))
                .center_x()
                .center_y();
            let right_button_container = Container::new(right_button.map(Message::Interaction))
                .center_x()
                .center_y();

            let mut checkbox = Checkbox::new(is_checked, title.clone(), move |is_checked| {
                Message::Interaction(Interaction::ToggleColumn(is_checked, column_key))
            })
            .text_size(DEFAULT_FONT_SIZE)
            .spacing(5);

            if column_key == ColumnKey::Title {
                checkbox = checkbox.style(style::AlwaysCheckedCheckbox(color_palette));
            } else {
                checkbox = checkbox.style(style::DefaultCheckbox(color_palette));
            }

            let checkbox_container =
                Container::new(checkbox).style(style::BrightBackgroundContainer(color_palette));

            let row = Row::new()
                .align_items(Align::Center)
                .height(Length::Units(26))
                .push(left_button_container)
                .push(right_button_container)
                .push(checkbox_container);

            my_addons_column = my_addons_column.push(row);
        }

        Container::new(my_addons_column)
    };

    let catalog_columns_container = {
        // Title for the Columns section.

        let title_container =
            Container::new(Text::new(localized_string("catalog")).size(DEFAULT_FONT_SIZE))
                .style(style::NormalBackgroundContainer(color_palette));
        let mut catalog_column = Column::new()
            .push(title_container)
            .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)));

        // Add each column to scrollable as checkbox + label + up / down buttons
        let columns_len = catalog_column_settings.columns.len();
        for (idx, column) in catalog_column_settings.columns.iter_mut().enumerate() {
            let is_first = idx == 0;
            let is_last = idx == columns_len - 1;

            let title = column.key.title();

            let column_key = column.key;

            let is_checked = catalog_column_config
                .iter()
                .any(|(key, _, hidden)| key == &column.key && !hidden)
                || column_key == CatalogColumnKey::Title;

            let mut left_button = Button::new(
                &mut column.up_btn_state,
                Text::new(" ▲  ").size(11).color(if !is_first {
                    color_palette.bright.primary
                } else {
                    color_palette.normal.primary
                }),
            )
            .style(style::DefaultButton(color_palette));
            if !is_first {
                left_button = left_button.on_press(Interaction::MoveCatalogColumnLeft(column_key));
            }

            let mut right_button = Button::new(
                &mut column.down_btn_state,
                Text::new(" ▼  ").size(11).color(if !is_last {
                    color_palette.bright.primary
                } else {
                    color_palette.normal.primary
                }),
            )
            .style(style::DefaultButton(color_palette));
            if !is_last {
                right_button =
                    right_button.on_press(Interaction::MoveCatalogColumnRight(column_key));
            }

            let left_button: Element<Interaction> = left_button.into();
            let right_button: Element<Interaction> = right_button.into();

            let left_button_container = Container::new(left_button.map(Message::Interaction))
                .center_x()
                .center_y();
            let right_button_container = Container::new(right_button.map(Message::Interaction))
                .center_x()
                .center_y();

            let mut checkbox = Checkbox::new(is_checked, title.clone(), move |is_checked| {
                Message::Interaction(Interaction::ToggleCatalogColumn(is_checked, column_key))
            })
            .text_size(DEFAULT_FONT_SIZE)
            .spacing(5);

            if column_key == CatalogColumnKey::Title {
                checkbox = checkbox.style(style::AlwaysCheckedCheckbox(color_palette));
            } else {
                checkbox = checkbox.style(style::DefaultCheckbox(color_palette));
            }

            let checkbox_container =
                Container::new(checkbox).style(style::BrightBackgroundContainer(color_palette));

            let row = Row::new()
                .align_items(Align::Center)
                .height(Length::Units(26))
                .push(left_button_container)
                .push(right_button_container)
                .push(checkbox_container);

            catalog_column = catalog_column.push(row);
        }

        Container::new(catalog_column)
    };

    let catalog_rows = Row::new()
        .push(my_addons_columns_container)
        .push(catalog_columns_container)
        .spacing(DEFAULT_PADDING);

    scrollable = scrollable
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(catalog_rows);

    // Reset columns button
    let reset_columns_button_title_container =
        Container::new(Text::new(localized_string("reset-columns")).size(DEFAULT_FONT_SIZE))
            .width(Length::FillPortion(1))
            .center_x()
            .align_x(Align::Center);
    let reset_columns_button: Element<Interaction> = Button::new(
        reset_columns_button_state,
        reset_columns_button_title_container,
    )
    .style(style::DefaultBoxedButton(color_palette))
    .on_press(Interaction::ResetColumns)
    .into();

    scrollable = scrollable
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(reset_columns_button.map(Message::Interaction));

    // Colum wrapping all the settings content.
    scrollable = scrollable.height(Length::Fill).width(Length::Fill);

    let col = Column::new()
        .push(Space::new(Length::Units(0), Length::Units(10)))
        .push(scrollable)
        .push(Space::new(Length::Units(0), Length::Units(20)));
    let row = Row::new()
        .push(Space::new(Length::Units(20), Length::Units(0)))
        .push(col);

    // Returns the final container.
    Container::new(row)
        .center_x()
        .width(Length::Fill)
        .height(Length::Shrink)
        .style(style::NormalBackgroundContainer(color_palette))
}
