use crate::{config::Flavor, curse_api, tukui_api, utility::strip_non_digits};
use chrono::prelude::*;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct RemotePackage {
    pub version: String,
    pub download_url: String,
    pub date_time: DateTime<Utc>,
    pub file_id: Option<i64>,
}

impl PartialOrd for RemotePackage {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.version.cmp(&other.version))
    }
}

impl Ord for RemotePackage {
    fn cmp(&self, other: &Self) -> Ordering {
        self.version.cmp(&other.version)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize, Hash)]
pub enum ReleaseChannel {
    Stable,
    Beta,
    Alpha,
}

impl ReleaseChannel {
    pub const ALL: [ReleaseChannel; 3] = [
        ReleaseChannel::Stable,
        ReleaseChannel::Beta,
        ReleaseChannel::Alpha,
    ];
}

impl Default for ReleaseChannel {
    fn default() -> ReleaseChannel {
        ReleaseChannel::Stable
    }
}

impl std::fmt::Display for ReleaseChannel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                ReleaseChannel::Stable => "Stable",
                ReleaseChannel::Beta => "Beta",
                ReleaseChannel::Alpha => "Alpha",
            }
        )
    }
}

#[derive(Debug, Clone, Eq, PartialEq, PartialOrd, Ord)]
pub enum AddonState {
    Ignored,
    Ajour(Option<String>),
    Downloading,
    Fingerprint,
    Unpacking,
    Updatable,
}

#[derive(Debug, Clone)]
/// Struct which stores identifiers for the different repositories.
pub struct RepositoryIdentifiers {
    pub wowi: Option<String>,
    pub tukui: Option<String>,
    pub curse: Option<u32>,
}

#[derive(Debug, Clone)]
/// Struct which stores information about a single Addon.
pub struct Addon {
    pub id: String,
    pub title: String,
    pub author: Option<String>,
    pub notes: Option<String>,
    pub version: Option<String>,
    pub release_channel: ReleaseChannel,
    pub remote_packages: HashMap<ReleaseChannel, RemotePackage>,
    pub file_id: Option<i64>,
    pub website_url: Option<String>,
    pub path: PathBuf,
    pub dependencies: Vec<String>,
    pub state: AddonState,
    pub wowi_id: Option<String>,
    pub tukui_id: Option<String>,
    pub curse_id: Option<u32>,
    pub fingerprint: Option<u32>,
    pub game_version: Option<String>,

    // States for GUI
    #[cfg(feature = "gui")]
    pub details_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub update_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub force_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub delete_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub ignore_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub unignore_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub website_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub pick_release_channel_state: iced_native::pick_list::State<ReleaseChannel>,
}

