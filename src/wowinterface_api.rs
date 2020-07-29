use crate::{error::ClientError, toc::addon::AddonDetails, Result};
use isahc::prelude::*;

const API_ENDPOINT: &str = "https://api.wowinterface.com/addons";

/// Helper function to handle requests.
/// It might make sense to refactor this out in a seperate module later.
async fn request<T: ToString>(url: T, token: &str) -> Result<Response<isahc::Body>> {
    Ok(Request::get(url.to_string())
        .timeout(std::time::Duration::from_secs(20))
        .header("x-api-token", token)
        .header("Content-Type", "application/json")
        .body(())?
        .send()?)
}

/// Function to fetch details for addon from `warcraftinterface.com`
/// Note: When fetching details for a addon, result might return multiple patches,
/// which is why the return is a `Vec<_>`
pub async fn get_addon_details(id: &str, token: &str) -> Result<Vec<AddonDetails>> {
    let url = format!("{}/details/{}.json", API_ENDPOINT, id);
    let mut resp = request(url, token).await?;

    if resp.status().is_success() {
        let addon_details: Vec<AddonDetails> = resp.json()?;
        Ok(addon_details)
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
