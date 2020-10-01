use crate::error::ClientError;
use crate::network::request_async;
use crate::Result;

use chrono::{DateTime, NaiveDate, Utc};
use isahc::prelude::*;
use serde::Deserialize;

const CATALOG_URL: &str =
    "https://raw.githubusercontent.com/ogri-la/wowman-data/master/curseforge-catalog.json";

pub async fn get_catalog(shared_client: &HttpClient) -> Result<Catalog> {
    let mut resp = request_async(shared_client, CATALOG_URL, vec![], Some(30)).await?;

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
    spec: CatalogSpec,
    datestamp: NaiveDate,
    updated_datestamp: NaiveDate,
    total: u32,
    addon_summary_list: Vec<CatalogAddon>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct CatalogSpec {
    version: u16,
}

#[serde(rename_all = "kebab-case")]
#[derive(Debug, Clone, Deserialize)]
pub struct CatalogAddon {
    alt_name: String,
    category_list: Vec<String>,
    created_date: DateTime<Utc>,
    description: String,
    download_count: u64,
    label: String,
    name: String,
    source: String,
    updated_date: DateTime<Utc>,
    uri: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_catalog_download() {
        async_std::task::block_on(async {
            let client = HttpClient::new().unwrap();

            let catalog = get_catalog(&client).await;

            if let Err(e) = catalog {
                panic!("{}", e);
            }
        });
    }
}
