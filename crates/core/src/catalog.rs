use crate::config::Flavor;
use crate::error::DownloadError;
use crate::network::request_async;

use async_std::task;
use chrono::prelude::*;
use isahc::ResponseExt;
use serde::{Deserialize, Serialize};

const CATALOG_URL: &str = "https://github.com/ajour/ajour-catalog/raw/master/catalog-2.0.json";

type Etag = Option<String>;

async fn get_catalog_addons_from(
    url: &str,
    cached_etag: Etag,
) -> Result<Option<(Etag, Vec<CatalogAddon>)>, DownloadError> {
    let mut headers = vec![];
    if let Some(etag) = cached_etag.as_deref() {
        headers.push(("If-None-Match", etag));
    }

    let mut response = request_async(url, headers, None).await?;

    match response.status().as_u16() {
        200 => {
            log::debug!("Downloaded latest catalog from {}", url);

            let etag = response
                .headers()
                .get("etag")
                .and_then(|h| h.to_str().map(String::from).ok());

            Ok(Some((
                etag,
                task::spawn_blocking(move || response.json::<Vec<CatalogAddon>>()).await?,
            )))
        }
        304 => {
            log::debug!("Etag match, cached catalog is latest version");
            Ok(None)
        }
        status => {
            log::error!("Catalog failed to download with status: {}", status);
            return Err(DownloadError::CatalogFailed);
        }
    }
}

pub(crate) async fn download_catalog(
    cached_etag: Etag,
) -> Result<Option<(Etag, Catalog)>, DownloadError> {
    let response = get_catalog_addons_from(CATALOG_URL, cached_etag)
        .await?
        .map(|(etag, addons)| (etag, Catalog { addons }));

    Ok(response)
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Source {
    #[serde(alias = "curse")]
    Curse,
    #[serde(alias = "tukui")]
    Tukui,
    #[serde(alias = "wowi")]
    WowI,
    #[serde(alias = "townlong-yak")]
    TownlongYak,
    #[serde(other)]
    Other,
}

impl std::fmt::Display for Source {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            Source::Curse => "Curse",
            Source::Tukui => "Tukui",
            Source::WowI => "WowInterface",
            Source::TownlongYak => "TownlongYak",

            // This is a fallback option.
            Source::Other => "Unknown",
        };
        write!(f, "{}", s)
    }
}

#[serde(transparent)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Catalog {
    pub addons: Vec<CatalogAddon>,
}

#[serde(rename_all = "camelCase")]
#[derive(Debug, Clone, Serialize, Deserialize, Eq, PartialEq, Ord, PartialOrd)]
pub struct GameVersion {
    #[serde(deserialize_with = "null_to_default::deserialize")]
    pub game_version: String,
    pub flavor: Flavor,
}

#[serde(rename_all = "camelCase")]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CatalogAddon {
    #[serde(deserialize_with = "null_to_default::deserialize")]
    pub id: i32,
    #[serde(deserialize_with = "null_to_default::deserialize")]
    pub website_url: String,
    #[serde(deserialize_with = "date_parser::deserialize")]
    pub date_released: Option<DateTime<Utc>>,
    #[serde(deserialize_with = "null_to_default::deserialize")]
    pub name: String,
    #[serde(deserialize_with = "null_to_default::deserialize")]
    pub categories: Vec<String>,
    #[serde(deserialize_with = "null_to_default::deserialize")]
    pub summary: String,
    #[serde(deserialize_with = "null_to_default::deserialize")]
    pub number_of_downloads: u64,
    pub source: Source,
    #[serde(deserialize_with = "null_to_default::deserialize")]
    #[deprecated(since = "0.4.4", note = "Please use game_versions instead")]
    pub flavors: Vec<Flavor>,
    #[serde(deserialize_with = "null_to_default::deserialize")]
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
            let catalog = download_catalog(None).await;

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
