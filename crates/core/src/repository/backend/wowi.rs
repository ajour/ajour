use super::*;
use crate::config::Flavor;
use crate::error::{DownloadError, RepositoryError};
use crate::network::request_async;
use crate::repository::{ReleaseChannel, RemotePackage, RepositoryKind, RepositoryPackage};

use async_trait::async_trait;
use chrono::{TimeZone, Utc};
use isahc::AsyncReadResponseExt;
use serde::Deserialize;

use std::collections::HashMap;

const API_ENDPOINT: &str = "https://api.mmoui.com/v4/game/WOW/filedetails";
const ADDON_URL: &str = "https://www.wowinterface.com/downloads/info";

#[derive(Debug, Clone)]
pub struct WowI {
    pub id: String,
    pub flavor: Flavor,
}

#[async_trait]
impl Backend for WowI {
    async fn get_metadata(&self) -> Result<RepositoryMetadata, RepositoryError> {
        let packages = fetch_remote_packages(&[self.id.clone()]).await?;

        let package = packages
            .into_iter()
            .next()
            .ok_or(RepositoryError::WowIMissingPackage {
                id: self.id.clone(),
            })?;

        let metadata = metadata_from_wowi_package(package);

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

pub(crate) fn metadata_from_wowi_package(package: WowIPackage) -> RepositoryMetadata {
    let mut remote_packages = HashMap::new();

    {
        let version = package.version.clone();
        let download_url = package.download_uri.clone();
        let date_time = Utc.timestamp(package.last_update / 1000, 0);

        let package = RemotePackage {
            version,
            download_url,
            date_time: Some(date_time),
            file_id: None,
            modules: vec![],
        };

        // Since WowI does not support release channels, our default is 'stable'.
        remote_packages.insert(ReleaseChannel::Stable, package);
    }

    let mut metadata = RepositoryMetadata::empty();
    metadata.remote_packages = remote_packages;

    let website_url = addon_url(&package.id.to_string());
    metadata.website_url = Some(website_url.clone());
    metadata.changelog_url = Some(format!("{}/#changelog", website_url));
    metadata.title = Some(package.title);

    metadata
}

/// Return the wowi API endpoint.
fn api_endpoint(ids: &str) -> String {
    format!("{}/{}.json", API_ENDPOINT, ids)
}

/// Returns the addon website url.
pub(crate) fn addon_url(id: &str) -> String {
    format!("{}{}", ADDON_URL, id)
}

pub(crate) async fn batch_fetch_repo_packages(
    flavor: Flavor,
    wowi_ids: &[String],
) -> Result<Vec<RepositoryPackage>, DownloadError> {
    let mut wowi_repo_packages = vec![];

    if wowi_ids.is_empty() {
        return Ok(wowi_repo_packages);
    }

    let wowi_packages = wowi::fetch_remote_packages(&wowi_ids).await?;

    wowi_repo_packages.extend(
        wowi_packages
            .into_iter()
            .map(|package| {
                (
                    package.id.to_string(),
                    wowi::metadata_from_wowi_package(package),
                )
            })
            .filter_map(|(id, metadata)| {
                RepositoryPackage::from_repo_id(flavor, RepositoryKind::WowI, id)
                    .ok()
                    .map(|r| r.with_metadata(metadata))
            }),
    );

    Ok(wowi_repo_packages)
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub(crate) async fn fetch_remote_packages(
    ids: &[String],
) -> Result<Vec<WowIPackage>, DownloadError> {
    let url = api_endpoint(&ids.join(","));
    let timeout = Some(30);
    let mut resp = request_async(&url, vec![], timeout).await?;

    if resp.status().is_success() {
        let packages = resp.json().await;
        Ok(packages?)
    } else {
        Err(DownloadError::InvalidStatusCode {
            code: resp.status(),
            url,
        })
    }
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
/// Struct for applying wowi details to an `Addon`.
pub struct WowIPackage {
    pub id: i64,
    pub title: String,
    pub version: String,
    pub download_uri: String,
    pub last_update: i64,
    pub author: String,
    pub description: String,
}
