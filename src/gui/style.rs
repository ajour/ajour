use ajour_core::theme::ColorPalette;
use iced::{button, checkbox, container, pick_list, scrollable, text_input, Background, Color};

pub struct SurfaceContainer(pub ColorPalette);
impl container::StyleSheet for SurfaceContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.surface)),
            ..container::Style::default()
        }
    }
}

pub struct TextButton(pub ColorPalette);
impl button::StyleSheet for TextButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: self.0.on_surface,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color::TRANSPARENT)),
            text_color: self.0.primary,
            ..self.active()
        }
    }
}

pub struct SelectedTextButton(pub ColorPalette);
impl button::StyleSheet for SelectedTextButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: self.0.primary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color::TRANSPARENT)),
            text_color: self.0.primary,
            ..self.active()
        }
    }
}

pub struct DefaultButton(pub ColorPalette);
impl button::StyleSheet for DefaultButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: self.0.primary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..self.0.primary
            })),
            text_color: self.0.primary,
            ..self.active()
        }
    }
}

pub struct DefaultBoxedButton(pub ColorPalette);
impl button::StyleSheet for DefaultBoxedButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.03,
                ..self.0.primary
            })),
            text_color: self.0.primary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..self.0.primary
            })),
            text_color: self.0.primary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.01,
                ..self.0.primary
            })),
            text_color: Color {
                a: 0.1,
                ..self.0.primary
            },
            ..self.active()
        }
    }
}

pub struct SecondaryButton(pub ColorPalette);
impl button::StyleSheet for SecondaryButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: self.0.secondary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..self.0.secondary
            })),
            text_color: self.0.secondary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.secondary)),
            text_color: self.0.secondary,
            ..self.active()
        }
    }
}

pub struct DeleteBoxedButton(pub ColorPalette);
impl button::StyleSheet for DeleteBoxedButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.03,
                ..self.0.error
            })),
            text_color: self.0.error,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..self.0.error
            })),
            text_color: self.0.error,
            ..self.active()
        }
    }
}

pub struct ColumnHeaderButton(pub ColorPalette);
impl button::StyleSheet for ColumnHeaderButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.background)),
            text_color: Color {
                ..self.0.on_surface
            },
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..self.0.primary
            })),
            text_color: self.0.primary,
            ..self.active()
        }
    }
}

pub struct UnclickableColumnHeaderButton(pub ColorPalette);
impl button::StyleSheet for UnclickableColumnHeaderButton {
    fn active(&self) -> button::Style {
        ColumnHeaderButton(self.0).active()
    }

    fn disabled(&self) -> button::Style {
        self.active()
    }
}

pub struct SelectedColumnHeaderButton(pub ColorPalette);
impl button::StyleSheet for SelectedColumnHeaderButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.background)),
            text_color: Color { ..self.0.primary },
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..self.0.primary
            })),
            text_color: self.0.primary,
            ..self.active()
        }
    }
}

pub struct SegmentedDisabledButton(pub ColorPalette);
impl button::StyleSheet for SegmentedDisabledButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color::TRANSPARENT)),
            text_color: Color {
                a: 0.1,
                ..self.0.primary
            },
            border_radius: 2,
            border_width: 0,
            border_color: Color {
                a: 0.1,
                ..self.0.primary
            },
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style { ..self.active() }
    }

    fn disabled(&self) -> button::Style {
        button::Style { ..self.active() }
    }
}

pub struct SegmentedUnselectedButton(pub ColorPalette);
impl button::StyleSheet for SegmentedUnselectedButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color::TRANSPARENT)),
            text_color: Color {
                a: 0.5,
                ..self.0.primary
            },
            border_radius: 2,
            border_width: 1,
            border_color: Color {
                a: 0.03,
                ..self.0.primary
            },
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.03,
                ..self.0.primary
            })),
            text_color: self.0.primary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.01,
                ..self.0.primary
            })),
            text_color: Color {
                a: 0.1,
                ..self.0.primary
            },
            ..self.active()
        }
    }
}

pub struct SegmentedSelectedButton(pub ColorPalette);
impl button::StyleSheet for SegmentedSelectedButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.03,
                ..self.0.primary
            })),
            text_color: self.0.primary,
            border_radius: 2,
            border_width: 0,
            border_color: Color::TRANSPARENT,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.03,
                ..self.0.primary
            })),
            text_color: self.0.primary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.01,
                ..self.0.primary
            })),
            text_color: Color {
                a: 0.1,
                ..self.0.primary
            },
            ..self.active()
        }
    }
}

