use iced::{
    button, scrollable, Button, Column, Container, Element, HorizontalAlignment, Length, Row,
    Sandbox, Scrollable, Settings, Text,
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
    UpdateAllPressed,
}

struct Ajour {
    scroll: scrollable::State,
    update_all_button: button::State,
}

// TODO: Upgrade from Sandbox to Appliation
// https://docs.rs/iced/0.1.1/iced/trait.Sandbox.html
impl Sandbox for Ajour {
    type Message = Message;

    fn new() -> Ajour {
        Ajour {
            update_all_button: button::State::new(),
            scroll: scrollable::State::new(),
        }
    }

    fn title(&self) -> String {
        String::from("Ajour")
    }

    fn update(&mut self, message: Message) {
        match message {
            Message::UpdateAllPressed => {
                println!("We pressed a button");
            }
        }
    }

    fn view(&mut self) -> Element<Self::Message> {
        let Ajour {
            update_all_button,
            scroll,
        } = self;

        let mut controls = Row::new();

        controls = controls.push(
            Button::new(
                update_all_button,
                Text::new("Update All").horizontal_alignment(HorizontalAlignment::Center),
            )
            .on_press(Message::UpdateAllPressed),
        );

        let content: Element<_> = Column::new().push(controls).into();

        let scrollable =
            Scrollable::new(scroll).push(Container::new(content).width(Length::Fill).center_x());

        Container::new(scrollable)
            .width(Length::Fill)
            .height(Length::Fill)
            .center_y()
            .into()
    }
}
