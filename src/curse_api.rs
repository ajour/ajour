use crate::{error::ClientError, network::request, Result};
use isahc::prelude::*;
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
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub fn fetch_remote_package(id: &u32) -> Result<Package> {
    let url = format!("{}/{}", API_ENDPOINT, id);
    let mut resp = request(&url, vec![])?;
    if resp.status().is_success() {
        let package: Package = resp.json()?;
        Ok(package)
    } else {
        println!("resp.text()?: {:?}", resp.text()?);
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}
