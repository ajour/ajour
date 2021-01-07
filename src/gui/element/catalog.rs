use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{
        style, Catalog, CatalogColumnKey, CatalogColumnState, CatalogRow, InstallAddon,
        InstallKind, InstallStatus, Interaction, Message, Mode, SortDirection,
    },
    crate::localization::localized_string,
    ajour_core::{config::Config, theme::ColorPalette},
    ajour_widgets::{header, Header, TableRow},
    chrono::prelude::*,
    iced::{Align, Button, Container, Element, Length, Row, Space, Text},
    num_format::{Locale, ToFormattedString},
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

#[allow(clippy::too_many_arguments)]
pub fn data_row_container<'a, 'b>(
    color_palette: ColorPalette,
    config: &Config,
    addon: &'a mut CatalogRow,
    column_config: &'b [(CatalogColumnKey, Length, bool)],
    installed_for_flavor: bool,
    install_addon: Option<&InstallAddon>,
    is_odd: Option<bool>,
) -> TableRow<'a, Message> {
    let default_height = Length::Units(26);
    let default_row_height = 26;

    let mut row_containers = vec![];

    let addon_data = &addon.addon;
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
            localized_string("not-available-abbreviation")
        } else {
            match status {
                Some(InstallStatus::Downloading) => localized_string("downloading"),
                Some(InstallStatus::Unpacking) => localized_string("unpacking"),
                Some(InstallStatus::Retry) => localized_string("retry"),
                Some(InstallStatus::Unavilable) | Some(InstallStatus::Error(_)) => {
                    localized_string("unavilable")
                }
                None => {
                    if installed_for_flavor {
                        localized_string("installed")
                    } else {
                        localized_string("install")
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
            .style(style::SecondaryButton(color_palette))
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
            .style(style::HoverableBrightForegroundContainer(color_palette));

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

        let title_container = Container::new(title)
            .padding(5)
            .height(default_height)
            .width(*width)
            .center_y()
            .style(style::HoverableBrightForegroundContainer(color_palette));

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
            .style(style::HoverableForegroundContainer(color_palette));

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
            .style(style::HoverableForegroundContainer(color_palette));

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
            .style(style::HoverableForegroundContainer(color_palette));

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
        // TODO (casperstorm): localization timeago.
        // @see: https://docs.rs/timeago/0.2.1/timeago/
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
            .style(style::HoverableForegroundContainer(color_palette));

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
            .style(style::HoverableForegroundContainer(color_palette));

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

    let mut table_row = TableRow::new(row)
        .width(Length::Fill)
        .inner_row_height(default_row_height)
        .on_press(move |_| {
            Message::Interaction(Interaction::OpenLink(addon_data.website_url.clone()))
        });

    if is_odd == Some(true) {
        table_row = table_row.style(style::TableRowAlternate(color_palette))
    } else {
        table_row = table_row.style(style::TableRow(color_palette))
    }

    table_row
}
