use iced_wgpu::Renderer;

mod renderer;
mod widget;

pub use widget::header;

pub type Header<'a, Message> = widget::header::Header<'a, Message, Renderer>;
