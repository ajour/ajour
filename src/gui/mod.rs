mod style;

use iced::{
    button, executor, scrollable, Application, Button, Column, Command, Container, Element,
    HorizontalAlignment, Length, Row, Scrollable, Settings, Text,
};

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
    RefreshPressed,
    UpdateAllPressed,
}

struct Ajour {
    update_all_button_state: button::State,
    refresh_button_state: button::State,

    addons_scrollable_state: scrollable::State,
}

impl Application for Ajour {
    type Executor = executor::Null;
    type Message = Message;
    type Flags = ();

    fn new(_flags: ()) -> (Ajour, Command<Self::Message>) {
        (
            Ajour {
                update_all_button_state: button::State::new(),
                refresh_button_state: button::State::new(),
                addons_scrollable_state: scrollable::State::new(),
            },
            Command::none(),
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
        }
    }

    fn view(&mut self) -> Element<Self::Message> {
        let Ajour {
            update_all_button_state,
            refresh_button_state,
            addons_scrollable_state,
        } = self;

        let mut controls = Row::new().spacing(2).padding(10);
        let mut addons = Scrollable::new(addons_scrollable_state)
            .spacing(1)
            .padding(10);

        for _ in 0..10 {
            let text = Text::new("addon").size(14);
            let cell = Container::new(text)
                .width(Length::Fill)
                .height(Length::Units(30))
                .center_y()
                .padding(5)
                .style(style::Cell);
            addons = addons.push(cell);
        }

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

        let content: Element<_> = Column::new().push(controls).push(addons).into();

        Container::new(content)
            .width(Length::Fill)
            .height(Length::Fill)
            .style(style::Content)
            .into()
    }
}
