use crate::{addon::Addon, Result};
use async_std::{fs::File, prelude::*};
use isahc::prelude::*;
use serde::Serialize;
use std::path::PathBuf;

/// Generic request function.
pub async fn request_async<T: ToString>(
    shared_client: &HttpClient,
    url: T,
    headers: Vec<(&str, &str)>,
    timeout: Option<u64>,
) -> Result<Response<isahc::Body>> {
    // Sometimes a download url has a space.
    let url = url.to_string().replace(" ", "%20");

    let mut request = Request::builder().uri(url);

    for (name, value) in headers {
        request = request.header(name, value);
    }

    if let Some(timeout) = timeout {
        request = request.timeout(std::time::Duration::from_secs(timeout));
    }

    Ok(shared_client.send_async(request.body(())?).await?)
}

// Generic function for posting Json data
pub async fn post_json_async<T: ToString, D: Serialize>(
    url: T,
    data: D,
    headers: Vec<(&str, &str)>,
    timeout: Option<u64>,
) -> Result<Response<isahc::Body>> {
    let mut request = Request::builder()
        .method("POST")
        .uri(url.to_string())
        .header("content-type", "application/json");

    for (name, value) in headers {
        request = request.header(name, value);
    }

    if let Some(timeout) = timeout {
        request = request.timeout(std::time::Duration::from_secs(timeout));
    }

    Ok(request
        .body(serde_json::to_vec(&data)?)?
        .send_async()
        .await?)
}

/// Function to download a zip archive for a `Addon`.
/// Note: Addon needs to have a `remote_url` to the file.
pub async fn download_addon(
    shared_client: &HttpClient,
    addon: &Addon,
    to_directory: &PathBuf,
) -> Result<()> {
    log::debug!(
        "downloading remote version {} for {}",
        addon.remote_version.as_deref().unwrap_or_default(),
        &addon.id
    );

    if let Some(url) = addon.remote_download_url.clone() {
        let mut resp = request_async(shared_client, url, vec![], None).await?;
        let body = resp.body_mut();
        let zip_path = to_directory.join(&addon.id);
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
                        .expect("TODO: error handling");
                }
                Err(e) => {
                    println!("error: {:?}", e);
                    break;
                }
            }
        }
    }

    Ok(())
}
