use crate::error::DownloadError;
#[cfg(target_os = "macos")]
use crate::error::FilesystemError;
use crate::network::{download_file, request_async};

use isahc::prelude::*;
use regex::Regex;
use retry::delay::Fibonacci;
use retry::{retry, Error as RetryError, OperationResult};
use serde::Deserialize;

use std::ffi::OsStr;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

/// Takes a `&str` and strips any non-digit.
/// This is used to unify and compare addon versions:
///
/// A string looking like 213r323 would return 213323.
/// A string looking like Rematch_4_10_15.zip would return 41015.
pub(crate) fn strip_non_digits(string: &str) -> Option<String> {
    let re = Regex::new(r"[\D]").unwrap();
    let stripped = re.replace_all(string, "").to_string();
    Some(stripped)
}

pub(crate) fn truncate(s: &str, max_chars: usize) -> &str {
    match s.char_indices().nth(max_chars) {
        None => s,
        Some((idx, _)) => &s[..idx],
    }
}

pub(crate) fn regex_html_tags_to_newline() -> Regex {
    regex::Regex::new(r"<br ?/?>|#.\s").unwrap()
}

pub(crate) fn regex_html_tags_to_space() -> Regex {
    regex::Regex::new(r"<[^>]*>|&#?\w+;|[gl]t;").unwrap()
}

#[derive(Debug, Deserialize, Clone)]
pub struct Release {
    pub tag_name: String,
    pub assets: Vec<ReleaseAsset>,
    pub body: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ReleaseAsset {
    pub name: String,
    #[serde(rename = "browser_download_url")]
    pub download_url: String,
}

pub async fn get_latest_release() -> Option<Release> {
    log::debug!("checking for application update");

    let client = HttpClient::new().ok()?;

    let mut resp = request_async(
        &client,
        "https://api.github.com/repos/casperstorm/ajour/releases/latest",
        vec![],
        None,
    )
    .await
    .ok()?;

    Some(resp.json().ok()?)
}

/// Downloads the latest release file that matches `bin_name` and saves it as
/// `tmp_bin_name`. Will return the temp file as pathbuf.
pub async fn download_update_to_temp_file(
    bin_name: String,
    release: Release,
) -> Result<(String, PathBuf), DownloadError> {
    #[cfg(not(target_os = "linux"))]
    let current_bin_path = std::env::current_exe()?;

    #[cfg(target_os = "linux")]
    let current_bin_path = PathBuf::from(
        std::env::var("APPIMAGE")
            .map_err(|e| error!("error getting APPIMAGE env variable: {:?}", e))?,
    );

    let current_bin_name = current_bin_path
        .file_name()
        .unwrap()
        .to_str()
        .unwrap()
        .to_owned();

    let new_bin_path = current_bin_path
        .parent()
        .unwrap()
        .join(&format!("tmp_{}", bin_name));

    // On macos, we actually download an archive with the new binary inside. Let's extract
    // that file and remove the archive.
    #[cfg(target_os = "macos")]
    {
        let asset_name = format!("{}-macos.tar.gz", bin_name);

        let asset = release
            .assets
            .iter()
            .find(|a| a.name == asset_name)
            .cloned()
            .ok_or_else(|| DownloadError::MissingSelfUpdateRelease { bin_name })?;

        let archive_path = current_bin_path.parent().unwrap().join(&asset_name);

        download_file(&asset.download_url, &archive_path).await?;

        extract_binary_from_tar(&archive_path, &new_bin_path, "ajour")?;

        std::fs::remove_file(&archive_path)?;
    }

    // For windows & linux, we download the new binary directly
    #[cfg(not(target_os = "macos"))]
    {
        let asset = release
            .assets
            .iter()
            .find(|a| a.name == bin_name)
            .cloned()
            .ok_or_else(|| DownloadError::MissingSelfUpdateRelease { bin_name })?;

        download_file(&asset.download_url, &new_bin_path).await?;
    }

    // Make executable
    #[cfg(not(target_os = "windows"))]
    {
        use async_std::fs;
        use std::os::unix::fs::PermissionsExt;

        let mut permissions = fs::metadata(&new_bin_path).await?.permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(&new_bin_path, permissions).await?;
    }

    Ok((current_bin_name, new_bin_path))
}

/// Extracts the Ajour binary from a `tar.gz` archive to temp_file path
#[cfg(target_os = "macos")]
fn extract_binary_from_tar(
    archive_path: &PathBuf,
    temp_file: &PathBuf,
    bin_name: &str,
) -> Result<(), FilesystemError> {
    use flate2::read::GzDecoder;
    use std::fs::File;
    use std::io::copy;
    use tar::Archive;

    let mut archive = Archive::new(GzDecoder::new(File::open(&archive_path)?));

    let mut temp_file = File::create(temp_file)?;

    for file in archive.entries()? {
        let mut file = file?;

        let path = file.path()?;

        if let Some(name) = path.to_str() {
            if name == bin_name {
                copy(&mut file, &mut temp_file)?;

                return Ok(());
            }
        }
    }

    Err(FilesystemError::BinMissingFromTar {
        bin_name: bin_name.to_owned(),
    })
}

/// Logic to help pick the right World of Warcraft folder. We want the root folder.
pub fn wow_path_resolution(path: Option<PathBuf>) -> Option<PathBuf> {
    if let Some(path) = path {
        // Known folders in World of Warcraft dir
        let known_folders = ["_retail_", "_classic_", "_ptr_"];

        // If chosen path has any of the known Wow folders, we have the right one.
        for folder in known_folders.iter() {
            if path.join(folder).exists() {
                return Some(path);
            }
        }

        // Iterate ancestors. If we find any of the known folders we can guess the root.
        for ancestor in path.as_path().ancestors() {
            if let Some(file_name) = ancestor.file_name() {
                for folder in known_folders.iter() {
                    if file_name == OsStr::new(folder) {
                        return ancestor.parent().map(|p| p.to_path_buf());
                    }
                }
            }
        }
    }

    None
}

/// Rename a file or directory to a new name, retrying if the operation fails because of permissions
///
/// Will retry for ~30 seconds with longer and longer delays between each, to allow for virus scan
/// and other automated operations to complete.
pub fn rename<F, T>(from: F, to: T) -> io::Result<()>
where
    F: AsRef<Path>,
    T: AsRef<Path>,
{
    // 21 Fibonacci steps starting at 1 ms is ~28 seconds total
    // See https://github.com/rust-lang/rustup/pull/1873 where this was used by Rustup to work around
    // virus scanning file locks
    let from = from.as_ref();
    let to = to.as_ref();

    retry(Fibonacci::from_millis(1).take(21), || {
        match fs::rename(from, to) {
            Ok(_) => OperationResult::Ok(()),
            Err(e) => match e.kind() {
                io::ErrorKind::PermissionDenied => OperationResult::Retry(e),
                _ => OperationResult::Err(e),
            },
        }
    })
    .map_err(|e| match e {
        RetryError::Operation { error, .. } => error,
        RetryError::Internal(message) => io::Error::new(io::ErrorKind::Other, message),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wow_path_resolution() {
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
