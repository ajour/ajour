use crate::config::Flavor;
use crate::error::ClientError;
use crate::network::request_async;
use crate::Result;
use chrono::prelude::*;

use isahc::{config::RedirectPolicy, prelude::*};
use serde::Deserialize;

// TODO: Change this back.
const CATALOG_URL: &str =
    "https://raw.githubusercontent.com/casperstorm/ajour-catalog/feat/wowi-source/catalog.json";

pub async fn get_catalog() -> Result<Catalog> {
    let client = HttpClient::builder()
        .redirect_policy(RedirectPolicy::Follow)
        .max_connections_per_host(6)
        .build()
        .unwrap();

    let mut resp = request_async(&client, CATALOG_URL, vec![], Some(30)).await?;

    if resp.status().is_success() {
        let catalog = resp.json()?;
        Ok(catalog)
    } else {
        Err(ClientError::Custom(format!(
            "Couldn't fetch catalog: {}",
            resp.text()?
        )))
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
            Source::WowI => "WowI",
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
        // TODO: Theres room for improvements here.
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
