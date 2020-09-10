use {
    super::{
        style, Addon, AddonState, AjourState, ColorPalette, Config, Flavor, Interaction, Message,
        SortKey, SortState, ThemeState,
    },
    crate::VERSION,
    iced::{
        button, pick_list, scrollable, Button, Column, Container, Element, HorizontalAlignment,
        Length, PickList, Row, Scrollable, Space, Text, VerticalAlignment,
    },
};

// Default values used on multiple elements.
static DEFAULT_FONT_SIZE: u16 = 14;
static DEFAULT_PADDING: u16 = 10;

/// Container for settings.
pub fn settings_container<'a>(
    color_palette: ColorPalette,
    directory_button_state: &'a mut button::State,
    flavor_list_state: &'a mut pick_list::State<Flavor>,
    ignored_addons_scrollable_state: &'a mut scrollable::State,
    ignored_addons: &'a mut Vec<(Addon, button::State)>,
    config: &Config,
    theme_state: &'a mut ThemeState,
) -> Container<'a, Message> {
    // Title for the World of Warcraft directory selection.
    let directory_info_text = Text::new("World of Warcraft directory").size(14);
    let directory_info_row = Row::new()
        .push(directory_info_text)
        .padding(DEFAULT_PADDING);

    // Directory button for World of Warcraft directory selection.
    let directory_button: Element<Interaction> = Button::new(
        directory_button_state,
        Text::new("Select Directory").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultBoxedButton(color_palette))
    .on_press(Interaction::OpenDirectory)
    .into();

    // We add some margin left to adjust to the rest of the content.
    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));

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
        .center_y()
        .padding(5)
        .style(style::SecondaryTextContainer(color_palette));

    // Data row for the World of Warcraft directory selection.
    let path_data_row = Row::new()
        .push(left_spacer)
        .push(directory_button.map(Message::Interaction))
        .push(directory_data_text_container);

    // Title for the flavor pick list.
    let flavor_info_text = Text::new("Flavor").size(14);
    let flavor_info_row = Row::new().push(flavor_info_text).padding(DEFAULT_PADDING);

    // We add some margin left to adjust to the rest of the content.
    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));

    let flavors = &Flavor::ALL[..];
    let flavor_pick_list = PickList::new(
        flavor_list_state,
        flavors,
        Some(config.wow.flavor),
        Message::FlavorSelected,
    )
    .text_size(14)
    .width(Length::Units(100))
    .style(style::PickList(color_palette));

    // Data row for flavor picker list.
    let flavor_data_row = Row::new().push(left_spacer).push(flavor_pick_list);

    // Title for the theme pick list.
    let theme_info_text = Text::new("Theme").size(14);
    let theme_info_row = Row::new().push(theme_info_text).padding(DEFAULT_PADDING);

    // We add some margin left to adjust to the rest of the content.
    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));

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
    let theme_data_row = Row::new().push(left_spacer).push(theme_pick_list);

    // Small space below content.
    let bottom_space = Space::new(Length::FillPortion(1), Length::Units(DEFAULT_PADDING));

    // Colum wrapping all the settings content.
    let left_column = Column::new()
        .push(directory_info_row)
        .push(path_data_row)
        .push(flavor_info_row)
        .push(flavor_data_row)
        .push(theme_info_row)
        .push(theme_data_row)
        .push(bottom_space);

    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
    let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));

    // Container wrapping colum.
    let left_container = Container::new(left_column)
        .width(Length::FillPortion(1))
        .height(Length::Fill)
        .style(style::AddonRowDefaultTextContainer(color_palette));

    // Title for the ignored addons scrollable.
    let ignored_addons_title = Text::new("Ignored addons").size(14);
    let ignored_addons_title_row = Row::new()
        .push(ignored_addons_title)
        .padding(DEFAULT_PADDING);
    let mut scrollable = ignored_addon_scrollable(color_palette, ignored_addons_scrollable_state)
        .width(Length::Fill);

    if ignored_addons.is_empty() {
        let title =
            Text::new("If you tell Ajour to ignore an addon, it will only appear in this list.")
                .size(14);
        let title_container = Container::new(title)
            .center_x()
            .center_y()
            .style(style::AddonRowSecondaryTextContainer(color_palette));
        let row = Row::new()
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
            .push(title_container);
        scrollable = scrollable.push(row);
    }

    for (addon, state) in ignored_addons {
        let title = addon
            .remote_title
            .clone()
            .unwrap_or_else(|| addon.title.clone());
        let title_text = Text::new(title).size(14);
        let title_container = Container::new(title_text)
            .height(Length::Units(26))
            .width(Length::FillPortion(1))
            .center_y()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette));
        let unignore_button: Element<Interaction> =
            Button::new(state, Text::new("Unignore").size(DEFAULT_FONT_SIZE))
                .style(style::DefaultBoxedButton(color_palette))
                .on_press(Interaction::Unignore(addon.id.clone()))
                .into();
        let row = Row::new()
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
            .push(unignore_button.map(Message::Interaction))
            .push(title_container);

        scrollable = scrollable.push(row);
    }

    let right_column = Column::new()
        .push(ignored_addons_title_row)
        .push(scrollable)
        .push(Space::new(Length::Fill, Length::Units(DEFAULT_PADDING)));
    let right_container = Container::new(right_column)
        .width(Length::FillPortion(1))
        .height(Length::Fill)
        .style(style::AddonRowDefaultTextContainer(color_palette));

    // Row to wrap each section.
    let row = Row::new()
        .push(left_spacer)
        .push(left_container)
        .push(right_container)
        .push(right_spacer);

    // Returns the final container.
    Container::new(row).height(Length::Units(185))
}

