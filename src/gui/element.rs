#![allow(clippy::too_many_arguments)]

use {
    super::{
        style, AddonVersionKey, BackupFolderKind, BackupState, CatalogColumnKey,
        CatalogColumnSettings, CatalogColumnState, CatalogRow, Changelog, ColumnKey,
        ColumnSettings, ColumnState, DirectoryType, ExpandType, InstallAddon, InstallKind,
        InstallStatus, Interaction, Message, Mode, ReleaseChannel, ScaleState, SelfUpdateState,
        SortDirection, State, ThemeState,
    },
    crate::VERSION,
    ajour_core::{
        addon::{Addon, AddonState},
        catalog::Catalog,
        config::{Config, Flavor},
        repository::RepositoryKind,
        theme::ColorPalette,
    },
    chrono::prelude::*,
    iced::{
        button, scrollable, Align, Button, Checkbox, Column, Container, Element,
        HorizontalAlignment, Length, PickList, Row, Scrollable, Space, Text, VerticalAlignment,
    },
    num_format::{Locale, ToFormattedString},
    std::collections::HashMap,
    version_compare::{CompOp, VersionCompare},
    widgets::{header, Header},
};

// Default values used on multiple elements.
pub static DEFAULT_FONT_SIZE: u16 = 14;
pub static DEFAULT_PADDING: u16 = 10;

