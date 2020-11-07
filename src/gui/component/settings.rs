use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{
        style, BackupState, CatalogColumnKey, CatalogColumnSettings, ColumnKey, ColumnSettings,
        DirectoryType, Interaction, Message, Mode, ScaleState, ThemeState,
    },
    ajour_core::{config::Config, theme::ColorPalette},
    iced::{
        button, Align, Button, Checkbox, Column, Container, Element, Length, PickList, Row,
        Scrollable, Space, Text, VerticalAlignment,
    },
};

// Settings updates
pub fn update() {}

/// Settings view
pub fn view<'a, 'b>(
    color_palette: ColorPalette,
    directory_button_state: &'a mut button::State,
    config: &'a Config,
    mode: &Mode,
    theme_state: &'a mut ThemeState,
    scale_state: &'a mut ScaleState,
    backup_state: &'a mut BackupState,
    column_settings: &'a mut ColumnSettings,
    column_config: &'b [(ColumnKey, Length, bool)],
    catalog_column_settings: &'a mut CatalogColumnSettings,
    catalog_column_config: &'b [(CatalogColumnKey, Length, bool)],
    website_button_state: &'a mut button::State,
) -> Container<'a, Message> {
    // Wow directory selector
    let directory = directory(color_palette, config, directory_button_state);

    // Theme selector
    let theme = theme(color_palette, theme_state);

    // Scale buttons
    let scale = scale(color_palette, scale_state);

    // Small space below content.
    let bottom_space = Space::new(Length::FillPortion(1), Length::Units(DEFAULT_PADDING));

    let (backup_title_row, backup_directory_row, backup_now_row) = {
        // Title for the Backup section.
        let backup_title_text = Text::new("Backup").size(DEFAULT_FONT_SIZE);
        let backup_title_row = Row::new().push(backup_title_text);

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
        .width(Length::Units(100))
        .style(style::DefaultBoxedButton(color_palette))
        .on_press(Interaction::OpenDirectory(DirectoryType::Backup))
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
            .style(style::NormalForegroundContainer(color_palette));

        // Data row for the Backup directory selection.
        let backup_directory_row = Row::new()
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
            .width(Length::Units(100))
            .style(style::DefaultBoxedButton(color_palette));

            // Only show button as clickable if it's not currently backing up and
            // the wow folder is chosen
            if !backup_state.backing_up && config.wow.directory.is_some() {
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
                .style(style::NormalForegroundContainer(color_palette));

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
                .style(style::NormalForegroundContainer(color_palette));

            backup_now_row = backup_now_row.push(backup_status_text_container);
        }

        (backup_title_row, backup_directory_row, backup_now_row)
    };

    let (columns_title_row, columns_scrollable) = {
        // Title for the Columns section.
        let columns_title_text = Text::new("My Addons Columns").size(DEFAULT_FONT_SIZE);
        let columns_title_row = Row::new().push(columns_title_text);

        // Scrollable for column selections
        let mut columns_scrollable = Scrollable::new(&mut column_settings.scrollable_state)
            .spacing(1)
            .width(Length::Fill)
            .height(Length::FillPortion(4))
            .style(style::SecondaryScrollable(color_palette));

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

            let checkbox_container = Container::new(checkbox).padding(5);

            let row = Row::new()
                .align_items(Align::Center)
                .height(Length::Units(26))
                .push(Space::new(Length::Units(5), Length::Units(0)))
                .push(left_button_container)
                .push(right_button_container)
                .push(checkbox_container);

            columns_scrollable = columns_scrollable.push(row);
        }

        (columns_title_row, columns_scrollable)
    };

    let (catalog_columns_title_row, catalog_columns_scrollable) = {
        // Title for the Columns section.
        let columns_title_text = Text::new("Catalog Columns").size(DEFAULT_FONT_SIZE);
        let columns_title_row = Row::new().push(columns_title_text);

        // Scrollable for column selections
        let mut columns_scrollable = Scrollable::new(&mut catalog_column_settings.scrollable_state)
            .spacing(1)
            .width(Length::Fill)
            .height(Length::FillPortion(4))
            .style(style::SecondaryScrollable(color_palette));

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

            let checkbox_container = Container::new(checkbox).padding(5);

            let row = Row::new()
                .align_items(Align::Center)
                .height(Length::Units(26))
                .push(Space::new(Length::Units(5), Length::Units(0)))
                .push(left_button_container)
                .push(right_button_container)
                .push(checkbox_container);

            columns_scrollable = columns_scrollable.push(row);
        }

        (columns_title_row, columns_scrollable)
    };

    let (website_button, website_title) = {
        let website_info = Text::new("About").size(14);
        let website_info_row = Row::new().push(website_info);

        let website_button_title_container =
            Container::new(Text::new("Website").size(DEFAULT_FONT_SIZE))
                .width(Length::FillPortion(1))
                .center_x()
                .align_x(Align::Center);
        let website_button: Element<Interaction> =
            Button::new(website_button_state, website_button_title_container)
                .width(Length::Units(100))
                .style(style::DefaultBoxedButton(color_palette))
                .on_press(Interaction::OpenLink("https://getajour.com".to_owned()))
                .into();

        (website_button, website_info_row)
    };

    // Colum wrapping all the settings content.
    let right_column = Column::new()
        .push(directory)
        .push(Space::new(
            Length::Units(0),
            Length::Units(DEFAULT_PADDING + DEFAULT_PADDING),
        ))
        .push(backup_title_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(backup_now_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(backup_directory_row)
        .push(bottom_space);

    let middle_column = Column::new()
        .push(scale)
        .push(Space::new(
            Length::Units(0),
            Length::Units(DEFAULT_PADDING + DEFAULT_PADDING),
        ))
        .push(theme)
        .push(Space::new(
            Length::Units(0),
            Length::Units(DEFAULT_PADDING + DEFAULT_PADDING),
        ))
        .push(website_title)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(website_button.map(Message::Interaction));

    // Container wrapping colum.
    let right_container = Container::new(right_column)
        .width(Length::FillPortion(1))
        .height(Length::Shrink)
        .style(style::BrightForegroundContainer(color_palette));

    let middle_container = Container::new(middle_column)
        .width(Length::Units(150))
        .height(Length::Shrink)
        .style(style::BrightForegroundContainer(color_palette));

    let my_addons_columns_column = Column::new()
        .push(columns_title_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(columns_scrollable)
        .push(Space::new(Length::Fill, Length::Units(DEFAULT_PADDING)));
    let my_addons_columns_container = Container::new(my_addons_columns_column)
        .width(Length::Units(200))
        .height(Length::Units(280))
        .style(style::BrightForegroundContainer(color_palette));

    let catalog_columns_column = Column::new()
        .push(catalog_columns_title_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(catalog_columns_scrollable)
        .push(Space::new(Length::Fill, Length::Units(DEFAULT_PADDING)));
    let catalog_columns_container = Container::new(catalog_columns_column)
        .width(Length::Units(200))
        .height(Length::Units(260))
        .style(style::BrightForegroundContainer(color_palette));

    // Row to wrap each section.
    let mut row = Row::new().push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)));

    // Depending on mode, we show different columns to edit.
    match mode {
        Mode::MyAddons(_) => {
            row = row.push(my_addons_columns_container);
        }
        Mode::Catalog => {
            row = row.push(catalog_columns_container);
        }
    }

    row = row
        .push(middle_container)
        .push(right_container)
        .push(Space::new(
            Length::Units(DEFAULT_PADDING + 5),
            Length::Units(0),
        ));

    // Returns the final container.
    Container::new(row)
        .height(Length::Shrink)
        .style(style::BrightForegroundContainer(color_palette))
        .padding(DEFAULT_PADDING)
}

