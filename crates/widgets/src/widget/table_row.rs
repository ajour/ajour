#![allow(clippy::type_complexity)]

pub use crate::style::table_row::{Style, StyleSheet};
use iced_native::{
    layout, overlay, Align, Clipboard, Element, Event, Hasher, Layout, Length, Point, Rectangle,
    Widget,
};

use std::hash::Hash;

#[allow(missing_debug_implementations)]
pub struct TableRow<'a, Message, Renderer: self::Renderer> {
    padding: u16,
    width: Length,
    height: Length,
    max_width: u32,
    max_height: u32,
    horizontal_alignment: Align,
    vertical_alignment: Align,
    style: Renderer::Style,
    content: Element<'a, Message, Renderer>,
}

impl<'a, Message, Renderer> TableRow<'a, Message, Renderer>
where
    Renderer: 'a + self::Renderer,
    Message: 'a,
{
    /// Creates an empty [`TableRow`].
    pub fn new<T>(content: T) -> Self
    where
        T: Into<Element<'a, Message, Renderer>>,
    {
        TableRow {
            padding: 1,
            width: Length::Shrink,
            height: Length::Shrink,
            max_width: u32::MAX,
            max_height: u32::MAX,
            horizontal_alignment: Align::Start,
            vertical_alignment: Align::Start,
            style: Renderer::Style::default(),
            content: content.into(),
        }
    }
    pub fn style(mut self, style: impl Into<<Renderer as self::Renderer>::Style>) -> Self {
        self.style = style.into();
        self
    }

    /// Sets the width of the [`TableRow`].
    pub fn width(mut self, width: Length) -> Self {
        self.width = width;
        self
    }

    /// Sets the height of the [`TableRow`].
    pub fn height(mut self, height: Length) -> Self {
        self.height = height;
        self
    }

    /// Sets the maximum width of the [`TableRow`].
    pub fn max_width(mut self, max_width: u32) -> Self {
        self.max_width = max_width;
        self
    }

    /// Sets the maximum height of the [`TableRow`] in pixels.
    pub fn max_height(mut self, max_height: u32) -> Self {
        self.max_height = max_height;
        self
    }

    /// Sets the content alignment for the horizontal axis of the [`TableRow`].
    pub fn align_x(mut self, alignment: Align) -> Self {
        self.horizontal_alignment = alignment;
        self
    }

    /// Sets the content alignment for the vertical axis of the [`TableRow`].
    pub fn align_y(mut self, alignment: Align) -> Self {
        self.vertical_alignment = alignment;
        self
    }

    /// Centers the contents in the horizontal axis of the [`TableRow`].
    pub fn center_x(mut self) -> Self {
        self.horizontal_alignment = Align::Center;
        self
    }

    /// Centers the contents in the vertical axis of the [`TableRow`].
    pub fn center_y(mut self) -> Self {
        self.vertical_alignment = Align::Center;
        self
    }
}

impl<'a, Message, Renderer> Widget<Message, Renderer> for TableRow<'a, Message, Renderer>
where
    Renderer: 'a + self::Renderer,
    Message: 'a,
{
    fn draw(
        &self,
        renderer: &mut Renderer,
        defaults: &Renderer::Defaults,
        layout: Layout<'_>,
        cursor_position: Point,
    ) -> Renderer::Output {
        self::Renderer::draw(
            renderer,
            defaults,
            layout.bounds(),
            cursor_position,
            &self.style,
            &self.content,
            layout.children().next().unwrap(),
        )
    }

    fn hash_layout(&self, state: &mut Hasher) {
        struct Marker;
        std::any::TypeId::of::<Marker>().hash(state);

        self.padding.hash(state);
        self.width.hash(state);
        self.height.hash(state);
        self.max_width.hash(state);
        self.max_height.hash(state);

        self.content.hash_layout(state);
    }

    fn overlay(&mut self, layout: Layout<'_>) -> Option<overlay::Element<'_, Message, Renderer>> {
        self.content.overlay(layout.children().next().unwrap())
    }

    fn width(&self) -> Length {
        self.width
    }

    fn height(&self) -> Length {
        self.height
    }

    fn layout(&self, renderer: &Renderer, limits: &layout::Limits) -> layout::Node {
        let padding = f32::from(self.padding);

        let limits = limits
            .loose()
            .max_width(self.max_width)
            .max_height(self.max_height)
            .width(self.width)
            .height(self.height)
            .pad(padding);

        let mut content = self.content.layout(renderer, &limits.loose());
        let size = limits.resolve(content.size());

        content.move_to(Point::new(padding, padding));
        content.align(self.horizontal_alignment, self.vertical_alignment, size);

        layout::Node::with_children(size.pad(padding), vec![content])
    }

    fn on_event(
        &mut self,
        event: Event,
        layout: Layout<'_>,
        cursor_position: Point,
        messages: &mut Vec<Message>,
        renderer: &Renderer,
        clipboard: Option<&dyn Clipboard>,
    ) {
        self.content.on_event(
            event,
            layout.children().next().unwrap(),
            cursor_position,
            messages,
            renderer,
            clipboard,
        );
    }
}

pub trait Renderer: iced_native::Renderer {
    type Style: Default;

    fn draw<Message>(
        &mut self,
        defaults: &Self::Defaults,
        bounds: Rectangle,
        cursor_position: Point,
        style: &Self::Style,
        content: &Element<'_, Message, Self>,
        content_layout: Layout<'_>,
    ) -> Self::Output;
}

impl<'a, Message, Renderer> From<TableRow<'a, Message, Renderer>> for Element<'a, Message, Renderer>
where
    Renderer: 'a + self::Renderer,
    Message: 'a,
{
    fn from(table_row: TableRow<'a, Message, Renderer>) -> Element<'a, Message, Renderer> {
        Element::new(table_row)
    }
}
