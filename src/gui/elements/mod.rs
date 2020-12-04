mod about;
pub use about::about_container;

mod settings;
pub use settings::settings_container;

mod addon_data;
pub use addon_data::addon_data_container;

// Default values used on multiple elements.
pub static DEFAULT_FONT_SIZE: u16 = 14;
pub static DEFAULT_PADDING: u16 = 10;