pub struct Content(pub ColorPalette);
impl container::StyleSheet for Content {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.background)),
            ..container::Style::default()
        }
    }
}

pub struct AddonRowDefaultTextContainer(pub ColorPalette);
impl container::StyleSheet for AddonRowDefaultTextContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.surface)),
            text_color: Some(self.0.on_surface),
            ..container::Style::default()
        }
    }
}

pub struct AddonRowSecondaryTextContainer(pub ColorPalette);
impl container::StyleSheet for AddonRowSecondaryTextContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.surface)),
            text_color: Some(Color {
                a: 0.65,
                ..self.0.on_surface
            }),
            ..container::Style::default()
        }
    }
}

pub struct AddonRowDetailsContainer(pub ColorPalette);
impl container::StyleSheet for AddonRowDetailsContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(Color {
                a: 0.60,
                ..self.0.surface
            })),
            text_color: Some(Color {
                a: 0.65,
                ..self.0.on_surface
            }),
            ..container::Style::default()
        }
    }
}

pub struct SecondaryTextContainer(pub ColorPalette);
impl container::StyleSheet for SecondaryTextContainer {
    fn style(&self) -> container::Style {
        container::Style {
            text_color: Some(Color {
                a: 0.65,
                ..self.0.on_surface
            }),
            ..container::Style::default()
        }
    }
}

pub struct DefaultTextContainer(pub ColorPalette);
impl container::StyleSheet for DefaultTextContainer {
    fn style(&self) -> container::Style {
        container::Style {
            text_color: Some(self.0.on_surface),
            ..container::Style::default()
        }
    }
}

pub struct StatusErrorTextContainer(pub ColorPalette);
impl container::StyleSheet for StatusErrorTextContainer {
    fn style(&self) -> container::Style {
        container::Style {
            text_color: Some(Color {
                a: 0.8,
                ..self.0.error
            }),
            ..container::Style::default()
        }
    }
}

pub struct Row(pub ColorPalette);
impl container::StyleSheet for Row {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.background)),
            ..container::Style::default()
        }
    }
}

pub struct Scrollable(pub ColorPalette);
impl scrollable::StyleSheet for Scrollable {
    fn active(&self) -> scrollable::Scrollbar {
        scrollable::Scrollbar {
            background: Some(Background::Color(self.0.background)),
            border_radius: 0,
            border_width: 0,
            border_color: Color::TRANSPARENT,
            scroller: scrollable::Scroller {
                color: self.0.surface,
                border_radius: 2,
                border_width: 0,
                border_color: Color::TRANSPARENT,
            },
        }
    }

    fn hovered(&self) -> scrollable::Scrollbar {
        let active = self.active();

        scrollable::Scrollbar {
            scroller: scrollable::Scroller { ..active.scroller },
            ..active
        }
    }

    fn dragging(&self) -> scrollable::Scrollbar {
        let hovered = self.hovered();
        scrollable::Scrollbar {
            scroller: scrollable::Scroller { ..hovered.scroller },
            ..hovered
        }
    }
}

pub struct SecondaryScrollable(pub ColorPalette);
impl scrollable::StyleSheet for SecondaryScrollable {
    fn active(&self) -> scrollable::Scrollbar {
        scrollable::Scrollbar {
            background: Some(Background::Color(self.0.surface)),
            border_radius: 0,
            border_width: 0,
            border_color: Color::TRANSPARENT,
            scroller: scrollable::Scroller {
                color: self.0.background,
                border_radius: 2,
                border_width: 0,
                border_color: Color::TRANSPARENT,
            },
        }
    }

    fn hovered(&self) -> scrollable::Scrollbar {
        let active = self.active();

        scrollable::Scrollbar {
            scroller: scrollable::Scroller { ..active.scroller },
            ..active
        }
    }

    fn dragging(&self) -> scrollable::Scrollbar {
        let hovered = self.hovered();
        scrollable::Scrollbar {
            scroller: scrollable::Scroller { ..hovered.scroller },
            ..hovered
        }
    }
}

pub struct PickList(pub ColorPalette);
impl pick_list::StyleSheet for PickList {
    fn menu(&self) -> pick_list::Menu {
        pick_list::Menu {
            text_color: self.0.on_surface,
            background: Background::Color(self.0.background),
            border_width: 1,
            border_color: self.0.surface,
            selected_background: Color {
                a: 0.1,
                ..self.0.primary
            }
            .into(),
            selected_text_color: self.0.primary,
        }
    }

