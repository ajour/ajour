use crate::config::Flavor;
use crate::error::{DownloadError, RepositoryError};

use chrono::{DateTime, Utc};
use isahc::http::uri::Uri;
use serde::{Deserialize, Serialize};

use std::cmp::Ordering;
use std::collections::HashMap;
use std::fmt::Display;
use std::str::FromStr;

mod backend;
use backend::Backend;

pub use backend::{curse, git, townlongyak, tukui, wowi};
use backend::{Curse, Github, Gitlab, TownlongYak, Tukui, WowI};

#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Ord, Eq, Serialize, Deserialize)]
pub enum RepositoryKind {
    Curse,
    Tukui,
    WowI,
    TownlongYak,
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
                RepositoryKind::TownlongYak => "TownlongYak",
                RepositoryKind::Git(git) => match git {
                    GitKind::Github => "GitHub",
                    GitKind::Gitlab => "GitLab",
                },
            }
        )
    }
}

impl RepositoryKind {
    pub(crate) fn is_git(self) -> bool {
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
    pub fn from_source_url(flavor: Flavor, url: Uri) -> Result<Self, RepositoryError> {
        let host = url.host().ok_or(RepositoryError::GitMissingHost {
            url: url.to_string(),
        })?;

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
                return Err(RepositoryError::GitInvalidHost {
                    host: host.to_string(),
                })
            }
        };

        Ok(RepositoryPackage {
            backend,
            id: url.to_string(),
            kind,
            metadata: Default::default(),
        })
    }

    pub fn from_repo_id(
        flavor: Flavor,
        kind: RepositoryKind,
        id: String,
    ) -> Result<Self, RepositoryError> {
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
            RepositoryKind::TownlongYak => Box::new(TownlongYak {
                id: id.clone(),
                flavor,
            }),
            RepositoryKind::Git(_) => return Err(RepositoryError::GitWrongConstructor),
        };

        Ok(RepositoryPackage {
            backend,
            id,
            kind,
            metadata: Default::default(),
        })
    }

    pub(crate) fn with_metadata(mut self, metadata: RepositoryMetadata) -> Self {
        self.metadata = metadata;

        self
    }

    pub async fn resolve_metadata(&mut self) -> Result<(), RepositoryError> {
        let metadata = self.backend.get_metadata().await?;

        self.metadata = metadata;

        Ok(())
    }

    /// Get changelog from the repository
    ///
    /// `channel` is only used for the Curse & GitHub repository since
    /// we can get unique changelogs for each version
    pub(crate) async fn get_changelog(
        &self,
        release_channel: ReleaseChannel,
        default_release_channel: GlobalReleaseChannel,
    ) -> Result<Option<String>, RepositoryError> {
        let release_channel = if release_channel == ReleaseChannel::Default {
            default_release_channel.convert_to_release_channel()
        } else {
            release_channel
        };

        let file_id = if self.kind == RepositoryKind::Curse {
            self.metadata
                .remote_packages
                .get(&release_channel)
                .and_then(|p| p.file_id)
        } else {
            None
        };

        let tag_name = if self.kind.is_git() {
            let remote_package = self.metadata.remote_packages.get(&release_channel).ok_or(
                RepositoryError::MissingPackageChannel {
                    channel: release_channel,
                },
            )?;

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

    // todo (casperstorm): better description here.
    // This is constructed, and is different for each repo.
    pub(crate) changelog_url: Option<String>,

    /// Remote packages available from the Repository
    pub(crate) remote_packages: HashMap<ReleaseChannel, RemotePackage>,
}

impl RepositoryMetadata {
    pub(crate) fn empty() -> Self {
        Default::default()
    }

    pub(crate) fn modules(&self) -> Vec<String> {
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

/// This is the global channel used.
/// If an addon has chosen `Default` as `ReleaseChannel`, we will `GlobalReleaseChannel`
/// instead, which is saved in the config.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize, Hash, PartialOrd, Ord)]
pub enum GlobalReleaseChannel {
    Stable,
    Beta,
    Alpha,
}

impl GlobalReleaseChannel {
    pub const ALL: [GlobalReleaseChannel; 3] = [
        GlobalReleaseChannel::Stable,
        GlobalReleaseChannel::Beta,
        GlobalReleaseChannel::Alpha,
    ];

    pub fn convert_to_release_channel(&self) -> ReleaseChannel {
        match self {
            GlobalReleaseChannel::Stable => ReleaseChannel::Stable,
            GlobalReleaseChannel::Beta => ReleaseChannel::Beta,
            GlobalReleaseChannel::Alpha => ReleaseChannel::Alpha,
        }
    }
}

impl Default for GlobalReleaseChannel {
    fn default() -> GlobalReleaseChannel {
        GlobalReleaseChannel::Stable
    }
}

impl std::fmt::Display for GlobalReleaseChannel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                GlobalReleaseChannel::Stable => "Stable",
                GlobalReleaseChannel::Beta => "Beta",
                GlobalReleaseChannel::Alpha => "Alpha",
            }
        )
    }
}

