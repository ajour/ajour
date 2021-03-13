use super::*;
use crate::config::Flavor;
use crate::error::{DownloadError, RepositoryError};
use crate::network::request_async;
use crate::repository::{ReleaseChannel, RemotePackage, RepositoryKind, RepositoryPackage};
use crate::utility::{regex_html_tags_to_newline, regex_html_tags_to_space, truncate};

use async_trait::async_trait;
use chrono::{NaiveDateTime, TimeZone, Utc};
use futures::future::join_all;
use isahc::AsyncReadResponseExt;
use serde::Deserialize;

use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct Tukui {
    pub id: String,
    pub flavor: Flavor,
}

#[async_trait]
impl Backend for Tukui {
    async fn get_metadata(&self) -> Result<RepositoryMetadata, RepositoryError> {
        let (_, package) = fetch_remote_package(&self.id, &self.flavor).await?;

        let metadata = metadata_from_tukui_package(package);

        Ok(metadata)
    }

    async fn get_changelog(
        &self,
        _file_id: Option<i64>,
        _tag_name: Option<String>,
    ) -> Result<Option<String>, RepositoryError> {
        let url = changelog_endpoint(&self.id, &self.flavor);

        match self.flavor {
            Flavor::Retail | Flavor::RetailBeta | Flavor::RetailPTR => {
                // Only TukUI and ElvUI main addons has changelog which can be fetched.
                // The others is embeded into a page.
                if &self.id == "-1" || &self.id == "-2" {
                    let mut resp = request_async(&url, vec![], None).await?;

                    if resp.status().is_success() {
                        let changelog: String = resp.text().await?;

                        let c = regex_html_tags_to_newline()
                            .replace_all(&changelog, "\n")
                            .to_string();
                        let c = regex_html_tags_to_space().replace_all(&c, "").to_string();
                        let c = truncate(&c, 2500).to_string();

                        return Ok(Some(c));
                    }
                }
            }
            Flavor::Classic | Flavor::ClassicPTR => {}
        }

        Ok(None)
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

fn changelog_endpoint(id: &str, flavor: &Flavor) -> String {
    match flavor {
        Flavor::Retail | Flavor::RetailPTR | Flavor::RetailBeta => match id {
            "-1" => "https://www.tukui.org/ui/tukui/changelog".to_owned(),
            "-2" => "https://www.tukui.org/ui/elvui/changelog".to_owned(),
            _ => format!("https://www.tukui.org/addons.php?id={}&changelog", id),
        },
        Flavor::Classic | Flavor::ClassicPTR => format!(
            "https://www.tukui.org/classic-addons.php?id={}&changelog",
            id
        ),
    }
}

pub(crate) async fn batch_fetch_repo_packages(
    flavor: Flavor,
    tukui_ids: &[String],
) -> Result<Vec<RepositoryPackage>, DownloadError> {
    let mut tukui_repo_packages = vec![];

    if tukui_ids.is_empty() {
        return Ok(tukui_repo_packages);
    }

    let fetch_tasks: Vec<_> = tukui_ids
        .iter()
        .map(|id| tukui::fetch_remote_package(&id, &flavor))
        .collect();

    tukui_repo_packages.extend(
        join_all(fetch_tasks)
            .await
            .into_iter()
            .filter_map(Result::ok)
            .map(|(id, package)| (id, tukui::metadata_from_tukui_package(package)))
            .filter_map(|(id, metadata)| {
                RepositoryPackage::from_repo_id(flavor, RepositoryKind::Tukui, id)
                    .ok()
                    .map(|r| r.with_metadata(metadata))
            }),
    );

    Ok(tukui_repo_packages)
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub(crate) async fn fetch_remote_package(
    id: &str,
    flavor: &Flavor,
) -> Result<(String, TukuiPackage), DownloadError> {
    let url = api_endpoint(id, flavor);

    let timeout = Some(30);
    let mut resp = request_async(&url, vec![], timeout).await?;

    if resp.status().is_success() {
        let package = resp.json().await?;
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
