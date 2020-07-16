mod style;

use iced::{
    button, scrollable, Application, Button, Column, Command, Container, Element,
    HorizontalAlignment, Length, Row, Scrollable, Settings, Text,
};

use crate::config::{load_config, Config};
use crate::toc::{read_addon_dir, Addon, Error};

/// Starts the GUI.
/// This function does not return.
pub fn run() {
    let mut settings = Settings::default();
    settings.window.size = (1050, 620);
    // Enforce the usage of dedicated gpu if available
    settings.antialiasing = true;
    Ajour::run(settings);
}

#[derive(Debug, Clone)]
pub enum Message {
    LoadConfig(Config),
    RefreshAddons(Result<Vec<Addon>, Error>),
    RefreshPressed,
    UpdateAllPressed,
}

struct Ajour {
    update_all_button_state: button::State,
    refresh_button_state: button::State,
    addons_scrollable_state: scrollable::State,
    addons: Vec<Addon>,
    config: Config,
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
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
            Command::perform(load_config(), Message::LoadConfig),
        )
    }

    fn title(&self) -> String {
        String::from("Ajour")
    }

    fn update(&mut self, message: Message) -> Command<Message> {
        match message {
            Message::LoadConfig(config) => {
                // When we have the config, we perform an action to read the addon directory
                // which is provided by the config.
                self.config = config;
                let wow_directory = self.config.wow_directory.clone();
                match wow_directory {
                    Some(wow_directory) => {
                        Command::perform(read_addon_dir(wow_directory), Message::RefreshAddons)
                    }
                    None => Command::none(),
                }
            }
            Message::UpdateAllPressed => {
                println!("Update all button pressed");
                Command::none()
            }
            Message::RefreshPressed => {
                // Refreshes the state.
                self.addons = Vec::new();
                Command::perform(load_config(), Message::LoadConfig)
            }
            Message::RefreshAddons(Ok(addons)) => {
                self.addons = addons;
                Command::none()
            }
            Message::RefreshAddons(Err(_)) => Command::none(),
        }
    }

    fn view(&mut self) -> Element<Self::Message> {
        // General controls
        //
        // A row contain general controls.
        let mut controls = Row::new().spacing(1).padding(10);
        controls = controls.push(
            Button::new(
                &mut self.update_all_button_state,
                Text::new("Update all")
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(12),
            )
            .on_press(Message::UpdateAllPressed)
            .style(style::DefaultButton),
        );
        controls = controls.push(
            Button::new(
                &mut self.refresh_button_state,
                Text::new("Refresh")
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(12),
            )
            .on_press(Message::RefreshPressed)
            .style(style::DefaultButton),
        );

        // Addons
        //
        // A scrollable list containg rows.
        // Each row holds information about a single addon.
        let mut addons_scrollable = Scrollable::new(&mut self.addons_scrollable_state)
            .spacing(1)
            .padding(10);

        for addon in &mut self.addons {
            let title = addon.title.clone().unwrap_or(String::from("-"));
            let version = addon.version.clone().unwrap_or(String::from("-"));

            let text = Text::new(title).size(12);
            let text_container = Container::new(text)
                .height(Length::Units(30))
                .width(Length::FillPortion(1))
                .center_y()
                .padding(5)
                .style(style::AddonTextContainer);

            let installed_version = Text::new(version).size(12);
            let installed_version_container = Container::new(installed_version)
                .height(Length::Units(30))
                .width(Length::Units(75))
                .center_y()
                .padding(5)
                .style(style::AddonDescriptionContainer);

            let available_version = Text::new("-").size(12);
            let available_version_container = Container::new(available_version)
                .height(Length::Units(30))
                .width(Length::Units(75))
                .center_y()
                .padding(5)
                .style(style::AddonDescriptionContainer);

            let delete_button = Button::new(
                &mut addon.delete_btn_state,
                Text::new("Delete")
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(12),
            )
            .on_press(Message::UpdateAllPressed)
            .style(style::DeleteButton);

            let delete_button_container = Container::new(delete_button)
                .height(Length::Units(30))
                .center_y()
                .padding(5)
                .style(style::AddonDescriptionContainer);

            let row = Row::new()
                .push(text_container)
                .push(installed_version_container)
                .push(available_version_container)
                .push(delete_button_container)
                .spacing(1);

            // Cell
            let cell = Container::new(row).width(Length::Fill).style(style::Cell);
            addons_scrollable = addons_scrollable.push(cell);
        }

        let content: Element<_> = Column::new().push(controls).push(addons_scrollable).into();

        Container::new(content)
            .width(Length::Fill)
            .height(Length::Fill)
            .style(style::Content)
            .into()
    }
}