/// Container for settings.
pub fn settings_container<'a, 'b>(
    color_palette: ColorPalette,
    directory_button_state: &'a mut button::State,
    config: &Config,
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
    // Title for the World of Warcraft directory selection.
    let directory_info_text = Text::new("World of Warcraft directory").size(14);

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
    let directory_data_text = Text::new(path_str)
        .size(14)
        .vertical_alignment(VerticalAlignment::Center);
    let directory_data_text_container = Container::new(directory_data_text)
        .height(Length::Units(25))
        .center_y()
        .style(style::NormalForegroundContainer(color_palette));

    // Data row for the World of Warcraft directory selection.
    let path_data_row = Row::new()
        .push(directory_button.map(Message::Interaction))
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(directory_data_text_container);

    // Title for the theme pick list.
    let theme_info_text = Text::new("Theme").size(14);
    let theme_info_row = Row::new().push(theme_info_text);

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

    // Scale buttons for application scale factoring.
    let (scale_title_row, scale_buttons_row) = {
        let scale_title = Text::new("UI Scale").size(DEFAULT_FONT_SIZE);
        let scale_title_row = Row::new().push(scale_title);

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

        (scale_title_row, scale_buttons_row)
    };

    // Small space below content.
    let bottom_space = Space::new(Length::FillPortion(1), Length::Units(DEFAULT_PADDING));

    let (backup_title_row, backup_directory_row, backup_now_row) = {
        // Title for the Backup section.
        let backup_title_text = Text::new("Backup").size(DEFAULT_FONT_SIZE);
        let backup_title_row = Row::new().push(backup_title_text);

        let addon_folder_checkbox: Element<_> = Container::new(
            Checkbox::new(config.backup_addons, "AddOns", move |is_checked| {
                Interaction::ToggleBackupFolder(is_checked, BackupFolderKind::AddOns)
            })
            .text_size(DEFAULT_FONT_SIZE)
            .spacing(5)
            .style(style::DefaultCheckbox(color_palette)),
        )
        .padding(5)
        .into();

        let wtf_folder_checkbox: Element<_> = Container::new(
            Checkbox::new(config.backup_wtf, "WTF", move |is_checked| {
                Interaction::ToggleBackupFolder(is_checked, BackupFolderKind::WTF)
            })
            .text_size(DEFAULT_FONT_SIZE)
            .spacing(5)
            .style(style::DefaultCheckbox(color_palette)),
        )
        .padding(5)
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
            .align_items(Align::Center)
            .height(Length::Units(26))
            .push(addon_folder_checkbox.map(Message::Interaction))
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
        .push(directory_info_text)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(path_data_row)
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
        .push(scale_title_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(scale_buttons_row)
        .push(Space::new(
            Length::Units(0),
            Length::Units(DEFAULT_PADDING + DEFAULT_PADDING),
        ))
        .push(theme_info_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(theme_data_row)
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

    let install_columns_column =
        Column::new().push(Text::new("Install Columns").size(DEFAULT_FONT_SIZE));
    let install_columns_container = Container::new(install_columns_column)
        .width(Length::Units(200))
        .height(Length::Units(200))
        .style(style::BrightForegroundContainer(color_palette));

    let catalog_columns_column = Column::new()
        .push(catalog_columns_title_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(catalog_columns_scrollable)
        .push(Space::new(Length::Fill, Length::Units(DEFAULT_PADDING)));
    let catalog_columns_container = Container::new(catalog_columns_column)
        .width(Length::Units(200))
        .height(Length::Units(230))
        .style(style::BrightForegroundContainer(color_palette));

    // Row to wrap each section.
    let mut row = Row::new().push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)));

    // Depending on mode, we show different columns to edit.
    match mode {
        Mode::MyAddons(_) => {
            row = row.push(my_addons_columns_container);
        }
        Mode::Install => {
            row = row.push(install_columns_container);
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

pub fn addon_data_cell<'a, 'b>(
    color_palette: ColorPalette,
    addon: &'a mut Addon,
    is_addon_expanded: bool,
    expand_type: &'a ExpandType,
    column_config: &'b [(ColumnKey, Length, bool)],
) -> Container<'a, Message> {
    let default_height = Length::Units(26);

    let mut row_containers = vec![];

    let author = addon.author().map(str::to_string);
    let game_version = addon.game_version().map(str::to_string);
    let notes = addon.notes().map(str::to_string);
    let website_url = addon.website_url().map(str::to_string);
    let repository_kind = addon.repository_kind();

    // Check if current addon is expanded.
    let addon_cloned = addon.clone();
    let version = addon
        .version()
        .map(str::to_string)
        .unwrap_or_else(|| "-".to_string());
    let release_package = addon_cloned.relevant_release_package();
    let remote_version = if let Some(package) = &release_package {
        package.version.clone()
    } else {
        String::from("-")
    };
    let remote_version = Text::new(remote_version).size(DEFAULT_FONT_SIZE);

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::Title && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let title = Text::new(addon.title()).size(DEFAULT_FONT_SIZE);
        let mut title_button = Button::new(&mut addon.details_btn_state, title).on_press(
            Interaction::Expand(ExpandType::Details(addon_cloned.clone())),
        );

        if release_package.is_some() {}

        if is_addon_expanded && matches!(expand_type, ExpandType::Details(_)) {
            title_button = title_button.style(style::SelectedBrightTextButton(color_palette));
        } else {
            title_button = title_button.style(style::BrightTextButton(color_palette));
        }

        let title_button: Element<Interaction> = title_button.into();

        let mut title_row = Row::new()
            .push(title_button.map(Message::Interaction))
            .spacing(3)
            .align_items(Align::Center);

        if addon.release_channel != ReleaseChannel::Stable {
            let release_channel =
                Container::new(Text::new(addon.release_channel.to_string()).size(10))
                    .style(style::ChannelBadge(color_palette))
                    .padding(3);

            title_row = title_row.push(release_channel);
        }

        let title_container = Container::new(title_row)
            .height(default_height)
            .width(*width)
            .center_y()
            .style(style::BrightForegroundContainer(color_palette));

        row_containers.push((idx, title_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::LocalVersion && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let installed_version = Text::new(version).size(DEFAULT_FONT_SIZE);
        let mut local_version_button = Button::new(&mut addon.local_btn_state, installed_version)
            .style(style::BrightTextButton(color_palette));

        if addon_cloned.repository_kind() == Some(RepositoryKind::Curse)
            && addon_cloned.file_id().is_some()
        {
            local_version_button =
                local_version_button.on_press(Interaction::Expand(ExpandType::Changelog(
                    Changelog::Request(addon_cloned.clone(), AddonVersionKey::Local),
                )));
        }

        if addon_cloned.repository_kind() == Some(RepositoryKind::Tukui)
            && addon_cloned.repository_id().is_some()
        {
            local_version_button =
                local_version_button.on_press(Interaction::Expand(ExpandType::Changelog(
                    Changelog::Request(addon_cloned.clone(), AddonVersionKey::Local),
                )));
        }

        if addon_cloned.repository_kind() == Some(RepositoryKind::WowI) {
            local_version_button =
                local_version_button.on_press(Interaction::Expand(ExpandType::Changelog(
                    Changelog::Request(addon_cloned.clone(), AddonVersionKey::Local),
                )));
        }

        // Lets check if addon is expanded, in changelog mode and local is shown.
        if is_addon_expanded {
            if let ExpandType::Changelog(Changelog::Some(_, _, k)) = expand_type {
                if k == &AddonVersionKey::Local {
                    local_version_button =
                        local_version_button.style(style::SelectedBrightTextButton(color_palette));
                }
            }

            if let ExpandType::Changelog(Changelog::Loading(_, k)) = expand_type {
                if k == &AddonVersionKey::Local {
                    local_version_button =
                        local_version_button.style(style::SelectedBrightTextButton(color_palette));
                }
            }
        }

        let local_version_button: Element<Interaction> = local_version_button.into();

        let installed_version_container =
            Container::new(local_version_button.map(Message::Interaction))
                .height(default_height)
                .width(*width)
                .center_y()
                .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, installed_version_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::RemoteVersion && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let mut remote_version_button = Button::new(&mut addon.remote_btn_state, remote_version)
            .style(style::BrightTextButton(color_palette));

        if addon_cloned.repository_kind() == Some(RepositoryKind::Curse) {
            if let Some(package) = addon_cloned.relevant_release_package() {
                if package.file_id.is_some() {
                    remote_version_button =
                        remote_version_button.on_press(Interaction::Expand(ExpandType::Changelog(
                            Changelog::Request(addon_cloned.clone(), AddonVersionKey::Remote),
                        )));
                }
            }
        }

        if addon_cloned.repository_kind() == Some(RepositoryKind::Tukui)
            && addon_cloned.repository_id().is_some()
        {
            remote_version_button =
                remote_version_button.on_press(Interaction::Expand(ExpandType::Changelog(
                    Changelog::Request(addon_cloned.clone(), AddonVersionKey::Remote),
                )));
        }

        if addon_cloned.repository_kind() == Some(RepositoryKind::WowI) {
            remote_version_button =
                remote_version_button.on_press(Interaction::Expand(ExpandType::Changelog(
                    Changelog::Request(addon_cloned.clone(), AddonVersionKey::Remote),
                )));
        }

        if matches!(addon_cloned.repository_kind(), Some(RepositoryKind::Git(_))) {
            remote_version_button = remote_version_button.on_press(Interaction::Expand(
                ExpandType::Changelog(Changelog::Request(addon_cloned, AddonVersionKey::Remote)),
            ));
        }

        // Lets check if addon is expanded, in changelog mode and remote is shown.
        if is_addon_expanded {
            if let ExpandType::Changelog(Changelog::Some(_, _, k)) = expand_type {
                if k == &AddonVersionKey::Remote {
                    remote_version_button =
                        remote_version_button.style(style::SelectedBrightTextButton(color_palette));
                }
            }

            if let ExpandType::Changelog(Changelog::Loading(_, k)) = expand_type {
                if k == &AddonVersionKey::Remote {
                    remote_version_button =
                        remote_version_button.style(style::SelectedBrightTextButton(color_palette));
                }
            }
        }

        let remote_version_button: Element<Interaction> = remote_version_button.into();
        let remote_version_container =
            Container::new(remote_version_button.map(Message::Interaction))
                .height(default_height)
                .width(*width)
                .center_y()
                .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, remote_version_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::Channel && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let channel = Text::new(addon.release_channel.to_string()).size(DEFAULT_FONT_SIZE);
        let channel_container = Container::new(channel)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, channel_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::Author && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let author = Text::new(author.as_deref().unwrap_or("-")).size(DEFAULT_FONT_SIZE);
        let author_container = Container::new(author)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, author_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::GameVersion && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let game_version =
            Text::new(game_version.as_deref().unwrap_or("-")).size(DEFAULT_FONT_SIZE);
        let game_version_container = Container::new(game_version)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, game_version_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::DateReleased && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let release_date_text: String = if let Some(package) = &release_package {
            let f = timeago::Formatter::new();
            let now = Local::now();

            if let Some(time) = package.date_time.as_ref() {
                f.convert_chrono(*time, now)
            } else {
                "".to_string()
            }
        } else {
            "-".to_string()
        };
        let release_date_text = Text::new(release_date_text).size(DEFAULT_FONT_SIZE);
        let game_version_container = Container::new(release_date_text)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, game_version_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::Source && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let source_text =
            repository_kind.map_or_else(|| String::from("Unknown"), |a| a.to_string());
        let source = Text::new(source_text).size(DEFAULT_FONT_SIZE);
        let source_container = Container::new(source)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, source_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::Status && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let update_button_container = match &addon.state {
            AddonState::Ajour(string) => Container::new(
                Text::new(string.clone().unwrap_or_else(|| "".to_string())).size(DEFAULT_FONT_SIZE),
            )
            .height(default_height)
            .width(*width)
            .center_y()
            .center_x()
            .style(style::NormalForegroundContainer(color_palette)),
            AddonState::Updatable | AddonState::Corrupted => {
                let id = addon.primary_folder_id.clone();
                let text = if addon.state == AddonState::Updatable {
                    "Update"
                } else {
                    "Repair"
                };

                let update_wrapper = Container::new(Text::new(text).size(DEFAULT_FONT_SIZE))
                    .width(*width)
                    .center_x()
                    .align_x(Align::Center);
                let update_button: Element<Interaction> =
                    Button::new(&mut addon.update_btn_state, update_wrapper)
                        .width(Length::FillPortion(1))
                        .style(style::SecondaryButton(color_palette))
                        .on_press(Interaction::Update(id))
                        .into();

                Container::new(update_button.map(Message::Interaction))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .style(style::BrightForegroundContainer(color_palette))
            }
            AddonState::Downloading => {
                Container::new(Text::new("Downloading").size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .padding(5)
                    .style(style::NormalForegroundContainer(color_palette))
            }
            AddonState::Unpacking => Container::new(Text::new("Unpacking").size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .padding(5)
                .style(style::NormalForegroundContainer(color_palette)),
            AddonState::Fingerprint => Container::new(Text::new("Hashing").size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .padding(5)
                .style(style::NormalForegroundContainer(color_palette)),
            AddonState::Ignored => Container::new(Text::new("Ignored").size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .padding(5)
                .style(style::NormalForegroundContainer(color_palette)),
            AddonState::Unknown => Container::new(Text::new("").size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .padding(5)
                .style(style::NormalForegroundContainer(color_palette)),
        };

        row_containers.push((idx, update_button_container));
    }

    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
    let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));

    let mut row = Row::new().push(left_spacer).spacing(1);

    // Sort columns and push them into row
    row_containers.sort_by(|a, b| a.0.cmp(&b.0));
    for (_, elem) in row_containers.into_iter() {
        row = row.push(elem);
    }

    row = row.push(right_spacer);

    let mut addon_column = Column::new().push(row);

    if is_addon_expanded {
        match expand_type {
            ExpandType::Changelog(changelog) => {
                let changelog_text = match changelog {
                    Changelog::Some(_, payload, _) => &payload.changelog,
                    _ => "Loading...",
                };

                let changelog_title_text = Text::new("Changelog").size(DEFAULT_FONT_SIZE);
                let changelog_title_container = Container::new(changelog_title_text)
                    .style(style::BrightForegroundContainer(color_palette));

                let mut full_changelog_button = Button::new(
                    &mut addon.full_changelog_btn_state,
                    Text::new("Full Changelog").size(DEFAULT_FONT_SIZE),
                )
                .style(style::DefaultButton(color_palette));

                if let ExpandType::Changelog(Changelog::Some(_, p, _)) = expand_type {
                    full_changelog_button =
                        full_changelog_button.on_press(Interaction::OpenLink(p.url.clone()));
                }

                let full_changelog_button: Element<Interaction> = full_changelog_button.into();

                let mut button_row =
                    Row::new().push(Space::new(Length::FillPortion(1), Length::Units(0)));

                if matches!(changelog, Changelog::Some(_, _, _)) {
                    button_row = button_row.push(full_changelog_button.map(Message::Interaction));
                }

                let column = Column::new()
                    .push(changelog_title_container)
                    .push(Space::new(Length::Units(0), Length::Units(12)))
                    .push(Text::new(changelog_text).size(DEFAULT_FONT_SIZE))
                    .push(Space::new(Length::Units(0), Length::Units(8)))
                    .push(button_row)
                    .push(Space::new(Length::Units(0), Length::Units(4)));
                let details_container = Container::new(column)
                    .width(Length::Fill)
                    .padding(20)
                    .style(style::FadedNormalForegroundContainer(color_palette));

                let row = Row::new()
                    .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                    .push(details_container)
                    .push(Space::new(
                        Length::Units(DEFAULT_PADDING + 5),
                        Length::Units(0),
                    ))
                    .spacing(1);

                addon_column = addon_column
                    .push(Space::new(Length::FillPortion(1), Length::Units(1)))
                    .push(row);
            }
            ExpandType::Details(_) => {
                let notes = notes.unwrap_or_else(|| "No description for addon.".to_string());
                let author = author.unwrap_or_else(|| "-".to_string());
                let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
                let space = Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING * 2));
                let bottom_space = Space::new(Length::Units(0), Length::Units(4));
                let notes_title_text = Text::new("Summary").size(DEFAULT_FONT_SIZE);
                let notes_text = Text::new(notes).size(DEFAULT_FONT_SIZE);
                let author_text = Text::new(author).size(DEFAULT_FONT_SIZE);
                let author_title_text = Text::new("Author(s)").size(DEFAULT_FONT_SIZE);
                let author_title_container = Container::new(author_title_text)
                    .style(style::FadedBrightForegroundContainer(color_palette));
                let notes_title_container = Container::new(notes_title_text)
                    .style(style::FadedBrightForegroundContainer(color_palette));

                let release_date_text: String = if let Some(package) = &release_package {
                    let f = timeago::Formatter::new();
                    let now = Local::now();

                    if let Some(time) = package.date_time.as_ref() {
                        format!("is {}", f.convert_chrono(*time, now))
                    } else {
                        "".to_string()
                    }
                } else {
                    "has no avaiable release".to_string()
                };
                let release_date_text = Text::new(release_date_text).size(DEFAULT_FONT_SIZE);
                let release_date_text_container = Container::new(release_date_text)
                    .center_y()
                    .padding(5)
                    .style(style::FadedBrightForegroundContainer(color_palette));

                let release_channel_title =
                    Text::new("Remote release channel").size(DEFAULT_FONT_SIZE);
                let release_channel_title_container = Container::new(release_channel_title)
                    .style(style::FadedBrightForegroundContainer(color_palette));
                let release_channel_list = PickList::new(
                    &mut addon.pick_release_channel_state,
                    &ReleaseChannel::ALL[..],
                    Some(addon.release_channel),
                    Message::ReleaseChannelSelected,
                )
                .text_size(14)
                .width(Length::Units(100))
                .style(style::PickList(color_palette));

                let mut website_button = Button::new(
                    &mut addon.website_btn_state,
                    Text::new("Website").size(DEFAULT_FONT_SIZE),
                )
                .style(style::DefaultButton(color_palette));

                if let Some(link) = website_url {
                    website_button = website_button.on_press(Interaction::OpenLink(link));
                }

                let website_button: Element<Interaction> = website_button.into();

                let mut force_download_button = Button::new(
                    &mut addon.force_btn_state,
                    Text::new("Force update").size(DEFAULT_FONT_SIZE),
                )
                .style(style::DefaultButton(color_palette));

                // If we have a release package on addon, enable force update.
                if release_package.is_some() {
                    force_download_button = force_download_button
                        .on_press(Interaction::Update(addon.primary_folder_id.clone()));
                }

                let force_download_button: Element<Interaction> = force_download_button.into();

                let is_ignored = addon.state == AddonState::Ignored;
                let ignore_button_text = if is_ignored {
                    Text::new("Unignore").size(DEFAULT_FONT_SIZE)
                } else {
                    Text::new("Ignore").size(DEFAULT_FONT_SIZE)
                };

                let mut ignore_button =
                    Button::new(&mut addon.ignore_btn_state, ignore_button_text)
                        .on_press(Interaction::Ignore(addon.primary_folder_id.clone()))
                        .style(style::DefaultButton(color_palette));

                if is_ignored {
                    ignore_button = ignore_button
                        .on_press(Interaction::Unignore(addon.primary_folder_id.clone()));
                } else {
                    ignore_button = ignore_button
                        .on_press(Interaction::Ignore(addon.primary_folder_id.clone()));
                }

                let ignore_button: Element<Interaction> = ignore_button.into();

                let delete_button: Element<Interaction> = Button::new(
                    &mut addon.delete_btn_state,
                    Text::new("Delete").size(DEFAULT_FONT_SIZE),
                )
                .on_press(Interaction::Delete(addon.primary_folder_id.clone()))
                .style(style::DefaultDeleteButton(color_palette))
                .into();

                let test_row = Row::new()
                    .push(release_channel_list)
                    .push(release_date_text_container);

                let button_row = Row::new()
                    .push(Space::new(Length::Fill, Length::Units(0)))
                    .push(website_button.map(Message::Interaction))
                    .push(Space::new(Length::Units(5), Length::Units(0)))
                    .push(force_download_button.map(Message::Interaction))
                    .push(Space::new(Length::Units(5), Length::Units(0)))
                    .push(ignore_button.map(Message::Interaction))
                    .push(Space::new(Length::Units(5), Length::Units(0)))
                    .push(delete_button.map(Message::Interaction))
                    .width(Length::Fill);
                let column = Column::new()
                    .push(author_title_container)
                    .push(Space::new(Length::Units(0), Length::Units(3)))
                    .push(author_text)
                    .push(Space::new(Length::Units(0), Length::Units(15)))
                    .push(notes_title_container)
                    .push(Space::new(Length::Units(0), Length::Units(3)))
                    .push(notes_text)
                    .push(Space::new(Length::Units(0), Length::Units(15)))
                    .push(release_channel_title_container)
                    .push(Space::new(Length::Units(0), Length::Units(3)))
                    .push(test_row)
                    .push(space)
                    .push(button_row)
                    .push(bottom_space);
                let details_container = Container::new(column)
                    .width(Length::Fill)
                    .padding(20)
                    .style(style::FadedNormalForegroundContainer(color_palette));

                let row = Row::new()
                    .push(left_spacer)
                    .push(details_container)
                    .push(Space::new(
                        Length::Units(DEFAULT_PADDING + 5),
                        Length::Units(0),
                    ))
                    .spacing(1);

                addon_column = addon_column
                    .push(Space::new(Length::FillPortion(1), Length::Units(1)))
                    .push(row);
            }
            _ => {}
        }
    }

    Container::new(addon_column)
        .width(Length::Fill)
        .style(style::Row(color_palette))
}

fn row_title<T: PartialEq>(
    column_key: T,
    previous_column_key: Option<T>,
    previous_sort_direction: Option<SortDirection>,
    title: &str,
) -> String {
    if Some(column_key) == previous_column_key {
        match previous_sort_direction {
            Some(SortDirection::Asc) => format!("{} ▲", title),
            Some(SortDirection::Desc) => format!("{} ▼", title),
            _ => title.to_string(),
        }
    } else {
        title.to_string()
    }
}

pub fn addon_row_titles<'a>(
    color_palette: ColorPalette,
    addons: &[Addon],
    header_state: &'a mut header::State,
    column_state: &'a mut [ColumnState],
    previous_column_key: Option<ColumnKey>,
    previous_sort_direction: Option<SortDirection>,
) -> Header<'a, Message> {
    // A row containing titles above the addon rows.
    let mut row_titles = vec![];

    for column in column_state.iter_mut().filter(|c| !c.hidden) {
        let column_key = column.key;

        let row_title = row_title(
            column_key,
            previous_column_key,
            previous_sort_direction,
            &column.key.title(),
        );

        let mut row_header = Button::new(
            &mut column.btn_state,
            Text::new(row_title)
                .size(DEFAULT_FONT_SIZE)
                .width(Length::Fill),
        )
        .width(Length::Fill)
        .on_press(Interaction::SortColumn(column_key));

        if previous_column_key == Some(column_key) {
            row_header = row_header.style(style::SelectedColumnHeaderButton(color_palette));
        } else {
            row_header = row_header.style(style::ColumnHeaderButton(color_palette));
        }

        let row_header: Element<Interaction> = row_header.into();

        let row_container = Container::new(row_header.map(Message::Interaction))
            .width(column.width)
            .style(style::NormalBackgroundContainer(color_palette));

        // Only shows row titles if we have any addons.
        if !addons.is_empty() {
            row_titles.push((column.key.as_string(), row_container));
        }
    }

    Header::new(
        header_state,
        row_titles,
        Some(Length::Units(DEFAULT_PADDING)),
        Some(Length::Units(DEFAULT_PADDING + 5)),
    )
    .spacing(1)
    .height(Length::Units(25))
    .on_resize(3, |event| {
        Message::Interaction(Interaction::ResizeColumn(
            Mode::MyAddons(Flavor::default()),
            event,
        ))
    })
}

#[allow(clippy::too_many_arguments)]
pub fn menu_addons_container<'a>(
    color_palette: ColorPalette,
    flavor: Flavor,
    update_all_button_state: &'a mut button::State,
    refresh_button_state: &'a mut button::State,
    state: &HashMap<Mode, State>,
    addons: &[Addon],
    config: &Config,
) -> Container<'a, Message> {
    // MyAddons state.
    let state = state
        .get(&Mode::MyAddons(flavor))
        .cloned()
        .unwrap_or_default();

    // A row contain general settings.
    let mut settings_row = Row::new().height(Length::Units(35));

    let mut update_all_button = Button::new(
        update_all_button_state,
        Text::new("Update All").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultButton(color_palette));

    let mut refresh_button = Button::new(
        refresh_button_state,
        Text::new("Refresh").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultButton(color_palette));

    // Is any addon performing an action.
    let addons_performing_actions = addons
        .iter()
        .any(|a| matches!(a.state, AddonState::Downloading | AddonState::Unpacking));

    // Is any addon updtable.
    let any_addon_updatable = addons
        .iter()
        .any(|a| matches!(a.state, AddonState::Updatable));

    // Enable update_all_button if:
    //   - We have addons.
    //   - No addon is performing any task.
    //   - We have updatable addons.
    if !addons.is_empty() && !addons_performing_actions && any_addon_updatable {
        update_all_button = update_all_button.on_press(Interaction::UpdateAll);
    }

    // Enable refresh_button if:
    //   - No addon is performing any task.
    //   - Mode state isn't start or loading
    if !addons_performing_actions && !matches!(state, State::Start | State::Loading) {
        refresh_button = refresh_button.on_press(Interaction::Refresh);
    }

    let update_all_button: Element<Interaction> = update_all_button.into();
    let refresh_button: Element<Interaction> = refresh_button.into();

    // Displays text depending on the state of the app.
    let flavor = config.wow.flavor;
    let ignored_addons = config.addons.ignored.get(&flavor);
    let parent_addons_count = addons
        .iter()
        .filter(|a| !a.is_ignored(ignored_addons))
        .count();

    let status_text = match state {
        State::Ready => Text::new(format!(
            "{} {} addons loaded",
            parent_addons_count,
            config.wow.flavor.to_string()
        ))
        .size(DEFAULT_FONT_SIZE),
        _ => Text::new(""),
    };

    let status_container = Container::new(status_text)
        .center_y()
        .padding(5)
        .style(style::NormalBackgroundContainer(color_palette));

    // Surrounds the elements with spacers, in order to make the GUI look good.
    settings_row = settings_row
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(refresh_button.map(Message::Interaction))
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(update_all_button.map(Message::Interaction))
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(status_container)
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)));

    // Add space above settings_row.
    let settings_column = Column::new()
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(settings_row);

    // Wraps it in a container.
    Container::new(settings_column)
}

