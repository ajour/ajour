use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{
        style, BackupFolderKind, BackupState, CatalogColumnKey, CatalogColumnSettings, ColumnKey,
        ColumnSettings, DirectoryType, Interaction, Message, ScaleState, SelfUpdateChannelState,
        ThemeState,
    },
    ajour_core::{config::Config, theme::ColorPalette},
    iced::{
        button, scrollable, Align, Button, Checkbox, Column, Container, Element, Length, PickList,
        Row, Scrollable, Space, Text, VerticalAlignment,
    },
};

pub fn data_container<'a, 'b>(
    color_palette: ColorPalette,
    scrollable_state: &'a mut scrollable::State,
    directory_button_state: &'a mut button::State,
    config: &Config,
    theme_state: &'a mut ThemeState,
    scale_state: &'a mut ScaleState,
    backup_state: &'a mut BackupState,
    column_settings: &'a mut ColumnSettings,
    column_config: &'b [(ColumnKey, Length, bool)],
    catalog_column_settings: &'a mut CatalogColumnSettings,
    catalog_column_config: &'b [(CatalogColumnKey, Length, bool)],
    open_config_dir_button_state: &'a mut button::State,
    self_update_channel_state: &'a mut SelfUpdateChannelState,
) -> Container<'a, Message> {
    let mut scrollable = Scrollable::new(scrollable_state)
        .spacing(1)
        .height(Length::FillPortion(1))
        .style(style::Scrollable(color_palette));

    // Title for the World of Warcraft directory selection.
    let directory_info_text = Text::new("World of Warcraft directory").size(DEFAULT_FONT_SIZE);
    let direction_info_text_container =
        Container::new(directory_info_text).style(style::BrightBackgroundContainer(color_palette));

    // Directory button for World of Warcraft directory selection.
    let directory_button_title_container =
        Container::new(Text::new("Select Directory").size(DEFAULT_FONT_SIZE))
            .width(Length::FillPortion(1))
            .center_x()
            .align_x(Align::Center);

    let directory_button: Element<Interaction> =
        Button::new(directory_button_state, directory_button_title_container)
            .width(Length::Units(120))
            .style(style::DefaultBoxedButton(color_palette))
            .on_press(Interaction::SelectDirectory(DirectoryType::Wow))
            .into();

    // Directory text, written next to directory button to let the user
    // know what has been selected..
    let path_str = config
        .wow
        .directory
        .as_ref()
        .and_then(|p| p.to_str())
        .unwrap_or("No directory is set");
    let directory_data_text = Text::new(path_str)
        .size(14)
        .vertical_alignment(VerticalAlignment::Center);
    let directory_data_text_container = Container::new(directory_data_text)
        .height(Length::Units(25))
        .center_y()
        .style(style::NormalBackgroundContainer(color_palette));

    // Data row for the World of Warcraft directory selection.
    let directory_data_row = Row::new()
        .push(directory_button.map(Message::Interaction))
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(directory_data_text_container);

    scrollable = scrollable
        .push(direction_info_text_container)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(directory_data_row);

    let theme_column = {
        let title_container = Container::new(Text::new("Theme").size(DEFAULT_FONT_SIZE))
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
        .text_size(14)
        .width(Length::Units(120))
        .style(style::PickList(color_palette));

        // Data row for theme picker list.
        let theme_data_row = Row::new().push(theme_pick_list);

        Column::new()
            .push(title_container)
            .push(Space::new(Length::Units(0), Length::Units(5)))
            .push(theme_data_row)
    };

    // Scale buttons for application scale factoring.
    let scale_column = {
        let title_container = Container::new(Text::new("Scale").size(DEFAULT_FONT_SIZE))
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
            .height(Length::Units(25))
            .center_y()
            .style(style::BrightBackgroundContainer(color_palette));

        // Data row for the World of Warcraft directory selection.
        let scale_buttons_row = Row::new()
            .push(scale_down_button.map(Message::Interaction))
            .push(current_scale_container)
            .push(scale_up_button.map(Message::Interaction));

        Column::new()
            .push(scale_title_row)
            .push(Space::new(Length::Units(0), Length::Units(5)))
            .push(scale_buttons_row)
    };

    let (backup_title_row, backup_directory_row, backup_now_row) = {
        // Title for the Backup section.
        let backup_title_text = Text::new("Backup").size(DEFAULT_FONT_SIZE);
        let backup_title_text_container = Container::new(backup_title_text)
            .style(style::BrightBackgroundContainer(color_palette));

        let addon_folder_checkbox: Element<_> = Container::new(
            Checkbox::new(config.backup_addons, "AddOns", move |is_checked| {
                Interaction::ToggleBackupFolder(is_checked, BackupFolderKind::AddOns)
            })
            .text_size(DEFAULT_FONT_SIZE)
            .spacing(5)
            .style(style::DefaultCheckbox(color_palette)),
        )
        .style(style::BrightBackgroundContainer(color_palette))
        .into();

        let wtf_folder_checkbox: Element<_> = Container::new(
            Checkbox::new(config.backup_wtf, "WTF", move |is_checked| {
                Interaction::ToggleBackupFolder(is_checked, BackupFolderKind::WTF)
            })
            .text_size(DEFAULT_FONT_SIZE)
            .spacing(5)
            .style(style::DefaultCheckbox(color_palette)),
        )
        .style(style::BrightBackgroundContainer(color_palette))
        .into();

        // Directory button for Backup directory selection.
        let directory_button_title_container =
            Container::new(Text::new("Select Directory").size(DEFAULT_FONT_SIZE))
                .width(Length::FillPortion(1))
                .center_x()
                .align_x(Align::Center);
        let directory_button: Element<Interaction> = Button::new(
            &mut backup_state.directory_btn_state,
            directory_button_title_container,
        )
        .width(Length::Units(120))
        .style(style::DefaultBoxedButton(color_palette))
        .on_press(Interaction::SelectDirectory(DirectoryType::Backup))
        .into();

        // Directory text, written next to directory button to let the user
        // know what has been selected.
        let path_str = config
            .backup_directory
            .as_ref()
            .and_then(|p| p.to_str())
            .unwrap_or("No directory is set");
        let directory_data_text = Text::new(path_str)
            .size(DEFAULT_FONT_SIZE)
            .vertical_alignment(VerticalAlignment::Center);
        let directory_data_text_container = Container::new(directory_data_text)
            .height(Length::Units(25))
            .center_y()
            .style(style::NormalBackgroundContainer(color_palette));

        // Data row for the Backup directory selection.
        let backup_directory_row = Row::new()
            .align_items(Align::Center)
            .height(Length::Units(26))
            .push(addon_folder_checkbox.map(Message::Interaction))
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
            .push(wtf_folder_checkbox.map(Message::Interaction))
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
                Container::new(Text::new("Backup Now").size(DEFAULT_FONT_SIZE))
                    .width(Length::FillPortion(1))
                    .center_x()
                    .align_x(Align::Center);
            let mut backup_button = Button::new(
                &mut backup_state.backup_now_btn_state,
                backup_button_title_container,
            )
            .width(Length::Units(120))
            .style(style::DefaultBoxedButton(color_palette));

            // Only show button as clickable if it's not currently backing up and
            // the wow folder is chosen and at least one of the folders is selected
            // for backup
            if !backup_state.backing_up
                && config.wow.directory.is_some()
                && (config.backup_addons || config.backup_wtf)
            {
                backup_button = backup_button.on_press(Interaction::Backup);
            }

            let backup_status_text = if backup_state.backing_up {
                Text::new("Backing up...")
                    .size(DEFAULT_FONT_SIZE)
                    .vertical_alignment(VerticalAlignment::Center)
            } else {
                let as_of = backup_state
                    .last_backup
                    .map(|d| d.format("%Y-%m-%d %H:%M:%S").to_string())
                    .unwrap_or_else(|| "Never".to_string());

                Text::new(&format!("Last backup: {}", as_of))
                    .size(DEFAULT_FONT_SIZE)
                    .vertical_alignment(VerticalAlignment::Center)
            };

            let backup_status_text_container = Container::new(backup_status_text)
                .height(Length::Units(25))
                .center_y()
                .style(style::NormalBackgroundContainer(color_palette));

            let backup_button: Element<Interaction> = backup_button.into();

            backup_now_row = backup_now_row
                .push(backup_button.map(Message::Interaction))
                .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                .push(backup_status_text_container);
        } else {
            let backup_status_text =
                Text::new("Back up your AddOns and WTF folder to the chosen directory")
                    .size(DEFAULT_FONT_SIZE)
                    .vertical_alignment(VerticalAlignment::Center);

            let backup_status_text_container = Container::new(backup_status_text)
                .height(Length::Units(25))
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

    let hide_addons_column = {
        let hide_ignored_addons = config.hide_ignored_addons;
        let title = "Hide ignored Addons".to_owned();
        let checkbox = Checkbox::new(hide_ignored_addons, title, move |is_checked| {
            Message::Interaction(Interaction::ToggleHideIgnoredAddons(is_checked))
        })
        .style(style::DefaultCheckbox(color_palette))
        .text_size(DEFAULT_FONT_SIZE)
        .spacing(5);
        let checkbox_container =
            Container::new(checkbox).style(style::BrightBackgroundContainer(color_palette));
        Column::new().push(checkbox_container)
    };

    let config_column = {
        let config_dir = ajour_core::fs::config_dir();
        let config_dir_string = config_dir.as_path().display().to_string();

        let open_config_button_title_container =
            Container::new(Text::new("Open data directory").size(DEFAULT_FONT_SIZE))
                .width(Length::Units(150))
                .center_x()
                .align_x(Align::Center);
        let open_config_button: Element<Interaction> = Button::new(
            open_config_dir_button_state,
            open_config_button_title_container,
        )
        .width(Length::Units(150))
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

    let ui_title = Text::new("UI").size(DEFAULT_FONT_SIZE);
    let ui_title_container =
        Container::new(ui_title).style(style::BrightBackgroundContainer(color_palette));

    let addon_title = Text::new("Addons").size(DEFAULT_FONT_SIZE);
    let addon_title_container =
        Container::new(addon_title).style(style::BrightBackgroundContainer(color_palette));

    let config_title = Text::new("Config").size(DEFAULT_FONT_SIZE);
    let config_title_container =
        Container::new(config_title).style(style::BrightBackgroundContainer(color_palette));

    let ui_row = Row::new()
        .push(theme_column)
        .push(scale_column)
        .spacing(DEFAULT_PADDING);

    let channel_title = Container::new(Text::new("Self Update Channel").size(DEFAULT_FONT_SIZE))
        .style(style::BrightBackgroundContainer(color_palette));
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
        .width(Length::Units(80))
        .style(style::NormalForegroundContainer(color_palette));

    scrollable = scrollable
        .push(Space::new(Length::Units(0), Length::Units(20)))
        .push(backup_title_row)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(backup_now_row)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(backup_directory_row)
        .push(Space::new(Length::Units(0), Length::Units(20)))
        .push(channel_title)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(channel_container)
        .push(Space::new(Length::Units(0), Length::Units(20)))
        .push(addon_title_container)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(hide_addons_column)
        .push(Space::new(Length::Units(0), Length::Units(20)))
        .push(ui_title_container)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(ui_row)
        .push(Space::new(Length::Units(0), Length::Units(20)))
        .push(config_title_container)
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(config_column);

    let columns_title_text = Text::new("Columns").size(DEFAULT_FONT_SIZE);
    let columns_title_text_container =
        Container::new(columns_title_text).style(style::BrightBackgroundContainer(color_palette));
    scrollable = scrollable
        .push(Space::new(Length::Units(0), Length::Units(20)))
        .push(columns_title_text_container);

    let my_addons_columns_container = {
        let title_container = Container::new(Text::new("My Addons").size(DEFAULT_FONT_SIZE))
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

        let title_container = Container::new(Text::new("Catalog").size(DEFAULT_FONT_SIZE))
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
