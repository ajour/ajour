use crate::{error::ClientError, network::request_async, Result};
use isahc::prelude::*;
use serde_derive::Deserialize;

#[derive(Clone, Debug, Deserialize)]
/// Struct for applying tukui details to an `Addon`.
pub struct Package {
    pub id: i32,
    pub version: String,
    pub url: String,
}

/// Return the tukui API endpoint.
fn api_endpoint(id: &str) -> String {
    match id {
        "-1" => "https://www.tukui.org/api.php?ui=tukui".to_owned(),
        "-2" => "https://www.tukui.org/api.php?ui=elvui".to_owned(),
        _ => format!("https://www.tukui.org/api.php?addon={}", id),
    }
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub async fn fetch_remote_package(shared_client: &HttpClient, id: &str) -> Result<Package> {
    let url = api_endpoint(id);
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
