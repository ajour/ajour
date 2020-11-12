use ajour_core::theme::ColorPalette;
use iced::{button, checkbox, container, pick_list, scrollable, text_input, Background, Color};

pub struct BrightForegroundContainer(pub ColorPalette);
impl container::StyleSheet for BrightForegroundContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.base.foreground)),
            text_color: Some(self.0.bright.surface),
            ..container::Style::default()
        }
    }
}

pub struct NormalForegroundContainer(pub ColorPalette);
impl container::StyleSheet for NormalForegroundContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.base.foreground)),
            text_color: Some(self.0.normal.surface),
            ..container::Style::default()
        }
    }
}

pub struct FadedNormalForegroundContainer(pub ColorPalette);
impl container::StyleSheet for FadedNormalForegroundContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(Color {
                a: 0.80,
                ..self.0.base.foreground
            })),

            text_color: Some(self.0.normal.surface),
            ..container::Style::default()
        }
    }
}

pub struct FadedBrightForegroundContainer(pub ColorPalette);
impl container::StyleSheet for FadedBrightForegroundContainer {
    fn style(&self) -> container::Style {
        container::Style {
            text_color: Some(self.0.bright.surface),
            ..container::Style::default()
        }
    }
}

pub struct NormalBackgroundContainer(pub ColorPalette);
impl container::StyleSheet for NormalBackgroundContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.base.background)),
            text_color: Some(self.0.normal.surface),
            ..container::Style::default()
        }
    }
}

pub struct BrightBackgroundContainer(pub ColorPalette);
impl container::StyleSheet for BrightBackgroundContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.base.background)),
            text_color: Some(self.0.bright.surface),
            ..container::Style::default()
        }
    }
}

pub struct SegmentedContainer(pub ColorPalette);
impl container::StyleSheet for SegmentedContainer {
    fn style(&self) -> container::Style {
        container::Style {
            border_radius: 4,
            border_width: 1,
            border_color: Color {
                a: 0.5,
                ..self.0.normal.primary
            },
            ..container::Style::default()
        }
    }
}

pub struct NormalErrorBackgroundContainer(pub ColorPalette);
impl container::StyleSheet for NormalErrorBackgroundContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.base.background)),
            text_color: Some(self.0.normal.error),
            ..container::Style::default()
        }
    }
}

pub struct NormalErrorForegroundContainer(pub ColorPalette);
impl container::StyleSheet for NormalErrorForegroundContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.base.foreground)),
            text_color: Some(self.0.normal.error),
            ..container::Style::default()
        }
    }
}

pub struct BrightTextButton(pub ColorPalette);
impl button::StyleSheet for BrightTextButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: self.0.bright.surface,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color::TRANSPARENT)),
            text_color: self.0.bright.primary,
            ..self.active()
        }
    }
}

pub struct SelectedBrightTextButton(pub ColorPalette);
impl button::StyleSheet for SelectedBrightTextButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: self.0.bright.primary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color::TRANSPARENT)),
            text_color: self.0.bright.primary,
            ..self.active()
        }
    }
}

pub struct DefaultButton(pub ColorPalette);
impl button::StyleSheet for DefaultButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: self.0.bright.primary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.normal.primary)),
            text_color: self.0.bright.primary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            text_color: Color {
                a: 0.25,
                ..self.0.normal.surface
            },
            ..self.active()
        }
    }
}

pub struct DefaultBoxedButton(pub ColorPalette);
impl button::StyleSheet for DefaultBoxedButton {
    fn active(&self) -> button::Style {
        button::Style {
            border_color: Color {
                a: 0.5,
                ..self.0.normal.primary
            },
            border_width: 1,
            border_radius: 2,
            text_color: self.0.bright.primary,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.normal.primary)),
            text_color: self.0.bright.primary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.05,
                ..self.0.normal.primary
            })),
            text_color: Color {
                a: 0.50,
                ..self.0.bright.primary
            },
            ..self.active()
        }
    }
}

pub struct SecondaryBoxedButton(pub ColorPalette);
impl button::StyleSheet for SecondaryBoxedButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.15,
                ..self.0.normal.secondary
            })),
            text_color: self.0.bright.secondary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.normal.secondary)),
            text_color: self.0.bright.secondary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.05,
                ..self.0.normal.secondary
            })),
            text_color: Color {
                a: 0.15,
                ..self.0.bright.secondary
            },
            ..self.active()
        }
    }
}

pub struct SecondaryButton(pub ColorPalette);
impl button::StyleSheet for SecondaryButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: self.0.bright.secondary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.normal.secondary)),
            text_color: self.0.bright.secondary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.7,
                ..self.0.normal.secondary
            })),
            text_color: Color {
                a: 0.7,
                ..self.0.normal.secondary
            },
            ..self.active()
        }
    }
}

pub struct DefaultDeleteButton(pub ColorPalette);
impl button::StyleSheet for DefaultDeleteButton {
    fn active(&self) -> button::Style {
        button::Style {
            border_radius: 2,
            text_color: self.0.bright.error,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.35,
                ..self.0.normal.error
            })),
            text_color: self.0.bright.error,
            ..self.active()
        }
    }
}

pub struct ColumnHeaderButton(pub ColorPalette);
impl button::StyleSheet for ColumnHeaderButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.base.background)),
            text_color: Color {
                ..self.0.bright.surface
            },
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.15,
                ..self.0.normal.primary
            })),
            text_color: self.0.bright.primary,
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
            background: Some(Background::Color(self.0.base.background)),
            text_color: Color {
                ..self.0.bright.primary
            },
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.15,
                ..self.0.normal.primary
            })),
            text_color: self.0.bright.primary,
            ..self.active()
        }
    }
}

