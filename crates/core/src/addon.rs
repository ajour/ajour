use crate::{config::Flavor, curse_api, tukui_api, utility::strip_non_digits};
use chrono::prelude::*;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum AddonVersionKey {
    Local,
    Remote,
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct RemotePackage {
    pub version: String,
    pub download_url: String,
    pub file_id: Option<i64>,
    pub date_time: Option<DateTime<Utc>>,
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

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize, Hash, PartialOrd, Ord)]
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
    Unknown,
    Ajour(Option<String>),
    Downloading,
    Fingerprint,
    Unpacking,
    // TODO: I have currently removed the state where curse-id only addons become corrupt.
    // It can happen that the fingerprint is unknown to the API but everything else is good.
    // This is properly not the best solution going forward, but for now it solves the purpose.
    Corrupted,
    Updatable,
}

#[derive(Default, Debug, Clone)]
/// Struct which stores identifiers for the different repositories.
pub struct RepositoryIdentifiers {
    pub wowi: Option<String>,
    pub tukui: Option<String>,
    pub curse: Option<u32>,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Repository {
    WowI,
    Tukui,
    Curse,
}

/// Struct that stores the metadata parsed from an Addon folder's
/// `.toc` file
#[derive(Debug, Clone)]
pub struct AddonFolder {
    /// ID is always the folder name
    pub id: String,
    pub title: String,
    pub path: PathBuf,
    pub author: Option<String>,
    pub notes: Option<String>,
    pub version: Option<String>,
    pub repository_identifiers: RepositoryIdentifiers,
    pub dependencies: Vec<String>,
    pub fingerprint: Option<u32>,
}

#[allow(clippy::too_many_arguments)]
impl AddonFolder {
    pub fn new(
        id: String,
        title: String,
        path: PathBuf,
        author: Option<String>,
        notes: Option<String>,
        version: Option<String>,
        repository_identifiers: RepositoryIdentifiers,
        dependencies: Vec<String>,
    ) -> Self {
        AddonFolder {
            id,
            title,
            path,
            author,
            notes,
            version,
            repository_identifiers,
            dependencies,
            fingerprint: None,
        }
    }
}

/// Metadata from one of the repository APIs
#[derive(Default, Debug, Clone)]
pub(crate) struct RepositoryMetadata {
    // If these fields are not set, we will try to get the value
    // from the primary `AddonFolder` of the `Addon`
    pub(crate) version: Option<String>,
    pub(crate) title: Option<String>,
    pub(crate) author: Option<String>,
    pub(crate) notes: Option<String>,

    // These fields are only available from the repo API
    pub(crate) website_url: Option<String>,
    pub(crate) game_version: Option<String>,
    pub(crate) file_id: Option<i64>,

    /// Remote packages available from the Repository
    pub(crate) remote_packages: HashMap<ReleaseChannel, RemotePackage>,
}

impl RepositoryMetadata {
    fn empty() -> Self {
        Default::default()
    }
}

#[derive(Debug, Clone)]
/// Struct which stores information about a single Addon. This struct is enriched
/// with metadata from the active repository for the addon. If there is no match
/// to any repository, metadata will be used from the primary `AddonFolder` for this
/// `Addon`.
pub struct Addon {
    /// Id of the `AddonFolder` that will serve as a fallback for metadata if no
    /// match to any Repository or if those fields don't populate from the active repository
    /// API. Also serves as the unique identifier for this `Addon`.
    ///
    /// When we match against Curse which has `modules` for bundling multiple folders
    /// into a single Addon, we use the first folder name alphabetically.
    ///
    /// When matching against Tukui, we use the folder which has the Tukui project id
    pub primary_folder_id: String,
    /// All `AddonFolder`'s provided by this `Addon`
    pub folders: Vec<AddonFolder>,

    pub state: AddonState,
    pub release_channel: ReleaseChannel,
    pub(crate) repository_identifiers: RepositoryIdentifiers,

    /// The `Repository` that this addon is linked against.
    pub active_repository: Option<Repository>,
    pub(crate) repository_metadata: RepositoryMetadata,