fn directory<'a>(
    color_palette: ColorPalette,
    config: &'a Config,
    directory_button_state: &'a mut button::State,
) -> Container<'a, Message> {
    // Directory button for World of Warcraft directory selection.
    let button_text = Container::new(Text::new("Select Directory").size(DEFAULT_FONT_SIZE))
        .width(Length::FillPortion(1))
        .center_x()
        .align_x(Align::Center);

    let button: Element<Interaction> = Button::new(directory_button_state, button_text)
        .width(Length::Units(100))
        .style(style::DefaultBoxedButton(color_palette))
        .on_press(Interaction::OpenDirectory(DirectoryType::Wow))
        .into();

    // Directory text, written next to directory button to let the user
    // know what has been selected..
    let path_str = config
        .wow
        .directory
        .as_ref()
        .and_then(|p| p.to_str())
        .unwrap_or("No directory is set");
    let path_text = Text::new(path_str)
        .size(14)
        .vertical_alignment(VerticalAlignment::Center);
    let path_container = Container::new(path_text)
        .height(Length::Units(25))
        .center_y()
        .style(style::NormalForegroundContainer(color_palette));

    let data_row = Row::new()
        .push(button.map(Message::Interaction))
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(path_container);

    Container::new(
        Column::new()
            .push(Text::new("World of Warcraft directory").size(DEFAULT_FONT_SIZE))
            .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
            .push(data_row),
    )
}

fn theme<'a>(
    color_palette: ColorPalette,
    theme_state: &'a mut ThemeState,
) -> Container<'a, Message> {
    let theme_names = theme_state
        .themes
        .iter()
        .cloned()
        .map(|(name, _)| name)
        .collect::<Vec<_>>();

    let pick_list = PickList::new(
        &mut theme_state.pick_list_state,
        theme_names,
        Some(theme_state.current_theme_name.clone()),
        Message::ThemeSelected,
    )
    .text_size(14)
    .width(Length::Units(100))
    .style(style::PickList(color_palette));

    let data_row = Row::new().push(pick_list);

    Container::new(
        Column::new()
            .push(Text::new("Theme").size(DEFAULT_FONT_SIZE))
            .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
            .push(data_row),
    )
}

fn scale<'a>(
    color_palette: ColorPalette,
    scale_state: &'a mut ScaleState,
) -> Container<'a, Message> {
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

    let data_row = Row::new()
        .push(scale_down_button.map(Message::Interaction))
        .push(current_scale_container)
        .push(scale_up_button.map(Message::Interaction));

    Container::new(
        Column::new()
            .push(Text::new("UI Scale").size(DEFAULT_FONT_SIZE))
            .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
            .push(data_row),
    )
}
