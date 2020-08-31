use crate::{config::Flavor, error::ClientError, network::request_async, Result};
use isahc::prelude::*;
use serde_derive::Deserialize;

#[derive(Clone, Debug, Deserialize)]
/// Struct for applying tukui details to an `Addon`.
pub struct Package {
    pub name: String,
    pub version: String,
    pub url: String,
}

/// Return the tukui API endpoint.
fn api_endpoint(id: &str, flavor: &Flavor) -> String {
    match flavor {
        Flavor::Retail => match id {
            "-1" => "https://www.tukui.org/api.php?ui=tukui".to_owned(),
            "-2" => "https://www.tukui.org/api.php?ui=elvui".to_owned(),
            _ => format!("https://www.tukui.org/api.php?addon={}", id),
        },
        Flavor::Classic => format!("https://www.tukui.org/api.php?classic-addon={}", id),
    }
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub async fn fetch_remote_package(
    shared_client: &HttpClient,
    id: &str,
    flavor: &Flavor,
) -> Result<Package> {
    let url = api_endpoint(id, flavor);
    let timeout = Some(30);
    let mut resp = request_async(shared_client, &url, vec![], timeout).await?;

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
