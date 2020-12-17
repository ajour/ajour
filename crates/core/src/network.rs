use crate::addon::Addon;
use crate::error::DownloadError;
use crate::repository::GlobalReleaseChannel;
use async_std::{
    fs::{create_dir_all, File},
    io::copy,
};
use isahc::config::RedirectPolicy;
use isahc::http::header::CONTENT_LENGTH;
use isahc::prelude::*;
use serde::Serialize;
use std::path::PathBuf;

lazy_static::lazy_static! {
    /// Shared `HttpClient`.
    static ref HTTP_CLIENT: HttpClient = HttpClient::builder().redirect_policy(RedirectPolicy::Follow).max_connections_per_host(6).build().unwrap();
}

/// Ajour user-agent.
fn user_agent() -> String {
    format!("ajour/{}", env!("CARGO_PKG_VERSION"))
}

/// Generic request function.
pub async fn request_async<T: ToString>(
    url: T,
    headers: Vec<(&str, &str)>,
    timeout: Option<u64>,
) -> Result<Response<isahc::Body>, DownloadError> {
    // Sometimes a download url has a space.
    let url = url.to_string().replace(" ", "%20");

    let mut request = Request::builder().uri(url);

    for (name, value) in headers {
        request = request.header(name, value);
    }

    request = request.header("user-agent", &user_agent());

    if let Some(timeout) = timeout {
        request = request.timeout(std::time::Duration::from_secs(timeout));
    }

    Ok(HTTP_CLIENT.send_async(request.body(())?).await?)
}

// Generic function for posting Json data
pub(crate) async fn post_json_async<T: ToString, D: Serialize>(
    url: T,
    data: D,
    headers: Vec<(&str, &str)>,
    timeout: Option<u64>,
) -> Result<Response<isahc::Body>, DownloadError> {
    let mut request = Request::builder()
        .method("POST")
        .uri(url.to_string())
        .header("content-type", "application/json");

    for (name, value) in headers {
        request = request.header(name, value);
    }

    request = request.header("user-agent", &user_agent());

    if let Some(timeout) = timeout {
        request = request.timeout(std::time::Duration::from_secs(timeout));
    }

    Ok(HTTP_CLIENT
        .send_async(request.body(serde_json::to_vec(&data)?)?)
        .await?)
}

/// Function to download a zip archive for a `Addon`.
/// Note: Addon needs to have a `remote_url` to the file.
pub async fn download_addon(
    addon: &Addon,
    global_release_channel: GlobalReleaseChannel,
    to_directory: &PathBuf,
) -> Result<(), DownloadError> {
    let package =
        if let Some(relevant_package) = addon.relevant_release_package(global_release_channel) {
            Some(relevant_package)
        } else if let Some(fallback_package) = addon.fallback_release_package() {
            Some(fallback_package)
        } else {
            None
        };

    if let Some(package) = package {
        log::debug!(
            "downloading remote version {} for {}",
            package.version,
            &addon.primary_folder_id
        );
        let resp = request_async(package.download_url.clone(), vec![], None).await?;
        let (parts, mut body) = resp.into_parts();

        // If response length doesn't equal content length, full file wasn't downloaded
        // so error out
        {
            let content_length = parts
                .headers
                .get(CONTENT_LENGTH)
                .map(|v| v.to_str().unwrap_or_default())
                .unwrap_or_default()
                .parse::<u64>()
                .unwrap_or_default();

            let body_length = body.len().unwrap_or_default();

            if body_length != content_length {
                return Err(DownloadError::ContentLength {
                    content_length,
                    body_length,
                });
            }
        }

        if !to_directory.exists() {
            create_dir_all(to_directory).await?;
        }

        let zip_path = to_directory.join(&addon.primary_folder_id);
        let mut file = File::create(&zip_path).await?;

        copy(&mut body, &mut file).await?;
    }

    Ok(())
}

/// Download a file from the internet
pub(crate) async fn download_file<T: ToString>(
    url: T,
    dest_file: &PathBuf,
) -> Result<(), DownloadError> {
    let url = url.to_string();

    log::debug!("downloading file from {}", &url);

    let resp = request_async(&url, vec![("ACCEPT", "application/octet-stream")], None).await?;
    let (parts, mut body) = resp.into_parts();

    // If response length doesn't equal content length, full file wasn't downloaded
    // so error out
    {
        let content_length = parts
            .headers
            .get(CONTENT_LENGTH)
            .map(|v| v.to_str().unwrap_or_default())
            .unwrap_or_default()
            .parse::<u64>()
            .unwrap_or_default();

        let body_length = body.len().unwrap_or_default();

        if body_length != content_length {
            return Err(DownloadError::ContentLength {
                content_length,
                body_length,
            });
        }
    }

    let mut file = File::create(&dest_file).await?;

    copy(&mut body, &mut file).await?;

    log::debug!("file saved as {:?}", &dest_file);

    Ok(())
}
