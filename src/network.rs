use crate::{config::Config, Result};
use isahc::prelude::*;

pub async fn request<T: ToString>(url: T, config: Config) -> Result<Response<isahc::Body>> {
    Ok(Request::get(url.to_string())
        .timeout(std::time::Duration::from_secs(20))
        .header("x-api-token", config.wow_interface_token)
        .header("Content-Type", "application/json")
        .body(())?
        .send()?)
}
