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
    HorizontalAlignment, Length, Row, Scrollable, Settings, Text, VerticalAlignment,
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

        // A row contain general controls.
        let mut controls = Row::new().spacing(1).height(Length::Units(35));

        let mut update_all_button = Button::new(
            &mut self.update_all_button_state,
            Text::new("Update All")
                .horizontal_alignment(HorizontalAlignment::Center)
                .size(default_font_size),
        )
        .style(style::DefaultButton);

        let mut refresh_button = Button::new(
            &mut self.refresh_button_state,
            Text::new("Refresh")
                .horizontal_alignment(HorizontalAlignment::Center)
                .size(default_font_size),
        )
        .style(style::DefaultButton);

        // Enable update_all_button and refresh_button,
        // if we have any Addons.
        if !self.addons.is_empty() {
            update_all_button = update_all_button.on_press(Interaction::UpdateAll);
            refresh_button = refresh_button.on_press(Interaction::Refresh);
        }

        let update_all_button: Element<Interaction> = update_all_button.into();
        let refresh_button: Element<Interaction> = refresh_button.into();

        // Displays text depending on the state of the app.
        let status_text = match &self.state {
            AjourState::Idle => Text::new(env!("CARGO_PKG_VERSION")).size(default_font_size),
            AjourState::Error(e) => Text::new(e.to_string()).size(default_font_size),
        };
        let status_container = Container::new(status_text)
            .center_y()
            .padding(5)
            .style(style::StatusTextContainer);

        let spacer = Container::new(Text::new("")).width(Length::Units(2));

        controls = controls
            .push(update_all_button.map(Message::Interaction))
            .push(spacer)
            .push(refresh_button.map(Message::Interaction))
            .push(status_container);

        // A row containing titles above the addon rows.
        let mut row_titles = Row::new().spacing(1).height(Length::Units(20));

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

        let delete_row_text = Text::new("Delete").size(default_font_size);
        let delete_row_container = Container::new(delete_row_text)
            .width(Length::Units(70))
            .style(style::StatusTextContainer);

        row_titles = row_titles
            .push(addon_row_container)
            .push(local_version_container)
            .push(remote_version_container)
            .push(status_row_container)
            .push(delete_row_container);

        // A scrollable list containing rows.
        // Each row holds information about a single addon.
        let mut addons_scrollable = Scrollable::new(&mut self.addons_scrollable_state).spacing(1);

        // Loops addons for GUI.
        for addon in &mut self.addons {
            // Default element height
            let default_height = Length::Units(35);

            // We filter away addons which isn't parent.
            if !addon.is_parent() {
                continue;
            }

            let title = addon.title.clone();
            let version = addon.version.clone().unwrap_or_else(|| String::from("-"));
            let remote_version = addon
                .remote_version
                .clone()
                .unwrap_or_else(|| String::from("-"));

            let text = Text::new(title).size(default_font_size);
            let text_container = Container::new(text)
                .height(default_height)
                .width(Length::FillPortion(1))
                .center_y()
                .padding(5)
                .style(style::AddonTextContainer);

            let installed_version = Text::new(version).size(default_font_size);
            let installed_version_container = Container::new(installed_version)
                .height(default_height)
                .width(Length::Units(150))
                .center_y()
                .padding(5)
                .style(style::AddonDescriptionContainer);

            let remote_version = Text::new(remote_version).size(default_font_size);
            let remote_version_container = Container::new(remote_version)
                .height(default_height)
                .width(Length::Units(150))
                .center_y()
                .padding(5)
                .style(style::AddonDescriptionContainer);

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
                .padding(5)
                .style(style::AddonDescriptionContainer),
                AddonState::Updatable => {
                    let id = addon.id.clone();
                    let update_button: Element<Interaction> = Button::new(
                        &mut addon.update_btn_state,
                        Text::new("Update")
                            .horizontal_alignment(HorizontalAlignment::Center)
                            .size(default_font_size),
                    )
                    .style(style::DefaultButton)
                    .on_press(Interaction::Update(id))
                    .into();

                    Container::new(update_button.map(Message::Interaction))
                        .height(default_height)
                        .width(update_button_width)
                        .center_y()
                        .center_x()
                        .padding(5)
                        .style(style::AddonDescriptionContainer)
                }
                AddonState::Downloading => {
                    Container::new(Text::new("Downloading").size(default_font_size))
                        .height(default_height)
                        .width(update_button_width)
                        .center_y()
                        .center_x()
                        .padding(5)
                        .style(style::AddonDescriptionContainer)
                }
                AddonState::Unpacking => {
                    Container::new(Text::new("Unpacking").size(default_font_size))
                        .height(default_height)
                        .width(update_button_width)
                        .center_y()
                        .center_x()
                        .padding(5)
                        .style(style::AddonDescriptionContainer)
                }
            };

            let delete_button: Element<Interaction> = Button::new(
                &mut addon.delete_btn_state,
                Text::new("Delete")
                    .vertical_alignment(VerticalAlignment::Center)
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(default_font_size),
            )
            .on_press(Interaction::Delete(addon.id.clone()))
            .style(style::DeleteButton)
            .into();

            let delete_button_container = Container::new(delete_button.map(Message::Interaction))
                .height(default_height)
                .width(Length::Units(70))
                .center_y()
                .center_x()
                .padding(5)
                .style(style::AddonDescriptionContainer);

            let row = Row::new()
                .push(text_container)
                .push(installed_version_container)
                .push(remote_version_container)
                .push(update_button_container)
                .push(delete_button_container)
                .spacing(1);

            let cell = Container::new(row).width(Length::Fill).style(style::Cell);
            addons_scrollable = addons_scrollable.push(cell);
        }

        // This column gathers all the other elements together.
        let content = Column::new()
            .push(controls)
            .push(row_titles)
            .push(addons_scrollable);

        // This container wraps the whole content.
        Container::new(content)
            .width(Length::Fill)
            .height(Length::Fill)
            .style(style::Content)
            .padding(10)
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
