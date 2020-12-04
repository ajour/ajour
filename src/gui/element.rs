#![allow(clippy::too_many_arguments)]

use {
    super::{
        style, BackupFolderKind, BackupState, CatalogColumnKey, CatalogColumnSettings,
        CatalogColumnState, CatalogRow, ColumnKey, ColumnSettings, ColumnState, DirectoryType,
        ExpandType, InstallAddon, InstallKind, InstallStatus, Interaction, Message, Mode,
        ReleaseChannel, ScaleState, SelfUpdateChannelState, SelfUpdateState, SortDirection, State,
        ThemeState,
    },
    crate::VERSION,
    ajour_core::{
        addon::{Addon, AddonState},
        catalog::Catalog,
        config::{Config, Flavor},
        theme::ColorPalette,
    },
    ajour_widgets::{header, Header},
    chrono::prelude::*,
    iced::{
        button, scrollable, Align, Button, Checkbox, Column, Container, Element,
        HorizontalAlignment, Length, PickList, Row, Scrollable, Space, Text, VerticalAlignment,
    },
    num_format::{Locale, ToFormattedString},
    std::collections::HashMap,
    version_compare::{CompOp, VersionCompare},
};

// Default values used on multiple elements.
pub static DEFAULT_FONT_SIZE: u16 = 14;
pub static DEFAULT_PADDING: u16 = 10;

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
    error: &Option<anyhow::Error>,
    config: &Config,
    valid_flavors: &[Flavor],
    settings_button_state: &'a mut button::State,
    about_button_state: &'a mut button::State,
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
        Text::new("Install from URL").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DisabledDefaultButton(color_palette));

    let mut settings_mode_button = Button::new(
        settings_button_state,
        Text::new("Settings")
            .horizontal_alignment(HorizontalAlignment::Center)
            .size(DEFAULT_FONT_SIZE),
    )
    .on_press(Interaction::ModeSelected(Mode::Settings));

    let mut about_mode_button = Button::new(
        about_button_state,
        Text::new("About")
            .horizontal_alignment(HorizontalAlignment::Center)
            .size(DEFAULT_FONT_SIZE),
    )
    .on_press(Interaction::ModeSelected(Mode::About));

    match mode {
        Mode::MyAddons(_) => {
            addons_mode_button =
                addons_mode_button.style(style::SelectedDefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
        }
        Mode::Install => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button =
                install_mode_button.style(style::SelectedDefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
        }
        Mode::Catalog => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button =
                catalog_mode_button.style(style::SelectedDefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
        }
        Mode::Settings => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button = about_mode_button.style(style::DefaultButton(color_palette));
            settings_mode_button =
                settings_mode_button.style(style::SelectedDefaultButton(color_palette));
        }
        Mode::About => {
            addons_mode_button = addons_mode_button.style(style::DefaultButton(color_palette));
            catalog_mode_button = catalog_mode_button.style(style::DefaultButton(color_palette));
            install_mode_button = install_mode_button.style(style::DefaultButton(color_palette));
            about_mode_button =
                about_mode_button.style(style::SelectedDefaultButton(color_palette));
            settings_mode_button = settings_mode_button.style(style::DefaultButton(color_palette));
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
    let settings_mode_button: Element<Interaction> = settings_mode_button.into();
    let about_mode_button: Element<Interaction> = about_mode_button.into();

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

    let mut segmented_flavor_control_container =
        Container::new(segmented_flavor_control_row).padding(2);

    // Only add style if we show container.
    if valid_flavors.len() > 1 {
        segmented_flavor_control_container =
            segmented_flavor_control_container.style(style::SegmentedContainer(color_palette));
    }

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

    // Surrounds the elements with spacers, in order to make the GUI look good.
    settings_row = settings_row
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(segmented_mode_control_container)
        .push(Space::new(Length::Units(20), Length::Units(0)))
        .push(segmented_flavor_control_container)
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
            .unwrap_or_else(|| "Update".to_string());

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
                .on_press(Interaction::SelectDirectory(DirectoryType::Wow))
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
