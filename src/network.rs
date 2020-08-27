use crate::{addon::Addon, Result};
use async_std::{fs::File, prelude::*};
use isahc::config::RedirectPolicy;
use isahc::prelude::*;
use std::path::PathBuf;

/// Generic request function.
pub async fn request_async<T: ToString>(
    url: T,
    headers: Vec<(&str, &str)>,
    timeout: Option<u64>,
) -> Result<Response<isahc::Body>> {
    // Edge case:
    // Sometimes a download url has a space.
    // FIXME: Can we do this more elegant?
    let url = url.to_string().replace(" ", "%20");
    let mut client = HttpClient::builder().redirect_policy(RedirectPolicy::Follow);

    for (name, value) in headers {
        client = client.default_header(name, value);
    }

    if let Some(timeout) = timeout {
        client = client.timeout(std::time::Duration::from_secs(timeout));
    }

    Ok(client.build()?.get_async(url.to_string()).await?)
}

/// Function to download a zip archive for a `Addon`.
/// Note: Addon needs to have a `remote_url` to the file.
pub async fn download_addon(addon: &Addon, to_directory: &PathBuf) -> Result<()> {
    let url = addon.remote_url.clone().unwrap();
    let mut resp = request_async(url, vec![], None).await?;
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

    Ok(())
}
