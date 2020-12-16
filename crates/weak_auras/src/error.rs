#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("No UID for Aura {slug}")]
    MissingUid { slug: String },
    #[error(transparent)]
    IO(#[from] std::io::Error),
    #[error(transparent)]
    Format(#[from] std::fmt::Error),
    #[error(transparent)]
    Mlua(#[from] mlua::Error),
    #[error(transparent)]
    SerdeJson(#[from] serde_json::Error),
    #[error(transparent)]
    Download(#[from] ajour_core::error::DownloadError),
}
