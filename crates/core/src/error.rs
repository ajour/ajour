use thiserror::*;

// Used by macro
#[doc(hidden)]
pub use anyhow;

#[derive(Error, Debug)]
pub enum Error {
    #[error("{0}")]
    Other(#[from] anyhow::Error),
}

#[macro_export]
macro_rules! error {
    ($($arg:tt)*) => {{
        let err = $crate::error::anyhow::anyhow!($($arg)*);
        $crate::error::Error::Other(err)
    }}
}
#[macro_export]
macro_rules! bail {
    ($($arg:tt)*) => {{
        return Err($crate::error!($($arg)*))
    }}
}

impl From<std::io::Error> for Error {
    fn from(error: std::io::Error) -> Self {
        Self::Other(error.into())
    }
}

impl From<serde_yaml::Error> for Error {
    fn from(error: serde_yaml::Error) -> Self {
        Self::Other(error.into())
    }
}

impl From<serde_json::Error> for Error {
    fn from(error: serde_json::Error) -> Self {
        Self::Other(error.into())
    }
}

impl From<isahc::Error> for Error {
    fn from(error: isahc::Error) -> Self {
        Self::Other(error.into())
    }
}

impl From<isahc::http::Error> for Error {
    fn from(error: isahc::http::Error) -> Self {
        Self::Other(error.into())
    }
}

impl From<zip::result::ZipError> for Error {
    fn from(error: zip::result::ZipError) -> Self {
        Self::Other(error.into())
    }
}

impl From<fern::InitError> for Error {
    fn from(error: fern::InitError) -> Self {
        Self::Other(error.into())
    }
}

impl From<log::SetLoggerError> for Error {
    fn from(error: log::SetLoggerError) -> Self {
        Self::Other(error.into())
    }
}

impl From<glob::PatternError> for Error {
    fn from(error: glob::PatternError) -> Self {
        Self::Other(error.into())
    }
}

impl From<glob::GlobError> for Error {
    fn from(error: glob::GlobError) -> Self {
        Self::Other(error.into())
    }
}

impl From<fancy_regex::Error> for Error {
    fn from(error: fancy_regex::Error) -> Self {
        Self::Other(error.into())
    }
}

impl From<std::path::StripPrefixError> for Error {
    fn from(error: std::path::StripPrefixError) -> Self {
        Self::Other(error.into())
    }
}
