use crate::{
    addon::Addon,
    config::Flavor,
    error::ClientError,
    network::request_async,
    utility::{regex_html_tags_to_newline, regex_html_tags_to_space, truncate},
    Result,
};
use isahc::config::RedirectPolicy;
use isahc::prelude::*;
use serde::Deserialize;
use std::path::PathBuf;

#[derive(Clone, Debug, Deserialize)]
/// Struct for applying tukui details to an `Addon`.
pub struct TukuiPackage {
    pub name: String,
    pub version: String,
    pub url: String,
    pub web_url: String,
    pub lastupdate: String,
    pub patch: Option<String>,
    pub author: Option<String>,
    pub small_desc: Option<String>,
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

fn changelog_endpoint(id: &str, flavor: &Flavor) -> String {
    match flavor {
        Flavor::Retail => match id {
            "-1" => "https://www.tukui.org/ui/tukui/changelog".to_owned(),
            "-2" => "https://www.tukui.org/ui/elvui/changelog".to_owned(),
            _ => format!("https://www.tukui.org/addons.php?id={}&changelog", id),
        },
        Flavor::Classic => format!(
            "https://www.tukui.org/classic-addons.php?id={}&changelog",
            id
        ),
    }
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub async fn fetch_remote_package(id: &str, flavor: &Flavor) -> Result<TukuiPackage> {
    let client = HttpClient::builder()
        .redirect_policy(RedirectPolicy::Follow)
        .max_connections_per_host(6)
        .build()
        .unwrap();
    let url = api_endpoint(id, flavor);
    let timeout = Some(30);
    let mut resp = request_async(&client, &url, vec![], timeout).await?;

    if resp.status().is_success() {
        let package = resp.json()?;
        Ok(package)
    } else {
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}

pub async fn latest_stable_addon_from_id(
    tukui_id: u32,
    mut addon: Addon,
    mut addon_path: PathBuf,
    flavor: Flavor,
) -> Result<(u32, Flavor, Addon)> {
    let tukui_id_string = tukui_id.to_string();

    let package = fetch_remote_package(&tukui_id_string, &flavor).await?;

    addon_path.push(&package.name);

    addon.title = package.name.clone();
    addon.id = package.name.clone();
    addon.author = package.author.clone();
    addon.notes = package.small_desc.clone();
    addon.tukui_id = Some(tukui_id_string);
    addon.path = addon_path;

    addon.apply_tukui_package(&package);

    Ok((tukui_id, flavor, addon))
}

pub async fn fetch_changelog(id: &str, flavor: &Flavor) -> Result<(String, String)> {
    let url = changelog_endpoint(id, &flavor);

    match flavor {
        Flavor::Retail => {
            // Only TukUI and ElvUI main addons has changelog which can be fetched.
            // The others is embeded into a page.
            if id == "-1" || id == "-2" {
                let client = HttpClient::builder().build().unwrap();
                let mut resp = request_async(&client, &url.clone(), vec![], None).await?;

                if resp.status().is_success() {
                    let changelog: String = resp.text()?;

                    let c = regex_html_tags_to_newline()
                        .replace_all(&changelog, "\n")
                        .to_string();
                    let c = regex_html_tags_to_space().replace_all(&c, "").to_string();
                    let c = truncate(&c, 2500).to_string();

                    return Ok((c, url));
                }

                return Ok(("No changelog found".to_string(), url));
            }

            return Ok(("Please view this changelog in the browser by pressing 'Full Changelog' to the right".to_string(), url));
        }
        Flavor::Classic => {
            return Ok(("Please view this changelog in the browser by pressing 'Full Changelog' to the right".to_string(), url));
        }
    }
}