pub struct DisabledDefaultButton(pub ColorPalette);
impl button::StyleSheet for DisabledDefaultButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color::TRANSPARENT)),
            text_color: Color {
                a: 0.25,
                ..self.0.normal.surface
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

pub struct SelectedDefaultButton(pub ColorPalette);
impl button::StyleSheet for SelectedDefaultButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.normal.primary)),
            text_color: self.0.bright.primary,
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(self.0.normal.primary)),
            text_color: self.0.bright.primary,
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style { ..self.active() }
    }
}

pub struct Row(pub ColorPalette);
impl container::StyleSheet for Row {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.base.background)),
            ..container::Style::default()
        }
    }
}

pub struct Scrollable(pub ColorPalette);
impl scrollable::StyleSheet for Scrollable {
    fn active(&self) -> scrollable::Scrollbar {
        scrollable::Scrollbar {
            background: Some(Background::Color(self.0.base.background)),
            border_radius: 0,
            border_width: 0,
            border_color: Color::TRANSPARENT,
            scroller: scrollable::Scroller {
                color: self.0.base.foreground,
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
            background: Some(Background::Color(self.0.base.foreground)),
            border_radius: 0,
            border_width: 0,
            border_color: Color::TRANSPARENT,
            scroller: scrollable::Scroller {
                color: self.0.base.background,
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
            text_color: self.0.bright.surface,
            background: Background::Color(self.0.base.background),
            border_width: 1,
            border_color: self.0.base.background,
            selected_background: Background::Color(Color {
                a: 0.15,
                ..self.0.normal.primary
            }),
            selected_text_color: self.0.bright.primary,
        }
    }

    fn active(&self) -> pick_list::Style {
        pick_list::Style {
            text_color: self.0.bright.surface,
            background: self.0.base.background.into(),
            border_width: 1,
            border_color: self.0.base.foreground,
            border_radius: 2,
            icon_size: 0.5,
        }
    }

    fn hovered(&self) -> pick_list::Style {
        let active = self.active();
        pick_list::Style {
            text_color: self.0.bright.primary,
            ..active
        }
    }
}

pub struct SecondaryPickList(pub ColorPalette);
impl pick_list::StyleSheet for SecondaryPickList {
    fn menu(&self) -> pick_list::Menu {
        pick_list::Menu {
            text_color: self.0.bright.surface,
            background: Background::Color(self.0.base.background),
            border_width: 1,
            border_color: self.0.base.foreground,
            selected_background: Background::Color(Color {
                a: 0.15,
                ..self.0.normal.primary
            }),
            selected_text_color: self.0.bright.primary,
        }
    }

    fn active(&self) -> pick_list::Style {
        pick_list::Style {
            text_color: self.0.bright.surface,
            background: self.0.base.foreground.into(),
            border_width: 0,
            border_color: self.0.base.background,
            border_radius: 2,
            icon_size: 0.5,
        }
    }

    fn hovered(&self) -> pick_list::Style {
        let active = self.active();
        pick_list::Style {
            background: Background::Color(Color {
                a: 0.15,
                ..self.0.normal.primary
            }),
            text_color: self.0.bright.primary,
            ..active
        }
    }
}

pub struct ChannelBadge(pub ColorPalette);
impl container::StyleSheet for ChannelBadge {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(self.0.base.foreground)),
            text_color: Some(self.0.bright.primary),
            border_color: self.0.bright.primary,
            border_radius: 3,
            border_width: 1,
        }
    }
}

pub struct DefaultCheckbox(pub ColorPalette);
impl checkbox::StyleSheet for DefaultCheckbox {
    fn active(&self, _is_checked: bool) -> checkbox::Style {
        checkbox::Style {
            background: Background::Color(self.0.base.foreground),
            checkmark_color: self.0.bright.primary,
            border_radius: 3,
            border_width: 2,
            border_color: self.0.normal.primary,
        }
    }

    fn hovered(&self, _is_checked: bool) -> checkbox::Style {
        checkbox::Style {
            background: Background::Color(self.0.base.foreground),
            checkmark_color: self.0.bright.primary,
            border_radius: 3,
            border_width: 2,
            border_color: self.0.bright.primary,
        }
    }
}

pub struct AlwaysCheckedCheckbox(pub ColorPalette);
impl checkbox::StyleSheet for AlwaysCheckedCheckbox {
    fn active(&self, _is_checked: bool) -> checkbox::Style {
        checkbox::Style {
            background: Background::Color(self.0.base.foreground),
            checkmark_color: self.0.normal.primary,
            border_radius: 3,
            border_width: 2,
            border_color: self.0.normal.primary,
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
            background: Background::Color(self.0.base.foreground),
            border_radius: 0,
            border_width: 0,
            border_color: self.0.base.foreground,
        }
    }

    /// Produces the style of a focused text input.
    fn focused(&self) -> text_input::Style {
        text_input::Style {
            background: Background::Color(self.0.base.foreground),
            border_radius: 2,
            border_width: 1,
            border_color: Color {
                a: 0.5,
                ..self.0.normal.primary
            },
        }
    }

    fn placeholder_color(&self) -> Color {
        self.0.normal.surface
    }

    fn value_color(&self) -> Color {
        self.0.bright.primary
    }

    fn selection_color(&self) -> Color {
        self.0.bright.secondary
    }

    /// Produces the style of an hovered text input.
    fn hovered(&self) -> text_input::Style {
        self.focused()
    }
}
