use crate::{
    error::ClientError,
    network::{post_json_async, request_async},
    Result,
};
use isahc::prelude::*;
use serde_derive::{Deserialize, Serialize};

const API_ENDPOINT: &str = "https://addons-ecs.forgesvc.net/api/v2";

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
/// Struct for applying curse details to an `Addon`.
pub struct Package {
    pub id: u32,
    pub name: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct File {
    pub id: i64,
    pub display_name: String,
    pub file_name: String,
    pub download_url: String,
    pub release_type: u32,
    pub game_version_flavor: String,
    pub modules: Vec<Module>,
    pub is_alternate: bool,
    pub game_version_date_released: String,
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
    pub is_cache_built: bool,
    pub exact_matches: Vec<AddonFingerprintInfo>,
    pub exact_fingerprints: Vec<u32>,
    pub partial_matches: Vec<::serde_json::Value>,
    pub partial_match_fingerprints: ::serde_json::Value,
    pub installed_fingerprints: Vec<u32>,
    pub unmatched_fingerprints: Vec<u32>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AddonFingerprintInfo {
    pub id: u32,
    pub file: File,
    pub latest_files: Vec<File>,
}

pub async fn fetch_remote_packages_by_fingerprint(fingerprints: &[u32]) -> Result<FingerprintInfo> {
    let url = format!("{}/fingerprint", API_ENDPOINT);
    let mut resp = post_json_async(url, fingerprints, vec![], None).await?;
    if resp.status().is_success() {
        let fingerprint_info = resp.json()?;
        Ok(fingerprint_info)
    } else {
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}

pub async fn fetch_remote_packages_by_ids(curse_ids: &[u32]) -> Result<Vec<Package>> {
    let url = format!("{}/addon", API_ENDPOINT);
    let mut resp = post_json_async(url, curse_ids, vec![], None).await?;
    if resp.status().is_success() {
        let packages = resp.json()?;
        Ok(packages)
    } else {
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}

pub async fn fetch_game_info() -> Result<GameInfo> {
    let url = format!("{}/game/1", API_ENDPOINT);
    let client = HttpClient::builder().build().unwrap();
    let mut resp = request_async(&client, url, vec![], None).await?;
    if resp.status().is_success() {
        let game_info = resp.json()?;
        Ok(game_info)
    } else {
        Err(ClientError::Custom(format!(
            "Coudn't fetch game information. Server returned: {}",
            resp.text()?
        )))
    }
}
