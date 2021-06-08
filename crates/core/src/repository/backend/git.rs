use crate::config::Flavor;
use crate::error::{DownloadError, RepositoryError};
use crate::repository::RepositoryPackage;

use futures::future::join_all;
use isahc::http::Uri;

pub use github::Github;
pub use gitlab::Gitlab;

pub(crate) async fn batch_fetch_repo_packages(
    flavor: Flavor,
    git_urls: &[String],
) -> Result<Vec<RepositoryPackage>, DownloadError> {
    let mut git_repo_packages = vec![];

    if git_urls.is_empty() {
        return Ok(git_repo_packages);
    }

    let fetch_tasks = git_urls
        .iter()
        .map(|url| {
            let url = url
                .parse::<Uri>()
                .map_err(|_| RepositoryError::GitInvalidUrl { url: url.clone() })?;

            RepositoryPackage::from_source_url(flavor, url)
        })
        .filter_map(|result| match result {
            Ok(package) => Some(package),
            Err(e) => {
                log::error!("{}", e);
                None
            }
        })
        .map(|mut package| async {
            if let Err(e) = package.resolve_metadata().await {
                log::error!("{}", e);
                Err(e)
            } else {
                Ok(package)
            }
        });

    git_repo_packages.extend(
        join_all(fetch_tasks)
            .await
            .into_iter()
            .filter_map(Result::ok),
    );

    Ok(git_repo_packages)
}

mod github {
    use crate::config::Flavor;
    use crate::error::RepositoryError;
    use crate::network::request_async;
    use crate::repository::{Backend, ReleaseChannel, RemotePackage, RepositoryMetadata};

    use async_trait::async_trait;
    use chrono::{DateTime, Utc};
    use isahc::http::Uri;
    use isahc::AsyncReadResponseExt;
    use serde::Deserialize;

    use std::collections::HashMap;

    #[derive(Debug, Clone)]
    pub struct Github {
        pub url: Uri,
        pub flavor: Flavor,
    }

    #[async_trait]
    impl Backend for Github {
        async fn get_metadata(&self) -> Result<RepositoryMetadata, RepositoryError> {
            let mut path = self.url.path().split('/');
            // Get rid of leading slash
            path.next();

            let author = path.next().ok_or(RepositoryError::GitMissingAuthor {
                url: self.url.to_string(),
            })?;
            let repo = path.next().ok_or(RepositoryError::GitMissingRepo {
                url: self.url.to_string(),
            })?;

            let url = format!("https://api.github.com/repos/{}/{}/releases", author, repo);

            let mut resp = request_async(&url, vec![], None).await?;

            let releases: Vec<Release> = resp
                .json()
                .await
                .map_err(|_| RepositoryError::GitMissingRelease { url: url.clone() })?;

            let stable_release = releases.iter().find(|r| !r.prerelease);
            let beta_release = releases.iter().find(|r| r.prerelease);

            if stable_release.is_none() && beta_release.is_none() {
                return Err(RepositoryError::GitMissingRelease { url: url.clone() });
            }

            let mut remote_packages = HashMap::new();

            if let Some(release) = stable_release {
                set_remote_package(
                    self.flavor,
                    &url,
                    &mut remote_packages,
                    ReleaseChannel::Stable,
                    release,
                )?;
            }

            if let Some(release) = beta_release {
                set_remote_package(
                    self.flavor,
                    &url,
                    &mut remote_packages,
                    ReleaseChannel::Beta,
                    release,
                )?;
            }

            // URL passed in by user might not be the correct letter casing. Let's
            // use the url from the API response instead to ensure the title we
            // use for the addon has the correct letter casing.
            let title = {
                let release = if stable_release.is_some() {
                    stable_release.unwrap()
                } else {
                    beta_release.unwrap()
                };

                let html_url = release.html_url.parse::<Uri>()?;

                let mut path = html_url.path().split('/');
                path.next();
                path.next();

                path.next()
                    .ok_or(RepositoryError::GitMissingRepo {
                        url: self.url.to_string(),
                    })?
                    .to_string()
            };

            let metadata = RepositoryMetadata {
                website_url: Some(self.url.to_string()),
                changelog_url: Some(format!("{}/releases", self.url)),
                remote_packages,
                title: Some(title),
                ..Default::default()
            };

            Ok(metadata)
        }