    fn active(&self) -> pick_list::Style {
        pick_list::Style {
            text_color: self.0.on_surface,
            background: Background::Color(self.0.background),
            border_width: 1,
            border_color: Color {
                a: 1.0,
                ..self.0.background
            },
            border_radius: 2,
            icon_size: 0.5,
        }
    }

    fn hovered(&self) -> pick_list::Style {
        let active = self.active();
        pick_list::Style { ..active }
    }
}

pub struct SecondaryPickList(pub ColorPalette);
impl pick_list::StyleSheet for SecondaryPickList {
    fn menu(&self) -> pick_list::Menu {
        pick_list::Menu {
            text_color: self.0.on_surface,
            background: Background::Color(self.0.background),
            border_width: 1,
            border_color: self.0.surface,
            selected_background: Color {
                a: 0.1,
                ..self.0.primary
            }
            .into(),
            selected_text_color: self.0.primary,
        }
    }

    fn active(&self) -> pick_list::Style {
        pick_list::Style {
            text_color: self.0.on_surface,
            background: Background::Color(self.0.surface),
            border_width: 0,
            border_color: Color {
                a: 1.0,
                ..self.0.background
            },
            border_radius: 2,
            icon_size: 0.5,
        }
    }

    fn hovered(&self) -> pick_list::Style {
        let active = self.active();
        pick_list::Style { ..active }
    }
}

pub struct ChannelBadge(pub ColorPalette);
impl container::StyleSheet for ChannelBadge {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.surface)),
            text_color: Some(self.0.primary),
            border_color: self.0.primary,
            border_radius: 3,
            border_width: 1,
        }
    }
}

pub struct DefaultCheckbox(pub ColorPalette);
impl checkbox::StyleSheet for DefaultCheckbox {
    fn active(&self, _is_checked: bool) -> checkbox::Style {
        checkbox::Style {
            background: Background::Color(self.0.surface),
            checkmark_color: Color {
                a: 0.70,
                ..self.0.primary
            },
            border_radius: 3,
            border_width: 2,
            border_color: Color {
                a: 0.70,
                ..self.0.primary
            },
        }
    }

    fn hovered(&self, _is_checked: bool) -> checkbox::Style {
        checkbox::Style {
            background: Background::Color(self.0.surface),
            checkmark_color: self.0.primary,
            border_radius: 3,
            border_width: 2,
            border_color: self.0.primary,
        }
    }
}

pub struct AlwaysCheckedCheckbox(pub ColorPalette);
impl checkbox::StyleSheet for AlwaysCheckedCheckbox {
    fn active(&self, _is_checked: bool) -> checkbox::Style {
        checkbox::Style {
            background: Background::Color(self.0.surface),
            checkmark_color: Color {
                a: 0.20,
                ..self.0.primary
            },
            border_radius: 3,
            border_width: 2,
            border_color: Color {
                a: 0.20,
                ..self.0.primary
            },
        }
    }

    fn hovered(&self, _is_checked: bool) -> checkbox::Style {
        self.active(_is_checked)
    }
}

pub struct CatalogQueryInput(pub ColorPalette);
impl text_input::StyleSheet for CatalogQueryInput {
    /// Produces the style of an active text input.
    fn active(&self) -> text_input::Style {
        text_input::Style {
            background: Background::Color(self.0.surface),
            border_radius: 0,
            border_width: 0,
            border_color: Color {
                a: 0.30,
                ..self.0.surface
            },
        }
    }

    /// Produces the style of a focused text input.
    fn focused(&self) -> text_input::Style {
        text_input::Style {
            background: Background::Color(self.0.surface),
            border_radius: 2,
            border_width: 1,
            border_color: Color {
                a: 0.70,
                ..self.0.primary
            },
        }
    }

    fn placeholder_color(&self) -> Color {
        Color {
            a: 0.30,
            ..self.0.on_surface
        }
    }

    fn value_color(&self) -> Color {
        self.0.primary
    }

    fn selection_color(&self) -> Color {
        Color {
            a: 0.30,
            ..self.0.secondary
        }
    }

    /// Produces the style of an hovered text input.
    fn hovered(&self) -> text_input::Style {
        self.focused()
    }
}
