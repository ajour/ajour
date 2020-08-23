mod style;
mod update;
use crate::{
    addon::{Addon, AddonState},
    config::{load_config, Config},
    curse_api,
    error::ClientError,
    tukui_api, wowinterface_api, Result,
};
use iced::{
    button, scrollable, Application, Button, Column, Command, Container, Element,
    HorizontalAlignment, Length, Row, Scrollable, Settings, Space, Text,
};

#[derive(Debug)]
pub enum AjourState {
    Idle,
    Error(ClientError),
}

#[derive(Debug, Clone)]
pub enum Interaction {
    Refresh,
    UpdateAll,
    Update(String),
    Delete(String),
    Expand(String),
}

#[derive(Debug)]
pub enum Message {
    Parse(Config),
    ParsedAddons(Result<Vec<Addon>>),
    PartialParsedAddons(Result<Vec<Addon>>),
    DownloadedAddon((String, Result<()>)),
    UnpackedAddon((String, Result<()>)),
    CursePackage((String, Result<curse_api::Package>)),
    CursePackages((String, u32, Result<Vec<curse_api::Package>>)),
    TukuiPackage((String, Result<tukui_api::Package>)),
    WowinterfacePackages((String, Result<Vec<wowinterface_api::Package>>)),
    Interaction(Interaction),
    Error(ClientError),
}

pub struct Ajour {
    state: AjourState,
    update_all_button_state: button::State,
    refresh_button_state: button::State,
    addons_scrollable_state: scrollable::State,
    addons: Vec<Addon>,
    config: Config,
    expanded_addon: Option<Addon>,
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
            state: AjourState::Idle,
            update_all_button_state: Default::default(),
            refresh_button_state: Default::default(),
            addons_scrollable_state: Default::default(),
            addons: Vec::new(),
            config: Config::default(),
            expanded_addon: None,
        }
    }
}

impl Application for Ajour {
    type Executor = iced::executor::Default;
    type Message = Message;
    type Flags = ();

    fn new(_flags: ()) -> (Self, Command<Message>) {
        (
            Ajour::default(),
            Command::perform(load_config(), Message::Parse),
        )
    }

    fn title(&self) -> String {
        String::from("Ajour")
    }

    fn update(&mut self, message: Message) -> Command<Message> {
        match update::handle_message(self, message) {
            Ok(x) => x,
            Err(e) => Command::perform(async { e }, Message::Error),
        }
    }

