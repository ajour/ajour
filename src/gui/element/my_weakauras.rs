use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{
        style, AuraColumnKey, AuraColumnState, AuraStatus, Interaction, Message, Mode,
        SortDirection, State,
    },
    crate::localization::localized_string,
    ajour_core::config::Flavor,
    ajour_core::theme::ColorPalette,
    ajour_weak_auras::Aura,
    ajour_widgets::TableRow,
    ajour_widgets::{header, Header},
    iced::{
        button, pick_list, Align, Button, Column, Container, Element, Length, PickList, Row, Space,
        Text,
    },
    std::collections::HashMap,
    strfmt::strfmt,
};

#[allow(clippy::too_many_arguments)]
pub fn menu_container<'a>(
    color_palette: ColorPalette,
    flavor: Flavor,
    update_all_button_state: &'a mut button::State,
    refresh_button_state: &'a mut button::State,
    state: &HashMap<Mode, State>,
    num_auras: usize,
    updates_available: bool,
    is_updating: bool,
    updates_queued: bool,
    accounts_picklist_state: &'a mut pick_list::State<String>,
    accounts: &'a [String],
    chosen_account: Option<String>,
) -> Container<'a, Message> {
    // MyWeakAuras state.
    let state = state.get(&Mode::MyWeakAuras(flavor));

    // A row contain general settings.
    let mut row = Row::new().align_items(Align::Center);

    let mut update_all_button = Button::new(
        update_all_button_state,
        Text::new(localized_string("update-all")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultButton(color_palette));

    let refresh_button = Button::new(
        refresh_button_state,
        Text::new(localized_string("refresh")).size(DEFAULT_FONT_SIZE),
    )
    .on_press(Interaction::Refresh(Mode::MyWeakAuras(flavor)))
    .style(style::DefaultButton(color_palette));

    let pick_list = PickList::new(
        accounts_picklist_state,
        accounts,
        chosen_account.clone(),
        Message::WeakAurasAccountSelected,
    )
    .text_size(14)
    .width(Length::Units(120))
    .style(style::PickList(color_palette));

    if updates_available && !is_updating && !updates_queued {
        update_all_button =
            update_all_button.on_press(Interaction::UpdateAll(Mode::MyWeakAuras(flavor)));
    }

    let update_all_button: Element<Interaction> = update_all_button.into();
    let refresh_button: Element<Interaction> = refresh_button.into();
    let status_text = match state {
        Some(State::Ready) => {
            if updates_queued {
                Text::new(localized_string("weakaura-updates-queued")).size(DEFAULT_FONT_SIZE)
            } else {
                let mut vars = HashMap::new();
                vars.insert("number".to_string(), &num_auras);
                let fmt = localized_string("weakauras-loaded");

                Text::new(strfmt(&fmt, &vars).unwrap()).size(DEFAULT_FONT_SIZE)
            }
        }
        _ => Text::new(""),
    };

    let status_container = Container::new(status_text)
        .center_y()
        .padding(5)
        .style(style::NormalBackgroundContainer(color_palette));

    let account_info_container = Container::new(
        Text::new(if chosen_account.is_some() {
            "".to_owned()
        } else {
            localized_string("select-account")
        })
        .size(DEFAULT_FONT_SIZE),
    )
    .center_y()
    .padding(5)
    .style(style::NormalBackgroundContainer(color_palette));

    row = row
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(refresh_button.map(Message::Interaction))
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(update_all_button.map(Message::Interaction))
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(status_container)
        .push(Space::new(Length::Fill, Length::Units(0)))
        .push(account_info_container)
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(pick_list)
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)));

    // Add space above settings_row.
    let settings_column = Column::new()
        .push(Space::new(Length::Units(0), Length::Units(7)))
        .push(row)
        .push(Space::new(Length::Units(0), Length::Units(10)));

    // Wraps it in a container.
    Container::new(settings_column)
}

