use crate::config::Flavor;
use crate::error::DownloadError;
use crate::network::request_async;

use chrono::prelude::*;
use isahc::AsyncReadResponseExt;
use serde::{Deserialize, Serialize};

const CATALOG_URL: &str = "https://github.com/ajour/ajour-catalog/raw/master/catalog-3.0.json";

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

            let mut addons = response.json::<Vec<CatalogAddon>>().await?;
            addons.retain(|a| !a.game_versions.is_empty());

            Ok(Some((etag, addons)))
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
    #[serde(deserialize_with = "skip_element_unknown_variant::deserialize")]
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

mod skip_element_unknown_variant {
    use serde::{
        de::{self, SeqAccess, Visitor},
        Deserialize, Deserializer,
    };
    use std::fmt;
    use std::marker::PhantomData;

    pub fn deserialize<'de, D, T>(deserializer: D) -> Result<Vec<T>, D::Error>
    where
        D: Deserializer<'de>,
        T: Deserialize<'de>,
    {
        struct SeqVisitor<V>(PhantomData<V>);

        impl<'de, V> Visitor<'de> for SeqVisitor<V>
        where
            V: Deserialize<'de>,
        {
            type Value = Vec<V>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                write!(formatter, "an array of values")
            }

            fn visit_unit<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(vec![])
            }

            fn visit_none<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(vec![])
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let mut values = vec![];

                loop {
                    let value = seq.next_element::<V>();

                    match value {
                        Ok(Some(v)) => {
                            values.push(v);
                        }
                        Ok(None) => break,
                        Err(e) => {
                            if e.to_string().starts_with("unknown variant") {
                                continue;
                            } else {
                                return Err(e);
                            }
                        }
                    }
                }

                Ok(values)
            }
        }

        deserializer.deserialize_any(SeqVisitor(PhantomData::default()))
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

    #[test]
    fn test_skip_failed_element() {
        #[derive(Debug, Deserialize)]
        struct Test(
            #[serde(deserialize_with = "skip_element_unknown_variant::deserialize")]
            Vec<GameVersion>,
        );

        let tests = [
            // Will return 0 results
            r"[]",
            // Will return 0 results
            r#"null"#,
            // Will return 2 results
            r#"[{"gameVersion": "asdf", "flavor": "classic"}, {"gameVersion": "asdf", "flavor": "retail"}]"#,
            // Will return 2 results, gameVersion as null will be String::default
            r#"[{"gameVersion": "asdf", "flavor": "classic"}, {"gameVersion": null, "flavor": "retail"}]"#,
            // Test skipping when GameVersion has an unknown flavor variant. Will return only first result.
            r#"[{"gameVersion": "asdf", "flavor": "classic"}, {"gameVersion": "asdf", "flavor": "unknown"}]"#,
            // All other deser error on elements will fail... missing field
            r#"[{"gameVersion": "asdf", "flavor": "classic"}, {"gameVersion": "asdf"}]"#,
            // All other deser error on elements will fail... null flavor
            r#"[{"gameVersion": "asdf", "flavor": "classic"}, {"gameVersion": "asdf", "flavor": null}]"#,
            // All other deser error on elements will fail... invalid type for a field
            r#"[{"gameVersion": "asdf", "flavor": "classic"}, {"gameVersion": {}, "flavor": "unknown"}]"#,
        ];

        for (idx, test) in tests.iter().enumerate() {
            let result = serde_json::from_str::<Test>(test);
            match idx {
                _ if idx < 5 => {
                    dbg!(&result);
                    assert!(result.is_ok());
                }
                _ => assert!(result.is_err()),
            }
        }
    }
}
