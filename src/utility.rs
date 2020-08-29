use crate::{network::request_async, Result, VERSION};
use isahc::prelude::*;
use regex::Regex;
use serde::Deserialize;

/// Takes a `&str` and strips any non-digit.
/// This is used to unify and compare addon versions:
///
/// A string looking like 213r323 would return 213323.
/// A string looking like Rematch_4_10_15.zip would return 41015.
pub fn strip_non_digits(string: &str) -> Option<String> {
    let re = Regex::new(r"[\D]").unwrap();
    let stripped = re.replace_all(string, "").to_string();
    Some(stripped)
}

#[derive(Deserialize)]
struct Release {
    tag_name: String,
}

pub async fn needs_update() -> Result<Option<String>> {
    let mut resp = request_async(
        "https://api.github.com/repos/casperstorm/ajour/releases/latest",
        vec![],
        None,
    )
    .await?;

    let release: Release = resp.json()?;

    if release.tag_name != VERSION {
        Ok(Some(release.tag_name))
    } else {
        Ok(None)
    }
}
