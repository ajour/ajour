use ajour_core::theme::ColorPalette;
use iced::{button, container, pick_list, scrollable, Background, Color};

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

pub struct SegmentedButton(pub ColorPalette);
impl button::StyleSheet for SegmentedButton {
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
