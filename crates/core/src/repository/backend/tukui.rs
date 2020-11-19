use super::*;
use crate::config::Flavor;
use crate::network::{request_async, DownloadError};
use crate::repository::{ReleaseChannel, RemotePackage, RepositoryError};
use crate::utility::{regex_html_tags_to_newline, regex_html_tags_to_space, truncate};

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

    async fn get_changelog(
        &self,
        _file_id: Option<i64>,
        _tag_name: Option<String>,
    ) -> Result<(String, String), RepositoryError> {
        let url = changelog_endpoint(&self.id, &self.flavor);

        match self.flavor {
            Flavor::Retail | Flavor::RetailBeta | Flavor::RetailPTR => {
                // Only TukUI and ElvUI main addons has changelog which can be fetched.
                // The others is embeded into a page.
                if &self.id == "-1" || &self.id == "-2" {
                    let client = HttpClient::builder().build().unwrap();
                    let mut resp = request_async(&client, &url.clone(), vec![], None).await?;

                    if resp.status().is_success() {
                        let changelog: String = resp.text()?;

                        let c = regex_html_tags_to_newline()
                            .replace_all(&changelog, "\n")
                            .to_string();
                        let c = regex_html_tags_to_space().replace_all(&c, "").to_string();
                        let c = truncate(&c, 2500).to_string();

                        return Ok((c, url));
                    }

                    return Ok(("No changelog found".to_string(), url));
                }

                Ok(("Please view this changelog in the browser by pressing 'Full Changelog' to the right".to_string(), url))
            }
            Flavor::Classic | Flavor::ClassicPTR => Ok((
                "Please view this changelog in the browser by pressing 'Full Changelog' to the right"
                    .to_string(),
                url,
            )),
        }
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
    let game_version = package.patch;
    let title = package.name;

    let mut metadata = RepositoryMetadata::empty();
    metadata.website_url = website_url;
    metadata.game_version = game_version;
    metadata.remote_packages = remote_packages;
    metadata.title = Some(title);

    metadata
}

/// Return the tukui API endpoint.
fn api_endpoint(id: &str, flavor: &Flavor) -> String {
    match flavor {
        Flavor::Retail | Flavor::RetailPTR | Flavor::RetailBeta => match id {
            "-1" => "https://www.tukui.org/api.php?ui=tukui".to_owned(),
            "-2" => "https://www.tukui.org/api.php?ui=elvui".to_owned(),
            _ => format!("https://www.tukui.org/api.php?addon={}", id),
        },
        Flavor::Classic | Flavor::ClassicPTR => {
            format!("https://www.tukui.org/api.php?classic-addon={}", id)
        }
    }
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
