pub use github::Github;
pub use gitlab::Gitlab;

mod github {
    use crate::config::Flavor;
    use crate::error;
    use crate::network::request_async;
    use crate::repository::{Backend, ReleaseChannel, RemotePackage, RepositoryMetadata};
    use crate::Result;

    use async_trait::async_trait;
    use chrono::{DateTime, Utc};
    use isahc::http::Uri;
    use isahc::prelude::*;
    use serde::Deserialize;

    use std::collections::HashMap;

    #[derive(Debug, Clone)]
    pub struct Github {
        pub url: Uri,
        pub flavor: Flavor,
    }

    #[async_trait]
    impl Backend for Github {
        async fn get_metadata(&self) -> Result<RepositoryMetadata> {
            let client = HttpClient::new()?;

            let mut path = self.url.path().split('/');
            // Get rid of leading slash
            path.next();

            let author = path
                .next()
                .ok_or_else(|| error!("author not present in url: {:?}", self.url))?;
            let repo = path
                .next()
                .ok_or_else(|| error!("repo not present in url: {:?}", self.url))?;

            let url = format!(
                "https://api.github.com/repos/{}/{}/releases/latest",
                author, repo
            );

            let mut resp = request_async(&client, &url, vec![], None).await?;

            let release: Release = resp.json()?;
            let asset = release
                .assets
                .iter()
                .find(|f| f.name.ends_with(".zip"))
                .ok_or_else(|| error!("No zip asset for {}", &url))?;

            let version = release.tag_name.clone();
            let download_url = asset.browser_download_url.clone();
            let date_time = Some(release.published_at);

            let mut remote_packages = HashMap::new();
            let remote_package = RemotePackage {
                version,
                download_url,
                date_time,
                file_id: None,
                modules: vec![],
            };

            remote_packages.insert(ReleaseChannel::Stable, remote_package);

            let metadata = RepositoryMetadata {
                website_url: Some(self.url.to_string()),
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
        ) -> Result<(String, String)> {
            let tag_name =
                tag_name.ok_or_else(|| error!("Tag name must be specified for git changelog"))?;

            let client = HttpClient::new()?;

            let mut path = self.url.path().split('/');
            // Get rid of leading slash
            path.next();

            let author = path
                .next()
                .ok_or_else(|| error!("author not present in url: {:?}", self.url))?;
            let repo = path
                .next()
                .ok_or_else(|| error!("repo not present in url: {:?}", self.url))?;

            let url = format!(
                "https://api.github.com/repos/{}/{}/releases/tags/{}",
                author, repo, tag_name
            );

            let mut resp = request_async(&client, &url, vec![], None).await?;

            let release: Release = resp.json()?;

            Ok((release.body, release.html_url))
        }
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
    use crate::error;
    use crate::network::request_async;
    use crate::repository::{Backend, ReleaseChannel, RemotePackage, RepositoryMetadata};
    use crate::Result;

    use async_trait::async_trait;
    use chrono::{DateTime, Utc};
    use isahc::http::Uri;
    use isahc::prelude::*;
    use serde::Deserialize;

    use std::collections::HashMap;

    #[derive(Debug, Clone)]
    pub struct Gitlab {
        pub url: Uri,
        pub flavor: Flavor,
    }

    #[async_trait]
    impl Backend for Gitlab {
        async fn get_metadata(&self) -> Result<RepositoryMetadata> {
            let client = HttpClient::new()?;

            let mut path = self.url.path().split('/');
            // Get rid of leading slash
            path.next();

            let author = path
                .next()
                .ok_or_else(|| error!("author not present in url: {:?}", self.url))?;
            let repo = path
                .next()
                .ok_or_else(|| error!("repo not present in url: {:?}", self.url))?;

            let url = format!(
                "https://gitlab.com/api/v4/projects/{}%2F{}/releases",
                author, repo
            );

            let mut resp = request_async(&client, &url, vec![], None).await?;

            let releases: Vec<Release> = resp.json()?;
            let release = releases
                .get(0)
                .ok_or_else(|| error!("No release found for {}", &url))?;

            let version = release.tag_name.clone();
            let asset = release
                .assets
                .links
                .iter()
                .find(|a| a.name.ends_with("zip"))
                .ok_or_else(|| error!("No zip asset for {}", &url))?;

            let download_url = asset.url.clone();
            let date_time = Some(release.released_at);

            let mut remote_packages = HashMap::new();
            let remote_package = RemotePackage {
                version,
                download_url,
                date_time,
                file_id: None,
                modules: vec![],
            };

            remote_packages.insert(ReleaseChannel::Stable, remote_package);

            let metadata = RepositoryMetadata {
                website_url: Some(self.url.to_string()),
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
        ) -> Result<(String, String)> {
            let tag_name =
                tag_name.ok_or_else(|| error!("Tag name must be specified for git changelog"))?;

            let client = HttpClient::new()?;

            let mut path = self.url.path().split('/');
            // Get rid of leading slash
            path.next();

            let author = path
                .next()
                .ok_or_else(|| error!("author not present in url: {:?}", self.url))?;
            let repo = path
                .next()
                .ok_or_else(|| error!("repo not present in url: {:?}", self.url))?;

            let url = format!(
                "https://gitlab.com/api/v4/projects/{}%2F{}/releases/{}",
                author, repo, tag_name
            );

            let mut resp = request_async(&client, &url, vec![], None).await?;

            let release: Release = resp.json()?;

            let release_url = format!("https://gitlab.com{}", &release.tag_path);

            Ok((release.description, release_url))
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
