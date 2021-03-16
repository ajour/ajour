use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{style, Interaction, Message, Mode, SelfUpdateState, State},
    crate::localization::localized_string,
    crate::VERSION,
    ajour_core::{
        config::{Config, Flavor},
        theme::ColorPalette,
    },
    iced::{
        button, pick_list, Align, Button, Column, Container, Element, HorizontalAlignment, Length,
        PickList, Row, Space, Text,
    },
    std::collections::HashMap,
    version_compare::{CompOp, VersionCompare},
};

#[allow(clippy::too_many_arguments)]
pub fn data_container<'a>(
    color_palette: ColorPalette,
    mode: &Mode,
    state: &HashMap<Mode, State>,
    error: &Option<anyhow::Error>,
    config: &Config,
    settings_button_state: &'a mut button::State,
    about_button_state: &'a mut button::State,
    addon_mode_button_state: &'a mut button::State,
    weakauras_mode_button_state: &'a mut button::State,
    catalog_mode_btn_state: &'a mut button::State,
    install_mode_btn_state: &'a mut button::State,
    self_update_state: &'a mut SelfUpdateState,
    flavor_picklist_state: &'a mut pick_list::State<Flavor>,
    weak_auras_is_installed: bool,
) -> Container<'a, Message> {
    let flavor = config.wow.flavor;
    let valid_flavors = config.wow.directories.keys().copied();

    // State.
    let myaddons_state = state
        .get(&Mode::MyAddons(flavor))
        .cloned()
        .unwrap_or_default();

    // A row contain general settings.
    let mut settings_row = Row::new()
        .height(Length::Units(50))
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)));

    let mut needs_update = false;

    let mut addons_mode_button = Button::new(
        addon_mode_button_state,
        Text::new(localized_string("my-addons")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette));

    let mut weakauras_mode_button = Button::new(
        weakauras_mode_button_state,
        Text::new(localized_string("my-weakauras")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette));

    let mut catalog_mode_button = Button::new(
        catalog_mode_btn_state,
        Text::new(localized_string("catalog")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette));

    let mut install_mode_button = Button::new(
        install_mode_btn_state,
        Text::new(localized_string("install-from-url")).size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette));

    let mut settings_mode_button = Button::new(
        settings_button_state,
        Text::new(localized_string("settings"))
            .horizontal_alignment(HorizontalAlignment::Center)
            .size(DEFAULT_FONT_SIZE),
    )
    .on_press(Interaction::ModeSelected(Mode::Settings));

    let mut about_mode_button = Button::new(
        about_button_state,
        Text::new(localized_string("about"))
            .horizontal_alignment(HorizontalAlignment::Center)
            .size(DEFAULT_FONT_SIZE),
    )
    .on_press(Interaction::ModeSelected(Mode::About));

    match mode {
        Mode::MyAddons(_) => {
            addons_mode_button =
                addons_mode_button.style(style::SelectedDefaultButton(color_palette));
            weakauras_mode_button =
                weakauras_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
        }
        Mode::MyWeakAuras(_) => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            weakauras_mode_button =
                weakauras_mode_button.style(style::SelectedDefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
        }
        Mode::Install => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            weakauras_mode_button =
                weakauras_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button =
                install_mode_button.style(style::SelectedDefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
        }
        Mode::Catalog => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            weakauras_mode_button =
                weakauras_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button =
                catalog_mode_button.style(style::SelectedDefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
        }
        Mode::Settings => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            weakauras_mode_button =
                weakauras_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button =
                settings_mode_button.style(style::SelectedDefaultButton(color_palette));
        }
        Mode::About => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            weakauras_mode_button =
                weakauras_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button =
                about_mode_button.style(style::SelectedDefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
        }
    }

    if matches!(myaddons_state, State::Start) {
        addons_mode_button = addons_mode_button.style(style::DisabledDefaultButton(color_palette));
        weakauras_mode_button =
            weakauras_mode_button.style(style::DisabledDefaultButton(color_palette));
        catalog_mode_button =
            catalog_mode_button.style(style::DisabledDefaultButton(color_palette));
        install_mode_button =
            install_mode_button.style(style::DisabledDefaultButton(color_palette));
    } else {
        addons_mode_button =
            addons_mode_button.on_press(Interaction::ModeSelected(Mode::MyAddons(flavor)));
        weakauras_mode_button =
            weakauras_mode_button.on_press(Interaction::ModeSelected(Mode::MyWeakAuras(flavor)));
        catalog_mode_button =
            catalog_mode_button.on_press(Interaction::ModeSelected(Mode::Catalog));
        install_mode_button =
            install_mode_button.on_press(Interaction::ModeSelected(Mode::Install));
    }

    let addons_mode_button: Element<Interaction> = addons_mode_button.into();
    let weakauras_mode_button: Element<Interaction> = weakauras_mode_button.into();
    let catalog_mode_button: Element<Interaction> = catalog_mode_button.into();
    let install_mode_button: Element<Interaction> = install_mode_button.into();
    let settings_mode_button: Element<Interaction> = settings_mode_button.into();
    let about_mode_button: Element<Interaction> = about_mode_button.into();

    let segmented_addons_row = Row::new()
        .push(catalog_mode_button.map(Message::Interaction))
        .push(install_mode_button.map(Message::Interaction))
        .spacing(1);

    let mut segmented_mode_row = Row::new()
        .push(addons_mode_button.map(Message::Interaction))
        .spacing(1);

    if weak_auras_is_installed {
        segmented_mode_row =
            segmented_mode_row.push(weakauras_mode_button.map(Message::Interaction));
    }

    let segmented_mode_container = Container::new(segmented_mode_row)
        .padding(2)
        .style(style::SegmentedContainer(color_palette));

    let segmented_addon_container = Container::new(segmented_addons_row)
        .padding(2)
        .style(style::SegmentedContainer(color_palette));

    let flavor_picklist_container = {
        let pick_list: Element<_> = PickList::new(
            flavor_picklist_state,
            valid_flavors.to_vec(),
            Some(flavor),
            Interaction::FlavorSelected,
        )
        .text_size(14)
        .style(style::MenuPickList(color_palette))
        .into();

        Container::new(pick_list.map(Message::Interaction))
            .padding(2)
            .style(style::SegmentedContainer(color_palette))
    };

    // Displays an error, if any has occured.
    let error_text = if let Some(error) = error {
        Text::new(error.to_string()).size(DEFAULT_FONT_SIZE)
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

    #[cfg(not(target_os = "linux"))]
    let is_updatable = true;

    #[cfg(target_os = "linux")]
    let is_updatable = std::env::var("APPIMAGE").is_ok();

    let version_text = Text::new(if let Some(release) = &self_update_state.latest_release {
        if VersionCompare::compare_to(&release.tag_name, VERSION, &CompOp::Gt).unwrap_or(false) {
            if is_updatable {
                needs_update = true;
            }

            format!(
                "{} {} -> {}",
                localized_string("new-update-available"),
                VERSION,
                &release.tag_name
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

    // Only adds flavor container picklist when we have more than 1 valid flavor.
    if valid_flavors.len() > 1 {
        settings_row = settings_row
            .push(flavor_picklist_container)
            .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)));
    }

    // Surrounds the elements with spacers, in order to make the GUI look good.
    settings_row = settings_row
        .push(segmented_mode_container)
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(segmented_addon_container)
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(error_container)
        .push(version_container);

    let mut segmented_mode_control_row = Row::new().spacing(1);

    // Add download button to latest github release page if Ajour update is available.
    if needs_update {
        let text = self_update_state
            .status
            .as_ref()
            .map(|s| s.to_string())
            .unwrap_or_else(|| localized_string("update"));

        let mut new_release_button = Button::new(
            &mut self_update_state.btn_state,
            Text::new(&text).size(DEFAULT_FONT_SIZE),
        )
        .style(style::SecondaryButton(color_palette));

        new_release_button = new_release_button.on_press(Interaction::UpdateAjour);

        let new_release_button: Element<Interaction> = new_release_button.into();

        segmented_mode_control_row =
            segmented_mode_control_row.push(new_release_button.map(Message::Interaction));
    } else {
        segmented_mode_control_row =
            segmented_mode_control_row.push(about_mode_button.map(Message::Interaction));
    }

    segmented_mode_control_row =
        segmented_mode_control_row.push(settings_mode_button.map(Message::Interaction));

    let segmented_mode_control_container = Container::new(segmented_mode_control_row)
        .padding(2)
        .style(style::SegmentedContainer(color_palette));

    settings_row = settings_row
        .push(segmented_mode_control_container)
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