    fn view(&mut self) -> Element<Self::Message> {
        let default_font_size = 14;
        let default_padding = 10;

        // A row contain general controls.
        let mut controls = Row::new().spacing(1).height(Length::Units(35));

        let mut update_all_button = Button::new(
            &mut self.update_all_button_state,
            Text::new("Update All")
                .horizontal_alignment(HorizontalAlignment::Center)
                .size(default_font_size),
        )
        .style(style::DefaultBoxedButton);

        let mut refresh_button = Button::new(
            &mut self.refresh_button_state,
            Text::new("Refresh")
                .horizontal_alignment(HorizontalAlignment::Center)
                .size(default_font_size),
        )
        .style(style::DefaultBoxedButton);

        // Enable update_all_button and refresh_button,
        // if we have any Addons.
        if !self.addons.is_empty() {
            update_all_button = update_all_button.on_press(Interaction::UpdateAll);
            refresh_button = refresh_button.on_press(Interaction::Refresh);
        }

        let update_all_button: Element<Interaction> = update_all_button.into();
        let refresh_button: Element<Interaction> = refresh_button.into();

        // Displays text depending on the state of the app.
        let ignored_addons = self.config.addons.ignore.as_ref();
        let parent_addons_count = self
            .addons
            .clone()
            .iter()
            .filter(|a| a.is_parent() && !a.is_ignored(&ignored_addons))
            .count();
        let loading_addons = self
            .addons
            .iter()
            .filter(|a| a.state == AddonState::Loading)
            .count();
        let status_text = if loading_addons != 0 {
            Text::new(format!("Fetching data for {} addons", loading_addons))
                .size(default_font_size)
        } else {
            Text::new(format!("{} addons loaded", parent_addons_count)).size(default_font_size)
        };

        let status_container = Container::new(status_text)
            .center_y()
            .padding(5)
            .style(style::StatusTextContainer);

        let error_text = if let AjourState::Error(e) = &self.state {
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

        let version_text = Text::new(env!("CARGO_PKG_VERSION"))
            .size(default_font_size)
            .horizontal_alignment(HorizontalAlignment::Right);
        let version_container = Container::new(version_text)
            .center_y()
            .padding(5)
            .style(style::StatusTextContainer);

        let spacer = Space::new(Length::Units(7), Length::Units(0));
        // Not using default padding, just to make it look prettier UI wise
        let top_spacer = Space::new(Length::Units(0), Length::Units(5));
        let left_spacer = Space::new(Length::Units(default_padding), Length::Units(0));
        let right_spacer = Space::new(Length::Units(default_padding), Length::Units(0));

        controls = controls
            .push(left_spacer)
            .push(update_all_button.map(Message::Interaction))
            .push(spacer)
            .push(refresh_button.map(Message::Interaction))
            .push(status_container)
            .push(error_container)
            .push(version_container)
            .push(right_spacer);

        let controls_column = Column::new().push(top_spacer).push(controls);
        let controls_container = Container::new(controls_column);

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
        if !self.addons.is_empty() {
            row_titles = row_titles
                .push(left_spacer)
                .push(addon_row_container)
                .push(local_version_container)
                .push(remote_version_container)
                .push(status_row_container)
                .push(delete_row_container)
                .push(right_spacer);
        }

        // A scrollable list containing rows.
        // Each row holds information about a single addon.
        let mut addons_scrollable = Scrollable::new(&mut self.addons_scrollable_state)
            .spacing(1)
            .height(Length::FillPortion(1))
            .style(style::Scrollable);

        // Loops addons for GUI.
        let ignored_addons = self.config.addons.ignore.as_ref();
        for addon in &mut self
            .addons
            .iter_mut()
            .filter(|a| a.is_parent() && !a.is_ignored(&ignored_addons))
        {
            // Default element height
            let default_height = Length::Units(26);
            // Check if current addon is expanded.
            let is_addon_expanded = match &self.expanded_addon {
                Some(expanded_addon) => addon.id == expanded_addon.id,
                None => false,
            };
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
                    Text::new(string.clone().unwrap_or_else(|| "".to_string()))
                        .size(default_font_size),
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
                AddonState::Downloading => {
                    Container::new(Text::new("Downloading").size(default_font_size))
                        .height(default_height)
                        .width(update_button_width)
                        .center_y()
                        .center_x()
                        .padding(5)
                        .style(style::AddonRowSecondaryTextContainer)
                }
                AddonState::Unpacking => {
                    Container::new(Text::new("Unpacking").size(default_font_size))
                        .height(default_height)
                        .width(update_button_width)
                        .center_y()
                        .center_x()
                        .padding(5)
                        .style(style::AddonRowSecondaryTextContainer)
                }
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

            let cell = Container::new(row).width(Length::Fill).style(style::Row);
            addons_scrollable = addons_scrollable.push(cell);

            // Expanding cell
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

                let cell = Container::new(row).width(Length::Fill).style(style::Row);
                addons_scrollable = addons_scrollable.push(cell);
            }
        }

        let bottom_space = Space::new(Length::FillPortion(1), Length::Units(default_padding));
        // This column gathers all the other elements together.
        let content = Column::new()
            .push(controls_container)
            .push(row_titles)
            .push(addons_scrollable)
            .push(bottom_space)
            .padding(3); // small padding to make scrollbar fit better.

        // This container wraps the whole content.
        Container::new(content)
            .width(Length::Fill)
            .height(Length::Fill)
            .style(style::Content)
            .into()
    }
}

/// Starts the GUI.
/// This function does not return.
pub fn run() {
    let mut settings = Settings::default();
    settings.window.size = (900, 620);
    // Enforce the usage of dedicated gpu if available
    settings.antialiasing = true;
    Ajour::run(settings);
}
