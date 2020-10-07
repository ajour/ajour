#![allow(clippy::too_many_arguments)]

use {
    super::{
        style, AjourMode, AjourState, BackupState, CatalogColumnKey, CatalogColumnState,
        CatalogRow, ColumnKey, ColumnSettings, ColumnState, DirectoryType, Interaction, Message,
        ReleaseChannel, ScaleState, SortDirection, ThemeState, LanguageState
    },
    crate::VERSION,
    ajour_core::{
        addon::{Addon, AddonState},
        catalog::Catalog,
        config::{Config, Flavor},
        theme::ColorPalette,
    },
    chrono::prelude::*,
    iced::{
        button, scrollable, Align, Button, Checkbox, Column, Container, Element,
        HorizontalAlignment, Length, PickList, Row, Scrollable, Space, Text, VerticalAlignment,
    },
    tr::tr,
    num_format::{Locale, ToFormattedString},
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
    language_state : &'a mut LanguageState,
    theme_state: &'a mut ThemeState,
    scale_state: &'a mut ScaleState,
    backup_state: &'a mut BackupState,
    column_settings: &'a mut ColumnSettings,
    column_config: &'b [(ColumnKey, Length, bool)],
) -> Container<'a, Message> {
    // Title for the World of Warcraft directory selection.
    let directory_info_text = Text::new(tr!("World of Warcraft directory")).size(14);

    // Directory button for World of Warcraft directory selection.
    let directory_button_title_container =
        Container::new(Text::new(tr!("Select Directory")).size(DEFAULT_FONT_SIZE))
            .width(Length::FillPortion(1))
            .center_x()
            .align_x(Align::Center);

    let directory_button: Element<Interaction> =
        Button::new(directory_button_state, directory_button_title_container)
            .width(Length::Units(100))
            .style(style::DefaultBoxedButton(color_palette))
            .on_press(Interaction::OpenDirectory(DirectoryType::Wow))
            .into();

    // Directory text, written next to directory button to let the user
    // know what has been selected..
    let directory_text = tr!("No directory is set");
    let path_str = config
        .wow
        .directory
        .as_ref()
        .and_then(|p| p.to_str())
        .unwrap_or(&directory_text);
    let directory_data_text = Text::new(path_str)
        .size(14)
        .vertical_alignment(VerticalAlignment::Center);
    let directory_data_text_container = Container::new(directory_data_text)
        .height(Length::Units(25))
        .center_y()
        .style(style::SecondaryTextContainer(color_palette));

    // Data row for the World of Warcraft directory selection.
    let path_data_row = Row::new()
        .push(directory_button.map(Message::Interaction))
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(directory_data_text_container);

    // Title for the language pick list
    let language_info_text = Text::new(tr!("Language")).size(14);
    let language_info_row = Row::new().push(language_info_text);

    let language_codes = language_state
        .languages
        .iter()
        .cloned()
        .map(|name|name)
        .collect::<Vec<_>>();
    let language_pick_list = PickList::new(
        &mut language_state.pick_list_state,
        language_codes,
        Some(language_state.current_language_name.clone()),
        Message::LanguageSelected,
    )
    .text_size(14)
    .width(Length::Units(100))
    .style(style::PickList(color_palette));

    // Data row for language pick list
    let language_data_row = Row::new().push(language_pick_list);

    // Title for the theme pick list.
    let theme_info_text = Text::new(tr!("Theme")).size(14);
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
    .width(Length::Units(100))
    .style(style::PickList(color_palette));

    // Data row for theme picker list.
    let theme_data_row = Row::new().push(theme_pick_list);

    // Scale buttons for application scale factoring.
    let (scale_title_row, scale_buttons_row) = {
        let scale_title = Text::new(tr!("UI Scale")).size(DEFAULT_FONT_SIZE);
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
            .style(style::SecondaryTextContainer(color_palette));

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
        let backup_title_text = Text::new(tr!("Backup")).size(DEFAULT_FONT_SIZE);
        let backup_title_row = Row::new().push(backup_title_text);

        // Directory button for Backup directory selection.
        let directory_button_title_container =
            Container::new(Text::new(tr!("Select Directory")).size(DEFAULT_FONT_SIZE))
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
        let directory_text = tr!("No directory is set");
        let path_str = config
            .backup_directory
            .as_ref()
            .and_then(|p| p.to_str())
            .unwrap_or(&directory_text);
        let directory_data_text = Text::new(path_str)
            .size(DEFAULT_FONT_SIZE)
            .vertical_alignment(VerticalAlignment::Center);
        let directory_data_text_container = Container::new(directory_data_text)
            .height(Length::Units(25))
            .center_y()
            .style(style::SecondaryTextContainer(color_palette));

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
                Container::new(Text::new(tr!("Backup Now")).size(DEFAULT_FONT_SIZE))
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
                Text::new(tr!("Backing up..."))
                    .size(DEFAULT_FONT_SIZE)
                    .vertical_alignment(VerticalAlignment::Center)
            } else {
                let as_of = backup_state
                    .last_backup
                    .map(|d| d.format("%Y-%m-%d %H:%M:%S").to_string())
                    .unwrap_or_else(|| tr!("Never").to_string());

                Text::new(&tr!("Last backup: {}", as_of))
                    .size(DEFAULT_FONT_SIZE)
                    .vertical_alignment(VerticalAlignment::Center)
            };

            let backup_status_text_container = Container::new(backup_status_text)
                .height(Length::Units(25))
                .center_y()
                .style(style::SecondaryTextContainer(color_palette));

            let backup_button: Element<Interaction> = backup_button.into();

            backup_now_row = backup_now_row
                .push(backup_button.map(Message::Interaction))
                .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                .push(backup_status_text_container);
        } else {
            let backup_status_text =
                Text::new(tr!("Back up your AddOns and WTF folder to the chosen directory"))
                    .size(DEFAULT_FONT_SIZE)
                    .vertical_alignment(VerticalAlignment::Center);

            let backup_status_text_container = Container::new(backup_status_text)
                .height(Length::Units(25))
                .center_y()
                .style(style::SecondaryTextContainer(color_palette));

            backup_now_row = backup_now_row.push(backup_status_text_container);
        }

        (backup_title_row, backup_directory_row, backup_now_row)
    };

    let (columns_title_row, columns_scrollable) = {
        // Title for the Columns section.
        let columns_title_text = Text::new(tr!("Columns")).size(DEFAULT_FONT_SIZE);
        let columns_title_row = Row::new().push(columns_title_text).padding(DEFAULT_PADDING);

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
                    color_palette.primary
                } else {
                    let mut color = color_palette.primary;
                    color.a = 0.20;
                    color
                }),
            )
            .style(style::DefaultButton(color_palette));
            if !is_first {
                left_button = left_button.on_press(Interaction::MoveColumnLeft(column_key));
            }

            let mut right_button = Button::new(
                &mut column.down_btn_state,
                Text::new(" ▼ ").size(11).color(if !is_last {
                    color_palette.primary
                } else {
                    let mut color = color_palette.primary;
                    color.a = 0.20;
                    color
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

    // Colum wrapping all the settings content.
    let left_column = Column::new()
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
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
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(scale_title_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(scale_buttons_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(theme_info_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(theme_data_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(language_info_row)
        .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
        .push(language_data_row);


    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
    let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));

    // Container wrapping colum.
    let left_container = Container::new(left_column)
        .width(Length::FillPortion(1))
        .height(Length::Shrink)
        .style(style::AddonRowDefaultTextContainer(color_palette));

    let middle_container = Container::new(middle_column)
        .width(Length::Units(150))
        .height(Length::Shrink)
        .style(style::AddonRowDefaultTextContainer(color_palette));

    let right_column = Column::new()
        .push(columns_title_row)
        .push(columns_scrollable)
        .push(Space::new(Length::Fill, Length::Units(DEFAULT_PADDING)));
    let right_container = Container::new(right_column)
        .width(Length::Units(200))
        .height(Length::Units(255))
        .style(style::AddonRowDefaultTextContainer(color_palette));

    // Row to wrap each section.
    let row = Row::new()
        .push(left_spacer)
        .push(right_container)
        .push(middle_container)
        .push(left_container)
        .push(right_spacer);

    // Returns the final container.
    Container::new(row)
        .height(Length::Shrink)
        .style(style::AddonRowDefaultTextContainer(color_palette))
        .padding(DEFAULT_PADDING + DEFAULT_PADDING)
}

pub fn addon_data_cell<'a, 'b>(
    color_palette: ColorPalette,
    addon: &'a mut Addon,
    is_addon_expanded: bool,
    column_config: &'b [(ColumnKey, Length, bool)],
) -> Container<'a, Message> {
    let default_height = Length::Units(26);

    let mut row_containers = vec![];

    // Check if current addon is expanded.
    let addon_cloned = addon.clone();
    let version = addon.version.clone().unwrap_or_else(|| String::from("-"));
    let release_package = addon_cloned.relevant_release_package();
    let remote_version = if let Some(package) = release_package.as_deref() {
        package.version.clone()
    } else {
        String::from("-")
    };

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
        let title = Text::new(&addon.title).size(DEFAULT_FONT_SIZE);
        let mut title_button = Button::new(&mut addon.details_btn_state, title)
            .on_press(Interaction::Expand(addon.id.clone()));

        if release_package.as_deref().is_some() {}

        if is_addon_expanded {
            title_button = title_button.style(style::SelectedTextButton(color_palette));
        } else {
            title_button = title_button.style(style::TextButton(color_palette));
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
            .style(style::AddonRowDefaultTextContainer(color_palette));

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
        let installed_version_container = Container::new(installed_version)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette));

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
        let remote_version = Text::new(remote_version).size(DEFAULT_FONT_SIZE);
        let remote_version_container = Container::new(remote_version)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette));

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
            .style(style::AddonRowSecondaryTextContainer(color_palette));

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
        let author = Text::new(addon.author.as_deref().unwrap_or("-")).size(DEFAULT_FONT_SIZE);
        let author_container = Container::new(author)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette));

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
            Text::new(addon.game_version.as_deref().unwrap_or("-")).size(DEFAULT_FONT_SIZE);
        let game_version_container = Container::new(game_version)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette));

        row_containers.push((idx, game_version_container));
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
            .style(style::AddonRowSecondaryTextContainer(color_palette)),
            AddonState::Updatable => {
                let id = addon.id.clone();
                let update_button: Element<Interaction> = Button::new(
                    &mut addon.update_btn_state,
                    Text::new(tr!("Update"))
                        .horizontal_alignment(HorizontalAlignment::Center)
                        .size(DEFAULT_FONT_SIZE),
                )
                .style(style::SecondaryButton(color_palette))
                .on_press(Interaction::Update(id))
                .into();

                Container::new(update_button.map(Message::Interaction))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .style(style::AddonRowDefaultTextContainer(color_palette))
            }
            AddonState::Downloading => {
                Container::new(Text::new(tr!("Downloading")).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .padding(5)
                    .style(style::AddonRowSecondaryTextContainer(color_palette))
            }
            AddonState::Unpacking => Container::new(Text::new(tr!("Unpacking")).size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .padding(5)
                .style(style::AddonRowSecondaryTextContainer(color_palette)),
            AddonState::Fingerprint => Container::new(Text::new(tr!("Hashing")).size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .padding(5)
                .style(style::AddonRowSecondaryTextContainer(color_palette)),
            AddonState::Ignored => Container::new(Text::new(tr!("Ignored")).size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .padding(5)
                .style(style::AddonRowSecondaryTextContainer(color_palette)),
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
        let notes = addon
            .notes
            .clone()
            .unwrap_or_else(|| tr!("No description for addon.").to_string());
        let author = addon.author.clone().unwrap_or_else(|| "-".to_string());
        let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
        let space = Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING * 2));
        let bottom_space = Space::new(Length::Units(0), Length::Units(4));
        let notes_title_text = Text::new(tr!("Summary")).size(DEFAULT_FONT_SIZE);
        let notes_text = Text::new(notes).size(DEFAULT_FONT_SIZE);
        let author_text = Text::new(author).size(DEFAULT_FONT_SIZE);
        let author_title_text = Text::new(tr!("Author(s)")).size(DEFAULT_FONT_SIZE);
        let author_title_container =
            Container::new(author_title_text).style(style::DefaultTextContainer(color_palette));
        let notes_title_container =
            Container::new(notes_title_text).style(style::DefaultTextContainer(color_palette));

        let release_date_text: String = if let Some(package) = release_package {
            let f = timeago::Formatter::new();
            let now = Local::now();

            if let Some(time) = package.date_time.as_ref() {
                format!("is {}", f.convert_chrono(*time, now))
            } else {
                "".to_string()
            }
        } else {
            tr!("has no avaiable release").to_string()
        };
        let release_date_text = Text::new(release_date_text).size(DEFAULT_FONT_SIZE);
        let release_date_text_container = Container::new(release_date_text)
            .center_y()
            .padding(5)
            .style(style::SecondaryTextContainer(color_palette));

        let release_channel_title = Text::new(tr!("Remote release channel")).size(DEFAULT_FONT_SIZE);
        let release_channel_title_container =
            Container::new(release_channel_title).style(style::DefaultTextContainer(color_palette));
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
            Text::new(tr!("Website")).size(DEFAULT_FONT_SIZE),
        )
        .style(style::DefaultBoxedButton(color_palette));

        if let Some(link) = addon.website_url.clone() {
            website_button = website_button.on_press(Interaction::OpenLink(link));
        }

        let website_button: Element<Interaction> = website_button.into();

        let mut force_download_button = Button::new(
            &mut addon.force_btn_state,
            Text::new(tr!("Force update")).size(DEFAULT_FONT_SIZE),
        )
        .style(style::DefaultBoxedButton(color_palette));

        // If we have a release package on addon, enable force update.
        if release_package.is_some() {
            force_download_button =
                force_download_button.on_press(Interaction::Update(addon.id.clone()));
        }

        let force_download_button: Element<Interaction> = force_download_button.into();

        let is_ignored = addon.state == AddonState::Ignored;
        let ignore_button_text = if is_ignored {
            Text::new(tr!("Unignore")).size(DEFAULT_FONT_SIZE)
        } else {
            Text::new(tr!("Ignore")).size(DEFAULT_FONT_SIZE)
        };

        let mut ignore_button = Button::new(&mut addon.ignore_btn_state, ignore_button_text)
            .on_press(Interaction::Ignore(addon.id.clone()))
            .style(style::DefaultBoxedButton(color_palette));

        if is_ignored {
            ignore_button = ignore_button.on_press(Interaction::Unignore(addon.id.clone()));
        } else {
            ignore_button = ignore_button.on_press(Interaction::Ignore(addon.id.clone()));
        }

        let ignore_button: Element<Interaction> = ignore_button.into();

        let delete_button: Element<Interaction> = Button::new(
            &mut addon.delete_btn_state,
            Text::new(tr!("Delete")).size(DEFAULT_FONT_SIZE),
        )
        .on_press(Interaction::Delete(addon.id.clone()))
        .style(style::DeleteBoxedButton(color_palette))
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
            .style(style::AddonRowDetailsContainer(color_palette));

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
            .style(style::SecondaryTextContainer(color_palette));

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
        Message::Interaction(Interaction::ResizeColumn(AjourMode::MyAddons, event))
    })
}

