use crate::{addon::Addon, Result};
use async_std::{fs::File, prelude::*};
use isahc::prelude::*;
use isahc::{config::RedirectPolicy, prelude::*};
use std::path::PathBuf;

/// Generic request function.
pub fn request<T: ToString>(url: T, headers: Vec<(&str, &str)>) -> Result<Response<isahc::Body>> {
    let mut r = Request::get(url.to_string()).timeout(std::time::Duration::from_secs(20));
    let mut r = Request::get(url.to_string())
        .redirect_policy(RedirectPolicy::Follow)
        .timeout(std::time::Duration::from_secs(20));

    for (name, value) in headers {
        r = r.header(name, value);
    }

    Ok(r.body(())?.send()?)
}

/// Function to download a zip archive for a `Addon`.
/// Note: Addon needs to have a `remote_url` to the file.
pub async fn download_addon(addon: &Addon, to_directory: &PathBuf) -> Result<()> {
    // TODO: clone shouldn't be needed here.
    let filename = addon.id.clone();
    let url = addon.remote_url.clone().unwrap();
    let mut resp = request(url, Vec::new())?;
    let body = resp.body_mut();
    let zip_path = to_directory.join(filename);
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