#[allow(clippy::too_many_arguments)]
pub fn menu_container<'a>(
    color_palette: ColorPalette,
    mode: &Mode,
    state: &HashMap<Mode, State>,
    error: &Option<String>,
    config: &Config,
    valid_flavors: &[Flavor],
    settings_button_state: &'a mut button::State,
    addon_mode_button_state: &'a mut button::State,
    catalog_mode_btn_state: &'a mut button::State,
    install_mode_btn_state: &'a mut button::State,
    retail_btn_state: &'a mut button::State,
    retail_ptr_btn_state: &'a mut button::State,
    retail_beta_btn_state: &'a mut button::State,
    classic_btn_state: &'a mut button::State,
    classic_ptr_btn_state: &'a mut button::State,
    self_update_state: &'a mut SelfUpdateState,
) -> Container<'a, Message> {
    let flavor = config.wow.flavor;

    // State.
    let myaddons_state = state
        .get(&Mode::MyAddons(flavor))
        .cloned()
        .unwrap_or_default();

    // A row contain general settings.
    let mut settings_row = Row::new().height(Length::Units(50));

    let mut needs_update = false;

    let mut addons_mode_button = Button::new(
        addon_mode_button_state,
        Text::new("My Addons").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette));

    let mut catalog_mode_button = Button::new(
        catalog_mode_btn_state,
        Text::new("Catalog").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette));

    let mut install_mode_button = Button::new(
        install_mode_btn_state,
        Text::new("Install From URL").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette));

    match mode {
        Mode::MyAddons(_) => {
            addons_mode_button =
                addons_mode_button.style(style::SelectedDefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
        }
        Mode::Install => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button =
                install_mode_button.style(style::SelectedDefaultButton(color_palette));
        }
        Mode::Catalog => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button =
                catalog_mode_button.style(style::SelectedDefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
        }
    }

    if matches!(myaddons_state, State::Start) {
        addons_mode_button = addons_mode_button.style(style::DisabledDefaultButton(color_palette));
        catalog_mode_button =
            catalog_mode_button.style(style::DisabledDefaultButton(color_palette));
        install_mode_button =
            install_mode_button.style(style::DisabledDefaultButton(color_palette));
    } else {
        addons_mode_button =
            addons_mode_button.on_press(Interaction::ModeSelected(Mode::MyAddons(flavor)));
        catalog_mode_button =
            catalog_mode_button.on_press(Interaction::ModeSelected(Mode::Catalog));
        install_mode_button =
            install_mode_button.on_press(Interaction::ModeSelected(Mode::Install));
    }

    let addons_mode_button: Element<Interaction> = addons_mode_button.into();
    let catalog_mode_button: Element<Interaction> = catalog_mode_button.into();
    let install_mode_button: Element<Interaction> = install_mode_button.into();

    let segmented_mode_control_row = Row::new()
        .push(addons_mode_button.map(Message::Interaction))
        .push(catalog_mode_button.map(Message::Interaction))
        .push(install_mode_button.map(Message::Interaction))
        .spacing(1);

    let segmented_mode_control_container = Container::new(segmented_mode_control_row)
        .padding(2)
        .style(style::SegmentedContainer(color_palette));

    let mut retail_button = Button::new(
        retail_btn_state,
        Text::new(Flavor::Retail.to_string()).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette))
    .on_press(Interaction::FlavorSelected(Flavor::Retail));

    let mut retail_ptr_button = Button::new(
        retail_ptr_btn_state,
        Text::new(Flavor::RetailPTR.to_string()).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette))
    .on_press(Interaction::FlavorSelected(Flavor::RetailPTR));

    let mut retail_beta_button = Button::new(
        retail_beta_btn_state,
        Text::new(Flavor::RetailBeta.to_string()).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette))
    .on_press(Interaction::FlavorSelected(Flavor::RetailBeta));

    let mut classic_button = Button::new(
        classic_btn_state,
        Text::new(Flavor::Classic.to_string()).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette))
    .on_press(Interaction::FlavorSelected(Flavor::Classic));

    let mut classic_ptr_button = Button::new(
        classic_ptr_btn_state,
        Text::new(Flavor::ClassicPTR.to_string()).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette))
    .on_press(Interaction::FlavorSelected(Flavor::ClassicPTR));

    match config.wow.flavor {
        Flavor::Retail => {
            retail_button = retail_button.style(style::SelectedDefaultButton(color_palette));
            retail_ptr_button = retail_ptr_button.style(style::DefaultButton(color_palette));
            retail_beta_button = retail_beta_button.style(style::DefaultButton(color_palette));
            classic_button = classic_button.style(style::DefaultButton(color_palette));
            classic_ptr_button = classic_ptr_button.style(style::DefaultButton(color_palette));
        }
        Flavor::RetailPTR => {
            retail_button = retail_button.style(style::DefaultButton(color_palette));
            retail_ptr_button =
                retail_ptr_button.style(style::SelectedDefaultButton(color_palette));
            retail_beta_button = retail_beta_button.style(style::DefaultButton(color_palette));
            classic_button = classic_button.style(style::DefaultButton(color_palette));
            classic_ptr_button = classic_ptr_button.style(style::DefaultButton(color_palette));
        }
        Flavor::RetailBeta => {
            retail_button = retail_button.style(style::DefaultButton(color_palette));
            retail_ptr_button = retail_ptr_button.style(style::DefaultButton(color_palette));
            retail_beta_button =
                retail_beta_button.style(style::SelectedDefaultButton(color_palette));
            classic_button = classic_button.style(style::DefaultButton(color_palette));
            classic_ptr_button = classic_ptr_button.style(style::DefaultButton(color_palette));
        }
        Flavor::Classic => {
            retail_button = retail_button.style(style::DefaultButton(color_palette));
            retail_ptr_button = retail_ptr_button.style(style::DefaultButton(color_palette));
            retail_beta_button = retail_beta_button.style(style::DefaultButton(color_palette));
            classic_button = classic_button.style(style::SelectedDefaultButton(color_palette));
            classic_ptr_button = classic_ptr_button.style(style::DefaultButton(color_palette));
        }
        Flavor::ClassicPTR => {
            retail_button = retail_button.style(style::DefaultButton(color_palette));
            retail_ptr_button = retail_ptr_button.style(style::DefaultButton(color_palette));
            retail_beta_button = retail_beta_button.style(style::DefaultButton(color_palette));
            classic_button = classic_button.style(style::DefaultButton(color_palette));
            classic_ptr_button =
                classic_ptr_button.style(style::SelectedDefaultButton(color_palette));
        }
    }

    let retail_button: Element<Interaction> = retail_button.into();
    let retail_ptr_button: Element<Interaction> = retail_ptr_button.into();
    let retail_beta_button: Element<Interaction> = retail_beta_button.into();
    let classic_button: Element<Interaction> = classic_button.into();
    let classic_ptr_button: Element<Interaction> = classic_ptr_button.into();

    let mut segmented_flavor_control_row = Row::new();

    if valid_flavors.len() > 1 {
        if valid_flavors.iter().any(|f| *f == Flavor::Retail) {
            segmented_flavor_control_row =
                segmented_flavor_control_row.push(retail_button.map(Message::Interaction))
        }

        if valid_flavors.iter().any(|f| *f == Flavor::RetailPTR) {
            segmented_flavor_control_row =
                segmented_flavor_control_row.push(retail_ptr_button.map(Message::Interaction))
        }

        if valid_flavors.iter().any(|f| *f == Flavor::RetailBeta) {
            segmented_flavor_control_row =
                segmented_flavor_control_row.push(retail_beta_button.map(Message::Interaction))
        }

        if valid_flavors.iter().any(|f| *f == Flavor::Classic) {
            segmented_flavor_control_row =
                segmented_flavor_control_row.push(classic_button.map(Message::Interaction))
        }

        if valid_flavors.iter().any(|f| *f == Flavor::ClassicPTR) {
            segmented_flavor_control_row =
                segmented_flavor_control_row.push(classic_ptr_button.map(Message::Interaction))
        }

        segmented_flavor_control_row = segmented_flavor_control_row.spacing(1);
    }

    let segmented_flavor_control_container = Container::new(segmented_flavor_control_row)
        .padding(2)
        .style(style::SegmentedContainer(color_palette));

    // Displays an error, if any has occured.
    let error_text = if let Some(error) = error {
        Text::new(error).size(DEFAULT_FONT_SIZE)
    } else {
        // Display nothing.
        Text::new("")
    };

    let error_container = Container::new(error_text)
        .center_y()
        .center_x()
        .padding(5)
        .width(Length::Fill)
        .style(style::NormalErrorForegroundContainer(color_palette));

    let version_text = Text::new(if let Some(release) = &self_update_state.latest_release {
        if VersionCompare::compare_to(&release.tag_name, VERSION, &CompOp::Gt).unwrap_or(false) {
            needs_update = true;

            format!(
                "New Ajour version available {} -> {}",
                VERSION, &release.tag_name
            )
        } else {
            VERSION.to_owned()
        }
    } else {
        VERSION.to_owned()
    })
    .size(DEFAULT_FONT_SIZE)
    .horizontal_alignment(HorizontalAlignment::Right);

    let version_container = Container::new(version_text)
        .center_y()
        .padding(5)
        .style(style::NormalForegroundContainer(color_palette));

    let settings_button: Element<Interaction> = Button::new(
        settings_button_state,
        Text::new("Settings")
            .horizontal_alignment(HorizontalAlignment::Center)
            .size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultButton(color_palette))
    .on_press(Interaction::Settings)
    .into();

    // Surrounds the elements with spacers, in order to make the GUI look good.
    settings_row = settings_row
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(segmented_mode_control_container)
        .push(Space::new(Length::Units(20), Length::Units(0)))
        .push(segmented_flavor_control_container)
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(error_container)
        .push(version_container);

    // Add download button to latest github release page if Ajour update is available.
    if needs_update {
        let text = self_update_state
            .status
            .as_ref()
            .map(|s| s.to_string())
            .unwrap_or_else(|| "Update".to_string());

        let mut new_release_button = Button::new(
            &mut self_update_state.btn_state,
            Text::new(&text).size(DEFAULT_FONT_SIZE),
        )
        .style(style::SecondaryButton(color_palette));

        new_release_button = new_release_button.on_press(Interaction::UpdateAjour);

        let new_release_button: Element<Interaction> = new_release_button.into();

        let spacer = Space::new(Length::Units(3), Length::Units(0));

        settings_row = settings_row.push(new_release_button.map(Message::Interaction));
        settings_row = settings_row.push(spacer);
    }

    settings_row = settings_row
        .push(settings_button.map(Message::Interaction))
        .push(Space::new(
            Length::Units(DEFAULT_PADDING + 5),
            Length::Units(0),
        ))
        .align_items(Align::Center);

    // Add space above settings_row.
    let settings_column = Column::new().push(settings_row);

    // Wraps it in a container.
    Container::new(settings_column).style(style::BrightForegroundContainer(color_palette))
}

