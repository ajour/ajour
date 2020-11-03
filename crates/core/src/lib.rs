pub mod addon;
pub mod backup;
pub mod cache;
pub mod catalog;
pub mod config;
pub mod error;
pub mod fs;
pub mod murmur2;
pub mod network;
pub mod parse;
pub mod repository;
#[cfg(feature = "gui")]
pub mod theme;
pub mod utility;

use crate::error::ClientError;

pub type Result<T> = std::result::Result<T, ClientError>;
