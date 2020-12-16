use ajour_core::network::request_async;
use async_std::fs;
use async_std::stream::StreamExt;
use futures::future;
use isahc::http;
use isahc::ResponseExt;
use mlua::{prelude::*, Value};
use serde::Deserialize;

use std::collections::{HashMap, HashSet};
use std::fmt::{self, Debug};
use std::path::Path;

pub async fn list_accounts(wtf_path: impl AsRef<Path>) -> Vec<String> {
    let account_path = wtf_path.as_ref().join("Account");

    let mut accounts = vec![];

    let mut read_dir = fs::read_dir(account_path).await.unwrap();

    while let Some(entry) = read_dir.next().await {
        if let Ok(entry) = entry {
            let path = entry.path();

            let name = path
                .file_name()
                .unwrap_or_default()
                .to_str()
                .unwrap_or_default();

            if path.is_dir().await && name != "SavedVariables" {
                accounts.push(name.to_owned());
            }
        }
    }

    accounts
}

pub async fn parse_auras(wtf_path: impl AsRef<Path>, account: String) -> Vec<Aura> {
    let path = wtf_path
        .as_ref()
        .join("Account")
        .join(&account)
        .join("SavedVariables")
        .join("WeakAuras.lua");

    let lua = mlua::Lua::new();

    let source = fs::read_to_string(&path).await.unwrap();
    let expression = source.replace("WeakAurasSaved = {", "{");

    let table = lua.load(&expression).eval::<mlua::Table>().unwrap();

    let displays = table
        .get::<_, HashMap<String, MaybeAuraDisplay>>("displays")
        .unwrap()
        .values()
        .cloned()
        .filter_map(MaybeAuraDisplay::into_inner)
        .collect::<Vec<_>>();

    let slugs = displays
        .iter()
        .map(|a| a.slug.clone())
        .collect::<HashSet<_>>()
        .into_iter()
        .collect::<Vec<_>>();

    let url = format!(
        "https://data.wago.io/api/check/weakauras?ids={}",
        slugs.join(",")
    );

    let mut response = request_async(url, vec![], None).await.unwrap();

    let mut auras: Vec<Aura> = response.json().unwrap();

    auras.iter_mut().for_each(|a| {
        let displays = displays
            .iter()
            .filter(|d| d.slug == a.slug)
            .cloned()
            .collect();

        a.displays = displays
    });

    auras
}

pub async fn get_aura_updates(auras: &[Aura]) -> Vec<AuraUpdate> {
    let fetched_updates = future::join_all(
        auras
            .iter()
            .filter(|a| a.has_update())
            .map(|aura| async move { (&aura.slug, get_encoded_update(&aura.slug).await) }),
    )
    .await;

    let mut updates = vec![];

    for (slug, encoded_update) in fetched_updates {
        if let Some(aura) = auras.iter().find(|a| &a.slug == slug).cloned() {
            updates.push(AuraUpdate {
                aura,
                encoded_update,
            });
        }
    }

    updates
}

async fn get_encoded_update(slug: &str) -> String {
    let url = format!("https://data.wago.io/api/raw/encoded?id={}", slug);

    request_async(url, vec![], None)
        .await
        .unwrap()
        .text_async()
        .await
        .unwrap()
}

#[derive(Clone)]
pub struct AuraUpdate {
    aura: Aura,
    encoded_update: String,
}

impl Debug for AuraUpdate {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("AuraUpdate")
            .field("aura", &self.aura)
            .field(
                "encoded_update",
                &format!("{}...", &self.encoded_update[..10]),
            )
            .finish()
    }
}

#[derive(Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Aura {
    slug: String,
    name: String,
    username: String,
    version: u16,
    version_string: String,
    changelog: AuraChangelog,
    #[serde(skip_deserializing)]
    displays: Vec<AuraDisplay>,
}

impl Debug for Aura {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("Aura")
            .field("slug", &self.slug)
            .field("name", &self.name)
            .field("username", &self.username)
            .field("version", &self.version)
            .field("version_string", &self.version_string)
            .field("changelog", &self.changelog)
            .field("number_of_displays", &self.displays.len())
            .field("update_needed", &self.has_update())
            .finish()
    }
}

impl Aura {
    fn parent_display(&self) -> Option<&AuraDisplay> {
        self.displays.iter().find(|d| d.parent.is_none())
    }

    fn installed_version(&self) -> Option<u16> {
        self.parent_display().map(|d| d.version)
    }

    fn uid(&self) -> Option<&str> {
        self.parent_display().map(|d| d.uid.as_str())
    }

    fn ids(&self) -> Vec<&str> {
        self.displays.iter().map(|d| d.id.as_str()).collect()
    }

    fn has_update(&self) -> bool {
        if let Some(installed) = self.installed_version() {
            self.version > installed
        } else {
            false
        }
    }
}

#[derive(Debug, Deserialize, Clone)]
struct AuraChangelog {
    text: String,
    format: String,
}

#[derive(Debug, Clone)]
struct AuraDisplay {
    slug: String,
    version: u16,
    parent: Option<String>,
    id: String,
    uid: String,
    ignore_updates: bool,
    skip_version: Option<u16>,
}

#[derive(Clone)]
struct MaybeAuraDisplay(Option<AuraDisplay>);

impl MaybeAuraDisplay {
    fn into_inner(self) -> Option<AuraDisplay> {
        self.0
    }
}

impl<'lua> FromLua<'lua> for MaybeAuraDisplay {
    fn from_lua(lua_value: Value<'lua>, _lua: &'lua Lua) -> Result<Self, mlua::Error> {
        if let Value::Table(table) = lua_value {
            if let Some(url) = table.get::<_, Option<String>>("url")? {
                if let Ok(uri) = url.parse::<http::Uri>() {
                    let mut path = uri.path().split_terminator('/');
                    path.next();

                    let slug = path.next();

                    if let Some(slug) = slug {
                        let parent = table.get("parent")?;
                        let id = table.get("id")?;
                        let uid = table.get("uid")?;
                        let version = table.get("version")?;
                        let ignore_updates = table
                            .get::<_, Option<bool>>("ignoreWagoUpdate")?
                            .unwrap_or_default();
                        let skip_version = table.get("skipWagoUpdate")?;

                        return Ok(MaybeAuraDisplay(Some(AuraDisplay {
                            slug: slug.to_owned(),
                            version,
                            parent,
                            id,
                            uid,
                            ignore_updates,
                            skip_version,
                        })));
                    }
                }
            }
        } else {
            return Err(mlua::Error::FromLuaConversionError {
                from: lua_value.type_name(),
                to: "HashMap",
                message: Some("expected table".to_string()),
            });
        }

        Ok(MaybeAuraDisplay(None))
    }
}