pub fn addon_data_cell(
    color_palette: ColorPalette,
    addon: &'_ mut Addon,
    is_addon_expanded: bool,
) -> Container<'_, Message> {
    let default_height = Length::Units(26);

    // Check if current addon is expanded.
    let version = addon.version.clone().unwrap_or_else(|| String::from("-"));
    let remote_version = addon
        .remote_version
        .clone()
        .unwrap_or_else(|| String::from("-"));

    let title = Text::new(&addon.title).size(DEFAULT_FONT_SIZE);
    let title_button: Element<Interaction> = Button::new(&mut addon.details_btn_state, title)
        .on_press(Interaction::Expand(addon.id.clone()))
        .style(style::TextButton(color_palette))
        .into();

    let title_container = Container::new(title_button.map(Message::Interaction))
        .height(default_height)
        .width(Length::FillPortion(1))
        .center_y()
        .style(style::AddonRowDefaultTextContainer(color_palette));

    let installed_version = Text::new(version).size(DEFAULT_FONT_SIZE);
    let installed_version_container = Container::new(installed_version)
        .height(default_height)
        .width(Length::Units(150))
        .center_y()
        .padding(5)
        .style(style::AddonRowSecondaryTextContainer(color_palette));

    let remote_version = Text::new(remote_version).size(DEFAULT_FONT_SIZE);
    let remote_version_container = Container::new(remote_version)
        .height(default_height)
        .width(Length::Units(150))
        .center_y()
        .padding(5)
        .style(style::AddonRowSecondaryTextContainer(color_palette));

    let update_button_width = Length::Units(85);
    let update_button_container = match &addon.state {
        AddonState::Ajour(string) => Container::new(
            Text::new(string.clone().unwrap_or_else(|| "".to_string())).size(DEFAULT_FONT_SIZE),
        )
        .height(default_height)
        .width(update_button_width)
        .center_y()
        .center_x()
        .style(style::AddonRowSecondaryTextContainer(color_palette)),
        AddonState::Updatable => {
            let id = addon.id.clone();
            let update_button: Element<Interaction> = Button::new(
                &mut addon.update_btn_state,
                Text::new("Update")
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(DEFAULT_FONT_SIZE),
            )
            .style(style::SecondaryButton(color_palette))
            .on_press(Interaction::Update(id))
            .into();

            Container::new(update_button.map(Message::Interaction))
                .height(default_height)
                .width(update_button_width)
                .center_y()
                .center_x()
                .style(style::AddonRowDefaultTextContainer(color_palette))
        }
        AddonState::Downloading => Container::new(Text::new("Downloading").size(DEFAULT_FONT_SIZE))
            .height(default_height)
            .width(update_button_width)
            .center_y()
            .center_x()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette)),
        AddonState::Unpacking => Container::new(Text::new("Unpacking").size(DEFAULT_FONT_SIZE))
            .height(default_height)
            .width(update_button_width)
            .center_y()
            .center_x()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette)),
        AddonState::Fingerprint => Container::new(Text::new("Hashing").size(DEFAULT_FONT_SIZE))
            .height(default_height)
            .width(update_button_width)
            .center_y()
            .center_x()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette)),
    };

    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
    let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));

    let row = Row::new()
        .push(left_spacer)
        .push(title_container)
        .push(installed_version_container)
        .push(remote_version_container)
        .push(update_button_container)
        .push(right_spacer)
        .spacing(1);

    let mut addon_column = Column::new().push(row);

    if is_addon_expanded {
        let notes = addon
            .notes
            .clone()
            .unwrap_or_else(|| "No description for addon.".to_string());
        let author = addon.author.clone().unwrap_or_else(|| "-".to_string());
        let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
        let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));
        let space = Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING * 2));
        let bottom_space = Space::new(Length::Units(0), Length::Units(4));
        let notes_title_text = Text::new("Summary").size(DEFAULT_FONT_SIZE);
        let notes_text = Text::new(notes).size(DEFAULT_FONT_SIZE);
        let author_text = Text::new(author).size(DEFAULT_FONT_SIZE);
        let author_title_text = Text::new("Author(s)").size(DEFAULT_FONT_SIZE);
        let author_title_container =
            Container::new(author_title_text).style(style::DefaultTextContainer(color_palette));
        let notes_title_container =
            Container::new(notes_title_text).style(style::DefaultTextContainer(color_palette));

        let mut force_download_button = Button::new(
            &mut addon.force_btn_state,
            Text::new("Force update").size(DEFAULT_FONT_SIZE),
        )
        .style(style::DefaultBoxedButton(color_palette));

        // If we have remote version on addon, enable force update.
        if addon.remote_version.is_some() {
            force_download_button =
                force_download_button.on_press(Interaction::Update(addon.id.clone()));
        }

        let force_download_button: Element<Interaction> = force_download_button.into();

        let ignore_button: Element<Interaction> = Button::new(
            &mut addon.ignore_btn_state,
            Text::new("Ignore").size(DEFAULT_FONT_SIZE),
        )
        .on_press(Interaction::Ignore(addon.id.clone()))
        .style(style::DefaultBoxedButton(color_palette))
        .into();

        let delete_button: Element<Interaction> = Button::new(
            &mut addon.delete_btn_state,
            Text::new("Delete").size(DEFAULT_FONT_SIZE),
        )
        .on_press(Interaction::Delete(addon.id.clone()))
        .style(style::DeleteBoxedButton(color_palette))
        .into();

        let row = Row::new()
            .push(force_download_button.map(Message::Interaction))
            .push(Space::new(Length::Units(5), Length::Units(0)))
            .push(ignore_button.map(Message::Interaction))
            .push(Space::new(Length::Units(5), Length::Units(0)))
            .push(delete_button.map(Message::Interaction));
        let column = Column::new()
            .push(author_title_container)
            .push(author_text)
            .push(Space::new(Length::Units(0), Length::Units(3)))
            .push(notes_title_container)
            .push(notes_text)
            .push(space)
            .push(row)
            .push(bottom_space);
        let details_container = Container::new(column)
            .width(Length::Fill)
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer(color_palette));

        let row = Row::new()
            .push(left_spacer)
            .push(details_container)
            .push(right_spacer)
            .spacing(1);

        addon_column = addon_column
            .push(Space::new(Length::FillPortion(1), Length::Units(1)))
            .push(row);
    }

    Container::new(addon_column)
        .width(Length::Fill)
        .style(style::Row(color_palette))
}

