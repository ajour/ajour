#[cfg(feature = "wgpu")]
use iced_wgpu::Renderer;

#[cfg(feature = "opengl")]
use iced_glow::Renderer;

mod renderer;
mod widget;

pub use widget::header;

pub type Header<'a, Message> = widget::header::Header<'a, Message, Renderer>;
