use crate::config::Flavor;
use crate::error::ClientError;
use crate::network::request_async;
use crate::Result;

use isahc::{config::RedirectPolicy, prelude::*};
use serde::Deserialize;

const CATALOG_URL: &str =
    "https://raw.githubusercontent.com/casperstorm/ajour-catalog/master/curse.json";

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

#[derive(Debug, Clone, Deserialize)]
pub enum Source {
    #[serde(alias = "curse")]
    Curse,
}

#[serde(transparent)]
#[derive(Debug, Clone, Deserialize)]
pub struct Catalog {
    pub addons: Vec<CatalogAddon>,
}

#[serde(rename_all = "camelCase")]
#[derive(Debug, Clone, Deserialize)]
pub struct CatalogAddon {
    pub id: u32,
    pub name: String,
    pub categories: Vec<CatalogCategory>,
    pub summary: String,
    pub number_of_downloads: u64,
    pub source: Source,
    pub flavors: Vec<Flavor>,
}

#[serde(transparent)]
#[derive(Debug, Clone, Deserialize, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct CatalogCategory {
    pub name: String,
}

impl CatalogCategory {
    pub fn all_option() -> Self {
        CatalogCategory {
            name: String::from("All Categories"),
        }
    }
}

impl std::fmt::Display for CatalogCategory {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.name)
    }
}

impl Default for CatalogCategory {
    fn default() -> Self {
        CatalogCategory::all_option()
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