pub fn addon_row_titles<'a>(
    color_palette: ColorPalette,
    addons: &[Addon],
    sort_state: &'a mut SortState,
) -> Row<'a, Message> {
    // A row containing titles above the addon rows.
    let mut row_titles = Row::new().spacing(1).height(Length::Units(25));

    // We add some margin left to adjust for inner-marigin in cell.
    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
    let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));

    let addon_row_header: Element<Interaction> = Button::new(
        &mut sort_state.title_btn_state,
        Text::new("Addon")
            .size(DEFAULT_FONT_SIZE)
            .width(Length::Fill),
    )
    .width(Length::Fill)
    .style(style::ColumnHeaderButton(color_palette))
    .on_press(Interaction::SortColumn(SortKey::Title))
    .into();

    let addon_row_container = Container::new(addon_row_header.map(Message::Interaction))
        .width(Length::FillPortion(1))
        .style(style::SecondaryTextContainer(color_palette));

    let local_row_header: Element<Interaction> = Button::new(
        &mut sort_state.local_version_btn_state,
        Text::new("Local")
            .size(DEFAULT_FONT_SIZE)
            .width(Length::Fill),
    )
    .width(Length::Fill)
    .style(style::ColumnHeaderButton(color_palette))
    .on_press(Interaction::SortColumn(SortKey::LocalVersion))
    .into();
    let local_version_container = Container::new(local_row_header.map(Message::Interaction))
        .width(Length::Units(150))
        .style(style::SecondaryTextContainer(color_palette));

    let remote_row_header: Element<Interaction> = Button::new(
        &mut sort_state.remote_version_btn_state,
        Text::new("Remote")
            .size(DEFAULT_FONT_SIZE)
            .width(Length::Fill),
    )
    .width(Length::Fill)
    .style(style::ColumnHeaderButton(color_palette))
    .on_press(Interaction::SortColumn(SortKey::RemoteVersion))
    .into();
    let remote_version_container = Container::new(remote_row_header.map(Message::Interaction))
        .width(Length::Units(150))
        .style(style::SecondaryTextContainer(color_palette));

    let status_row_header: Element<Interaction> = Button::new(
        &mut sort_state.status_btn_state,
        Text::new("Status")
            .size(DEFAULT_FONT_SIZE)
            .width(Length::Fill),
    )
    .width(Length::Fill)
    .style(style::ColumnHeaderButton(color_palette))
    .on_press(Interaction::SortColumn(SortKey::Status))
    .into();
    let status_row_container = Container::new(status_row_header.map(Message::Interaction))
        .width(Length::Units(85))
        .style(style::SecondaryTextContainer(color_palette));

    // Only shows row titles if we have any addons.
    if !addons.is_empty() {
        row_titles = row_titles
            .push(left_spacer)
            .push(addon_row_container)
            .push(local_version_container)
            .push(remote_version_container)
            .push(status_row_container)
            .push(right_spacer);
    }

    row_titles
}

