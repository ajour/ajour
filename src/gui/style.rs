use iced::{button, container, Background, Color};

enum ColorPalette {
    Primary,
    OnPrimary,
    Surface,
    OnSurface,
    Background,
}

impl ColorPalette {
    fn rgb(&self) -> Color {
        match self {
            ColorPalette::Primary => return Color::from_rgb(0.22, 0.17, 0.28),
            ColorPalette::OnPrimary => return Color::from_rgb(0.73, 0.52, 0.99),
            ColorPalette::Surface => return Color::from_rgb(0.12, 0.12, 0.12),
            ColorPalette::OnSurface => return Color::from_rgb(0.88, 0.88, 0.88),
            ColorPalette::Background => return Color::from_rgb(0.07, 0.07, 0.07),
        }
    }
}

pub struct DefaultButton;
impl button::StyleSheet for DefaultButton {
    fn active(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(ColorPalette::Primary.rgb())),
            text_color: ColorPalette::OnPrimary.rgb(),
            border_radius: 2,
            ..button::Style::default()
        }
    }

    fn hovered(&self) -> button::Style {
        button::Style {
            background: Some(Background::Color(ColorPalette::OnPrimary.rgb())),
            text_color: ColorPalette::Primary.rgb(),
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

pub struct Cell;
impl container::StyleSheet for Cell {
    fn style(&self) -> container::Style {
        container::Style {
            background: Some(Background::Color(ColorPalette::Surface.rgb())),
            text_color: Some(ColorPalette::OnSurface.rgb()),
            ..container::Style::default()
        }
    }
}