        async fn get_changelog(
            &self,
            _file_id: Option<i64>,
            tag_name: Option<String>,
        ) -> Result<Option<String>, RepositoryError> {
            let tag_name = tag_name.ok_or(RepositoryError::GitChangelogTagName)?;

            let mut path = self.url.path().split('/');
            // Get rid of leading slash
            path.next();

            let author = path.next().ok_or(RepositoryError::GitMissingAuthor {
                url: self.url.to_string(),
            })?;
            let repo = path.next().ok_or(RepositoryError::GitMissingRepo {
                url: self.url.to_string(),
            })?;

            let url = format!(
                "https://api.github.com/repos/{}/{}/releases/tags/{}",
                author, repo, tag_name
            );

            let mut resp = request_async(&url, vec![], None).await?;

            let release: Release = resp
                .json()
                .await
                .map_err(|_| RepositoryError::GitMissingRelease { url })?;

            Ok(Some(release.body))
        }
    }

    fn set_remote_package(
        flavor: Flavor,
        url: &str,
        remote_packages: &mut HashMap<ReleaseChannel, RemotePackage>,
        release_channel: ReleaseChannel,
        release: &Release,
    ) -> Result<(), RepositoryError> {
        let num_non_classic = release
            .assets
            .iter()
            .filter(|a| a.name.ends_with("zip"))
            .filter(|a| !a.name.to_lowercase().contains("classic"))
            .count();

        let num_classic = release
            .assets
            .iter()
            .filter(|a| a.name.ends_with("zip"))
            .filter(|a| a.name.to_lowercase().contains("classic"))
            .count();

        if flavor.base_flavor() == Flavor::Retail && num_non_classic > 1
            || flavor.base_flavor() == Flavor::ClassicEra && num_classic == 0 && num_non_classic > 1
        {
            return Err(RepositoryError::GitIndeterminableZip {
                count: num_non_classic,
                url: url.to_string(),
            });
        } else if flavor.base_flavor() == Flavor::ClassicEra && num_classic > 1 {
            return Err(RepositoryError::GitIndeterminableZipClassic {
                count: num_classic,
                url: url.to_string(),
            });
        }

        let asset = release
            .assets
            .iter()
            .find(|a| {
                if flavor.base_flavor() == Flavor::Retail {
                    a.name.ends_with("zip") && !a.name.to_lowercase().contains("classic")
                } else if num_classic > 0 {
                    a.name.ends_with("zip") && a.name.to_lowercase().contains("classic")
                } else {
                    a.name.ends_with("zip")
                }
            })
            .ok_or(RepositoryError::GitNoZip {
                url: url.to_string(),
            })?;

        let version = release.tag_name.clone();
        let download_url = asset.browser_download_url.clone();
        let date_time = Some(release.published_at);

        let remote_package = RemotePackage {
            version,
            download_url,
            date_time,
            file_id: None,
            modules: vec![],
        };

        remote_packages.insert(release_channel, remote_package);

        Ok(())
    }

    #[derive(Debug, Deserialize, Clone)]
    pub struct Release {
        pub tag_name: String,
        pub published_at: DateTime<Utc>,
        pub prerelease: bool,
        pub html_url: String,
        pub body: String,
        pub assets: Vec<ReleaseAsset>,
    }

    #[derive(Debug, Deserialize, Clone)]
    pub struct ReleaseAsset {
        pub name: String,
        pub browser_download_url: String,
    }
}

mod gitlab {
    use crate::config::Flavor;
    use crate::error::RepositoryError;
    use crate::network::request_async;
    use crate::repository::{Backend, ReleaseChannel, RemotePackage, RepositoryMetadata};

    use async_trait::async_trait;
    use chrono::{DateTime, Utc};
    use isahc::http::Uri;
    use isahc::AsyncReadResponseExt;
    use serde::Deserialize;

    use std::collections::HashMap;

    #[derive(Debug, Clone)]
    pub struct Gitlab {
        pub url: Uri,
        pub flavor: Flavor,
    }

