use crate::{
    addon::Addon,
    config::Flavor,
    error::ClientError,
    network::{post_json_async, request_async},
    utility::{regex_html_tags_to_newline, regex_html_tags_to_space, truncate},
    Result,
};
use isahc::prelude::*;
use serde::{Deserialize, Serialize};

const API_ENDPOINT: &str = "https://addons-ecs.forgesvc.net/api/v2";
const FINGERPRINT_API_ENDPOINT: &str = "https://hub.dev.wowup.io/curseforge/addons/fingerprint";

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
/// Struct for applying curse details to an `Addon`.
pub struct Package {
    pub id: u32,
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
    pub id: u32,
    pub file: File,
    pub latest_files: Vec<File>,
}

#[derive(Serialize)]
struct FingerprintData {
    fingerprints: Vec<u32>,
}

pub async fn fetch_remote_packages_by_fingerprint(fingerprints: &[u32]) -> Result<FingerprintInfo> {
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

pub async fn fetch_changelog(id: u32, file_id: i64) -> Result<(String, String)> {
    let url = format!("{}/addon/{}/file/{}/changelog", API_ENDPOINT, id, file_id);
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

    Ok(("No changelog found.".to_owned(), url))
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

pub async fn latest_addon(curse_id: u32, flavor: Flavor) -> Result<Addon> {
    let packages: Vec<Package> = fetch_remote_packages_by_ids(&[curse_id]).await?;

    let package = packages.into_iter().next().ok_or_else(|| {
        ClientError::Custom(format!("No package found for curse id {}", curse_id))
    })?;

    let mut addon = Addon::from_curse_package(&package, flavor, &[]).unwrap();
    addon.set_title(package.name);

    Ok(addon)
}