pub fn status_container<'a>(
    color_palette: ColorPalette,
    title: &str,
    description: &str,
    onboarding_directory_btn_state: Option<&'a mut button::State>,
) -> Container<'a, Message> {
    let title = Text::new(title)
        .size(DEFAULT_FONT_SIZE)
        .width(Length::Fill)
        .horizontal_alignment(HorizontalAlignment::Center);
    let title_container = Container::new(title)
        .width(Length::Fill)
        .style(style::BrightBackgroundContainer(color_palette));

    let description = Text::new(description)
        .size(DEFAULT_FONT_SIZE)
        .width(Length::Fill)
        .horizontal_alignment(HorizontalAlignment::Center);
    let description_container = Container::new(description)
        .width(Length::Fill)
        .style(style::NormalBackgroundContainer(color_palette));

    let mut colum = Column::new()
        .push(title_container)
        .push(Space::new(Length::Units(0), Length::Units(2)))
        .push(description_container);

    if let (_, Some(btn_state)) = (State::Start, onboarding_directory_btn_state) {
        let onboarding_button_title_container =
            Container::new(Text::new("Select Directory").size(DEFAULT_FONT_SIZE))
                .width(Length::Units(120))
                .center_x()
                .align_x(Align::Center);
        let onboarding_button: Element<Interaction> =
            Button::new(btn_state, onboarding_button_title_container)
                .width(Length::Units(120))
                .style(style::DefaultButton(color_palette))
                .on_press(Interaction::OpenDirectory(DirectoryType::Wow))
                .into();

        colum = colum
            .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
            .push(onboarding_button.map(Message::Interaction))
            .align_items(Align::Center);
    }

    Container::new(colum)
        .center_y()
        .center_x()
        .width(Length::Fill)
        .height(Length::Fill)
}

