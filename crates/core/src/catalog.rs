use crate::config::Flavor;
use crate::error;
use crate::Result;
use async_std::task;
use chrono::prelude::*;
use futures::future::join_all;
use std::time::Duration;

use isahc::{config::RedirectPolicy, prelude::*};
use serde::Deserialize;

const DEFAULT_TIMEOUT: u64 = 30;

const CURSE_CATALOG_URL: &str =
    "https://github.com/casperstorm/ajour-catalog/releases/latest/download/curse.json";
const TUKUI_CATALOG_URL: &str =
    "https://github.com/casperstorm/ajour-catalog/releases/latest/download/tukui.json";
const WOWI_CATALOG_URL: &str =
    "https://github.com/casperstorm/ajour-catalog/releases/latest/download/wowi.json";

const CATALOG_URLS: [&str; 3] = [WOWI_CATALOG_URL, CURSE_CATALOG_URL, TUKUI_CATALOG_URL];

pub async fn get_catalog_addons_from(url: &str) -> Result<Vec<CatalogAddon>> {
    let client = HttpClient::builder()
        .redirect_policy(RedirectPolicy::Follow)
        .max_connections_per_host(6)
        .timeout(Duration::from_secs(DEFAULT_TIMEOUT))
        .build()
        .unwrap();

    let request = client.get_async(url.to_string());
    if let Ok(mut response) = request.await {
        log::debug!("Fetched {}, beginning parsing", url);
        if let Ok(json) = task::spawn_blocking(move || response.json()).await {
            log::debug!("Successfully fetched and parsed {}", url);
            Ok(json)
        } else {
            log::debug!("Could not parse {}", url);
            Err(error!("Could not parse catalog"))
        }
    } else {
        log::debug!("Could not fetch {}", url);
        Err(error!("Could not fetch catalog"))
    }
}

pub async fn get_catalog() -> Result<Catalog> {
    let mut futures = vec![];
    for url in CATALOG_URLS.iter() {
        futures.push(get_catalog_addons_from(url));
    }

    let mut addons = vec![];
    let results = join_all(futures).await;
    for api_result in results {
        match api_result {
            Ok(c) => addons.append(&mut c.clone()),
            Err(e) => log::debug!("{}", e),
        };
    }

    Ok(Catalog { addons })
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
    pub game_version: String,
    pub flavor: Flavor,
}

#[serde(rename_all = "camelCase")]
#[derive(Debug, Clone, Deserialize)]
pub struct CatalogAddon {
    pub id: i32,
    pub website_url: String,
    #[serde(with = "date_parser")]
    pub date_released: Option<DateTime<Utc>>,
    pub name: String,
    pub categories: Vec<String>,
    pub summary: String,
    pub number_of_downloads: u64,
    pub source: Source,
    #[deprecated(since = "0.4.4", note = "Please use game_versions instead")]
    pub flavors: Vec<Flavor>,
    pub game_versions: Vec<GameVersion>,
}

mod date_parser {
    use chrono::prelude::*;
    use serde::{self, Deserialize, Deserializer};

    pub fn deserialize<'de, D>(deserializer: D) -> Result<Option<DateTime<Utc>>, D::Error>
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
}
