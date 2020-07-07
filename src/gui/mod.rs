mod style;

use iced::{
    button, scrollable, Application, Button, Column, Command, Container, Element,
    HorizontalAlignment, Length, Row, Scrollable, Settings, Text,
};

use crate::toc::{Addon, Error, read_addon_dir};

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
    RefreshAddons(Result<Vec<Addon>, Error>),
    RefreshPressed,
    UpdateAllPressed,
}


struct Ajour {
    update_all_button_state: button::State,
    refresh_button_state: button::State,
    addons_scrollable_state: scrollable::State,
    addons: Vec<Addon>,
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
            update_all_button_state: Default::default(),
            refresh_button_state: Default::default(),
            addons_scrollable_state: Default::default(),
            addons: Default::default(),
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
            Command::perform(read_addon_dir("../../test-data"), Message::RefreshAddons),
        )
    }


    fn title(&self) -> String {
        String::from("Ajour")
    }

    fn update(&mut self, message: Message) -> Command<Message> {
        match message {
            Message::UpdateAllPressed => {
                println!("Update all button pressed");
                Command::none()
            }
            Message::RefreshPressed => {
                println!("Refresh button pressed");
                Command::none()
            }
            Message::RefreshAddons(result) => {
                println!("We fetched addons");
                println!("addons {:?}", result);
                // self.addons = addons;
                Command::none()
            }
        }
    }

    fn view(&mut self) -> Element<Self::Message> {
        let Ajour {
            update_all_button_state,
            refresh_button_state,
            addons_scrollable_state,
            addons,
        } = self;

        println!("addons: {:?}", addons);

        // General controls
        //
        // A row contain general controls.
        let mut controls = Row::new().spacing(1).padding(10);
        controls = controls.push(
            Button::new(
                update_all_button_state,
                Text::new("Update all")
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(12),
            )
            .on_press(Message::UpdateAllPressed)
            .style(style::DefaultButton),
        );
        controls = controls.push(
            Button::new(
                refresh_button_state,
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
        let mut addons = Scrollable::new(addons_scrollable_state)
            .spacing(1)
            .padding(10);
        for _ in 0..10 {
            let text = Text::new("Raider.IO Mythic Plus and Raid Progress by TheFakeJah").size(12);
            let text_container = Container::new(text)
                .height(Length::Units(30))
                .width(Length::FillPortion(1))
                .center_y()
                .padding(5)
                .center_y()
                .style(style::AddonTextContainer);

            let installed_version = Text::new("8.2.5").size(12);
            let installed_version_container = Container::new(installed_version)
                .height(Length::Units(30))
                .width(Length::Units(75))
                .center_y()
                .padding(5)
                .center_y()
                .style(style::AddonDescriptionContainer);

            let available_version = Text::new("8.2.5").size(12);
            let available_version_container = Container::new(available_version)
                .height(Length::Units(30))
                .width(Length::Units(75))
                .center_y()
                .padding(5)
                .center_y()
                .style(style::AddonDescriptionContainer);

            let row = Row::new()
                .push(text_container)
                .push(installed_version_container)
                .push(available_version_container)
                .spacing(1);

            // Cell
            let cell = Container::new(row).width(Length::Fill).style(style::Cell);
            addons = addons.push(cell);
        }

        let content: Element<_> = Column::new().push(controls).push(addons).into();

        Container::new(content)
            .width(Length::Fill)
            .height(Length::Fill)
            .style(style::Content)
            .into()
    }
}