    // States for GUI
    #[cfg(feature = "gui")]
    pub details_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub remote_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub local_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub full_changelog_btn_state: iced_native::button::State,
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
    pub fn empty(primary_folder_id: &str) -> Self {
        Addon {
            primary_folder_id: primary_folder_id.to_string(),
            folders: Default::default(),
            active_repository: None,
            release_channel: Default::default(),
            state: AddonState::Ajour(None),
            repository_identifiers: Default::default(),
            repository_metadata: Default::default(),

            #[cfg(feature = "gui")]
            details_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            remote_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            local_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            full_changelog_btn_state: Default::default(),
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

    /// Creates an `Addon` from the Tukui package
    pub fn from_tukui_package(
        tukui_id: String,
        addon_folders: &[AddonFolder],
        package: &tukui_api::TukuiPackage,
    ) -> Self {
        let mut remote_packages = HashMap::new();
        {
            let version = package.version.clone();
            let download_url = package.url.clone();

            let date_time = NaiveDateTime::parse_from_str(&package.lastupdate, "%Y-%m-%d %H:%M:%S")
                .map_or(
                    NaiveDateTime::parse_from_str(
                        &format!("{} 00:00:00", &package.lastupdate),
                        "%Y-%m-%d %T",
                    ),
                    Result::Ok,
                )
                .map(|d| Utc.from_utc_datetime(&d))
                .ok();

            let package = RemotePackage {
                version,
                download_url,
                date_time,
                file_id: None,
            };

            // Since Tukui does not support release channels, our default is 'stable'.
            remote_packages.insert(ReleaseChannel::Stable, package);
        }

        let website_url = Some(package.web_url.clone());
        let game_version = package.patch.clone();

        let mut metadata = RepositoryMetadata::empty();
        metadata.website_url = website_url;
        metadata.game_version = game_version;
        metadata.remote_packages = remote_packages;

        // Shouldn't panic since we only get `Package` for tukui id's in our
        // parsed `AddonFolder`s
        let primary_folder_id = addon_folders
            .iter()
            .find(|f| f.repository_identifiers.tukui == Some(tukui_id.clone()))
            .map(|f| f.id.clone())
            .unwrap_or_else(|| tukui_id.clone());

        let mut addon = Addon::empty(&primary_folder_id);
        addon.active_repository = Some(Repository::Tukui);
        addon.repository_identifiers.tukui = Some(tukui_id);
        addon.repository_metadata = metadata;

        // Get folders that match primary folder id or any folder that has a dependency
        // of primary folder id
        let folders = addon_folders
            .iter()
            .filter(|f| f.id == primary_folder_id || f.dependencies.contains(&primary_folder_id))
            .cloned()
            .collect();
        addon.folders = folders;

        addon
    }

    /// Creates an `Addon` from the Curse package. This is a fallback for when we don't
    /// have an exact fingerprint match, but we have a curse id for the addon.
    pub fn from_curse_package(
        package: &curse_api::Package,
        flavor: Flavor,
        addon_folders: &[AddonFolder],
    ) -> Option<Self> {
        let mut remote_packages = HashMap::new();

        let mut stable_exists = false;
        let mut beta_exists = false;
        let mut alpha_exists = false;

        for file in package.latest_files.iter() {
            let game_version_flavor = file.game_version_flavor.as_ref();
            if !file.is_alternate && game_version_flavor == Some(&flavor.curse_format()) {
                let version = file.display_name.clone();
                let download_url = file.download_url.clone();
                let date_time = DateTime::parse_from_rfc3339(&file.file_date)
                    .map(|d| d.with_timezone(&Utc))
                    .ok();
                let package = RemotePackage {
                    version,
                    download_url,
                    date_time,
                    file_id: Some(file.id),
                };

                match file.release_type {
                    1 /* stable */ => {
                        stable_exists = true;
                        remote_packages.insert(ReleaseChannel::Stable, package);
                    }
                    2 /* beta */ => {
                        beta_exists = true;
                        remote_packages.insert(ReleaseChannel::Beta, package);
                    }
                    3 /* alpha */ => {
                        alpha_exists = true;
                        remote_packages.insert(ReleaseChannel::Alpha, package);
                    }
                    _ => ()
                };
            }
        }

        let mut metadata = RepositoryMetadata::empty();
        metadata.remote_packages = remote_packages;

        let release_type = if stable_exists {
            1
        } else if beta_exists {
            2
        } else if alpha_exists {
            3
        } else {
            return None;
        };

        let file = package
            .latest_files
            .iter()
            .find(|file| {
                !file.is_alternate
                    && file.game_version_flavor.as_ref() == Some(&flavor.curse_format())
                    && file.release_type == release_type
            })
            .unwrap_or_else(|| unreachable!("No file in curse package for {}", package.id));

        // Shouldn't panic since we got this curse id from an `AddonFolder`. We use the
        // first folder (sorted alphabetically) that has a match on curse id as the primary id.
        // If no folders have a curse id, we just use the first folder alphabetically.
        let primary_folder_id = if let Some(f) = addon_folders.iter().find(|f| {
            f.repository_identifiers.curse == Some(package.id)
                && file.modules.iter().any(|m| m.foldername == f.id)
        }) {
            f.id.clone()
        } else {
            addon_folders
                .iter()
                .find(|f| file.modules.iter().any(|m| m.foldername == f.id))
                .as_ref()
                .unwrap()
                .id
                .clone()
        };

        let mut addon = Addon::empty(&primary_folder_id);
        addon.active_repository = Some(Repository::Curse);
        addon.repository_identifiers.curse = Some(package.id);
        addon.repository_metadata = metadata;

        let folders: Vec<AddonFolder> = addon_folders
            .iter()
            .filter(|f| file.modules.iter().any(|m| m.foldername == f.id))
            .cloned()
            .collect();
        addon.folders = folders;

        Some(addon)
    }

    /// Creates an `Addon` from the Curse fingerprint info
    pub fn from_curse_fingerprint_info(
        curse_id: u32,
        info: &curse_api::AddonFingerprintInfo,
        flavor: Flavor,
        addon_folders: &[AddonFolder],
    ) -> Self {
        let mut remote_packages = HashMap::new();

        for file in info.latest_files.iter() {
            let game_version_flavor = file.game_version_flavor.as_ref();
            if !file.is_alternate && game_version_flavor == Some(&flavor.curse_format()) {
                let version = file.display_name.clone();
                let download_url = file.download_url.clone();
                let date_time = DateTime::parse_from_rfc3339(&file.file_date)
                    .map(|d| d.with_timezone(&Utc))
                    .ok();
                let package = RemotePackage {
                    version,
                    download_url,
                    date_time,
                    file_id: Some(file.id),
                };

                match file.release_type {
                    1 /* stable */ => {
                        remote_packages.insert(ReleaseChannel::Stable, package);
                    }
                    2 /* beta */ => {
                        remote_packages.insert(ReleaseChannel::Beta, package);
                    }
                    3 /* alpha */ => {
                        remote_packages.insert(ReleaseChannel::Alpha, package);
                    }
                    _ => ()
                };
            }
        }

        let version = Some(info.file.display_name.clone());
        let file_id = Some(info.file.id);
        let game_version = info.file.game_version.get(0).cloned();

        let mut metadata = RepositoryMetadata::empty();
        metadata.version = version;
        metadata.file_id = file_id;
        metadata.game_version = game_version;
        metadata.remote_packages = remote_packages;

        // Shouldn't panic since we have an exact match on the fingerprint. We use the
        // first folder (sorted alphabetically) that has a match on curse id as the primary id.
        // If no folders have a curse id, we just use the first folder alphabetically.
        let primary_folder_id = if addon_folders.is_empty() {
            // This is assigned when we install an addon via the catalog and we don't
            // yet know the AddonFolders for it. This will get updated after the unpack
            // finished and we can assign the AddonFolders for the addon.
            info.id.to_string()
        } else if let Some(f) = addon_folders.iter().find(|f| {
            f.repository_identifiers.curse == Some(curse_id)
                && info.file.modules.iter().any(|m| m.foldername == f.id)
        }) {
            f.id.clone()
        } else {
            addon_folders
                .iter()
                .find(|f| info.file.modules.iter().any(|m| m.foldername == f.id))
                .as_ref()
                .unwrap()
                .id
                .clone()
        };

        let mut addon = Addon::empty(&primary_folder_id);
        addon.active_repository = Some(Repository::Curse);
        addon.repository_identifiers.curse = Some(curse_id);
        addon.repository_metadata = metadata;

        let folders: Vec<AddonFolder> = addon_folders
            .iter()
            .filter(|f| info.file.modules.iter().any(|m| m.foldername == f.id))
            .cloned()
            .collect();
        addon.folders = folders;

        addon
    }

    /// Returns the version of the addon
    pub fn version(&self) -> Option<&str> {
        if self.repository_metadata.version.is_some() {
            self.repository_metadata.version.as_deref()
        } else {
            self.folders
                .iter()
                .find(|f| f.id == self.primary_folder_id)
                .map(|f| f.version.as_deref())
                .flatten()
        }
    }

    /// Sets the version of the addon
    pub fn set_version(&mut self, version: String) {
        self.repository_metadata.version = Some(version);
    }

    /// Returns the title of the addon.
    pub fn title(&self) -> &str {
        let meta_title = self.repository_metadata.title.as_deref();
        let folder_title = self
            .primary_addon_folder()
            .map(|f| f.title.as_str())
            .unwrap_or_else(|| self.primary_folder_id.as_str());

        meta_title.unwrap_or(folder_title)
    }

    /// Returns the author of the addon.
    pub fn author(&self) -> Option<&str> {
        let meta_author = self.repository_metadata.author.as_deref();
        let folder_author = self
            .primary_addon_folder()
            .map(|f| f.author.as_deref())
            .flatten();

        meta_author.map_or(folder_author, Option::Some)
    }

    /// Returns the game version of the addon.
    pub fn game_version(&self) -> Option<&str> {
        self.repository_metadata.game_version.as_deref()
    }

    /// Returns the notes of the addon.
    pub fn notes(&self) -> Option<&str> {
        let meta_notes = self.repository_metadata.notes.as_deref();
        let folder_notes = self
            .primary_addon_folder()
            .map(|f| f.notes.as_deref())
            .flatten();

        meta_notes.map_or(folder_notes, Option::Some)
    }

    /// Returns the website url of the addon.
    pub fn website_url(&self) -> Option<&str> {
        self.repository_metadata.website_url.as_deref()
    }

    /// Returns the curse id of the addon, if applicable.
    pub fn curse_id(&self) -> Option<u32> {
        let folder_curse = self
            .primary_addon_folder()
            .map(|f| f.repository_identifiers.curse)
            .flatten();

        self.repository_identifiers
            .curse
            .map_or(folder_curse, Option::Some)
    }

    /// Returns the tukui id of the addon, if applicable.
    pub fn tukui_id(&self) -> Option<&str> {
        let folder_tukui = self
            .primary_addon_folder()
            .map(|f| f.repository_identifiers.tukui.as_deref())
            .flatten();

        self.repository_identifiers
            .tukui
            .as_deref()
            .map_or(folder_tukui, Option::Some)
    }

    /// Returns the wowi id of the addon, if applicable.
    pub fn wowi_id(&self) -> Option<&str> {
        let folder_wowi = self
            .primary_addon_folder()
            .map(|f| f.repository_identifiers.wowi.as_deref())
            .flatten();

        self.repository_identifiers
            .wowi
            .as_deref()
            .map_or(folder_wowi, Option::Some)
    }

    /// Set the curse id for the addon
    pub fn set_curse_id(&mut self, curse_id: u32) {
        self.repository_identifiers.curse = Some(curse_id);
    }

    /// Set the tukui id for the addon
    pub fn set_tukui_id(&mut self, tukui_id: String) {
        self.repository_identifiers.tukui = Some(tukui_id);
    }

    /// Set the wowi id for the addon
    pub fn set_wowi_id(&mut self, wowi_id: String) {
        self.repository_identifiers.wowi = Some(wowi_id);
    }

    /// Set title for the addon
    pub fn set_title(&mut self, title: String) {
        self.repository_metadata.title = Some(title);
    }

    pub fn remote_packages(&self) -> &HashMap<ReleaseChannel, RemotePackage> {
        &self.repository_metadata.remote_packages
    }

    pub fn file_id(&self) -> Option<i64> {
        self.repository_metadata.file_id
    }

    fn primary_addon_folder(&self) -> Option<&AddonFolder> {
        self.folders.iter().find(|f| f.id == self.primary_folder_id)
    }

    /// Returns the repository id for the active repository
    pub fn repository_id(&self) -> Option<String> {
        match self.active_repository {
            Some(repo) => match repo {
                Repository::Curse => self.repository_identifiers.curse.map(|i| i.to_string()),
                Repository::Tukui => self.repository_identifiers.tukui.clone(),
                Repository::WowI => self.repository_identifiers.wowi.clone(),
            },
            None => None,
        }
    }

    /// Function returns a `bool` indicating if the user has manually ignored the addon.
    pub fn is_ignored(&self, ignored: Option<&Vec<String>>) -> bool {
        match ignored {
            Some(ignored) => ignored.iter().any(|i| i == &self.primary_folder_id),
            _ => false,
        }
    }

    /// Function returns a `bool` indicating if the `remote_package` is a update.
    pub fn is_updatable(&self, remote_package: &RemotePackage) -> bool {
        if self.repository_metadata.file_id.is_none() {
            return self.is_updatable_by_version_comparison(remote_package);
        }

        remote_package.file_id > self.repository_metadata.file_id
    }

    /// We strip both version for non digits, and then
    /// checks if `remote_version` is a sub_slice of `local_version`.
    fn is_updatable_by_version_comparison(&self, remote_package: &RemotePackage) -> bool {
        if let Some(version) = self.version() {
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
        let remote_packages = &self.repository_metadata.remote_packages;

        let stable_package = remote_packages.get(&ReleaseChannel::Stable);
        let beta_package = remote_packages.get(&ReleaseChannel::Beta);
        let alpha_package = remote_packages.get(&ReleaseChannel::Alpha);

        fn should_choose_other(
            base: &Option<&RemotePackage>,
            other: &Option<&RemotePackage>,
        ) -> bool {
            if base.is_none() {
                return true;
            }

            if other.is_none() {
                return false;
            }

            if let (Some(base), Some(other)) = (base, other) {
                other.file_id > base.file_id
            } else {
                false
            }
        }

        match &self.release_channel {
            ReleaseChannel::Stable => stable_package,
            ReleaseChannel::Beta => {
                let choose_stable = should_choose_other(&beta_package, &stable_package);
                if choose_stable {
                    return stable_package;
                }

                beta_package
            }
            ReleaseChannel::Alpha => {
                let choose_stable = should_choose_other(&alpha_package, &stable_package);
                let choose_beta = should_choose_other(&alpha_package, &beta_package);

                if choose_beta {
                    let choose_stable = should_choose_other(&beta_package, &stable_package);
                    if choose_stable {
                        return stable_package;
                    }

                    return beta_package;
                }

                if choose_stable {
                    return stable_package;
                }

                alpha_package
            }
        }
    }
}

impl PartialEq for Addon {
    fn eq(&self, other: &Self) -> bool {
        self.primary_folder_id == other.primary_folder_id
    }
}

impl PartialOrd for Addon {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.title().cmp(&other.title()).then_with(|| {
            self.relevant_release_package()
                .cmp(&other.relevant_release_package())
                .reverse()
        }))
    }
}

impl Ord for Addon {
    fn cmp(&self, other: &Self) -> Ordering {
        self.title().cmp(&other.title()).then_with(|| {
            self.relevant_release_package()
                .cmp(&other.relevant_release_package())
                .reverse()
        })
    }
}
impl Eq for Addon {}
