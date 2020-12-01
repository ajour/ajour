use crate::widget::table_row;
use crate::style::table_row::{StyleSheet};
use iced_graphics::{Backend, Primitive, Renderer};
use iced_native::{Background, Element, Layout, Point, Color, Rectangle};


impl<B> table_row::Renderer for Renderer<B>
    where
        B: Backend
{
    type Style = Box<dyn StyleSheet>;

    fn draw<Message>(
        &mut self,
        defaults: &Self::Defaults,
        bounds: Rectangle,
        cursor_position: Point,
        style_sheet: &Self::Style,
        content: &Element<'_, Message, Self>,
        content_layout: Layout<'_>,
        is_mouse_over: bool,
    ) -> Self::Output {

        let style = if is_mouse_over {
            style_sheet.hovered()
        } else {
            style_sheet.style()
        };

        let (content, mouse_interaction) = content.draw(
            self,
            &defaults,
            content_layout,
            cursor_position
        );

        (
            if style.background.is_some() || style.border_width > 0 {
                let background = Primitive::Quad {
                    bounds,
                    background: style
                        .background
                        .unwrap_or(Background::Color(Color::TRANSPARENT)),
                    border_radius: style.border_radius,
                    border_width: style.border_width,
                    border_color: style.border_color,
                };

                    Primitive::Group {
                        primitives: vec![background, content],
                    }

            } else {
                content
            },
            mouse_interaction,
        )
    }
}
