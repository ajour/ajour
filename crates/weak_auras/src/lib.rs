use ajour_core::network::request_async;
use async_std::fs;
use async_std::path::Path;
use async_std::stream::StreamExt;
use futures::future;
use isahc::http;
use isahc::ResponseExt;
use mlua::{prelude::*, Value};
use serde::Deserialize;

use std::collections::{HashMap, HashSet};
use std::fmt::{self, Debug, Display, Write};

mod companion;
mod error;

pub use companion::{ensure_companion_addon_exists, write_updates};
pub use error::Error;

pub async fn is_weak_auras_installed(addon_dir: impl AsRef<Path>) -> bool {
    let weak_auras_toc = addon_dir.as_ref().join("WeakAuras").join("WeakAuras.toc");

    weak_auras_toc.is_file().await
}

/// Return a list of Account names under the specified WTF folder
pub async fn list_accounts(wtf_path: impl AsRef<Path>) -> Result<Vec<String>, Error> {
    let account_path = wtf_path.as_ref().join("Account");

    let mut accounts = vec![];

    if !account_path.exists().await {
        return Ok(accounts);
    }

    let mut read_dir = fs::read_dir(account_path).await?;

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

    Ok(accounts)
}

/// Parse and return all Auras installed under the accounts `WeakAuras.lua`
/// SavedVariables file
pub async fn parse_auras(wtf_path: impl AsRef<Path>, account: String) -> Result<Vec<Aura>, Error> {
    let lua_path = wtf_path
        .as_ref()
        .join("Account")
        .join(&account)
        .join("SavedVariables")
        .join("WeakAuras.lua");

    if !lua_path.exists().await {
        return Ok(vec![]);
    }

    let source = fs::read_to_string(&lua_path).await?;

    let displays = async_std::task::spawn_blocking(move || {
        let expression = source.replace("WeakAurasSaved = {", "{");

        let lua = mlua::Lua::new();
        let table = lua.load(&expression).eval::<mlua::Table>()?.to_owned();

        let maybe_table = table.get::<_, Option<HashMap<String, MaybeAuraDisplay>>>("displays")?;

        match maybe_table {
            Some(table) => {
                let displays = table
                    .values()
                    .cloned()
                    .filter_map(MaybeAuraDisplay::into_inner)
                    .collect::<Vec<_>>();

                Ok::<_, Error>(displays)
            }
            None => Ok::<_, Error>(vec![]),
        }
    })
    .await?;

    if displays.is_empty() {
        return Ok(vec![]);
    }

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

    let mut response = request_async(url, vec![], Some(30)).await?;

    let mut auras: Vec<Aura> = response.json()?;

    auras.iter_mut().for_each(|a| {
        let displays = displays
            .iter()
            .filter(|d| d.slug == a.slug)
            .cloned()
            .collect();

        a.displays = displays;

        if a.has_update() {
            a.status = AuraStatus::UpdateAvailable;
        }
    });

    Ok(auras)
}

/// Fetch and return the encoded update strings for all Auras that have an
/// update available.
pub async fn get_aura_updates(auras: &[Aura]) -> Result<Vec<AuraUpdate>, Error> {
    let fetched_updates = future::join_all(
        auras
            .iter()
            .filter(|a| a.has_update())
            .map(|aura| async move { (aura.slug.clone(), get_encoded_update(&aura.slug).await) }),
    )
    .await;

    let mut updates = vec![];

    for (slug, encoded_update) in fetched_updates {
        let encoded_update = encoded_update?;

        if let Some(aura) = auras.iter().find(|a| a.slug == slug).cloned() {
            updates.push(AuraUpdate {
                slug,
                encoded_update,
                aura,
            });
        }
    }

    Ok(updates)
}

async fn get_encoded_update(slug: &str) -> Result<String, Error> {
    let url = format!("https://data.wago.io/api/raw/encoded?id={}", slug);

    Ok(request_async(url, vec![], Some(30))
        .await?
        .text_async()
        .await?)
}

/// An Aura that has an update. This stores the [`Aura`] along with the encoded
/// string of it's new version fetched from Wago.io.
#[derive(Clone)]
pub struct AuraUpdate {
    pub slug: String,
    pub encoded_update: String,
    pub aura: Aura,
}

impl AuraUpdate {
    #[rustfmt::skip]
    fn formatted_slug(&self) -> Result<String, Error> {
        let mut slug = String::new();

        writeln!(&mut slug, "    [\"{}\"] = {{", self.slug)?;
        writeln!(&mut slug, "      name = [=[{}]=],", self.aura.name)?;
        writeln!(&mut slug, "      author = [=[{}]=],", self.aura.author())?;
        writeln!(&mut slug, "      encoded = [=[{}]=],", self.encoded_update)?;
        writeln!(&mut slug, "      wagoVersion = [=[{}]=],", self.aura.version)?;
        writeln!(&mut slug, "      wagoSemver = [=[{}]=],", self.aura.version_string)?;
        // TODO: Proper changelog formatting
        writeln!(&mut slug, "      versionNote = [=[{}]=],", self.aura.changelog.text.as_deref().unwrap_or_default())?;
        writeln!(&mut slug, "    }},")?;

        Ok(slug)
    }