/// This is the channel used on an addon level.
/// If `Default` is chosen, we will use the value from `GlobalReleaseChannel` which
/// is saved in the config.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize, Hash, PartialOrd, Ord)]
pub enum ReleaseChannel {
    Default,
    Stable,
    Beta,
    Alpha,
}

impl ReleaseChannel {
    pub const ALL: [ReleaseChannel; 4] = [
        ReleaseChannel::Default,
        ReleaseChannel::Stable,
        ReleaseChannel::Beta,
        ReleaseChannel::Alpha,
    ];
}

impl Default for ReleaseChannel {
    fn default() -> ReleaseChannel {
        ReleaseChannel::Default
    }
}

impl std::fmt::Display for ReleaseChannel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                ReleaseChannel::Default => "Default",
                ReleaseChannel::Stable => "Stable",
                ReleaseChannel::Beta => "Beta",
                ReleaseChannel::Alpha => "Alpha",
            }
        )
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Hash, PartialOrd, Ord, Deserialize)]
pub enum CompressionFormat {
    Zip,
    Zstd,
}

impl CompressionFormat {
    pub const ALL: [CompressionFormat; 2] = [CompressionFormat::Zip, CompressionFormat::Zstd];

    pub(crate) const fn file_ext(&self) -> &'static str {
        match self {
            CompressionFormat::Zip => "zip",
            CompressionFormat::Zstd => "tar.zst",
        }
    }
}

impl Default for CompressionFormat {
    fn default() -> CompressionFormat {
        CompressionFormat::Zip
    }
}

impl Display for CompressionFormat {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CompressionFormat::Zip => f.write_str("Zip"),
            CompressionFormat::Zstd => f.write_str("Zstd"),
        }
    }
}

impl FromStr for CompressionFormat {
    type Err = &'static str;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "zip" | "Zip" => Ok(CompressionFormat::Zip),
            "zstd" | "Zstd" => Ok(CompressionFormat::Zstd),
            _ => Err("valid values are: zip, zstd"),
        }
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

#[derive(Debug, Clone)]
pub struct Changelog {
    pub text: Option<String>,
}

pub async fn batch_refresh_repository_packages(
    flavor: Flavor,
    repos: &[RepositoryPackage],
) -> Result<Vec<RepositoryPackage>, DownloadError> {
    let curse_ids = repos
        .iter()
        .filter(|r| r.kind == RepositoryKind::Curse)
        .map(|r| r.id.parse::<i32>().ok())
        .flatten()
        .collect::<Vec<_>>();
    let tukui_ids = repos
        .iter()
        .filter(|r| r.kind == RepositoryKind::Tukui)
        .map(|r| r.id.clone())
        .collect::<Vec<_>>();
    let wowi_ids = repos
        .iter()
        .filter(|r| r.kind == RepositoryKind::WowI)
        .map(|r| r.id.clone())
        .collect::<Vec<_>>();
    let townlong_ids = repos
        .iter()
        .filter(|r| r.kind == RepositoryKind::TownlongYak)
        .map(|r| r.id.clone())
        .collect::<Vec<_>>();
    let git_urls = repos
        .iter()
        .filter(|r| matches!(r.kind, RepositoryKind::Git(_)))
        .map(|r| r.id.clone())
        .collect::<Vec<_>>();

    // Get all curse repo packages
    let curse_repo_packages = curse::batch_fetch_repo_packages(flavor, &curse_ids, None).await?;

    // Get all tukui repo packages
    let tukui_repo_packages = tukui::batch_fetch_repo_packages(flavor, &tukui_ids).await?;

    // Get all wowi repo packages
    let wowi_repo_packages = wowi::batch_fetch_repo_packages(flavor, &wowi_ids).await?;

    // Get all townlong repo packages
    let townlong_repo_packages =
        townlongyak::batch_fetch_repo_packages(flavor, &townlong_ids).await?;

    // Get all git repo packages
    let git_repo_packages = git::batch_fetch_repo_packages(flavor, &git_urls).await?;

    Ok([
        &curse_repo_packages[..],
        &tukui_repo_packages[..],
        &wowi_repo_packages[..],
        &townlong_repo_packages[..],
        &git_repo_packages[..],
    ]
    .concat())
}
