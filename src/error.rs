use std::fmt;

#[derive(Debug)]
pub enum ClientError {
    Custom(String),
    IoError(std::io::Error),
    WalkDir(walkdir::Error),
}

impl fmt::Display for ClientError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::IoError(x) => write!(f, "{}", x),
            Self::WalkDir(x) => write!(f, "{}", x),
            Self::Custom(x) => write!(f, "{}", x),
        }
    }
}

impl From<std::io::Error> for ClientError {
    fn from(error: std::io::Error) -> Self {
        Self::IoError(error)
    }
}

impl From<walkdir::Error> for ClientError {
    fn from(error: walkdir::Error) -> Self {
        Self::WalkDir(error)
    }
}
