use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{
        style, CatalogColumnKey, CatalogRow, InstallAddon, InstallKind, InstallStatus, Interaction,
        Message,
    },
    ajour_core::{config::Config, theme::ColorPalette},
    chrono::prelude::*,
    iced::{Align, Button, Container, Element, Length, Row, Space, Text},
    num_format::{Locale, ToFormattedString},
};

pub fn catalog_data_container<'a, 'b>(
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