pub fn catalog_row_titles<'a>(
    color_palette: ColorPalette,
    catalog: &Catalog,
    header_state: &'a mut header::State,
    column_state: &'a mut [CatalogColumnState],
    previous_column_key: Option<CatalogColumnKey>,
    previous_sort_direction: Option<SortDirection>,
) -> Header<'a, Message> {
    // A row containing titles above the addon rows.
    let mut row_titles = vec![];

    for column in column_state.iter_mut().filter(|c| !c.hidden) {
        let column_key = column.key;

        let row_title = row_title(
            column_key,
            previous_column_key,
            previous_sort_direction,
            &column.key.title(),
        );

        let mut row_header = Button::new(
            &mut column.btn_state,
            Text::new(row_title)
                .size(DEFAULT_FONT_SIZE)
                .width(Length::Fill),
        )
        .width(Length::Fill);

        if column_key != CatalogColumnKey::Install {
            row_header = row_header.on_press(Interaction::SortCatalogColumn(column_key));
        }

        if previous_column_key == Some(column_key) {
            row_header = row_header.style(style::SelectedColumnHeaderButton(color_palette));
        } else if column_key == CatalogColumnKey::Install {
            row_header = row_header.style(style::UnclickableColumnHeaderButton(color_palette));
        } else {
            row_header = row_header.style(style::ColumnHeaderButton(color_palette));
        }

        let row_header: Element<Interaction> = row_header.into();

        let row_container = Container::new(row_header.map(Message::Interaction))
            .width(column.width)
            .style(style::NormalBackgroundContainer(color_palette));

        // Only shows row titles if we have any catalog results.
        if !catalog.addons.is_empty() {
            row_titles.push((column.key.as_string(), row_container));
        }
    }

    Header::new(
        header_state,
        row_titles,
        Some(Length::Units(DEFAULT_PADDING)),
        Some(Length::Units(DEFAULT_PADDING + 5)),
    )
    .spacing(1)
    .height(Length::Units(25))
    .on_resize(3, |event| {
        Message::Interaction(Interaction::ResizeColumn(Mode::Catalog, event))
    })
}

