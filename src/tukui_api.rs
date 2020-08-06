use crate::{
    error::ClientError,
    toc::{Addon, AddonDetails},
    Result,
};
use async_std::{fs::File, prelude::*};
use isahc::{config::RedirectPolicy, prelude::*};
use std::path::PathBuf;

/// Helper function to handle requests.
/// TODO: It might make sense to refactor this out in a seperate module later.
async fn request<T: ToString>(url: T) -> Result<Response<isahc::Body>> {
    Ok(Request::get(url.to_string())
        .timeout(std::time::Duration::from_secs(20))
        .header("Content-Type", "application/json")
        .body(())?
        .send()?)
}

fn api_endpoint(id: &str) -> String {
    match id {
        "-1" => "https://www.tukui.org/api.php?ui=tukui".to_owned(),
        "-2" => "https://www.tukui.org/api.php?ui=elvui".to_owned(),
        _    => format!("https://www.tukui.org/api.php?addon={}", id)
    }
}

fn typeid<T: std::any::Any>(_: &T) {
    println!("{:?}", std::any::TypeId::of::<T>());
}

pub async fn fetch_addon_details(id: &str) -> Result<Vec<AddonDetails>> {
    let url = api_endpoint(id);
    let mut resp = request(&url).await?;

    println!("url: {:?}", &url);
    println!("resp: {:?}", &resp);

    // Err(ClientError::Custom("testing".to_owned()))
    if resp.status().is_success() {
        let test: serde_json::Value = resp.json()?;
        typeid(&test["id"]);
        Err(ClientError::Custom("test".to_owned()))
        // let addon_details: Vec<AddonDetails> = resp.json()?;
        // Ok(addon_details)
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
