use crate::config::Flavor;
use crate::error::DownloadError;
use crate::network::request_async;

use async_std::task;
use chrono::prelude::*;
use futures::future::join_all;
use isahc::ResponseExt;
use serde::Deserialize;

const CURSE_CATALOG_URL: &str =
    "https://github.com/ajour/ajour-catalog/raw/master/curse.json";
const TUKUI_CATALOG_URL: &str =
    "https://github.com/ajour/ajour-catalog/raw/master/tukui.json";
const WOWI_CATALOG_URL: &str =
    "https://github.com/ajour/ajour-catalog/raw/master/wowi.json";

const CATALOG_URLS: [&str; 3] = [WOWI_CATALOG_URL, CURSE_CATALOG_URL, TUKUI_CATALOG_URL];

pub async fn get_catalog_addons_from(url: &str) -> Vec<CatalogAddon> {
    let mut addons = vec![];

    let request = request_async(url, vec![], None);
    if let Ok(mut response) = request.await {
        if let Ok(json) = task::spawn_blocking(move || response.json::<Vec<CatalogAddon>>()).await {
            log::debug!("Successfully fetched and parsed {}", url);
            addons.extend(json);
        } else {
            log::debug!("Could not parse {}", url);
        }
    } else {
        log::debug!("Could not fetch {}", url);
    }

    addons
}

pub async fn get_catalog() -> Result<Catalog, DownloadError> {
    let mut futures = vec![];
    for url in CATALOG_URLS.iter() {
        futures.push(get_catalog_addons_from(url));
    }

    let mut addons = vec![];
    let results = join_all(futures).await;
    for _addons in results {
        addons.extend(_addons);
    }

    if !addons.is_empty() {
        Ok(Catalog { addons })
    } else {
        Err(DownloadError::CatalogFailed)
    }
}

#[derive(Debug, Clone, Copy, Deserialize, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Source {
    #[serde(alias = "curse")]
    Curse,
    #[serde(alias = "tukui")]
    Tukui,
    #[serde(alias = "wowi")]
    WowI,
}

impl std::fmt::Display for Source {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            Source::Curse => "Curse",
            Source::Tukui => "Tukui",
            Source::WowI => "WowInterface",
        };
        write!(f, "{}", s)
    }
}

#[serde(transparent)]
#[derive(Debug, Clone, Deserialize)]
pub struct Catalog {
    pub addons: Vec<CatalogAddon>,
}

#[serde(rename_all = "camelCase")]
#[derive(Debug, Clone, Deserialize, Eq, PartialEq, Ord, PartialOrd)]
pub struct GameVersion {
    #[serde(with = "null_to_default")]
    pub game_version: String,
    pub flavor: Flavor,
}

#[serde(rename_all = "camelCase")]
#[derive(Debug, Clone, Deserialize)]
pub struct CatalogAddon {
    #[serde(with = "null_to_default")]
    pub id: i32,
    #[serde(with = "null_to_default")]
    pub website_url: String,
    #[serde(with = "date_parser")]
    pub date_released: Option<DateTime<Utc>>,
    #[serde(with = "null_to_default")]
    pub name: String,
    #[serde(with = "null_to_default")]
    pub categories: Vec<String>,
    #[serde(with = "null_to_default")]
    pub summary: String,
    #[serde(with = "null_to_default")]
    pub number_of_downloads: u64,
    pub source: Source,
    #[serde(with = "null_to_default")]
    #[deprecated(since = "0.4.4", note = "Please use game_versions instead")]
    pub flavors: Vec<Flavor>,
    #[serde(with = "null_to_default")]
    pub game_versions: Vec<GameVersion>,
}

mod null_to_default {
    use serde::{self, Deserialize, Deserializer};

    pub fn deserialize<'de, D, T>(deserializer: D) -> Result<T, D::Error>
    where
        D: Deserializer<'de>,
        T: Default + Deserialize<'de>,
    {
        let opt = Option::deserialize(deserializer)?;
        Ok(opt.unwrap_or_default())
    }
}

mod date_parser {
    use chrono::prelude::*;
    use serde::{self, Deserialize, Deserializer};

    pub(crate) fn deserialize<'de, D>(deserializer: D) -> Result<Option<DateTime<Utc>>, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;

        // Curse format
        let date = DateTime::parse_from_rfc3339(&s)
            .map(|d| d.with_timezone(&Utc))
            .ok();

        if date.is_some() {
            return Ok(date);
        }

        // Tukui format
        let date = NaiveDateTime::parse_from_str(&s, "%Y-%m-%d %T")
            .map(|d| Utc.from_utc_datetime(&d))
            .ok();

        if date.is_some() {
            return Ok(date);
        }

        // Handles Elvui and Tukui addons which runs in a format without HH:mm:ss.
        let s_modified = format!("{} 00:00:00", &s);
        let date = NaiveDateTime::parse_from_str(&s_modified, "%Y-%m-%d %T")
            .map(|d| Utc.from_utc_datetime(&d))
            .ok();

        if date.is_some() {
            return Ok(date);
        }

        // Handles WowI.
        if let Ok(ts) = &s.parse::<i64>() {
            let date = Utc.timestamp(ts / 1000, 0);
            return Ok(Some(date));
        }

        Ok(None)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_catalog_download() {
        async_std::task::block_on(async {
            let catalog = get_catalog().await;

            if let Err(e) = catalog {
                panic!("{}", e);
            }
        });
    }

    #[test]
    fn test_null_fields() {
        let tests = [
            r"[]",
            r#"[{"id": null,"websiteUrl": null,"dateReleased":"2020-11-20T02:29:43.46Z","name": null,"summary": null,"numberOfDownloads": null,"categories": null,"flavors": null,"gameVersions": null,"source":"curse"}]"#,
        ];

        for test in tests.iter() {
            serde_json::from_str::<Vec<CatalogAddon>>(test).unwrap();
        }
    }
}
