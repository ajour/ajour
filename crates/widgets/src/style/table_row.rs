//! Decorate content and apply alignment.
use iced_core::{Background, Color};

/// The appearance of a table row.
#[derive(Debug, Clone, Copy)]
pub struct Style {
    pub text_color: Option<Color>,
    pub background: Option<Background>,
    pub border_radius: f32,
    pub border_width: f32,
    pub border_color: Color,
    pub offset_left: f32,
    pub offset_right: f32,
}

/// A set of rules that dictate the style of a table row.
pub trait StyleSheet {
    fn style(&self) -> Style;

    /// Produces the style of a hovered table row.
    fn hovered(&self) -> Style;
}

struct Default;

impl StyleSheet for Default {
    fn style(&self) -> Style {
        Style {
            text_color: None,
            background: None,
            border_radius: 0.0,
            border_width: 0.0,
            border_color: Color::TRANSPARENT,
            offset_right: 0.0,
            offset_left: 0.0,
        }
    }

    fn hovered(&self) -> Style {
        Style {
            background: Some(Background::Color(Color::from_rgb(0.90, 0.90, 0.90))),
            ..self.style()
        }
    }
}

impl std::default::Default for Box<dyn StyleSheet> {
    fn default() -> Self {
        Box::new(Default)
    }
}

impl<T> From<T> for Box<dyn StyleSheet>
where
    T: 'static + StyleSheet,
{
    fn from(style: T) -> Self {
        Box::new(style)
    }
}
