use crate::{error::ClientError, network::request_async, Result};
use isahc::prelude::*;
use percent_encoding::{utf8_percent_encode, NON_ALPHANUMERIC};
use serde_derive::Deserialize;

const API_ENDPOINT: &str = "https://addons-ecs.forgesvc.net/api/v2/addon";

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
/// Struct for applying curse details to an `Addon`.
pub struct Package {
    pub id: u32,
    pub latest_files: Vec<File>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct File {
    pub display_name: String,
    pub download_url: String,
    pub release_type: u32,
    pub game_version_flavor: String,
    pub modules: Vec<Module>,
    pub is_alternate: bool,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Module {
    pub foldername: String,
    pub fingerprint: u32,
}

/// Function to fetch a remote addon package for id.
pub async fn fetch_remote_package(id: &u32) -> Result<Package> {
    let url = format!("{}/{}", API_ENDPOINT, id);
    let mut resp = request_async(&url, vec![]).await?;
    if resp.status().is_success() {
        let package: Package = resp.json()?;
        Ok(package)
    } else {
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}

/// Function to fetch a remote addon packages for a search string.
pub async fn fetch_remote_packages(search_string: &str) -> Result<Vec<Package>> {
    let game_id = 1; // wow
    let page_size = 20; // capping results
    let search_string = utf8_percent_encode(search_string, NON_ALPHANUMERIC).to_string();
    let url = format!(
        "{}/search?gameId={}&pageSize={}&searchFilter={}",
        API_ENDPOINT, game_id, page_size, search_string
    );

    let mut resp = request_async(&url, vec![]).await?;
    if resp.status().is_success() {
        let packages: Vec<Package> = resp.json()?;
        Ok(packages)
    } else {
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}
