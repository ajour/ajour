use {
    super::{style, Addon, AddonState, AjourState, Config, Interaction, Message},
    iced::{
        button, Button, Column, Container, Element, HorizontalAlignment, Length, Row, Space, Text,
    },
};

// pub fn gui_container<'a>(input_state: &'a mut text_input::State) -> Container<'a, Message> {
//     let text_input = TextInput::new(
//         input_state,
//         "Type something...",
//         "Hello",
//         Message::InputChanged,
//     )
//     .padding(10)
//     .size(30);

//     // let path_row = Row::new().push(text_input);

//     // Container::new(path_row)
//     //     .width(Length::FillPortion(1))
//     //     .height(Length::Units(200))
// }
//

pub fn addon_data_cell<'a>(
    addon: &'a mut Addon,
    is_addon_expanded: bool,
) -> Container<'a, Message> {
    let default_font_size = 14;
    let default_padding = 10;
    let default_height = Length::Units(26);

    // Check if current addon is expanded.
    let version = addon.version.clone().unwrap_or_else(|| String::from("-"));
    let remote_version = addon
        .remote_version
        .clone()
        .unwrap_or_else(|| String::from("-"));

    let title = Text::new(&addon.title).size(default_font_size);
    let title_container = Container::new(title)
        .height(default_height)
        .width(Length::FillPortion(1))
        .center_y()
        .padding(5)
        .style(style::AddonRowDefaultTextContainer);

    let installed_version = Text::new(version).size(default_font_size);
    let installed_version_container = Container::new(installed_version)
        .height(default_height)
        .width(Length::Units(150))
        .center_y()
        .padding(5)
        .style(style::AddonRowSecondaryTextContainer);

    let remote_version = Text::new(remote_version).size(default_font_size);
    let remote_version_container = Container::new(remote_version)
        .height(default_height)
        .width(Length::Units(150))
        .center_y()
        .padding(5)
        .style(style::AddonRowSecondaryTextContainer);

    let update_button_width = Length::Units(85);
    let update_button_container = match &addon.state {
        AddonState::Ajour(string) => Container::new(
            Text::new(string.clone().unwrap_or_else(|| "".to_string())).size(default_font_size),
        )
        .height(default_height)
        .width(update_button_width)
        .center_y()
        .center_x()
        .style(style::AddonRowSecondaryTextContainer),
        AddonState::Updatable => {
            let id = addon.id.clone();
            let update_button: Element<Interaction> = Button::new(
                &mut addon.update_btn_state,
                Text::new("Update")
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(default_font_size),
            )
            .style(style::SecondaryButton)
            .on_press(Interaction::Update(id))
            .into();

            Container::new(update_button.map(Message::Interaction))
                .height(default_height)
                .width(update_button_width)
                .center_y()
                .center_x()
                .style(style::AddonRowDefaultTextContainer)
        }
        AddonState::Downloading => Container::new(Text::new("Downloading").size(default_font_size))
            .height(default_height)
            .width(update_button_width)
            .center_y()
            .center_x()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer),
        AddonState::Unpacking => Container::new(Text::new("Unpacking").size(default_font_size))
            .height(default_height)
            .width(update_button_width)
            .center_y()
            .center_x()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer),
        AddonState::Loading => Container::new(Text::new("Loading").size(default_font_size))
            .height(default_height)
            .width(update_button_width)
            .center_y()
            .center_x()
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer),
    };

    let details_button_text = match is_addon_expanded {
        true => "Close",
        false => "Details",
    };

    let details_button: Element<Interaction> = Button::new(
        &mut addon.details_btn_state,
        Text::new(details_button_text).size(default_font_size),
    )
    .on_press(Interaction::Expand(addon.id.clone()))
    .style(style::DefaultButton)
    .into();

    let details_button_container = Container::new(details_button.map(Message::Interaction))
        .height(default_height)
        .width(Length::Units(70))
        .center_y()
        .center_x()
        .style(style::AddonRowSecondaryTextContainer);

    let left_spacer = Space::new(Length::Units(default_padding), Length::Units(0));
    let right_spacer = Space::new(Length::Units(default_padding + 5), Length::Units(0));

    let row = Row::new()
        .push(left_spacer)
        .push(title_container)
        .push(installed_version_container)
        .push(remote_version_container)
        .push(update_button_container)
        .push(details_button_container)
        .push(right_spacer)
        .spacing(1);

    let mut addon_column = Column::new().push(row);

    if is_addon_expanded {
        let notes = addon
            .notes
            .clone()
            .unwrap_or_else(|| "No description for addon.".to_string());
        let left_spacer = Space::new(Length::Units(default_padding), Length::Units(0));
        let right_spacer = Space::new(Length::Units(default_padding + 5), Length::Units(0));
        let space = Space::new(Length::Units(0), Length::Units(default_padding * 2));
        let bottom_space = Space::new(Length::Units(0), Length::Units(4));
        let notes_text = Text::new(notes).size(default_font_size);

        let delete_button: Element<Interaction> = Button::new(
            &mut addon.delete_btn_state,
            Text::new("Delete").size(default_font_size),
        )
        .on_press(Interaction::Delete(addon.id.clone()))
        .style(style::DeleteBoxedButton)
        .into();

        let row = Row::new().push(delete_button.map(Message::Interaction));
        let column = Column::new()
            .push(notes_text)
            .push(space)
            .push(row)
            .push(bottom_space);
        let details_container = Container::new(column)
            .width(Length::Fill)
            .padding(5)
            .style(style::AddonRowSecondaryTextContainer);

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
        .style(style::Row)
}

