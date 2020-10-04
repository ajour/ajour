use crate::{network::request_async, Result};
use isahc::prelude::*;
use regex::Regex;
use serde::Deserialize;
use std::ffi::OsStr;
use std::path::PathBuf;

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

pub async fn needs_update(current_version: &str) -> Result<Option<String>> {
    log::debug!("checking for application update");

    let client = HttpClient::new()?;

    let mut resp = request_async(
        &client,
        "https://api.github.com/repos/casperstorm/ajour/releases/latest",
        vec![],
        None,
    )
    .await?;

    let release: Release = resp.json()?;

    if release.tag_name != current_version {
        Ok(Some(release.tag_name))
    } else {
        Ok(None)
    }
}

/// Logic to help pick the right World of Warcraft folder. We want the root folder.
pub fn wow_path_resolution(path: Option<PathBuf>) -> Option<PathBuf> {
    if let Some(path) = path {
        // If chosen path has any of the known Wow folders, we have the right one.
        let known_folders = ["_retail_", "_classic_"];
        for folder in known_folders.iter() {
            if path.join(folder).exists() {
                return Some(path);
            }
        }

        // Iterate ancestors. If we find any of the known folders we can guess the root.
        for ancestor in path.as_path().ancestors() {
            if let Some(file_name) = ancestor.file_name() {
                if file_name == OsStr::new("_retail_") || file_name == OsStr::new("_classic_") {
                    return ancestor.parent().map(|p| p.to_path_buf());
                }
            }
        }
    }

    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wow_path() {
        // Tests known result

        let classic_addon_path =
            PathBuf::from(r"/Applications/World of Warcraft/_classic_/Interface/Addons");
        let retail_addon_path =
            PathBuf::from(r"/Applications/World of Warcraft/_retail_/Interface/Addons");
        let retail_interface_path =
            PathBuf::from(r"/Applications/World of Warcraft/_retail_/Interface");
        let classic_interface_path =
            PathBuf::from(r"/Applications/World of Warcraft/_classic_/Interface");
        let classic_alternate_path = PathBuf::from(r"/Applications/Wow/_classic_");

        let root_alternate_path = PathBuf::from(r"/Applications/Wow");
        let root_path = PathBuf::from(r"/Applications/World of Warcraft");

        assert_eq!(
            root_path.eq(&wow_path_resolution(Some(classic_addon_path)).unwrap()),
            true
        );
        assert_eq!(
            root_path.eq(&wow_path_resolution(Some(retail_addon_path)).unwrap()),
            true
        );
        assert_eq!(
            root_path.eq(&wow_path_resolution(Some(retail_interface_path)).unwrap()),
            true
        );
        assert_eq!(
            root_path.eq(&wow_path_resolution(Some(classic_interface_path)).unwrap()),
            true
        );
        assert_eq!(
            root_alternate_path.eq(&wow_path_resolution(Some(classic_alternate_path)).unwrap()),
            true
        );
    }
}
