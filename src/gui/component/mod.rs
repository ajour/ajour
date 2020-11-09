pub mod settings;

// Default values used on multiple elements.
pub const DEFAULT_FONT_SIZE: u16 = 14;
pub const DEFAULT_PADDING: u16 = 10;

// Helper so we don't need to alway type out the full nested message on our element,
/// since we always need to return a gui::Message at the end.
trait NestedMessage {
    fn root(message: Self) -> super::Message;
}
