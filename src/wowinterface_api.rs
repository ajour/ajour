use std::path::{Path, PathBuf};
use async_std::{fs::File, prelude::*};
use crate::{error::ClientError, toc::addon::{Addon, AddonDetails}, Result};
use isahc::{config::RedirectPolicy, prelude::*};

const API_ENDPOINT: &str = "https://api.wowinterface.com/addons";
const DL_ENDPOINT: &str = "https://cdn.wowinterface.com/downloads/getfile.php?id=";

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
pub async fn fetch_addon_details(id: &str, token: &str) -> Result<Vec<AddonDetails>> {
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

/// TBA.
pub async fn download_addon(addon: &Addon) -> Result<()> {
    let wowi_id = addon.wowi_id.clone().unwrap();
    let filename = addon.remote_filename.clone().unwrap();

    let mut response = Request::get(format!("{}{}", DL_ENDPOINT, wowi_id))
        .metrics(true)
        .redirect_policy(RedirectPolicy::Follow)
        .body(())?
        .send()?;

    let zip_path = PathBuf::from("/tmp").join(filename);

    let body = response.body_mut();
    let mut buffer = [0; 8000]; // 8KB
    let mut file = File::create(&zip_path)
        .await
        .expect("failed to create file for download!");

    loop {
        match body.read(&mut buffer).await {
            Ok(0) => {
                break;
            }
            Ok(x) => {
                file.write_all(&buffer[0..x])
                    .await
                    // TODO: deal with this error!
                    .expect("TODO: error handling");
                for i in 0..x {
                    buffer[i] = 0;
                }
            }
            Err(e) => {
                println!("error: {:?}", e);
                break;
            }
        }
    }

    // TODO: få filename
    // TODO: få temp-dir fra config
    // TODO: brug metrics
    // TODO: find ud af om der er racecondition
    // TODO: update gui
    // TODO: unpack, move and cleanup

    Ok(())
}