    #[async_trait]
    impl Backend for Gitlab {
        async fn get_metadata(&self) -> Result<RepositoryMetadata, RepositoryError> {
            let mut path = self.url.path();
            // Remove leading slash
            path = path.trim_start_matches('/');

            // Encode entire path for API
            let encoded = urlencoding::encode(path);

            // Get last path part as repo name
            let path_parts = path.split('/');
            let repo = path_parts.last().ok_or(RepositoryError::GitMissingRepo {
                url: self.url.to_string(),
            })?;

            let url = format!("https://gitlab.com/api/v4/projects/{}/releases", &encoded);

            let mut resp = request_async(&url, vec![], None).await?;

            let releases: Vec<Release> = resp
                .json()
                .await
                .map_err(|_| RepositoryError::GitMissingRelease { url: url.clone() })?;
            let release = releases
                .get(0)
                .ok_or(RepositoryError::GitMissingRelease { url: url.clone() })?;

            let version = release.tag_name.clone();

            let num_non_classic = release
                .assets
                .links
                .iter()
                .filter(|a| a.name.ends_with("zip"))
                .filter(|a| !a.name.to_lowercase().contains("classic"))
                .count();
            let num_classic = release
                .assets
                .links
                .iter()
                .filter(|a| a.name.ends_with("zip"))
                .filter(|a| a.name.to_lowercase().contains("classic"))
                .count();

            if self.flavor.base_flavor() == Flavor::Retail && num_non_classic > 1
                || self.flavor.base_flavor() == Flavor::ClassicEra
                    && num_classic == 0
                    && num_non_classic > 1
            {
                return Err(RepositoryError::GitIndeterminableZip {
                    count: num_non_classic,
                    url: url.clone(),
                });
            } else if self.flavor.base_flavor() == Flavor::ClassicEra && num_classic > 1 {
                return Err(RepositoryError::GitIndeterminableZipClassic {
                    count: num_classic,
                    url,
                });
            }

            let asset = release
                .assets
                .links
                .iter()
                .find(|a| {
                    if self.flavor.base_flavor() == Flavor::Retail {
                        a.name.ends_with("zip") && !a.name.to_lowercase().contains("classic")
                    } else if num_classic > 0 {
                        a.name.ends_with("zip") && a.name.to_lowercase().contains("classic")
                    } else {
                        a.name.ends_with("zip")
                    }
                })
                .ok_or(RepositoryError::GitNoZip { url })?;

            let download_url = asset.url.clone();
            let date_time = Some(release.released_at);

            let mut remote_packages = HashMap::new();
            let remote_package = RemotePackage {
                version: version.clone(),
                download_url,
                date_time,
                file_id: None,
                modules: vec![],
            };

            remote_packages.insert(ReleaseChannel::Stable, remote_package);

            let metadata = RepositoryMetadata {
                website_url: Some(self.url.to_string()),
                changelog_url: Some(format!("{}/-/tags/{}", self.url, version)),
                remote_packages,
                title: Some(repo.to_string()),
                ..Default::default()
            };

            Ok(metadata)
        }

        async fn get_changelog(
            &self,
            _file_id: Option<i64>,
            tag_name: Option<String>,
        ) -> Result<Option<String>, RepositoryError> {
            let tag_name = tag_name.ok_or(RepositoryError::GitChangelogTagName)?;

            let mut path = self.url.path();
            // Remove leading slash
            path = path.trim_start_matches('/');

            // Encode entire path for API
            let encoded = urlencoding::encode(path);

            let url = format!(
                "https://gitlab.com/api/v4/projects/{}/releases/{}",
                encoded, tag_name
            );

            let mut resp = request_async(&url, vec![], None).await?;

            let release: Release = resp
                .json()
                .await
                .map_err(|_| RepositoryError::GitMissingRelease { url })?;

            Ok(Some(release.description))
        }
    }

    #[derive(Debug, Deserialize, Clone)]
    pub struct Release {
        pub tag_name: String,
        pub description: String,
        pub released_at: DateTime<Utc>,
        pub assets: ReleaseAssets,
        pub upcoming_release: bool,
        pub tag_path: String,
    }

    #[derive(Debug, Deserialize, Clone)]
    pub struct ReleaseAssets {
        pub count: u8,
        pub links: Vec<ReleaseLink>,
    }

    #[derive(Debug, Deserialize, Clone)]
    pub struct ReleaseLink {
        pub name: String,
        pub url: String,
    }
}
