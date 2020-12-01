use super::*;
use crate::config::Flavor;
use crate::error::{DownloadError, RepositoryError};
use crate::network::request_async;
use crate::repository::{ReleaseChannel, RemotePackage};

use async_trait::async_trait;
use chrono::{TimeZone, Utc};
use isahc::config::RedirectPolicy;
use isahc::prelude::*;
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
    ) -> Result<(String, String), RepositoryError> {
        Ok((
            "Please view this changelog in the browser by pressing 'Full Changelog' to the right"
                .to_owned(),
            changelog_url(&self.id),
        ))
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

/// Returns changelog url for addon.
pub(crate) fn changelog_url(id: &str) -> String {
    format!("{}{}/#changelog", ADDON_URL, id)
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub(crate) async fn fetch_remote_packages(
    ids: &[String],
) -> Result<Vec<WowIPackage>, DownloadError> {
    let client = HttpClient::builder()
        .redirect_policy(RedirectPolicy::Follow)
        .max_connections_per_host(6)
        .build()
        .unwrap();
    let url = api_endpoint(&ids.join(","));
    let timeout = Some(30);
    let mut resp = request_async(&client, &url, vec![], timeout).await?;

    if resp.status().is_success() {
        let packages = resp.json();
        Ok(packages?)
    } else {
        Err(DownloadError::InvalidStatusCode {
            code: resp.status(),
            url,
        })
    }
}

#[serde(rename_all = "camelCase")]
#[derive(Clone, Debug, Deserialize)]
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
