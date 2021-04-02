use super::*;
use crate::config::Flavor;
use crate::error::{DownloadError, RepositoryError};
use crate::network::post_json_async;
use crate::repository::{ReleaseChannel, RemotePackage, RepositoryKind, RepositoryPackage};

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use isahc::AsyncReadResponseExt;
use serde::{Deserialize, Serialize};

use std::collections::HashMap;

const API_ENDPOINT: &str = "https://hub.wowup.io";

#[derive(Debug, Clone)]
pub struct TownlongYak {
    pub id: String,
    pub flavor: Flavor,
}

#[async_trait]
impl Backend for TownlongYak {
    async fn get_metadata(&self) -> Result<RepositoryMetadata, RepositoryError> {
        let packages = fetch_remote_packages(self.flavor, &[self.id.clone()]).await?;

        let package = packages
            .into_iter()
            .next()
            .ok_or(RepositoryError::HubMissingPackage {
                id: self.id.clone(),
            })?;

        let metadata = metadata_from_townlong_package(self.flavor, package);

        Ok(metadata)
    }

    async fn get_changelog(
        &self,
        _file_id: Option<i64>,
        _tag_name: Option<String>,
    ) -> Result<Option<String>, RepositoryError> {
        Ok(None)
    }
}

pub(crate) fn metadata_from_townlong_package(
    flavor: Flavor,
    package: TownlongYakPackage,
) -> RepositoryMetadata {
    let mut remote_packages = HashMap::new();

    for release in package.releases.iter() {
        if Some(release.game_type.clone()) == flavor.hub_format() {
            let version = release.tag_name.clone();
            let download_url = release.download_url.clone();
            let date_time = Some(release.published_at);

            let package = RemotePackage {
                version,
                download_url,
                date_time,
                file_id: Some(release.id),
                modules: vec![],
            };

            if release.prerelease {
                remote_packages.insert(ReleaseChannel::Beta, package);
            } else {
                remote_packages.insert(ReleaseChannel::Stable, package);
            }
        }
    }

    let mut metadata = RepositoryMetadata::empty();
    metadata.remote_packages = remote_packages;
    metadata.website_url = Some(package.repository.clone());
    metadata.title = Some(package.repository_name);
    metadata.author = package.owner_name;

    metadata
}

pub(crate) async fn batch_fetch_repo_packages(
    flavor: Flavor,
    townlong_ids: &[String],
) -> Result<Vec<RepositoryPackage>, DownloadError> {
    let mut townlong_repo_packages = vec![];

    if townlong_ids.is_empty() {
        return Ok(townlong_repo_packages);
    }

    let townlong_packages = townlongyak::fetch_remote_packages(flavor, &townlong_ids).await?;

    townlong_repo_packages.extend(
        townlong_packages
            .into_iter()
            .map(|package| {
                (
                    package.id.to_string(),
                    townlongyak::metadata_from_townlong_package(flavor, package),
                )
            })
            .filter_map(|(id, metadata)| {
                RepositoryPackage::from_repo_id(flavor, RepositoryKind::TownlongYak, id)
                    .ok()
                    .map(|r| r.with_metadata(metadata))
            }),
    );

    Ok(townlong_repo_packages)
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub(crate) async fn fetch_remote_packages(
    flavor: Flavor,
    ids: &[String],
) -> Result<Vec<TownlongYakPackage>, DownloadError> {
    let url = format!(
        "{}/addons/batch/{}",
        API_ENDPOINT,
        flavor.hub_format().unwrap()
    );

    let addon_ids = ids.iter().filter_map(|i| i.parse::<i64>().ok()).collect();

    let timeout = Some(30);

    let mut resp = post_json_async(&url, BatchRequest { addon_ids }, vec![], timeout).await?;

    if resp.status().is_success() {
        let packages = resp
            .json::<TownlongYakBatchResponse>()
            .await
            .map(|r| r.addons);

        Ok(packages?)
    } else {
        Err(DownloadError::InvalidStatusCode {
            code: resp.status(),
            url,
        })
    }
}

#[derive(Clone, Debug, Deserialize)]
pub struct TownlongYakBatchResponse {
    pub addons: Vec<TownlongYakPackage>,
    pub count: i64,
}

#[derive(Clone, Debug, Deserialize)]
/// Struct for applying wowi details to an `Addon`.
pub struct TownlongYakPackage {
    pub id: i64,
    pub repository: String,
    pub repository_name: String,
    pub source: String,
    pub description: Option<String>,
    pub homepage: Option<String>,
    pub owner_name: Option<String>,
    pub releases: Vec<TownlongYakRelease>,
}

#[derive(Clone, Debug, Deserialize)]
pub struct TownlongYakRelease {
    pub id: i64,
    pub download_url: String,
    pub game_type: String,
    pub game_version: String,
    pub tag_name: String,
    pub published_at: DateTime<Utc>,
    #[serde(default)]
    pub prerelease: bool,
}

#[serde(rename_all = "camelCase")]
#[derive(Clone, Debug, Serialize)]
struct BatchRequest {
    addon_ids: Vec<i64>,
}
