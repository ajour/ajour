use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{style, Interaction, Message},
    ajour_core::theme::ColorPalette,
    iced::{
        button, Align, Button, Column, Container, Element, HorizontalAlignment, Length, Space, Text,
    },
};

// TODO (casperstorm): I would like to make this only handle title and description.
pub fn data_container<'a>(
    color_palette: ColorPalette,
    title: &str,
    description: &str,
    button: Option<(&'a mut button::State, String, Interaction)>,
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

    if let Some((state, title, interaction)) = button {
        let title_container = Container::new(Text::new(title).size(DEFAULT_FONT_SIZE))
            .center_x()
            .align_x(Align::Center);
        let button: Element<Interaction> = Button::new(state, title_container)
            .style(style::DefaultButton(color_palette))
            .on_press(interaction)
            .into();

        colum = colum
            .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
            .push(button.map(Message::Interaction))
            .align_items(Align::Center);
    }

    Container::new(colum)
        .center_y()
        .center_x()
        .width(Length::Fill)
        .height(Length::Fill)
}
