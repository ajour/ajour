use crate::{error::ClientError, network::request_async, Result};
use isahc::prelude::*;
use serde_derive::Deserialize;

const API_ENDPOINT: &str = "https://api.wowinterface.com/addons";
const DL_ENDPOINT: &str = "https://cdn.wowinterface.com/downloads/getfile.php?id=";

#[derive(Clone, Debug, Deserialize)]
/// Struct for applying tukui details to an `Addon`.
pub struct Package {
    pub id: String,
    pub title: String,
    pub version: String,
}

/// Function to fetch remote addon packages which contains
/// information about the addon on the repository.
/// Note: More packages can be returned for a single `Addon`
pub async fn fetch_remote_packages(
    shared_client: &HttpClient,
    id: &str,
    token: &str,
) -> Result<Vec<Package>> {
    let url = format!("{}/details/{}.json", API_ENDPOINT, id);
    let headers = vec![("x-api-token", token)];
    let timeout = Some(30);
    let mut resp = request_async(shared_client, url, headers, timeout).await?;

    if resp.status().is_success() {
        let addon_details: Vec<Package> = resp.json()?;
        Ok(addon_details)
    } else {
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}

/// Return the `remote_url` for a given `wowi_id`.
pub fn remote_url(id: &str) -> String {
    format!("{}{}", DL_ENDPOINT, id)
}
