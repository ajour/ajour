use crate::config::Flavor;
use crate::error;
use crate::Result;

use chrono::{DateTime, Utc};
use isahc::http::uri::Uri;
use serde::{Deserialize, Serialize};

use std::cmp::Ordering;
use std::collections::HashMap;

mod backend;
use backend::Backend;

pub(crate) use backend::{curse, tukui, wowi};
use backend::{Curse, Github, Gitlab, Tukui, WowI};

#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Ord, Eq, Serialize, Deserialize)]
pub enum RepositoryKind {
    Curse,
    Tukui,
    WowI,
    Git(GitKind),
}

impl std::fmt::Display for RepositoryKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                RepositoryKind::WowI => "WoWInterface",
                RepositoryKind::Tukui => "Tukui",
                RepositoryKind::Curse => "CurseForge",
                RepositoryKind::Git(git) => match git {
                    GitKind::Github => "GitHub",
                    GitKind::Gitlab => "GitLab",
                },
            }
        )
    }
}

impl RepositoryKind {
    pub fn is_git(self) -> bool {
        matches!(self, RepositoryKind::Git(_))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Ord, Eq, Serialize, Deserialize)]
pub enum GitKind {
    Github,
    Gitlab,
}

#[derive(Clone)]
pub struct RepositoryPackage {
    backend: Box<dyn Backend>,
    pub id: String,
    pub kind: RepositoryKind,
    pub metadata: RepositoryMetadata,
}

impl std::fmt::Debug for RepositoryPackage {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "RepositoryPackage {{ kind: {:?}, id: {}, metadata: {:?} }}",
            self.kind, self.id, self.metadata
        )
    }
}

impl RepositoryPackage {
    pub fn from_source_url(flavor: Flavor, url: Uri) -> Result<Self> {
        let host = url
            .host()
            .ok_or_else(|| error!("no host for url: {:?}", url))?;

        let (backend, kind): (Box<dyn Backend>, _) = match host {
            "github.com" => (
                Box::new(Github {
                    url: url.clone(),
                    flavor,
                }),
                RepositoryKind::Git(GitKind::Github),
            ),
            "gitlab.com" => (
                Box::new(Gitlab {
                    url: url.clone(),
                    flavor,
                }),
                RepositoryKind::Git(GitKind::Gitlab),
            ),
            _ => {
                return Err(error!(
                    "Invalid host, only GitHub and GitLab are supported: {}",
                    host
                ))
            }
        };

        Ok(RepositoryPackage {
            backend,
            id: url.to_string(),
            kind,
            metadata: Default::default(),
        })
    }

    pub fn from_repo_id(flavor: Flavor, kind: RepositoryKind, id: String) -> Result<Self> {
        let backend: Box<dyn Backend> = match kind {
            RepositoryKind::Curse => Box::new(Curse {
                id: id.clone(),
                flavor,
            }),
            RepositoryKind::WowI => Box::new(WowI {
                id: id.clone(),
                flavor,
            }),
            RepositoryKind::Tukui => Box::new(Tukui {
                id: id.clone(),
                flavor,
            }),
            RepositoryKind::Git(_) => {
                return Err(error!("Git repo must be created with `from_source_url`"))
            }
        };

        Ok(RepositoryPackage {
            backend,
            id,
            kind,
            metadata: Default::default(),
        })
    }

    pub fn with_metadata(mut self, metadata: RepositoryMetadata) -> Self {
        self.metadata = metadata;

        self
    }

    pub async fn resolve_metadata(&mut self) -> Result<()> {
        let metadata = self.backend.get_metadata().await?;

        self.metadata = metadata;

        Ok(())
    }

    /// Get changelog from the repository
    ///
    /// `channel` and `is_remote` are only used for the Curse repository since
    /// we can get unique changelogs for each version
    pub async fn get_changelog(
        &self,
        channel: ReleaseChannel,
        is_remote: bool,
    ) -> Result<(String, String)> {
        let file_id = if self.kind == RepositoryKind::Curse {
            if is_remote {
                self.metadata
                    .remote_packages
                    .get(&channel)
                    .map(|p| p.file_id)
                    .flatten()
            } else {
                self.metadata.file_id
            }
        } else {
            None
        };

        let tag_name = if self.kind.is_git() {
            let remote_package = self
                .metadata
                .remote_packages
                .get(&channel)
                .ok_or_else(|| error!("No remote package for channel {:?}", channel))?;

            Some(remote_package.version.clone())
        } else {
            None
        };

        self.backend.get_changelog(file_id, tag_name).await
    }
}

/// Metadata from one of the repository APIs
#[derive(Default, Debug, Clone)]
pub struct RepositoryMetadata {
    // If these fields are not set, we will try to get the value
    // from the primary `AddonFolder` of the `Addon`
    pub(crate) version: Option<String>,
    pub(crate) title: Option<String>,
    pub(crate) author: Option<String>,
    pub(crate) notes: Option<String>,

    // These fields are only available from the repo API
    pub(crate) website_url: Option<String>,
    pub(crate) game_version: Option<String>,
    pub(crate) file_id: Option<i64>,

    /// Remote packages available from the Repository
    pub(crate) remote_packages: HashMap<ReleaseChannel, RemotePackage>,
}

impl RepositoryMetadata {
    pub fn empty() -> Self {
        Default::default()
    }

    pub fn modules(&self) -> Vec<String> {
        let mut entries: Vec<_> = self.remote_packages.iter().collect();
        entries.sort_by_key(|(key, _)| *key);

        if let Some((_, package)) = entries.get(0) {
            return package.modules.clone();
        }

        vec![]
    }
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct RemotePackage {
    pub version: String,
    pub download_url: String,
    pub file_id: Option<i64>,
    pub date_time: Option<DateTime<Utc>>,
    pub modules: Vec<String>,
}

impl PartialOrd for RemotePackage {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.version.cmp(&other.version))
    }
}

impl Ord for RemotePackage {
    fn cmp(&self, other: &Self) -> Ordering {
        self.version.cmp(&other.version)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize, Hash, PartialOrd, Ord)]
pub enum ReleaseChannel {
    Stable,
    Beta,
    Alpha,
}

impl ReleaseChannel {
    pub const ALL: [ReleaseChannel; 3] = [
        ReleaseChannel::Stable,
        ReleaseChannel::Beta,
        ReleaseChannel::Alpha,
    ];
}

impl Default for ReleaseChannel {
    fn default() -> ReleaseChannel {
        ReleaseChannel::Stable
    }
}

impl std::fmt::Display for ReleaseChannel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                ReleaseChannel::Stable => "Stable",
                ReleaseChannel::Beta => "Beta",
                ReleaseChannel::Alpha => "Alpha",
            }
        )
    }
}

#[derive(Default, Debug, Clone)]
/// Struct which stores identifiers for the different repositories.
pub struct RepositoryIdentifiers {
    pub wowi: Option<String>,
    pub tukui: Option<String>,
    pub curse: Option<i32>,
    pub git: Option<String>,
}
