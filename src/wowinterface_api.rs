use crate::{config::Config, error::ClientError, network::request, toc::addon::AddonPatch, Result};
use isahc::prelude::*;

const API_ENDPOINT: &str = "https://api.wowinterface.com/addons";

pub async fn get_addon_details(id: String, config: Config) -> Result<Vec<AddonPatch>> {
    let url = format!("{}/details/{}.json", API_ENDPOINT, id);
    let mut resp = request(url, config).await?;

    if resp.status().is_success() {
        let addon_patches: Vec<AddonPatch> = resp.json()?;
        Ok(addon_patches)
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