#[allow(clippy::too_many_arguments)]
pub fn menu_container<'a>(
    color_palette: ColorPalette,
    update_all_button_state: &'a mut button::State,
    refresh_button_state: &'a mut button::State,
    settings_button_state: &'a mut button::State,
    state: &AjourState,
    addons: &[Addon],
    config: &Config,
    needs_update: Option<&'a str>,
    new_release_button_state: &'a mut button::State,
) -> Container<'a, Message> {
    // A row contain general settings.
    let mut settings_row = Row::new().spacing(1).height(Length::Units(35));

    let mut update_all_button = Button::new(
        update_all_button_state,
        Text::new("Update All").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultBoxedButton(color_palette));

    let mut refresh_button = Button::new(
        refresh_button_state,
        Text::new("Refresh").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultBoxedButton(color_palette));

    // Is any addon performing an action.
    let addons_performing_actions = addons.iter().any(|a| match a.state {
        AddonState::Downloading | AddonState::Unpacking => true,
        _ => false,
    });

    let ajour_performing_actions = match state {
        AjourState::Loading => true,
        _ => false,
    };

    // Is any addon updtable.
    let any_addon_updatable = addons.iter().any(|a| match a.state {
        AddonState::Updatable => true,
        _ => false,
    });

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
    if !addons_performing_actions && !ajour_performing_actions {
        refresh_button = refresh_button.on_press(Interaction::Refresh);
    }

    let update_all_button: Element<Interaction> = update_all_button.into();
    let refresh_button: Element<Interaction> = refresh_button.into();

    // Displays text depending on the state of the app.
    let ignored_addons = config.addons.ignored.as_ref();
    let parent_addons_count = addons
        .iter()
        .filter(|a| !a.is_ignored(&ignored_addons))
        .count();

    let status_text = match state {
        AjourState::Idle => {
            Text::new(format!("{} addons loaded", parent_addons_count)).size(DEFAULT_FONT_SIZE)
        }
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

    let version_text = Text::new(if let Some(new_version) = needs_update {
        format!("New Ajour version available {} -> {}", VERSION, new_version)
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
        Text::new("Settings")
            .horizontal_alignment(HorizontalAlignment::Center)
            .size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultBoxedButton(color_palette))
    .on_press(Interaction::Settings)
    .into();

    let spacer = Space::new(Length::Units(7), Length::Units(0));
    // Not using default padding, just to make it look prettier UI wise
    let top_spacer = Space::new(Length::Units(0), Length::Units(5));
    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
    let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));

    // Surrounds the elements with spacers, in order to make the GUI look good.
    settings_row = settings_row
        .push(left_spacer)
        .push(update_all_button.map(Message::Interaction))
        .push(spacer)
        .push(refresh_button.map(Message::Interaction))
        .push(status_container)
        .push(error_container)
        .push(version_container);

    // Add download button to latest github release page if Ajour update is available.
    if needs_update.is_some() {
        let mut new_release_button = Button::new(
            new_release_button_state,
            Text::new("Download").size(DEFAULT_FONT_SIZE),
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
        .push(right_spacer);

    // Add space above settings_row.
    let settings_column = Column::new().push(top_spacer).push(settings_row);

    // Wraps it in a container.
    Container::new(settings_column)
}

pub fn status_container<'a>(
    color_palette: ColorPalette,
    title: &str,
    description: &str,
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

    let colum = Column::new()
        .push(title_container)
        .push(Space::new(Length::Units(0), Length::Units(2)))
        .push(description_container);
    Container::new(colum)
        .center_y()
        .center_x()
        .width(Length::Fill)
        .height(Length::Fill)
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

pub fn ignored_addon_scrollable(
    color_palette: ColorPalette,
    state: &'_ mut scrollable::State,
) -> Scrollable<'_, Message> {
    Scrollable::new(state)
        .spacing(1)
        .height(Length::FillPortion(1))
        .style(style::SecondaryScrollable(color_palette))
}
