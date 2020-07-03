use iced::{Element, Sandbox, Settings, Text};

pub struct Window {
}

impl Window {
    pub fn new() -> Window {
        Hello::run(Settings::default());
        return Window {

        }
    }
}

struct Hello;

// TODO: Upgrade from Sandbox to Appliation
// https://docs.rs/iced/0.1.1/iced/trait.Sandbox.html
impl Sandbox for Hello {
    type Message = ();

    fn new() -> Hello {
        Hello
    }

    fn title(&self) -> String {
        String::from("Ajour")
    }

    fn update(&mut self, _message: Self::Message) {
        // This application has no interactions
    }

    fn view(&mut self) -> Element<Self::Message> {
        Text::new("Hello, world!").into()
    }
}
