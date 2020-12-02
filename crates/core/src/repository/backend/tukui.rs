use super::*;
use crate::config::Flavor;
use crate::error::{DownloadError, RepositoryError};
use crate::network::request_async;
use crate::repository::{ReleaseChannel, RemotePackage};

use async_trait::async_trait;
use chrono::{NaiveDateTime, TimeZone, Utc};
use isahc::config::RedirectPolicy;
use isahc::prelude::*;
use serde::Deserialize;

use std::collections::HashMap;
use std::sync::Arc;

#[derive(Debug, Clone)]
pub struct Tukui {
    pub id: String,
    pub flavor: Flavor,
}

#[async_trait]
impl Backend for Tukui {
    async fn get_metadata(&self) -> Result<RepositoryMetadata, RepositoryError> {
        let client = Arc::new(
            HttpClient::builder()
                .redirect_policy(RedirectPolicy::Follow)
                .max_connections_per_host(6)
                .build()
                .unwrap(),
        );

        let (_, package) = fetch_remote_package(client, &self.id, &self.flavor).await?;

        let metadata = metadata_from_tukui_package(package);

        Ok(metadata)
    }
}

pub(crate) fn metadata_from_tukui_package(package: TukuiPackage) -> RepositoryMetadata {
    let mut remote_packages = HashMap::new();

    {
        let version = package.version.clone();
        let download_url = package.url.clone();

        let date_time = NaiveDateTime::parse_from_str(&package.lastupdate, "%Y-%m-%d %H:%M:%S")
            .map_or(
                NaiveDateTime::parse_from_str(
                    &format!("{} 00:00:00", &package.lastupdate),
                    "%Y-%m-%d %T",
                ),
                std::result::Result::Ok,
            )
            .map(|d| Utc.from_utc_datetime(&d))
            .ok();

        let package = RemotePackage {
            version,
            download_url,
            date_time,
            file_id: None,
            modules: vec![],
        };

        // Since Tukui does not support release channels, our default is 'stable'.
        remote_packages.insert(ReleaseChannel::Stable, package);
    }

    let website_url = Some(package.web_url.clone());
    let changelog_url = Some(format!("{}&changelog", package.web_url));
    let game_version = package.patch;
    let title = package.name;

    let mut metadata = RepositoryMetadata::empty();
    metadata.website_url = website_url;
    metadata.changelog_url = changelog_url;
    metadata.game_version = game_version;
    metadata.remote_packages = remote_packages;
    metadata.title = Some(title);

    metadata
}

/// Returns flavor `String` in Tukui format
fn format_flavor(flavor: &Flavor) -> String {
    let base_flavor = flavor.base_flavor();
    match base_flavor {
        Flavor::Retail => "retail".to_owned(),
        Flavor::Classic => "classic".to_owned(),
        _ => panic!(format!("Unknown base flavor {}", base_flavor)),
    }
}

/// Return the tukui API endpoint.
fn api_endpoint(id: &str, flavor: &Flavor) -> String {
    format!(
        "https://hub.wowup.io/tukui/{}/{}",
        format_flavor(flavor),
        id
    )
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub(crate) async fn fetch_remote_package(
    shared_client: Arc<HttpClient>,
    id: &str,
    flavor: &Flavor,
) -> Result<(String, TukuiPackage), DownloadError> {
    let url = api_endpoint(id, flavor);

    let timeout = Some(30);
    let mut resp = request_async(&shared_client, &url, vec![], timeout).await?;

    if resp.status().is_success() {
        let package = resp.json()?;
        Ok((id.to_string(), package))
    } else {
        Err(DownloadError::InvalidStatusCode {
            code: resp.status(),
            url,
        })
    }
}

#[derive(Clone, Debug, Deserialize)]
/// Struct for applying tukui details to an `Addon`.
pub struct TukuiPackage {
    pub name: String,
    pub version: String,
    pub url: String,
    pub web_url: String,
    pub lastupdate: String,
    pub patch: Option<String>,
    pub author: Option<String>,
    pub small_desc: Option<String>,
}
