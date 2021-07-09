use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{
        style, AddonsSearchState, ColumnKey, ColumnState, ExpandType, Flavor, Interaction, Message,
        Mode, ReleaseChannel, SortDirection, State,
    },
    crate::localization::{localized_string, localized_timeago_formatter},
    ajour_core::{
        addon::{Addon, AddonState},
        config::Config,
        theme::ColorPalette,
    },
    ajour_widgets::{header, Header, TableRow},
    chrono::prelude::*,
    iced::{
        button, Align, Button, Column, Container, Element, Length, PickList, Row, Space, Text,
        TextInput,
    },
    std::collections::HashMap,
    strfmt::strfmt,
};

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

pub fn titles_row_header<'a>(
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
pub fn data_row_container<'a, 'b>(
    color_palette: ColorPalette,
    addon: &'a mut Addon,
    is_addon_expanded: bool,
    expand_type: &'a ExpandType,
    config: &Config,
    column_config: &'b [(ColumnKey, Length, bool)],
    is_odd: Option<bool>,
) -> TableRow<'a, Message> {
    let default_height = Length::Units(26);
    let default_row_height = 26;

    let mut row_containers = vec![];

    let author = addon.author().map(str::to_string);
    let game_version = addon.game_version().map(str::to_string);
    let notes = addon.notes().map(str::to_string);
    let website_url = addon.website_url().map(str::to_string);
    let changelog_url = addon.changelog_url(config.addons.global_release_channel);
    let repository_kind = addon.repository_kind();

    let global_release_channel = config.addons.global_release_channel;

    // Check if current addon is expanded.
    let addon_cloned = addon.clone();
    let addon_cloned_for_row = addon.clone();
    let version = addon
        .version()
        .map(str::to_string)
        .unwrap_or_else(|| "-".to_string());
    let release_package = addon_cloned.relevant_release_package(global_release_channel);

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

        let mut title_row = Row::new().push(title).spacing(5).align_items(Align::Center);

        if addon.release_channel != ReleaseChannel::Default {
            let release_channel =
                Container::new(Text::new(addon.release_channel.to_string()).size(10))
                    .style(style::ChannelBadge(color_palette))
                    .padding(3);

            title_row = title_row.push(release_channel);
        }

        let mut title_container = Container::new(title_row)
            .padding(5)
            .height(default_height)
            .width(*width)
            .center_y();
        if is_addon_expanded && matches!(expand_type, ExpandType::Details(_)) {
            title_container =
                title_container.style(style::SelectedBrightForegroundContainer(color_palette));
        } else {
            title_container =
                title_container.style(style::HoverableBrightForegroundContainer(color_palette));
        }

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
            .style(style::HoverableForegroundContainer(color_palette));

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
        let remote_version = if let Some(package) = &release_package {
            package.version.clone()
        } else {
            String::from("-")
        };
        let remote_version = Text::new(remote_version).size(DEFAULT_FONT_SIZE);

        let mut remote_version_button =
            Button::new(&mut addon.remote_version_btn_state, remote_version)
                .style(style::NormalTextButton(color_palette));

        if changelog_url.is_some() {
            remote_version_button =
                remote_version_button.on_press(Interaction::Expand(ExpandType::Changelog {
                    addon: addon_cloned.clone(),
                    changelog: None,
                }));
        }

        let remote_version_button: Element<Interaction> = remote_version_button.into();

        let remote_version_container =
            Container::new(remote_version_button.map(Message::Interaction))
                .height(default_height)
                .width(*width)
                .center_y()
                .style(style::HoverableForegroundContainer(color_palette));

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
            .style(style::HoverableForegroundContainer(color_palette));

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
            .style(style::HoverableForegroundContainer(color_palette));

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
            .style(style::HoverableForegroundContainer(color_palette));

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
            let f = localized_timeago_formatter();
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
            .style(style::HoverableForegroundContainer(color_palette));

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
            repository_kind.map_or_else(|| localized_string("unknown"), |a| a.to_string());
        let source = Text::new(source_text).size(DEFAULT_FONT_SIZE);
        let source_container = Container::new(source)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::HoverableForegroundContainer(color_palette));

        row_containers.push((idx, source_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == ColumnKey::Summary && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let text = addon_cloned.notes().unwrap_or("-");
        let summary = Text::new(text).size(DEFAULT_FONT_SIZE);
        let container = Container::new(summary)
            .height(default_height)
            .width(*width)
            .center_y()
            .padding(5)
            .style(style::HoverableForegroundContainer(color_palette));

        row_containers.push((idx, container));
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
                .style(style::HoverableForegroundContainer(color_palette)),
            AddonState::Completed => {
                Container::new(Text::new(localized_string("completed")).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .style(style::HoverableForegroundContainer(color_palette))
            }
            AddonState::Error(message) => {
                Container::new(Text::new(message).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .style(style::HoverableForegroundContainer(color_palette))
            }
            AddonState::Updatable | AddonState::Retry => {
                let id = addon.primary_folder_id.clone();

                let text = match addon.state {
                    AddonState::Updatable => localized_string("update"),
                    AddonState::Retry => localized_string("retry"),
                    _ => "".to_owned(),
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
                    .style(style::HoverableBrightForegroundContainer(color_palette))
            }
            AddonState::Downloading => {
                Container::new(Text::new(localized_string("downloading")).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .padding(5)
                    .style(style::HoverableForegroundContainer(color_palette))
            }
            AddonState::Unpacking => {
                Container::new(Text::new(localized_string("unpacking")).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .padding(5)
                    .style(style::HoverableForegroundContainer(color_palette))
            }
            AddonState::Fingerprint => {
                Container::new(Text::new(localized_string("hashing")).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .padding(5)
                    .style(style::HoverableForegroundContainer(color_palette))
            }
            AddonState::Ignored => {
                Container::new(Text::new(localized_string("ignored")).size(DEFAULT_FONT_SIZE))
                    .height(default_height)
                    .width(*width)
                    .center_y()
                    .center_x()
                    .padding(5)
                    .style(style::HoverableForegroundContainer(color_palette))
            }
            AddonState::Unknown => Container::new(Text::new("").size(DEFAULT_FONT_SIZE))
                .height(default_height)
                .width(*width)
                .center_y()
                .center_x()
                .padding(5)
                .style(style::HoverableForegroundContainer(color_palette)),
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
            ExpandType::Details(_) => {
                let notes = notes.unwrap_or_else(|| localized_string("no-addon-description"));
                let author = author.unwrap_or_else(|| "-".to_string());
                let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
                let space = Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING * 2));
                let bottom_space = Space::new(Length::Units(0), Length::Units(4));
                let notes_title_text =
                    Text::new(localized_string("summary")).size(DEFAULT_FONT_SIZE);
                let notes_text = Text::new(notes).size(DEFAULT_FONT_SIZE);
                let author_text = Text::new(author).size(DEFAULT_FONT_SIZE);
                let author_title_text =
                    Text::new(localized_string("authors")).size(DEFAULT_FONT_SIZE);
                let author_title_container = Container::new(author_title_text)
                    .style(style::HoverableBrightForegroundContainer(color_palette));
                let notes_title_container = Container::new(notes_title_text)
                    .style(style::HoverableBrightForegroundContainer(color_palette));

                let release_date_text: String = if let Some(package) = &release_package {
                    let f = localized_timeago_formatter();
                    let now = Local::now();

                    if let Some(time) = package.date_time.as_ref() {
                        f.convert_chrono(*time, now)
                    } else {
                        "".to_string()
                    }
                } else {
                    localized_string("release-channel-no-release")
                };
                let release_date_text = Text::new(release_date_text).size(DEFAULT_FONT_SIZE);
                let release_date_text_container = Container::new(release_date_text)
                    .center_y()
                    .padding(5)
                    .style(style::FadedBrightForegroundContainer(color_palette));

                let release_channel_title =
                    Text::new(localized_string("remote-release-channel")).size(DEFAULT_FONT_SIZE);
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
                    Text::new(localized_string("website")).size(DEFAULT_FONT_SIZE),
                )
                .style(style::DefaultButton(color_palette));

                if let Some(link) = website_url {
                    website_button = website_button.on_press(Interaction::OpenLink(link));
                }

                let website_button: Element<Interaction> = website_button.into();

                let is_ignored = addon.state == AddonState::Ignored;
                let ignore_button_text = if is_ignored {
                    Text::new(localized_string("unignore")).size(DEFAULT_FONT_SIZE)
                } else {
                    Text::new(localized_string("ignore")).size(DEFAULT_FONT_SIZE)
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
                    Text::new(localized_string("delete")).size(DEFAULT_FONT_SIZE),
                )
                .on_press(Interaction::Delete(addon.primary_folder_id.clone()))
                .style(style::DefaultDeleteButton(color_palette))
                .into();

                let mut changelog_button = Button::new(
                    &mut addon.changelog_btn_state,
                    Text::new(localized_string("changelog")).size(DEFAULT_FONT_SIZE),
                )
                .style(style::DefaultButton(color_palette));

                if changelog_url.is_some() {
                    changelog_button =
                        changelog_button.on_press(Interaction::Expand(ExpandType::Changelog {
                            addon: addon_cloned,
                            changelog: None,
                        }));
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
            ExpandType::Changelog { changelog, .. } => {
                let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
                let bottom_space = Space::new(Length::Units(0), Length::Units(4));

                let changelog_title_text =
                    Text::new(localized_string("changelog")).size(DEFAULT_FONT_SIZE);
                let changelog_title_container = Container::new(changelog_title_text)
                    .style(style::BrightForegroundContainer(color_palette));

                let changelog_text = match changelog {
                    Some(changelog) => changelog
                        .text
                        .as_ref()
                        .cloned()
                        .unwrap_or_else(|| localized_string("changelog-press-full-changelog")),
                    _ => localized_string("loading"),
                };

                let mut full_changelog_button = Button::new(
                    &mut addon.changelog_btn_state,
                    Text::new(localized_string("full-changelog")).size(DEFAULT_FONT_SIZE),
                )
                .style(style::DefaultButton(color_palette));

                if let Some(url) = &changelog_url {
                    full_changelog_button =
                        full_changelog_button.on_press(Interaction::OpenLink(url.clone()));
                }

                let full_changelog_button: Element<Interaction> = full_changelog_button.into();

                let mut button_row =
                    Row::new().push(Space::new(Length::FillPortion(1), Length::Units(0)));

                if changelog_url.is_some() {
                    button_row = button_row.push(full_changelog_button.map(Message::Interaction));
                }

                let column = Column::new()
                    .push(changelog_title_container)
                    .push(Space::new(Length::Units(0), Length::Units(12)))
                    .push(Text::new(changelog_text).size(DEFAULT_FONT_SIZE))
                    .push(Space::new(Length::Units(0), Length::Units(8)))
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
            ExpandType::None => {}
        }
    }

    let mut table_row = TableRow::new(addon_column)
        .width(Length::Fill)
        .inner_row_height(default_row_height)
        .on_press(move |_| {
            Message::Interaction(Interaction::Expand(ExpandType::Details(
                addon_cloned_for_row.clone(),
            )))
        });

    if is_odd == Some(true) {
        table_row = table_row.style(style::TableRowAlternate(color_palette))
    } else {
        table_row = table_row.style(style::TableRow(color_palette))
    }

    table_row
}

#[allow(clippy::too_many_arguments)]
pub fn menu_container<'a>(
    color_palette: ColorPalette,
    flavor: Flavor,
    update_all_button_state: &'a mut button::State,
    refresh_button_state: &'a mut button::State,
    addons_search_state: &'a mut AddonsSearchState,
    state: &HashMap<Mode, State>,
    addons: &[Addon],
    config: &Config,
) -> Container<'a, Message> {
    // MyAddons state.
    let state = state.get(&Mode::MyAddons(flavor));

    // A row contain general settings.
    let mut settings_row = Row::new().align_items(Align::Center);

    let mut update_all_button = Button::new(
        update_all_button_state,
        Text::new(localized_string("update-all")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultButton(color_palette));

    let mut refresh_button = Button::new(
        refresh_button_state,
        Text::new(localized_string("refresh")).size(DEFAULT_FONT_SIZE),
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
        update_all_button =
            update_all_button.on_press(Interaction::UpdateAll(Mode::MyAddons(flavor)));
    }

    // Enable refresh_button if:
    //   - No addon is performing any task.
    //   - Mode state isn't start or loading
    if !addons_performing_actions && !matches!(state, None | Some(State::Loading)) {
        refresh_button = refresh_button.on_press(Interaction::Refresh(Mode::MyAddons(flavor)));
    }

    let update_all_button: Element<Interaction> = update_all_button.into();
    let refresh_button: Element<Interaction> = refresh_button.into();

    // Displays text depending on the state of the app.
    let flavor = config.wow.flavor;
    let ignored_addons = config.addons.ignored.get(&flavor);

    let status_text = match state {
        Some(State::Ready) => {
            let flavor = flavor.to_string().to_lowercase();
            let addons_count = addons
                .iter()
                .filter(|a| !a.is_ignored(ignored_addons))
                .count()
                .to_string();
            let mut vars = HashMap::new();
            vars.insert("flavor".to_string(), &flavor);
            vars.insert("number".to_string(), &addons_count);
            let fmt = localized_string("addons-loaded");

            Text::new(strfmt(&fmt, &vars).unwrap()).size(DEFAULT_FONT_SIZE)
        }
        _ => Text::new(""),
    };

    let query = addons_search_state.query.as_deref().unwrap_or_default();
    let addons_query = TextInput::new(
        &mut addons_search_state.query_state,
        &localized_string("search-for-addon")[..],
        query,
        Interaction::AddonsQuery,
    )
    .size(DEFAULT_FONT_SIZE)
    .padding(7)
    .width(Length::Units(225))
    .style(style::AddonsQueryInput(color_palette));

    let addons_query: Element<Interaction> = addons_query.into();

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
        .push(Space::new(Length::Fill, Length::Units(0)))
        .push(addons_query.map(Message::Interaction))
        .push(Space::new(
            Length::Units(DEFAULT_PADDING + 5),
            Length::Units(0),
        ));

    // Add space above settings_row.
    let settings_column = Column::new()
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(settings_row)
        .push(Space::new(Length::Units(0), Length::Units(8)));

    // Wraps it in a container.
    Container::new(settings_column)
}
