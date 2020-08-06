mod style;
mod update;
use crate::{
    config::{load_config, Config},
    error::ClientError,
    toc::{Addon, AddonState},
    Result,
};
use iced::{
    button, scrollable, Application, Button, Column, Command, Container, Element,
    HorizontalAlignment, Length, Row, Scrollable, Settings, Text, VerticalAlignment,
};

#[derive(Debug)]
pub enum AjourState {
    Idle,
    Parsing,
    FetchingDetails,
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
    PatchedAddons(Result<Vec<Addon>>),
    DownloadedAddon((String, Result<()>)),
    UnpackedAddon((String, Result<()>)),
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
            state: AjourState::Parsing,
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
        // General controls
        //
        // A row contain general controls.
        let mut controls = Row::new().spacing(1);

        let update_all_button: Element<Interaction> = Button::new(
            &mut self.update_all_button_state,
            Text::new("Update All")
                .horizontal_alignment(HorizontalAlignment::Center)
                .size(12),
        )
        .on_press(Interaction::UpdateAll)
        .style(style::DefaultButton)
        .into();

        let refresh_button: Element<Interaction> = Button::new(
            &mut self.refresh_button_state,
            Text::new("Refresh")
                .horizontal_alignment(HorizontalAlignment::Center)
                .size(12),
        )
        .on_press(Interaction::Refresh)
        .style(style::DefaultButton)
        .into();

        controls = controls.push(update_all_button.map(Message::Interaction));
        controls = controls.push(refresh_button.map(Message::Interaction));

        // Addons
        //
        // A scrollable list containg rows.
        // Each row holds information about a single addon.
        let mut addons_scrollable = Scrollable::new(&mut self.addons_scrollable_state).spacing(1);

        // Primitive way to count how many addons we will show.
        let mut addon_count = 0;

        // Loops addons for GUI.
        for addon in &mut self.addons {
            // Default element height
            let default_height = Length::Units(35);

            // We filter away addons which isn't parent.
            if !addon.is_parent() {
                continue;
            }

            // Increment addon count.
            addon_count = addon_count + 1;

            let title = addon.title.clone();
            let version = addon.version.clone().unwrap_or(String::from("-"));
            let remote_version = addon.remote_version.clone().unwrap_or(String::from("-"));

            let text = Text::new(title).size(12);
            let text_container = Container::new(text)
                .height(default_height)
                .width(Length::FillPortion(1))
                .center_y()
                .padding(5)
                .style(style::AddonTextContainer);

            let installed_version = Text::new(version).size(12);
            let installed_version_container = Container::new(installed_version)
                .height(default_height)
                .width(Length::Units(125))
                .center_y()
                .padding(5)
                .style(style::AddonDescriptionContainer);

            let remote_version = Text::new(remote_version).size(12);
            let remote_version_container = Container::new(remote_version)
                .height(default_height)
                .width(Length::Units(125))
                .center_y()
                .padding(5)
                .style(style::AddonDescriptionContainer);

            let update_button_width = Length::Units(75);
            let update_button_container = match &addon.state {
                AddonState::Ajour(string) => {
                    Container::new(Text::new(string.clone().unwrap_or("".to_string())).size(12))
                        .height(default_height)
                        .width(update_button_width)
                        .center_y()
                        .center_x()
                        .padding(5)
                        .style(style::AddonDescriptionContainer)
                }
                AddonState::Updatable => {
                    let id = addon.wowi_id.clone().unwrap();
                    let update_button: Element<Interaction> = Button::new(
                        &mut addon.update_btn_state,
                        Text::new("Update")
                            .horizontal_alignment(HorizontalAlignment::Center)
                            .size(12),
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
                AddonState::Downloading => Container::new(Text::new("Downloading").size(12))
                    .height(default_height)
                    .width(update_button_width)
                    .center_y()
                    .center_x()
                    .padding(5)
                    .style(style::AddonDescriptionContainer),
                AddonState::Unpacking => Container::new(Text::new("Unpacking").size(12))
                    .height(default_height)
                    .width(update_button_width)
                    .center_y()
                    .center_x()
                    .padding(5)
                    .style(style::AddonDescriptionContainer),
            };

            let delete_button: Element<Interaction> = Button::new(
                &mut addon.delete_btn_state,
                Text::new("Delete")
                    .vertical_alignment(VerticalAlignment::Center)
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(12),
            )
            .on_press(Interaction::Delete(addon.id.clone()))
            .style(style::DeleteButton)
            .into();

            let delete_button_container = Container::new(delete_button.map(Message::Interaction))
                .height(default_height)
                .width(Length::Units(65))
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

        // Status text
        //
        // Displays text depending on the state of the app.
        let status_text = match &self.state {
            AjourState::Idle => Text::new(format!("Loaded {:?} addons", addon_count)).size(12),
            AjourState::Parsing => Text::new("Parsing local addons").size(12),
            AjourState::FetchingDetails => Text::new("Fetching data from repositories").size(12),
            AjourState::Error(e) => Text::new(e.to_string()).size(12),
        };
        let status_container = Container::new(status_text)
            .height(Length::Units(35))
            .width(Length::FillPortion(1))
            .center_y()
            .padding(5)
            .style(style::StatusTextContainer);

        // A little "hack" to make a spacer
        let spacer_1 = Container::new(Text::new(""))
            .height(Length::Units(10))
            .width(Length::Fill);

        // A little "hack" to make a spacer
        let spacer_2 = Container::new(Text::new(""))
            .height(Length::Units(10))
            .width(Length::Fill);

        // Column
        //
        // This column gathers all the other elements together.
        let content = Column::new()
            .push(controls)
            .push(spacer_1)
            .push(status_container)
            .push(spacer_2)
            .push(addons_scrollable);

        // Container
        //
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