pub fn data_row_container<'a, 'b>(
    color_palette: ColorPalette,
    aura: &'a Aura,
    column_config: &'b [(AuraColumnKey, Length, bool)],
    is_odd: Option<bool>,
) -> TableRow<'a, Message> {
    let default_height = Length::Units(26);
    let default_row_height = 26;

    let mut row_containers = vec![];

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == AuraColumnKey::Title && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let title = Text::new(aura.name()).size(DEFAULT_FONT_SIZE);

        let title_row = Row::new().push(title).spacing(3).align_items(Align::Center);

        let title_container = Container::new(title_row)
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
            if *key == AuraColumnKey::LocalVersion && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let local_version =
            Text::new(aura.installed_symver().unwrap_or("-")).size(DEFAULT_FONT_SIZE);

        let local_version_row = Row::new()
            .push(local_version)
            .spacing(3)
            .align_items(Align::Center);

        let local_version_container = Container::new(local_version_row)
            .height(default_height)
            .width(*width)
            .center_y()
            .style(style::HoverableForegroundContainer(color_palette));

        row_containers.push((idx, local_version_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == AuraColumnKey::RemoteVersion && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let remote_version = Text::new(aura.remote_symver()).size(DEFAULT_FONT_SIZE);

        let remote_version_row = Row::new()
            .push(remote_version)
            .spacing(3)
            .align_items(Align::Center);

        let remote_version_container = Container::new(remote_version_row)
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
            if *key == AuraColumnKey::Author && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let author = Text::new(aura.author()).size(DEFAULT_FONT_SIZE);

        let author_row = Row::new()
            .push(author)
            .spacing(3)
            .align_items(Align::Center);

        let author_container = Container::new(author_row)
            .height(default_height)
            .width(*width)
            .center_y()
            .style(style::HoverableForegroundContainer(color_palette));

        row_containers.push((idx, author_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == AuraColumnKey::Type && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let kind = Text::new(aura.kind().to_string()).size(DEFAULT_FONT_SIZE);

        let kind_row = Row::new().push(kind).spacing(3).align_items(Align::Center);

        let kind_container = Container::new(kind_row)
            .height(default_height)
            .width(*width)
            .center_y()
            .style(style::HoverableForegroundContainer(color_palette));

        row_containers.push((idx, kind_container));
    }

    if let Some((idx, width)) = column_config
        .iter()
        .enumerate()
        .filter_map(|(idx, (key, width, hidden))| {
            if *key == AuraColumnKey::Status && !hidden {
                Some((idx, width))
            } else {
                None
            }
        })
        .next()
    {
        let status = Text::new(AuraStatus(aura.status()).to_string()).size(DEFAULT_FONT_SIZE);

        let status_row = Row::new()
            .push(status)
            .spacing(3)
            .align_items(Align::Center);

        let status_container = Container::new(status_row)
            .height(default_height)
            .width(*width)
            .center_y()
            .style(style::HoverableForegroundContainer(color_palette));

        row_containers.push((idx, status_container));
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
        .inner_row_height(default_row_height);

    if let Some(url) = aura.url() {
        table_row = table_row
            .on_press(move |_| Message::Interaction(Interaction::OpenLink(url.to_string())));
    }

    if is_odd == Some(true) {
        table_row = table_row.style(style::TableRowAlternate(color_palette))
    } else {
        table_row = table_row.style(style::TableRow(color_palette))
    }

    table_row
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

pub fn titles_row_header<'a>(
    color_palette: ColorPalette,
    auras: &[Aura],
    header_state: &'a mut header::State,
    column_state: &'a mut [AuraColumnState],
    previous_column_key: Option<AuraColumnKey>,
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
        .on_press(Interaction::SortAuraColumn(column_key));

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
        if !auras.is_empty() {
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
            Mode::MyWeakAuras(Flavor::default()),
            event,
        ))
    })
}
