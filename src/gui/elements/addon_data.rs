use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{style, ColumnKey, ExpandType, Interaction, Message, ReleaseChannel},
    ajour_core::{
        addon::{Addon, AddonState},
        theme::ColorPalette,
    },
    chrono::prelude::*,
    iced::{Align, Button, Column, Container, Element, Length, PickList, Row, Space, Text},
};

pub fn addon_data_container<'a, 'b>(
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
    let changelog_url = addon.changelog_url().map(str::to_string);
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
        let mut title_button = Button::new(&mut addon.details_btn_state, title)
            .on_press(Interaction::Expand(ExpandType::Details(addon_cloned)));

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

        let installed_version_container = Container::new(installed_version)
            .padding(5)
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
        let remote_version_container = Container::new(remote_version)
            .padding(5)
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
            AddonState::Idle => Container::new(Text::new("".to_string()).size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .style(style::NormalForegroundContainer(color_palette)),
            AddonState::Completed => {
                Container::new(Text::new("Completed".to_string()).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .style(style::NormalForegroundContainer(color_palette))
            }
            AddonState::Error(message) => {
                Container::new(Text::new(message).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .style(style::NormalForegroundContainer(color_palette))
            }
            AddonState::Updatable | AddonState::Retry => {
                let id = addon.primary_folder_id.clone();

                let text = match addon.state {
                    AddonState::Updatable => "Update",
                    AddonState::Retry => "Retry",
                    _ => "",
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
        if let ExpandType::Details(_) = expand_type {
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

            let release_channel_title = Text::new("Remote release channel").size(DEFAULT_FONT_SIZE);
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

            let mut ignore_button = Button::new(&mut addon.ignore_btn_state, ignore_button_text)
                .on_press(Interaction::Ignore(addon.primary_folder_id.clone()))
                .style(style::DefaultButton(color_palette));

            if is_ignored {
                ignore_button =
                    ignore_button.on_press(Interaction::Unignore(addon.primary_folder_id.clone()));
            } else {
                ignore_button =
                    ignore_button.on_press(Interaction::Ignore(addon.primary_folder_id.clone()));
            }

            let ignore_button: Element<Interaction> = ignore_button.into();

            let delete_button: Element<Interaction> = Button::new(
                &mut addon.delete_btn_state,
                Text::new("Delete").size(DEFAULT_FONT_SIZE),
            )
            .on_press(Interaction::Delete(addon.primary_folder_id.clone()))
            .style(style::DefaultDeleteButton(color_palette))
            .into();

            let mut changelog_button = Button::new(
                &mut addon.changelog_btn_state,
                Text::new("Changelog").size(DEFAULT_FONT_SIZE),
            )
            .style(style::DefaultButton(color_palette));

            if let Some(link) = changelog_url {
                changelog_button = changelog_button.on_press(Interaction::OpenLink(link));
            }

            let changelog_button: Element<Interaction> = changelog_button.into();

            let test_row = Row::new()
                .push(release_channel_list)
                .push(release_date_text_container);

            let button_row = Row::new()
                .push(Space::new(Length::Fill, Length::Units(0)))
                .push(website_button.map(Message::Interaction))
                .push(Space::new(Length::Units(5), Length::Units(0)))
                .push(changelog_button.map(Message::Interaction))
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
    }

    Container::new(addon_column)
        .width(Length::Fill)
        .style(style::Row(color_palette))
}
