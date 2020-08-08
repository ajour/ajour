use serde_derive::Deserialize;
use isahc::prelude::*;
use crate::{
    error::ClientError,
    network::request,
    Result,
};

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
        _    => format!("https://www.tukui.org/api.php?addon={}", id)
    }
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub async fn fetch_remote_package(id: &str) -> Result<Package> {
    let url = api_endpoint(id);
    let mut resp = request(&url, vec![])?;

    if resp.status().is_success() {
        let package: Package = resp.json()?;
        Ok(package)
    } else {
        Err(ClientError::Custom(
            format!(
                "Coudn't fetch details for addon. Server returned: {}",
                resp.text()?
            )
            .to_owned(),
        ))
    }
}
