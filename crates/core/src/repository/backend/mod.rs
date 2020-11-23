use super::RepositoryMetadata;
use crate::error::RepositoryError;

use async_trait::async_trait;
use dyn_clone::{clone_trait_object, DynClone};

pub mod curse;
mod git;
pub mod tukui;
pub mod wowi;

pub use curse::Curse;
pub use git::{Github, Gitlab};
pub use tukui::Tukui;
pub use wowi::WowI;

#[async_trait]
pub(crate) trait Backend: DynClone + Send + Sync {
    async fn get_metadata(&self) -> Result<RepositoryMetadata, RepositoryError>;

    async fn get_changelog(
        &self,
        file_id: Option<i64>,
        tag_name: Option<String>,
    ) -> Result<(String, String), RepositoryError>;
}

clone_trait_object!(Backend);
