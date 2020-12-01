#[cfg(feature = "wgpu")]
use iced_wgpu::Renderer;

#[cfg(feature = "opengl")]
use iced_glow::Renderer;

mod renderer;
mod widget;
mod style;

pub use widget::header;
pub use widget::table_row;

pub type Header<'a, Message> = widget::header::Header<'a, Message, Renderer>;
pub type TableRow<'a, Message> = widget::table_row::TableRow<'a, Message, Renderer>;
