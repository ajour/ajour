use {
    super::{DEFAULT_FONT_SIZE, DEFAULT_PADDING},
    crate::gui::{style, ColumnKey, Interaction, Message, Mode, State, WeakAurasState},
    ajour_core::config::Flavor,
    ajour_core::theme::ColorPalette,
    ajour_weak_auras::Aura,
    ajour_widgets::TableRow,
    iced::{
        button, pick_list, Button, Column, Container, Element, Length, PickList, Row, Space, Text,
    },
    std::collections::HashMap,
};

#[allow(clippy::too_many_arguments)]
pub fn menu_container<'a>(
    color_palette: ColorPalette,
    flavor: Flavor,
    update_all_button_state: &'a mut button::State,
    refresh_button_state: &'a mut button::State,
    state: &HashMap<Mode, State>,
    num_auras: usize,
    updates_available: bool,
    accounts_picklist_state: &'a mut pick_list::State<String>,
    accounts: &'a [String],
    chosen_account: Option<String>,
) -> Container<'a, Message> {
    // MyWeakAuras state.
    let state = state
        .get(&Mode::MyWeakAuras(flavor))
        .cloned()
        .unwrap_or_default();

    // A row contain general settings.
    let mut row = Row::new().height(Length::Units(35));

    let mut update_all_button = Button::new(
        update_all_button_state,
        Text::new("Update All").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultButton(color_palette));

    let mut refresh_button = Button::new(
        refresh_button_state,
        Text::new("Refresh").size(DEFAULT_FONT_SIZE),
    )
    .style(style::DefaultButton(color_palette));

    let pick_list = PickList::new(
        accounts_picklist_state,
        accounts,
        chosen_account,
        Message::WeakAurasAccountSelected,
    )
    .text_size(14)
    .width(Length::Units(120))
    .style(style::PickList(color_palette));

    if updates_available {
        update_all_button =
            update_all_button.on_press(Interaction::UpdateAll(Mode::MyWeakAuras(flavor)));
    }

    refresh_button = refresh_button.on_press(Interaction::Refresh(Mode::MyWeakAuras(flavor)));

    let update_all_button: Element<Interaction> = update_all_button.into();
    let refresh_button: Element<Interaction> = refresh_button.into();
    let status_text = match state {
        State::Ready => {
            Text::new(format!("{} weakauras loaded", num_auras,)).size(DEFAULT_FONT_SIZE)
        }
        _ => Text::new(""),
    };

    let status_container = Container::new(status_text)
        .center_y()
        .padding(5)
        .style(style::NormalBackgroundContainer(color_palette));

    row = row
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
        .push(refresh_button.map(Message::Interaction))
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(update_all_button.map(Message::Interaction))
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(pick_list)
        .push(Space::new(Length::Units(7), Length::Units(0)))
        .push(status_container)
        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)));

    // Add space above settings_row.
    let settings_column = Column::new()
        .push(Space::new(Length::Units(0), Length::Units(5)))
        .push(row);

    // Wraps it in a container.
    Container::new(settings_column)
}

pub fn data_row_container<'a, 'b>(
    color_palette: ColorPalette,
    aura: &Aura,
    _: &'b [(ColumnKey, Length, bool)],
) -> TableRow<'a, Message> {
    let default_height = 26;

    let title = Text::new(aura.name()).size(DEFAULT_FONT_SIZE);
    let title_container = Container::new(title)
        .height(Length::Units(default_height))
        .center_y();

    let left_spacer = Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0));
    let right_spacer = Space::new(Length::Units(DEFAULT_PADDING + 5), Length::Units(0));

    let mut row = Row::new().spacing(1);

    row = row.push(left_spacer);
    row = row.push(title_container);
    row = row.push(right_spacer);

    let addon_column = Column::new().push(row);

    return TableRow::new(addon_column)
        .width(Length::Fill)
        .inner_row_height(26)
        .style(style::TableRow(color_palette));
}
