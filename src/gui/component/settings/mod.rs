use {
    super::NestedMessage,
    crate::gui::{self, CatalogColumnKey, ColumnKey},
};

mod update;
mod view;

pub use update::update;
pub use view::view;

#[derive(Debug, Clone)]
pub enum Message {
    Interaction(Interaction),
}

#[derive(Debug, Clone)]
pub enum Interaction {
    ThemeSelected(String),
    ScaleUp,
    ScaleDown,
    Backup,
    ToggleColumn(bool, ColumnKey),
    ToggleCatalogColumn(bool, CatalogColumnKey),
    MoveColumnLeft(ColumnKey),
    MoveColumnRight(ColumnKey),
    MoveCatalogColumnLeft(CatalogColumnKey),
    MoveCatalogColumnRight(CatalogColumnKey),
}

impl NestedMessage for Message {
    fn root(message: Self) -> gui::Message {
        gui::Message::Component(gui::Component::Settings(message))
    }
}