pub fn addon_row_titles<'a>(addons: &[Addon]) -> Row<'a, Message> {
    let default_font_size = 14;
    let default_padding = 10;
    // A row containing titles above the addon rows.
    let mut row_titles = Row::new().spacing(1).height(Length::Units(20));

    // We add some margin left to adjust for inner-marigin in cell.
    let left_spacer = Space::new(Length::Units(default_padding + 5), Length::Units(0));
    let right_spacer = Space::new(Length::Units(default_padding), Length::Units(0));

    let addon_row_text = Text::new("Addon").size(default_font_size);
    let addon_row_container = Container::new(addon_row_text)
        .width(Length::FillPortion(1))
        .style(style::StatusTextContainer);

    let local_version_text = Text::new("Local").size(default_font_size);
    let local_version_container = Container::new(local_version_text)
        .width(Length::Units(150))
        .style(style::StatusTextContainer);

    let remote_version_text = Text::new("Remote").size(default_font_size);
    let remote_version_container = Container::new(remote_version_text)
        .width(Length::Units(150))
        .style(style::StatusTextContainer);

    let status_row_text = Text::new("Status").size(default_font_size);
    let status_row_container = Container::new(status_row_text)
        .width(Length::Units(85))
        .style(style::StatusTextContainer);

    let delete_row_text = Text::new("Details").size(default_font_size);
    let delete_row_container = Container::new(delete_row_text)
        .width(Length::Units(70))
        .style(style::StatusTextContainer);

    // Only shows row titles if we have any addons.
    if !addons.is_empty() {
        row_titles = row_titles
            .push(left_spacer)
            .push(addon_row_container)
            .push(local_version_container)
            .push(remote_version_container)
            .push(status_row_container)
            .push(delete_row_container)
            .push(right_spacer);
    }

    row_titles
}

pub fn menu_container<'a>(
    update_all_button_state: &'a mut button::State,
    refresh_button_state: &'a mut button::State,
    settings_button_state: &'a mut button::State,
    state: &AjourState,
    addons: &[Addon],
    config: &Config,
) -> Container<'a, Message> {
    // FIXME: Maybe we should have these as statics?
    let default_font_size = 14;
    let default_padding = 10;

    // A row contain general settings.
    let mut settings_row = Row::new().spacing(1).height(Length::Units(35));

    let mut update_all_button = Button::new(
        update_all_button_state,
        Text::new("Update All").size(default_font_size),
    )
    .style(style::DefaultBoxedButton);

    let mut refresh_button = Button::new(
        refresh_button_state,
        Text::new("Refresh").size(default_font_size),
    )
    .style(style::DefaultBoxedButton);

    // Enable update_all_button and refresh_button, if we have any Addons.
    if !addons.is_empty() {
        update_all_button = update_all_button.on_press(Interaction::UpdateAll);
        refresh_button = refresh_button.on_press(Interaction::Refresh);
    }

    let update_all_button: Element<Interaction> = update_all_button.into();
    let refresh_button: Element<Interaction> = refresh_button.into();

    // Displays text depending on the state of the app.
    let hidden_addons = config.addons.hidden.as_ref();
    let parent_addons_count = addons
        .iter()
        .filter(|a| a.is_parent() && !a.is_hidden(&hidden_addons))
        .count();
    let loading_addons = addons
        .iter()
        .filter(|a| a.state == AddonState::Loading)
        .count();
    let status_text = if loading_addons != 0 {
        Text::new(format!("Fetching data for {} addons", loading_addons)).size(default_font_size)
    } else {
        Text::new(format!("{} addons loaded", parent_addons_count)).size(default_font_size)
    };

    let status_container = Container::new(status_text)
        .center_y()
        .padding(5)
        .style(style::StatusTextContainer);

    // Displays an error, if any has occured.
    let error_text = if let AjourState::Error(e) = state {
        Text::new(e.to_string()).size(default_font_size)
    } else {
        // Display nothing.
        Text::new("")
    };

    let error_container = Container::new(error_text)
        .center_y()
        .center_x()
        .padding(5)
        .width(Length::FillPortion(1))
        .style(style::StatusErrorTextContainer);

    // TODO: Move to Settings.
    // let version_text = Text::new(env!("CARGO_PKG_VERSION"))
    //     .size(default_font_size)
    //     .horizontal_alignment(HorizontalAlignment::Right);
    // let version_container = Container::new(version_text)
    //     .center_y()
    //     .padding(5)
    //     .style(style::StatusTextContainer);

    let settings_button: Element<Interaction> = Button::new(
        settings_button_state,
        Text::new("Settings")
            .horizontal_alignment(HorizontalAlignment::Center)
            .size(default_font_size),
    )
    .style(style::DefaultBoxedButton)
    .on_press(Interaction::Settings)
    .into();

    let spacer = Space::new(Length::Units(7), Length::Units(0));
    // Not using default padding, just to make it look prettier UI wise
    let top_spacer = Space::new(Length::Units(0), Length::Units(5));
    let left_spacer = Space::new(Length::Units(default_padding), Length::Units(0));
    let right_spacer = Space::new(Length::Units(default_padding + 5), Length::Units(0));

    // Surrounds the elements with spacers, in order to make the GUI look good.
    settings_row = settings_row
        .push(left_spacer)
        .push(update_all_button.map(Message::Interaction))
        .push(spacer)
        .push(refresh_button.map(Message::Interaction))
        .push(status_container)
        .push(error_container)
        .push(settings_button.map(Message::Interaction))
        .push(right_spacer);

    // Add space above settings_row.
    let settings_column = Column::new().push(top_spacer).push(settings_row);

    // Wraps it in a container.
    Container::new(settings_column)
}
