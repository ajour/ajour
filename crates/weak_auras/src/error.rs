#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("Failed to parse WeakAuras: {0}")]
    ParseWeakAuras(#[source] anyhow::Error),
    #[error("Failed to parse Plater Nameplates: {0}")]
    ParsePlater(#[source] anyhow::Error),
    #[error("No UID for Aura {slug}")]
    MissingUid { slug: String },
    #[error(transparent)]
    IO(#[from] std::io::Error),
    #[error(transparent)]
    Format(#[from] std::fmt::Error),
    #[error("{0}")]
    Mlua(String),
    #[error(transparent)]
    SerdeJson(#[from] serde_json::Error),
    #[error(transparent)]
    Download(#[from] ajour_core::error::DownloadError),
}

impl From<mlua::Error> for Error {
    fn from(error: mlua::Error) -> Self {
        Error::Mlua(error.to_string())
    }
}