impl Addon {
    /// Creates a new Addon
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        id: String,
        title: String,
        author: Option<String>,
        notes: Option<String>,
        version: Option<String>,
        path: PathBuf,
        dependencies: Vec<String>,
        wowi_id: Option<String>,
        tukui_id: Option<String>,
        curse_id: Option<u32>,
    ) -> Self {
        Addon {
            id,
            title,
            author,
            notes,
            version,
            release_channel: Default::default(),
            remote_packages: HashMap::new(),
            file_id: None,
            website_url: None,
            path,
            dependencies,
            state: AddonState::Ajour(None),
            wowi_id,
            tukui_id,
            curse_id,
            fingerprint: None,
            game_version: None,
            #[cfg(feature = "gui")]
            details_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            update_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            force_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            delete_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            ignore_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            unignore_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            website_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            pick_release_channel_state: Default::default(),
        }
    }

    /// Package from Tukui.
    ///
    /// This function takes a `Package` and updates self with the information.
    pub fn apply_tukui_package(&mut self, package: &tukui_api::TukuiPackage) {
        self.website_url = Some(package.web_url.clone());
        self.game_version = package.patch.clone();

        let version = package.version.clone();
        let download_url = package.url.clone();
        let date_time =
            DateTime::parse_from_rfc3339(&format!("{}T15:33:15.007Z", &package.lastupdate))
                .map(|d| d.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now());

        let package = RemotePackage {
            version,
            download_url,
            date_time,
            file_id: None,
        };

        // Since Tukui does not support release channels, our default is 'stable'.
        self.remote_packages.insert(ReleaseChannel::Stable, package);
    }

    /// Package from Curse.
    ///
    /// This function takes a `Package` and updates self with the information
    pub fn apply_curse_package(&mut self, package: &curse_api::Package) {
        self.title = package.name.clone();
        self.website_url = Some(package.website_url.clone());
    }

    pub fn apply_fingerprint_module(
        &mut self,
        info: &curse_api::AddonFingerprintInfo,
        flavor: Flavor,
    ) {
        let dependencies: Vec<String> = info
            .file
            .modules
            .iter()
            .map(|m| m.foldername.clone())
            .collect();

        let flavor = format!("wow_{}", flavor.to_string());
        for file in info.latest_files.iter() {
            if !file.is_alternate && file.game_version_flavor == flavor {
                let version = file.display_name.clone();
                let download_url = file.download_url.clone();
                let date_time = DateTime::parse_from_rfc3339(&file.file_date)
                    .map(|d| d.with_timezone(&Utc))
                    .unwrap_or_else(|_| Utc::now());
                let package = RemotePackage {
                    version,
                    download_url,
                    date_time,
                    file_id: Some(file.id),
                };

                match file.release_type {
                    1 /* stable */ => {
                        self.remote_packages.insert(ReleaseChannel::Stable, package);
                    }
                    2 /* beta */ => {
                        self.remote_packages.insert(ReleaseChannel::Beta, package);
                    }
                    3 /* alpha */ => {
                        self.remote_packages.insert(ReleaseChannel::Alpha, package);
                    }
                    _ => ()
                };
            }
        }

        self.dependencies = dependencies;
        self.version = Some(info.file.display_name.clone());
        self.curse_id = Some(info.id);
        self.file_id = Some(info.file.id);
        self.game_version = info.file.game_version.get(0).cloned();
    }

    /// Function returns a `bool` indicating if the user has manually ignored the addon.
    pub fn is_ignored(&self, ignored: Option<&Vec<String>>) -> bool {
        match ignored {
            Some(ignored) => ignored.iter().any(|i| i == &self.id),
            _ => false,
        }
    }

    /// Function returns a `bool` indicating if the `remote_package` is a update.
    pub fn is_updatable(&self, remote_package: &RemotePackage) -> bool {
        if self.file_id.is_none() {
            return self.is_updatable_by_version_comparison(remote_package);
        }

        remote_package.file_id > self.file_id
    }

    /// We strip both version for non digits, and then
    /// checks if `remote_version` is a sub_slice of `local_version`.
    fn is_updatable_by_version_comparison(&self, remote_package: &RemotePackage) -> bool {
        if let Some(version) = self.version.clone() {
            let srv = strip_non_digits(&remote_package.version);
            let slv = strip_non_digits(&version);

            if let (Some(srv), Some(slv)) = (srv, slv) {
                return !slv.contains(&srv);
            }
        }

        false
    }

    /// Returns the relevant release_package for the addon.
    /// Logic is that if a release channel above the selected is newer, we return that instead.
    pub fn relevant_release_package(&self) -> Option<&RemotePackage> {
        let stable_package = self.remote_packages.get(&ReleaseChannel::Stable);
        let beta_package = self.remote_packages.get(&ReleaseChannel::Beta);
        let alpha_package = self.remote_packages.get(&ReleaseChannel::Alpha);

        let stable_newer_than_beta =
            if let (Some(stable_package), Some(beta_package)) = (stable_package, beta_package) {
                // If stable is newer than beta, we return that instead.
                stable_package.file_id > beta_package.file_id
            } else {
                false
            };
        let beta_newer_than_alpha =
            if let (Some(beta_package), Some(alpha_package)) = (beta_package, alpha_package) {
                // If beta is newer than alpha, we return that instead.
                beta_package.file_id > alpha_package.file_id
            } else {
                false
            };

        match &self.release_channel {
            ReleaseChannel::Stable => stable_package,
            ReleaseChannel::Beta => {
                if stable_newer_than_beta {
                    return stable_package;
                }

                beta_package
            }
            ReleaseChannel::Alpha => {
                if beta_newer_than_alpha {
                    if stable_newer_than_beta {
                        return stable_package;
                    }

                    return beta_package;
                }

                alpha_package
            }
        }
    }
}

impl PartialEq for Addon {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl PartialOrd for Addon {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.title.cmp(&other.title).then_with(|| {
            self.relevant_release_package()
                .cmp(&other.relevant_release_package())
                .reverse()
        }))
    }
}

impl Ord for Addon {
    fn cmp(&self, other: &Self) -> Ordering {
        self.title.cmp(&other.title).then_with(|| {
            self.relevant_release_package()
                .cmp(&other.relevant_release_package())
                .reverse()
        })
    }
}
impl Eq for Addon {}
