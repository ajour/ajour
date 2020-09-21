use iced_wgpu::Renderer;

mod renderer;
mod widget;

pub use widget::table_header;

pub type Header<'a, Message> = widget::Header<'a, Message, Renderer>;
