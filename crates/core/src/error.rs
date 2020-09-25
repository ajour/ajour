use std::{fmt, path::PathBuf};

#[derive(Debug)]
pub enum ClientError {
    Custom(String),
    IoError(std::io::Error),
    YamlError(serde_yaml::Error),
    JsonError(serde_json::Error),
    HttpError(isahc::http::Error),
    NetworkError(isahc::Error),
    ZipError(zip::result::ZipError),
    LoadFileDoesntExist(PathBuf),
    LogError(String),
    FingerprintError(String),
}

impl ClientError {
    pub fn fingerprint(e: impl fmt::Display) -> ClientError {
        ClientError::FingerprintError(format!("{}", e))
    }
}

impl fmt::Display for ClientError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::IoError(x) => write!(f, "{}", x),
            Self::Custom(x) => write!(f, "{}", x),
            Self::YamlError(x) => write!(f, "{}", x),
            Self::JsonError(x) => write!(f, "{}", x),
            Self::NetworkError(_) => write!(
                f,
                "A network error occurred. Please check your internet connection and try again."
            ),
            Self::HttpError(x) => write!(f, "{}", x),
            Self::ZipError(x) => write!(f, "{}", x),
            Self::LoadFileDoesntExist(x) => write!(f, "file doesn't exist: {:?}", x),
            Self::LogError(x) => write!(f, "{}", x),
            Self::FingerprintError(x) => write!(f, "{}", x),
        }
    }
}

impl From<std::io::Error> for ClientError {
    fn from(error: std::io::Error) -> Self {
        Self::IoError(error)
    }
}

impl From<serde_yaml::Error> for ClientError {
    fn from(val: serde_yaml::Error) -> Self {
        Self::YamlError(val)
    }
}

impl From<serde_json::Error> for ClientError {
    fn from(val: serde_json::Error) -> Self {
        Self::JsonError(val)
    }
}

impl From<isahc::Error> for ClientError {
    fn from(error: isahc::Error) -> Self {
        Self::NetworkError(error)
    }
}

impl From<isahc::http::Error> for ClientError {
    fn from(error: isahc::http::Error) -> Self {
        Self::HttpError(error)
    }
}

impl From<zip::result::ZipError> for ClientError {
    fn from(error: zip::result::ZipError) -> Self {
        Self::ZipError(error)
    }
}

impl From<fern::InitError> for ClientError {
    fn from(error: fern::InitError) -> Self {
        Self::LogError(format!("{:?}", error))
    }
}

impl From<log::SetLoggerError> for ClientError {
    fn from(error: log::SetLoggerError) -> Self {
        Self::LogError(format!("{:?}", error))
    }
}
