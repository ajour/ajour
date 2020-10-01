use crate::error::ClientError;
use crate::network::request_async;
use crate::Result;

use chrono::{DateTime, NaiveDate, Utc};
use isahc::{config::RedirectPolicy, prelude::*};
use serde::Deserialize;

const CATALOG_URL: &str =
    "https://raw.githubusercontent.com/ogri-la/wowman-data/master/curseforge-catalog.json";

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

#[serde(rename_all = "kebab-case")]
#[derive(Debug, Clone, Deserialize)]
pub struct Catalog {
    pub spec: CatalogSpec,
    pub datestamp: NaiveDate,
    pub updated_datestamp: NaiveDate,
    pub total: u32,
    pub addon_summary_list: Vec<CatalogAddon>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct CatalogSpec {
    pub version: u16,
}

#[serde(rename_all = "kebab-case")]
#[derive(Debug, Clone, Deserialize)]
pub struct CatalogAddon {
    pub alt_name: String,
    pub category_list: Vec<String>,
    pub created_date: DateTime<Utc>,
    pub description: String,
    pub download_count: u64,
    pub label: String,
    pub name: String,
    pub source: String,
    pub updated_date: DateTime<Utc>,
    pub uri: String,
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
