#![allow(clippy::type_complexity)]
#![allow(clippy::too_many_arguments)]

use iced_native::{
    container, layout, mouse, space, Align, Clipboard, Container, Element, Event, Hasher, Layout,
    Length, Point, Space, Widget,
};
use std::hash::Hash;

mod state;
use state::Inner;
pub use state::State;

pub struct Header<'a, Message, Renderer>
where
    Renderer: self::Renderer,
{
    spacing: u16,
    width: Length,
    height: Length,
    state: &'a mut Inner,
    leeway: u16,
    on_resize: Option<(u16, Box<dyn Fn(ResizeEvent) -> Message + 'a>)>,
    children: Vec<Element<'a, Message, Renderer>>,
    left_margin: bool,
    right_margin: bool,
    names: Vec<&'static str>,
}

impl<'a, Message, Renderer> Header<'a, Message, Renderer>
where
    Renderer: 'a + self::Renderer + container::Renderer + space::Renderer,
    Message: 'a,
{
    pub fn new(
        state: &'a mut State,
        headers: Vec<(&'static str, Container<'a, Message, Renderer>)>,
        left_margin: Option<Length>,
        right_margin: Option<Length>,
    ) -> Self {
        let state = &mut state.inner;

        let mut names = vec![];
        let mut left = false;
        let mut right = false;

        let mut children = vec![];

        if let Some(margin) = left_margin {
            children.push(Space::new(margin, Length::Units(0)).into());
            left = true;
        }

        for (key, container) in headers {
            names.push(key);

            children.push(container.into());
        }

        if let Some(margin) = right_margin {
            children.push(Space::new(margin, Length::Units(0)).into());
            right = true;
        }

        Self {
            spacing: 0,
            width: Length::Fill,
            height: Length::Fill,
            leeway: 0,
            state,
            on_resize: None,
            children,
            left_margin: left,
            right_margin: right,
            names,
        }
    }

    pub fn spacing(mut self, units: u16) -> Self {
        self.spacing = units;
        self
    }

    pub fn width(mut self, width: Length) -> Self {
        self.width = width;
        self
    }

    pub fn height(mut self, height: Length) -> Self {
        self.height = height;
        self
    }

    pub fn on_resize<F>(mut self, leeway: u16, f: F) -> Self
    where
        F: 'a + Fn(ResizeEvent) -> Message,
    {
        self.leeway = leeway;
        self.on_resize = Some((leeway, Box::new(f)));
        self
    }

    fn trigger_resize(
        &mut self,
        left_name: &'static str,
        left_width: u16,
        right_name: &'static str,
        right_width: u16,
        messages: &mut Vec<Message>,
    ) {
        if let Some((_, on_resize)) = &self.on_resize {
            messages.push(on_resize(ResizeEvent {
                left_name,
                left_width,
                right_name,
                right_width,
            }));
        }
    }
}

impl<'a, Message, Renderer> Widget<Message, Renderer> for Header<'a, Message, Renderer>
where
    Renderer: 'a + self::Renderer + container::Renderer + space::Renderer,
    Message: 'a,
{
    fn width(&self) -> Length {
        self.width
    }

    fn height(&self) -> Length {
        self.height
    }

    fn layout(&self, renderer: &Renderer, limits: &layout::Limits) -> layout::Node {
        let limits = limits.width(self.width).height(self.height);

        layout::flex::resolve(
            layout::flex::Axis::Horizontal,
            renderer,
            &limits,
            0.0,
            self.spacing as f32,
            Align::Start,
            &self.children,
        )
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
        let child_len = self.children.len();
        let start_offset = if self.left_margin { 1 } else { 0 };
        let end_offset = if self.right_margin { 1 } else { 0 };

        let dividers = self
            .children
            .iter()
            .enumerate()
            .zip(layout.children())
            .filter_map(|((idx, _), layout)| {
                if idx >= (start_offset) && idx < (child_len - 1 - end_offset) {
                    Some((idx, layout.position().x + layout.bounds().width))
                } else {
                    None
                }
            })
            .collect::<Vec<_>>();

        if self.on_resize.is_some() {
            if !self.state.resizing {
                self.state.resize_hovering = false;
            }

            for (idx, divider) in dividers.iter() {
                if cursor_position.x > (divider - self.leeway as f32)
                    && cursor_position.x < (divider + self.leeway as f32)
                {
                    if !self.state.resize_hovering {
                        self.state.resizing_idx = *idx;
                    }

                    self.state.resize_hovering = true;
                }
            }
        }

        match event {
            Event::Mouse(mouse::Event::ButtonPressed(mouse::Button::Left)) => {
                if self.state.resize_hovering {
                    self.state.resizing = true;
                    self.state.starting_cursor_pos = Some(cursor_position);
                    self.state.starting_left_width = layout
                        .children()
                        .nth(self.state.resizing_idx)
                        .unwrap()
                        .bounds()
                        .width;
                    self.state.starting_right_width = layout
                        .children()
                        .nth(self.state.resizing_idx + 1)
                        .unwrap()
                        .bounds()
                        .width;
                    return;
                }
            }
            Event::Mouse(mouse::Event::ButtonReleased(mouse::Button::Left)) => {
                if self.state.resizing {
                    self.state.resizing = false;
                    self.state.starting_cursor_pos.take();
                    return;
                }
            }
            Event::Mouse(mouse::Event::CursorMoved { x, .. }) => {
                if self.state.resizing {
                    let delta = x - self.state.starting_cursor_pos.unwrap().x;

                    let left_width = self.state.starting_left_width;
                    let right_width = self.state.starting_right_width;

                    let max_width = left_width + right_width - 30.0;

                    let left_width = (left_width + delta).max(30.0).min(max_width) as u16;
                    let left_name = self.names[self.state.resizing_idx - start_offset];
                    let right_width = (right_width - delta).max(30.0).min(max_width) as u16;
                    let right_name = self.names[self.state.resizing_idx + 1 - start_offset];

                    self.trigger_resize(left_name, left_width, right_name, right_width, messages);
                    return;
                }
            }
            _ => {}
        }

        self.children
            .iter_mut()
            .zip(layout.children())
            .for_each(|(child, layout)| {
                child.on_event(
                    event.clone(),
                    layout,
                    cursor_position,
                    messages,
                    renderer,
                    clipboard,
                );
            });
    }

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
            &self.children,
            layout,
            cursor_position,
            self.state.resize_hovering,
        )
    }

    fn hash_layout(&self, state: &mut Hasher) {
        struct Marker;
        std::any::TypeId::of::<Marker>().hash(state);

        self.width.hash(state);
        self.height.hash(state);
        self.spacing.hash(state);

        for child in &self.children {
            child.hash_layout(state);
        }
    }
}

pub trait Renderer: iced_native::Renderer + container::Renderer + space::Renderer + Sized {
    /// Draws a [`Row`].
    ///
    /// It receives:
    /// - the children of the [`Row`]
    /// - the [`Layout`] of the [`Row`] and its children
    /// - the cursor position
    ///
    /// [`Row`]: struct.Row.html
    /// [`Layout`]: ../layout/struct.Layout.html
    fn draw<Message>(
        &mut self,
        defaults: &Self::Defaults,
        children: &[Element<'_, Message, Self>],
        layout: Layout<'_>,
        cursor_position: Point,
        resize_hovering: bool,
    ) -> Self::Output;
}

#[derive(Debug, Clone, Copy)]
pub struct ResizeEvent {
    pub left_name: &'static str,
    pub left_width: u16,
    pub right_name: &'static str,
    pub right_width: u16,
}

impl<'a, Message, Renderer> From<Header<'a, Message, Renderer>> for Element<'a, Message, Renderer>
where
    Renderer: 'a + self::Renderer,
    Message: 'a,
{
    fn from(header: Header<'a, Message, Renderer>) -> Element<'a, Message, Renderer> {
        Element::new(header)
    }
}
