use crate::{
    addon::Addon,
    config::Flavor,
    error::ClientError,
    network::request_async,
    utility::{regex_html_tags_to_newline, regex_html_tags_to_space, truncate},
    Result,
};
use async_std::sync::Arc;
use isahc::config::RedirectPolicy;
use isahc::prelude::*;
use serde::Deserialize;

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
        Flavor::Retail | Flavor::RetailPTR | Flavor::RetailBeta => match id {
            "-1" => "https://www.tukui.org/api.php?ui=tukui".to_owned(),
            "-2" => "https://www.tukui.org/api.php?ui=elvui".to_owned(),
            _ => format!("https://www.tukui.org/api.php?addon={}", id),
        },
        Flavor::Classic | Flavor::ClassicPTR => {
            format!("https://www.tukui.org/api.php?classic-addon={}", id)
        }
    }
}

fn changelog_endpoint(id: &str, flavor: &Flavor) -> String {
    match flavor {
        Flavor::Retail | Flavor::RetailPTR | Flavor::RetailBeta => match id {
            "-1" => "https://www.tukui.org/ui/tukui/changelog".to_owned(),
            "-2" => "https://www.tukui.org/ui/elvui/changelog".to_owned(),
            _ => format!("https://www.tukui.org/addons.php?id={}&changelog", id),
        },
        Flavor::Classic | Flavor::ClassicPTR => format!(
            "https://www.tukui.org/classic-addons.php?id={}&changelog",
            id
        ),
    }
}

/// Function to fetch a remote addon package which contains
/// information about the addon on the repository.
pub async fn fetch_remote_package(
    shared_client: Arc<HttpClient>,
    id: &str,
    flavor: &Flavor,
) -> Result<(String, TukuiPackage)> {
    let url = api_endpoint(id, flavor);
    let timeout = Some(30);
    let mut resp = request_async(&shared_client, &url, vec![], timeout).await?;

    if resp.status().is_success() {
        let package = resp.json()?;
        Ok((id.to_string(), package))
    } else {
        Err(ClientError::Custom(format!(
            "Couldn't fetch details for addon. Server returned: {}",
            resp.text()?
        )))
    }
}

pub async fn latest_addon(tukui_id: i32, flavor: Flavor) -> Result<Addon> {
    let tukui_id_string = tukui_id.to_string();

    let client = Arc::new(
        HttpClient::builder()
            .redirect_policy(RedirectPolicy::Follow)
            .max_connections_per_host(6)
            .build()
            .unwrap(),
    );

    let (_, package) = fetch_remote_package(client, &tukui_id_string, &flavor).await?;

    let mut addon = Addon::empty(&tukui_id_string);
    // We assign the proper addon folders and primary folder id after unpacking the addon
    addon.update_with_tukui_package(tukui_id_string, &package, None);

    Ok(addon)
}

pub async fn fetch_changelog(id: &str, flavor: &Flavor) -> Result<(String, String)> {
    let url = changelog_endpoint(id, &flavor);

    match flavor {
        Flavor::Retail | Flavor::RetailBeta | Flavor::RetailPTR => {
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

            Ok(("Please view this changelog in the browser by pressing 'Full Changelog' to the right".to_string(), url))
        }
        Flavor::Classic | Flavor::ClassicPTR => Ok((
            "Please view this changelog in the browser by pressing 'Full Changelog' to the right"
                .to_string(),
            url,
        )),
    }
}
