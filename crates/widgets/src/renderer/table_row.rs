use crate::style::table_row::StyleSheet;

use crate::widget::table_row;
use iced_graphics::{Backend, Primitive, Renderer};
use iced_native::{mouse, Background, Color, Element, Layout, Point, Rectangle};

impl<B> table_row::Renderer for Renderer<B>
where
    B: Backend,
{
    type Style = Box<dyn StyleSheet>;

    fn draw<Message>(
        &mut self,
        defaults: &Self::Defaults,
        layout: Layout<'_>,
        cursor_position: Point,
        style_sheet: &Self::Style,
        content: &Element<'_, Message, Self>,
        viewport: &Rectangle,
        custom_bounds: &Rectangle,
    ) -> Self::Output {
        let bounds = layout.bounds();
        let is_mouse_over = custom_bounds.contains(cursor_position);
        let content_layout = layout.children().next().unwrap();

        let style = if is_mouse_over {
            style_sheet.hovered()
        } else {
            style_sheet.style()
        };

        let (content, mouse_interaction) =
            content.draw(self, defaults, content_layout, cursor_position, viewport);

        (
            if style.background.is_some() {
                let background = Primitive::Quad {
                    bounds: Rectangle {
                        x: bounds.x + style.offset_left,
                        y: bounds.y,
                        width: bounds.width - style.offset_right,
                        height: custom_bounds.height,
                    },
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
            if is_mouse_over {
                mouse::Interaction::Pointer
            } else {
                mouse_interaction
            },
        )
    }
}
