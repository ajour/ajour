use iced::{button, container, scrollable, Background, Color};

enum ColorPalette {
    Primary,
    Secondary,
    Error,
    Surface,
    OnSurface,
    Background,
}

impl ColorPalette {
    fn rgb(&self) -> Color {
        match self {
            ColorPalette::Primary => Color::from_rgb(0.73, 0.52, 0.99),
            ColorPalette::Secondary => Color::from_rgb(0.88, 0.74, 0.28),
            ColorPalette::Surface => Color::from_rgb(0.12, 0.12, 0.12),
            ColorPalette::OnSurface => Color::from_rgb(0.88, 0.88, 0.88),
            ColorPalette::Background => Color::from_rgb(0.07, 0.07, 0.07),
            ColorPalette::Error => Color::from_rgb(0.76, 0.19, 0.28),
        }
    }
}

pub struct DefaultButton;
impl button::StyleSheet for DefaultButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: ColorPalette::Primary.rgb(),
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..ColorPalette::Primary.rgb()
            })),
            text_color: ColorPalette::Primary.rgb(),
            ..self.active()
        }
    }
}

pub struct DefaultBoxedButton;
impl button::StyleSheet for DefaultBoxedButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.03,
                ..ColorPalette::Primary.rgb()
            })),
            text_color: ColorPalette::Primary.rgb(),
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..ColorPalette::Primary.rgb()
            })),
            text_color: ColorPalette::Primary.rgb(),
            ..self.active()
        }
    }
}

pub struct SecondaryButton;
impl button::StyleSheet for SecondaryButton {
    fn active(&self) -> button::Style {
        button::Style {
            text_color: ColorPalette::Secondary.rgb(),
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..ColorPalette::Secondary.rgb()
            })),
            text_color: ColorPalette::Secondary.rgb(),
            ..self.active()
        }
    }

    fn disabled(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(ColorPalette::Secondary.rgb())),
            text_color: ColorPalette::Secondary.rgb(),
            ..self.active()
        }
    }
}

pub struct DeleteBoxedButton;
impl button::StyleSheet for DeleteBoxedButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.03,
                ..ColorPalette::Error.rgb()
            })),
            text_color: ColorPalette::Error.rgb(),
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(Color {
                a: 0.1,
                ..ColorPalette::Error.rgb()
            })),
            text_color: ColorPalette::Error.rgb(),
            ..self.active()
        }
    }
}

pub struct Content;
impl container::StyleSheet for Content {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(ColorPalette::Background.rgb())),
            ..container::Style::default()
        }
    }
}

pub struct AddonRowTextContainer;
impl container::StyleSheet for AddonRowTextContainer {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(ColorPalette::Surface.rgb())),
            text_color: Some(ColorPalette::OnSurface.rgb()),
            ..container::Style::default()
        }
    }
}

pub struct StatusTextContainer;
impl container::StyleSheet for StatusTextContainer {
    fn style(&self) -> container::Style {
        container::Style {
            text_color: Some(Color {
                a: 0.4,
                ..ColorPalette::OnSurface.rgb()
            }),
            ..container::Style::default()
        }
    }
}

pub struct Row;
impl container::StyleSheet for Row {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(ColorPalette::Background.rgb())),
            ..container::Style::default()
        }
    }
}

pub struct Scrollable;
impl scrollable::StyleSheet for Scrollable {
    fn active(&self) -> scrollable::Scrollbar {
        scrollable::Scrollbar {
            background: Some(Background::Color(ColorPalette::Background.rgb())),
            border_radius: 0,
            border_width: 0,
            border_color: Color::TRANSPARENT,
            scroller: scrollable::Scroller {
                color: ColorPalette::Surface.rgb(),
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
