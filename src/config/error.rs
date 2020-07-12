use std::fmt::{self, Display, Formatter};
use std::io;

/// Errors occurring during config loading.
///
/// Based on https://serde.rs/error-handling.html
#[derive(Debug)]
pub enum Error {
    /// Config file not found.
    NotFound,

    /// io error reading file.
    Io(io::Error),

    /// Not valid yaml or missing parameters.
    Yaml(serde_yaml::Error),
}

impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Error::NotFound => None,
            Error::Io(err) => err.source(),
            Error::Yaml(err) => err.source(),
        }
    }
}

impl Display for Error {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Error::NotFound => write!(f, "Couldn't locate config file"),
            Error::Io(err) => write!(f, "Error reading config file: {}", err),
            Error::Yaml(err) => write!(f, "Problem with config: {}", err),
        }
    }
}

impl From<io::Error> for Error {
    fn from(val: io::Error) -> Self {
        if val.kind() == io::ErrorKind::NotFound {
            Error::NotFound
        } else {
            Error::Io(val)
        }
    }
}

impl From<serde_yaml::Error> for Error {
    fn from(val: serde_yaml::Error) -> Self {
        Error::Yaml(val)
    }
}
