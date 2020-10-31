use crate::{error::ClientError, network::request_async, Result};
use isahc::config::RedirectPolicy;
use isahc::prelude::*;
use serde::Deserialize;

const API_ENDPOINT: &str = "https://api.mmoui.com/v4/game/WOW/filedetails";
const ADDON_URL: &str = "https://www.wowinterface.com/downloads/info";

/// Return the wowi API endpoint.
fn api_endpoint(ids: &str) -> String {
    format!("{}/{}.json", API_ENDPOINT, ids)
}

/// Returns the addon website url.
pub fn addon_url(id: &str) -> String {
    format!("{}{}", ADDON_URL, id)
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

/// Returns changelog url for addon.
pub fn changelog_url(id: String) -> String {
    format!("{}{}/#changelog", ADDON_URL, id)
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub async fn fetch_remote_packages(ids: Vec<String>) -> Result<Vec<WowIPackage>> {
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
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}