#[allow(clippy::too_many_arguments)]
pub fn menu_addons_container<'a>(
    color_palette: ColorPalette,
    update_all_button_state: &'a mut button::State,
    refresh_button_state: &'a mut button::State,
    retail_btn_state: &'a mut button::State,
    classic_btn_state: &'a mut button::State,
    state: &AjourState,
    addons: &[Addon],
    config: &'a mut Config,
) -> Container<'a, Message> {
    // A row contain general settings.
    let mut settings_row = Row::new().height(Length::Units(35));

    let mut update_all_button = Button::new(
        update_all_button_state,
        Text::new(tr!("Update All")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultBoxedButton(color_palette));

    let mut refresh_button = Button::new(
        refresh_button_state,
        Text::new(tr!("Refresh")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultBoxedButton(color_palette));

    // Is any addon performing an action.
    let addons_performing_actions = addons
        .iter()
        .any(|a| matches!(a.state, AddonState::Downloading | AddonState::Unpacking));

    let ajour_performing_actions = matches!(state, AjourState::Loading);
    let ajour_welcome = matches!(state, AjourState::Welcome);

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
    //   - Ajour isn't loading
    if !addons_performing_actions
        && !ajour_performing_actions
        && !matches!(state, AjourState::Welcome)
    {
        refresh_button = refresh_button.on_press(Interaction::Refresh);
    }

    let update_all_button: Element<Interaction> = update_all_button.into();
    let refresh_button: Element<Interaction> = refresh_button.into();

    let mut retail_button = Button::new(
        retail_btn_state,
        Text::new(tr!("Retail")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::SegmentedDisabledButton(color_palette))
    .on_press(Interaction::FlavorSelected(Flavor::Retail));

    let mut classic_button = Button::new(
        classic_btn_state,
        Text::new(tr!("Classic")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::SegmentedDisabledButton(color_palette))
    .on_press(Interaction::FlavorSelected(Flavor::Classic));

    if !ajour_performing_actions && !ajour_welcome {
        match config.wow.flavor {
            Flavor::Retail => {
                retail_button = retail_button.style(style::SegmentedSelectedButton(color_palette));
                classic_button =
                    classic_button.style(style::SegmentedUnselectedButton(color_palette));
            }
            Flavor::Classic => {
                classic_button =
                    classic_button.style(style::SegmentedSelectedButton(color_palette));
                retail_button =
                    retail_button.style(style::SegmentedUnselectedButton(color_palette));
            }
        }
    }

    let retail_button: Element<Interaction> = retail_button.into();
    let classic_button: Element<Interaction> = classic_button.into();

    let segmented_flavor_control_container = Row::new()
        .push(retail_button.map(Message::Interaction))
        .push(classic_button.map(Message::Interaction))
        .spacing(1);

    // Displays text depending on the state of the app.
    let flavor = config.wow.flavor;
    let ignored_addons = config.addons.ignored.get(&flavor);
    let parent_addons_count = addons
        .iter()
        .filter(|a| !a.is_ignored(ignored_addons))
        .count();

    let status_text = match state {
        AjourState::Idle => Text::new(tr!(
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
        .style(style::SecondaryTextContainer(color_palette));

    // Displays an error, if any has occured.
    let error_text = if let AjourState::Error(e) = state {
        Text::new(e.to_string()).size(DEFAULT_FONT_SIZE)
    } else {
        // Display nothing.
        Text::new("")
    };

    let error_container = Container::new(error_text)
        .center_y()
        .center_x()
        .padding(5)
        .width(Length::FillPortion(1))
        .style(style::StatusErrorTextContainer(color_palette));

    // Surrounds the elements with spacers, in order to make the GUI look good.
    settings_row = settings_row
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(refresh_button.map(Message::Interaction))
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(update_all_button.map(Message::Interaction))
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(segmented_flavor_control_container)
        .push(status_container)
        .push(error_container);

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
    mode: &AjourMode,
    state: &AjourState,
    settings_button_state: &'a mut button::State,
    addon_mode_button_state: &'a mut button::State,
    catalog_mode_btn_state: &'a mut button::State,
    needs_update: Option<&'a str>,
    new_release_button_state: &'a mut button::State,
) -> Container<'a, Message> {
    // A row contain general settings.
    let mut settings_row = Row::new().height(Length::Units(40));

    let mut addons_mode_button = Button::new(
        addon_mode_button_state,
        Text::new(tr!("My Addons")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::SegmentedDisabledButton(color_palette));

    let mut catalog_mode_button = Button::new(
        catalog_mode_btn_state,
        Text::new(tr!("Catalog")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::SegmentedDisabledButton(color_palette));

    match mode {
        AjourMode::MyAddons => {
            addons_mode_button =
                addons_mode_button.style(style::SegmentedSelectedButton(color_palette));
            catalog_mode_button =
                catalog_mode_button.style(style::SegmentedUnselectedButton(color_palette));
        }
        AjourMode::Catalog => {
            addons_mode_button =
                addons_mode_button.style(style::SegmentedUnselectedButton(color_palette));
            catalog_mode_button =
                catalog_mode_button.style(style::SegmentedSelectedButton(color_palette));
        }
    }

    // If we are onboarding, we disable the mode buttons and set proper styling.
    if !matches!(state, AjourState::Welcome | AjourState::Loading) {
        addons_mode_button =
            addons_mode_button.on_press(Interaction::ModeSelected(AjourMode::MyAddons));
        catalog_mode_button =
            catalog_mode_button.on_press(Interaction::ModeSelected(AjourMode::Catalog));
    } else {
        addons_mode_button =
            addons_mode_button.style(style::SegmentedDisabledButton(color_palette));
        catalog_mode_button =
            catalog_mode_button.style(style::SegmentedDisabledButton(color_palette));
    }

    let addons_mode_button: Element<Interaction> = addons_mode_button.into();
    let catalog_mode_button: Element<Interaction> = catalog_mode_button.into();

    let segmented_mode_control_container = Row::new()
        .push(addons_mode_button.map(Message::Interaction))
        .push(catalog_mode_button.map(Message::Interaction))
        .spacing(1);

    let version_text = Text::new(if let Some(new_version) = needs_update {
        tr!("New Ajour version available {} -> {}", VERSION, new_version)
    } else {
        VERSION.to_owned()
    })
    .size(DEFAULT_FONT_SIZE)
    .horizontal_alignment(HorizontalAlignment::Right);

    let mut version_container = Container::new(version_text).center_y().padding(5);
    if needs_update.is_some() {
        version_container = version_container.style(style::StatusErrorTextContainer(color_palette));
    } else {
        version_container = version_container.style(style::SecondaryTextContainer(color_palette));
    }

    let settings_button: Element<Interaction> = Button::new(
        settings_button_state,
        Text::new(tr!("Settings"))
            .horizontal_alignment(HorizontalAlignment::Center)
            .size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultBoxedButton(color_palette))
    .on_press(Interaction::Settings)
    .into();

    // Surrounds the elements with spacers, in order to make the GUI look good.
    settings_row = settings_row
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(segmented_mode_control_container)
        .push(Space::new(Length::Fill, Length::Units(0)))
        .push(version_container);

    // Add download button to latest github release page if Ajour update is available.
    if needs_update.is_some() {
        let mut new_release_button = Button::new(
            new_release_button_state,
            Text::new(tr!("Download")).size(DEFAULT_FONT_SIZE),
        )
        .style(style::SecondaryButton(color_palette));

        new_release_button = new_release_button.on_press(Interaction::OpenLink(
            "https://github.com/casperstorm/ajour/releases/latest".to_owned(),
        ));

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
    Container::new(settings_column).style(style::SurfaceContainer(color_palette))
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
        .style(style::DefaultTextContainer(color_palette));

    let description = Text::new(description)
        .size(DEFAULT_FONT_SIZE)
        .width(Length::Fill)
        .horizontal_alignment(HorizontalAlignment::Center);
    let description_container = Container::new(description)
        .width(Length::Fill)
        .style(style::SecondaryTextContainer(color_palette));

    let mut colum = Column::new()
        .push(title_container)
        .push(Space::new(Length::Units(0), Length::Units(2)))
        .push(description_container);

    if let (_, Some(btn_state)) = (AjourState::Welcome, onboarding_directory_btn_state) {
        let onboarding_button_title_container =
            Container::new(Text::new(tr!("Select Directory")).size(DEFAULT_FONT_SIZE))
                .width(Length::Units(100))
                .center_x()
                .align_x(Align::Center);
        let onboarding_button: Element<Interaction> =
            Button::new(btn_state, onboarding_button_title_container)
                .width(Length::Units(100))
                .style(style::DefaultBoxedButton(color_palette))
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

    for column in column_state.iter_mut() {
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

        if column_key != CatalogColumnKey::InstallRetail
            || column_key != CatalogColumnKey::InstallClassic
        {
            row_header = row_header.on_press(Interaction::SortCatalogColumn(column_key));
        }

        if previous_column_key == Some(column_key) {
            row_header = row_header.style(style::SelectedColumnHeaderButton(color_palette));
        } else if column_key == CatalogColumnKey::InstallRetail
            || column_key == CatalogColumnKey::InstallClassic
        {
            row_header = row_header.style(style::UnclickableColumnHeaderButton(color_palette));
        } else {
            row_header = row_header.style(style::ColumnHeaderButton(color_palette));
        }

        let row_header: Element<Interaction> = row_header.into();

        let row_container = Container::new(row_header.map(Message::Interaction))
            .width(column.width)
            .style(style::SecondaryTextContainer(color_palette));

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
        Message::Interaction(Interaction::ResizeColumn(AjourMode::Catalog, event))
    })
}

pub fn catalog_data_cell<'a, 'b>(
    color_palette: ColorPalette,
    addon: &'a mut CatalogRow,
    column_config: &'b [(CatalogColumnKey, Length)],
    retail_downloading: bool,
    retail_installed: bool,
    classic_downloading: bool,
    classic_installed: bool,
) -> Container<'a, Message> {
    let default_height = Length::Units(26);

    let mut row_containers = vec![];

    let addon_data = &addon.addon;
    let retail_install_state = &mut addon.retail_install_state;
    let classic_install_state = &mut addon.classic_install_state;

    let retail_exists = addon_data.flavors.contains(&Flavor::Retail);
    let classic_exists = addon_data.flavors.contains(&Flavor::Classic);

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width))| {
            if *key == CatalogColumnKey::InstallRetail {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let retail_install = Text::new(if !retail_exists {
            "N/A"
        } else if retail_downloading {
            "Downloading"
        } else if retail_installed {
            "Installed"
        } else {
            "Retail"
        })
        .size(DEFAULT_FONT_SIZE);

        let retail_install_wrapper = Container::new(retail_install)
            .width(*width)
            .center_x()
            .align_x(Align::Center);

        let mut retail_install_button = Button::new(retail_install_state, retail_install_wrapper)
            .style(style::DefaultBoxedButton(color_palette))
            .width(*width);

        if !retail_installed && !retail_downloading && retail_exists {
            retail_install_button = retail_install_button.on_press(Interaction::CatalogInstall(
                addon_data.source,
                Flavor::Retail,
                addon_data.id,
            ));
        }

        let retail_install_button: Element<Interaction> = retail_install_button.into();

        let retail_install_container =
            Container::new(retail_install_button.map(Message::Interaction))
                .height(default_height)
                .width(*width)
                .center_y()
                .style(style::AddonRowDefaultTextContainer(color_palette));

        row_containers.push((idx, retail_install_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width))| {
            if *key == CatalogColumnKey::InstallClassic {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let classic_install = Text::new(if !classic_exists {
            "N/A"
        } else if classic_downloading {
            "Downloading"
        } else if classic_installed {
            "Installed"
        } else {
            "Classic"
        })
        .size(DEFAULT_FONT_SIZE);

        let classic_install_wrapper = Container::new(classic_install)
            .width(*width)
            .center_x()
            .align_x(Align::Center);

        let mut classic_install_button =
            Button::new(classic_install_state, classic_install_wrapper)
                .style(style::DefaultBoxedButton(color_palette))
                .width(*width);

        if !classic_installed && !classic_downloading && classic_exists {
            classic_install_button = classic_install_button.on_press(Interaction::CatalogInstall(
                addon_data.source,
                Flavor::Classic,
                addon_data.id,
            ));
        }

        let classic_install_button: Element<Interaction> = classic_install_button.into();

        let classic_install_container =
            Container::new(classic_install_button.map(Message::Interaction))
                .height(default_height)
                .width(*width)
                .center_x()
                .center_y()
                .style(style::AddonRowDefaultTextContainer(color_palette));

        row_containers.push((idx, classic_install_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width))| {
            if *key == CatalogColumnKey::Title {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let title = Text::new(&addon_data.name).size(DEFAULT_FONT_SIZE);
        let title_container = Container::new(title)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::AddonRowDefaultTextContainer(color_palette));

        row_containers.push((idx, title_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width))| {
            if *key == CatalogColumnKey::Description {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let description = Text::new(&addon_data.summary).size(DEFAULT_FONT_SIZE);
        let description_container = Container::new(description)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette));

        row_containers.push((idx, description_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width))| {
            if *key == CatalogColumnKey::Source {
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
            .padding(5)
            .style(style::AddonRowDefaultTextContainer(color_palette));

        row_containers.push((idx, source_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width))| {
            if *key == CatalogColumnKey::NumDownloads {
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
            .style(style::AddonRowSecondaryTextContainer(color_palette));

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