    #[rustfmt::skip]
    fn formatted_uid(&self) -> Result<String, Error> {
        let mut formatted_uid = String::new();

        let uid = self.aura.uid().ok_or(Error::MissingUid {
            slug: self.slug.clone(),
        })?;

        writeln!(&mut formatted_uid, "    [\"{}\"] = [=[{}]=],", uid, self.slug)?;

        Ok(formatted_uid)
    }

    #[rustfmt::skip]
    fn formatted_ids(&self) -> Result<String, Error> {
        let mut ids = String::new();

        for display in self.aura.displays.iter() {
            writeln!(&mut ids, "    [\"{}\"] = [=[{}]=],", display.id, self.slug)?;
        }

        Ok(ids)
    }
}

impl Debug for AuraUpdate {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("AuraUpdate")
            .field("slug", &self.slug)
            .field(
                "encoded_update",
                &format!("{}...", &self.encoded_update[..30]),
            )
            .field("aura", &"...")
            .finish()
    }
}

/// Status used by GUI to track state of the Aura
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Eq, Ord)]
pub enum AuraStatus {
    Idle,
    UpdateQueued,
    UpdateAvailable,
}

impl Default for AuraStatus {
    fn default() -> Self {
        AuraStatus::Idle
    }
}

impl Display for AuraStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s = match self {
            AuraStatus::Idle => "",
            AuraStatus::UpdateAvailable => "Update Available",
            AuraStatus::UpdateQueued => "Update Queued",
        };

        write!(f, "{}", s)
    }
}

/// A parsed Aura from SavedVariables along with it's Wago.io metadata
#[derive(Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Aura {
    slug: String,
    name: String,
    username: Option<String>,
    version: u16,
    version_string: String,
    changelog: AuraChangelog,
    #[serde(skip_deserializing)]
    displays: Vec<AuraDisplay>,
    #[serde(skip_deserializing)]
    status: AuraStatus,
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
    pub fn name(&self) -> &str {
        &self.name
    }

    pub fn slug(&self) -> &str {
        &self.slug
    }

    pub fn url(&self) -> Option<&str> {
        self.parent_display().map(|d| d.url.as_str())
    }

    pub fn status(&self) -> AuraStatus {
        self.status
    }

    pub fn set_status(&mut self, status: AuraStatus) {
        self.status = status;
    }

    pub fn installed_version(&self) -> Option<u16> {
        self.parent_display().map(|d| d.version)
    }

    pub fn remote_version(&self) -> u16 {
        self.version
    }

    pub fn installed_symver(&self) -> Option<&str> {
        self.parent_display()
            .map(|d| d.version_string.as_deref())
            .flatten()
    }

    pub fn remote_symver(&self) -> &str {
        &self.version_string
    }

    pub fn author(&self) -> &str {
        match &self.username {
            Some(username) => username,
            None => "Unknown",
        }
    }

    fn parent_display(&self) -> Option<&AuraDisplay> {
        self.displays.iter().find(|d| d.parent.is_none())
    }

    fn uid(&self) -> Option<&str> {
        self.parent_display().map(|d| d.uid.as_str())
    }

    fn updates_ignored(&self) -> bool {
        self.parent_display()
            .map(|d| d.ignore_updates)
            .unwrap_or_default()
    }

    fn ignored_version(&self) -> Option<u16> {
        self.parent_display().map(|d| d.skip_version).flatten()
    }

    pub fn has_update(&self) -> bool {
        if let Some(installed) = self.installed_version() {
            if !self.updates_ignored() {
                if let Some(ignored_version) = self.ignored_version() {
                    return self.version > installed && self.version != ignored_version;
                } else {
                    return self.version > installed;
                }
            }
        }

        false
    }
}

#[derive(Debug, Deserialize, Clone)]
struct AuraChangelog {
    text: Option<String>,
    format: Option<String>,
}

#[derive(Debug, Clone)]
struct AuraDisplay {
    url: String,
    slug: String,
    version: u16,
    version_string: Option<String>,
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
                        let version_string = table.get("semver")?;
                        let ignore_updates = table
                            .get::<_, Option<bool>>("ignoreWagoUpdate")?
                            .unwrap_or_default();
                        let skip_version = table.get("skipWagoUpdate")?;

                        return Ok(MaybeAuraDisplay(Some(AuraDisplay {
                            url,
                            slug: slug.to_owned(),
                            version,
                            version_string,
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