pub fn catalog_data_cell<'a, 'b>(
    color_palette: ColorPalette,
    config: &Config,
    addon: &'a mut CatalogRow,
    column_config: &'b [(CatalogColumnKey, Length, bool)],
    installed_for_flavor: bool,
    install_addon: Option<&InstallAddon>,
) -> Container<'a, Message> {
    let default_height = Length::Units(26);

    let mut row_containers = vec![];

    let addon_data = &addon.addon;
    let website_state = &mut addon.website_state;
    let install_button_state = &mut addon.install_button_state;

    let flavor_exists_for_addon = addon_data
        .game_versions
        .iter()
        .any(|gc| gc.flavor == config.wow.flavor.base_flavor());

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == CatalogColumnKey::Install && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let status = install_addon.map(|a| a.status.clone());

        let install_text = Text::new(if !flavor_exists_for_addon {
            "N/A"
        } else {
            match status {
                Some(InstallStatus::Downloading) => "Downloading",
                Some(InstallStatus::Unpacking) => "Unpacking",
                Some(InstallStatus::Retry) => "Retry",
                Some(InstallStatus::Unavilable) | Some(InstallStatus::Error(_)) => "Unavailable",
                None => {
                    if installed_for_flavor {
                        "Installed"
                    } else {
                        "Install"
                    }
                }
            }
        })
        .size(DEFAULT_FONT_SIZE);

        let install_wrapper = Container::new(install_text)
            .width(*width)
            .center_x()
            .align_x(Align::Center);

        let mut install_button = Button::new(install_button_state, install_wrapper)
            .style(style::DefaultButton(color_palette))
            .width(*width);

        if flavor_exists_for_addon
            && (status == Some(InstallStatus::Retry) || (status == None && !installed_for_flavor))
        {
            install_button = install_button.on_press(Interaction::InstallAddon(
                config.wow.flavor,
                addon_data.id.to_string(),
                InstallKind::Catalog {
                    source: addon_data.source,
                },
            ));
        }

        let install_button: Element<Interaction> = install_button.into();

        let install_container = Container::new(install_button.map(Message::Interaction))
            .height(default_height)
            .width(*width)
            .center_y()
            .style(style::BrightForegroundContainer(color_palette));

        row_containers.push((idx, install_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, _))| {
            if *key == CatalogColumnKey::Title {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let title = Text::new(&addon_data.name).size(DEFAULT_FONT_SIZE);
        let title_button: Element<Interaction> = Button::new(website_state, title)
            .style(style::BrightTextButton(color_palette))
            .on_press(Interaction::OpenLink(addon_data.website_url.clone()))
            .into();

        let title_container = Container::new(title_button.map(Message::Interaction))
            .height(default_height)
            .width(*width)
            .center_y()
            .style(style::BrightForegroundContainer(color_palette));

        row_containers.push((idx, title_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == CatalogColumnKey::Description && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let description = {
            let text = &addon_data.summary;
            if !text.is_empty() {
                text
            } else {
                "-"
            }
        };
        let description = Text::new(description).size(DEFAULT_FONT_SIZE);
        let description_container = Container::new(description)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, description_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == CatalogColumnKey::Source && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let source = Text::new(&format!("{}", addon_data.source)).size(DEFAULT_FONT_SIZE);
        let source_container = Container::new(source)
            .height(default_height)
            .width(*width)
            .center_y()
            .center_x()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, source_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == CatalogColumnKey::GameVersion && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let game_version_text = addon_data
            .game_versions
            .iter()
            .find(|gv| gv.flavor == config.wow.flavor.base_flavor())
            .map(|gv| gv.game_version.clone())
            .unwrap_or_else(|| "-".to_owned());

        let game_version_text = Text::new(game_version_text).size(DEFAULT_FONT_SIZE);
        let game_version_container = Container::new(game_version_text)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, game_version_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == CatalogColumnKey::DateReleased && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let release_date_text: String = if let Some(date_released) = addon_data.date_released {
            let f = timeago::Formatter::new();
            let now = Local::now();
            f.convert_chrono(date_released, now)
        } else {
            "-".to_string()
        };
        let release_date_text = Text::new(release_date_text).size(DEFAULT_FONT_SIZE);
        let game_version_container = Container::new(release_date_text)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, game_version_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == CatalogColumnKey::NumDownloads && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let num_downloads = Text::new(
            &addon_data
                .number_of_downloads
                .to_formatted_string(&Locale::en),
        )
        .size(DEFAULT_FONT_SIZE);
        let num_downloads_container = Container::new(num_downloads)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::NormalForegroundContainer(color_palette));

        row_containers.push((idx, num_downloads_container));
    }

    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
    let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));

    let mut row = Row::new().push(left_spacer).spacing(1);

    // Sort columns and push them into row
    row_containers.sort_by(|a, b| a.0.cmp(&b.0));
    for (_, elem) in row_containers.into_iter() {
        row = row.push(elem);
    }

    row = row.push(right_spacer);

    Container::new(row)
        .width(Length::Fill)
        .style(style::Row(color_palette))
}

pub fn addon_scrollable(
    color_palette: ColorPalette,
    state: &'_ mut scrollable::State,
) -> Scrollable<'_, Message> {
    Scrollable::new(state)
        .spacing(1)
        .height(Length::FillPortion(1))
        .style(style::Scrollable(color_palette))
}
