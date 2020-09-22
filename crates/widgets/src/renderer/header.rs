use crate::widget::header;
use iced_graphics::{Backend, Primitive, Renderer};
use iced_native::mouse;
use iced_native::{Element, Layout, Point};

impl<B> header::Renderer for Renderer<B>
where
    B: Backend,
{
    fn draw<Message>(
        &mut self,
        defaults: &Self::Defaults,
        content: &[Element<'_, Message, Self>],
        layout: Layout<'_>,
        cursor_position: Point,
        resize_hovering: bool,
    ) -> Self::Output {
        let mut mouse_interaction = if resize_hovering {
            mouse::Interaction::ResizingHorizontally
        } else {
            mouse::Interaction::default()
        };

        (
            Primitive::Group {
                primitives: content
                    .iter()
                    .zip(layout.children())
                    .map(|(child, layout)| {
                        let (primitive, new_mouse_interaction) =
                            child.draw(self, defaults, layout, cursor_position);

                        if new_mouse_interaction > mouse_interaction {
                            mouse_interaction = new_mouse_interaction;
                        }

                        primitive
                    })
                    .collect(),
            },
            mouse_interaction,
        )
    }
}
