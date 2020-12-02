use super::*;
use crate::config::Flavor;
use crate::error::DownloadError;
use crate::network::{post_json_async, request_async};
use crate::repository::{ReleaseChannel, RemotePackage};
use crate::utility::{regex_html_tags_to_newline, regex_html_tags_to_space, truncate};

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use isahc::prelude::*;
use serde::{Deserialize, Serialize};

use std::collections::HashMap;

const API_ENDPOINT: &str = "https://addons-ecs.forgesvc.net/api/v2";
const FINGERPRINT_API_ENDPOINT: &str = "https://hub.wowup.io/curseforge/addons/fingerprint";

#[derive(Debug, Clone)]
pub struct Curse {
    pub id: String,
    pub flavor: Flavor,
}

#[async_trait]
impl Backend for Curse {
    async fn get_metadata(&self) -> Result<RepositoryMetadata, RepositoryError> {
        let id = self
            .id
            .parse::<i32>()
            .map_err(|_| RepositoryError::CurseIdConversion {
                id: self.id.clone(),
            })?;

        let packages: Vec<Package> = fetch_remote_packages_by_ids(&[id]).await?;

        let package = packages
            .into_iter()
            .next()
            .ok_or(RepositoryError::CurseMissingPackage {
                id: self.id.clone(),
            })?;

        let metadata = metadata_from_curse_package(self.flavor, package);

        Ok(metadata)
    }

}

pub(crate) fn metadata_from_curse_package(flavor: Flavor, package: Package) -> RepositoryMetadata {
    let mut remote_packages = HashMap::new();

    for file in package.latest_files.iter() {
        let game_version_flavor = file.game_version_flavor.as_ref();
        if !file.is_alternate && game_version_flavor == Some(&flavor.curse_format()) {
            let version = file.display_name.clone();
            let download_url = file.download_url.clone();
            let date_time = DateTime::parse_from_rfc3339(&file.file_date)
                .map(|d| d.with_timezone(&Utc))
                .ok();
            let modules = file.modules.iter().map(|m| m.foldername.clone()).collect();

            let package = RemotePackage {
                version,
                download_url,
                date_time,
                file_id: Some(file.id),
                modules,
            };

            match file.release_type {
                1 /* stable */ => {
                    remote_packages.insert(ReleaseChannel::Stable, package);
                }
                2 /* beta */ => {
                    remote_packages.insert(ReleaseChannel::Beta, package);
                }
                3 /* alpha */ => {
                    remote_packages.insert(ReleaseChannel::Alpha, package);
                }
                _ => ()
            };
        }
    }

    let mut metadata = RepositoryMetadata::empty();
    metadata.remote_packages = remote_packages;
    metadata.title = Some(package.name.clone());
    metadata.website_url = Some(package.website_url.clone());
    metadata.changelog_url = Some(format!("{}/files", package.website_url));

    metadata
}

pub(crate) fn metadata_from_fingerprint_info(
    flavor: Flavor,
    info: &AddonFingerprintInfo,
) -> RepositoryMetadata {
    let mut remote_packages = HashMap::new();

    for file in info.latest_files.iter() {
        let game_version_flavor = file.game_version_flavor.as_ref();
        if !file.is_alternate && game_version_flavor == Some(&flavor.curse_format()) {
            let version = file.display_name.clone();
            let download_url = file.download_url.clone();
            let date_time = DateTime::parse_from_rfc3339(&file.file_date)
                .map(|d| d.with_timezone(&Utc))
                .ok();
            let modules = file.modules.iter().map(|m| m.foldername.clone()).collect();

            let package = RemotePackage {
                version,
                download_url,
                date_time,
                file_id: Some(file.id),
                modules,
            };

            match file.release_type {
                1 /* stable */ => {
                    remote_packages.insert(ReleaseChannel::Stable, package);
                }
                2 /* beta */ => {
                    remote_packages.insert(ReleaseChannel::Beta, package);
                }
                3 /* alpha */ => {
                    remote_packages.insert(ReleaseChannel::Alpha, package);
                }
                _ => ()
            };
        }
    }

    let version = Some(info.file.display_name.clone());
    let file_id = Some(info.file.id);
    let game_version = info.file.game_version.get(0).cloned();

    let mut metadata = RepositoryMetadata::empty();
    metadata.remote_packages = remote_packages;
    metadata.version = version;
    metadata.file_id = file_id;
    metadata.game_version = game_version;

    metadata
}

pub(crate) async fn fetch_remote_packages_by_fingerprint(
    fingerprints: &[u32],
) -> Result<FingerprintInfo, DownloadError> {
    let mut resp = post_json_async(
        FINGERPRINT_API_ENDPOINT,
        FingerprintData {
            fingerprints: fingerprints.to_owned(),
        },
        vec![],
        None,
    )
    .await?;
    if resp.status().is_success() {
        let fingerprint_info = resp.json()?;
        Ok(fingerprint_info)
    } else {
        Err(DownloadError::InvalidStatusCode {
            code: resp.status(),
            url: FINGERPRINT_API_ENDPOINT.to_owned(),
        })
    }
}

pub(crate) async fn fetch_remote_packages_by_ids(
    curse_ids: &[i32],
) -> Result<Vec<Package>, DownloadError> {
    let url = format!("{}/addon", API_ENDPOINT);
    let mut resp = post_json_async(&url, curse_ids, vec![], None).await?;
    if resp.status().is_success() {
        let packages = resp.json()?;
        Ok(packages)
    } else {
        Err(DownloadError::InvalidStatusCode {
            code: resp.status(),
            url,
        })
    }
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
/// Struct for applying curse details to an `Addon`.
pub struct Package {
    pub id: i32,
    pub name: String,
    pub website_url: String,
    pub latest_files: Vec<File>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct File {
    pub id: i64,
    pub display_name: String,
    pub file_name: String,
    pub file_date: String,
    pub download_url: String,
    pub release_type: u32,
    pub game_version_flavor: Option<String>,
    pub modules: Vec<Module>,
    pub is_alternate: bool,
    pub game_version: Vec<String>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Module {
    pub foldername: String,
    pub fingerprint: u32,
    #[serde(rename = "type")]
    pub type_field: i64,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GameInfo {
    pub id: i64,
    pub name: String,
    pub slug: String,
    pub date_modified: String,
    pub file_parsing_rules: Vec<FileParsingRule>,
    pub category_sections: Vec<CategorySection>,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileParsingRule {
    pub comment_strip_pattern: String,
    pub file_extension: String,
    pub inclusion_pattern: String,
    pub game_id: i64,
    pub id: i64,
}

#[derive(Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CategorySection {
    pub id: i64,
    pub game_id: i64,
    pub name: String,
    pub package_type: i64,
    pub path: String,
    pub initial_inclusion_pattern: String,
    pub extra_include_pattern: String,
    pub game_category_id: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FingerprintInfo {
    pub exact_matches: Vec<AddonFingerprintInfo>,
    pub partial_matches: Vec<AddonFingerprintInfo>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AddonFingerprintInfo {
    pub id: i32,
    pub file: File,
    pub latest_files: Vec<File>,
}

#[derive(Serialize)]
struct FingerprintData {
    fingerprints: Vec<u32>,
}
