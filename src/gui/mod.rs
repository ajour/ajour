mod style;
mod update;
use crate::{
    config::{load_config, Config},
    error::ClientError,
    toc::addon::Addon,
    Result,
};
use iced::{
    button, scrollable, Application, Button, Column, Command, Container, Element,
    HorizontalAlignment, Length, Row, Scrollable, Settings, Text,
};

#[derive(Debug)]
pub enum AjourState {
    Idle,
    Loading,
    Refreshing,
    Error(ClientError),
}

#[derive(Debug, Clone)]
pub enum Interaction {
    Refresh,
    UpdateAll,
    Delete(String),
}

#[derive(Debug)]
pub enum Message {
    Load(Config),
    Loaded(Result<Vec<Addon>>),
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
            state: AjourState::Loading,
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
            Command::perform(load_config(), Message::Load),
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
        let addons_length = &mut self.addons.len().clone();

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

        for addon in &mut self.addons {
            // We filter away addons which isn't parent
            if !addon.is_parent() {
                continue;
            }

            let title = addon.title.clone();
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

            let delete_button: Element<Interaction> = Button::new(
                &mut addon.delete_btn_state,
                Text::new("Delete")
                    .horizontal_alignment(HorizontalAlignment::Center)
                    .size(12),
            )
            .on_press(Interaction::Delete(addon.id.clone()))
            .style(style::DeleteButton)
            .into();

            let delete_button_container = Container::new(delete_button.map(Message::Interaction))
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

            let cell = Container::new(row).width(Length::Fill).style(style::Cell);
            addons_scrollable = addons_scrollable.push(cell);
        }

        // Status text
        //
        // Displays text depending on the state of the app.
        let status_text = match &self.state {
            AjourState::Idle => Text::new(format!("Loaded {:?} addons", addons_length)).size(12),
            AjourState::Loading => Text::new("Loading config file").size(12),
            AjourState::Refreshing => Text::new("Refreshing addons").size(12),
            AjourState::Error(e) => Text::new(e.to_string()).size(12),
        };
        let status_container = Container::new(status_text)
            .height(Length::Units(30))
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
    settings.window.size = (1050, 620);
    // Enforce the usage of dedicated gpu if available
    settings.antialiasing = true;
    Ajour::run(settings);
}
