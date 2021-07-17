use crate::{
    error::{ParseError, RepositoryError},
    repository::{
        Changelog, GitKind, GlobalReleaseChannel, ReleaseChannel, RemotePackage,
        RepositoryIdentifiers, RepositoryKind, RepositoryMetadata, RepositoryPackage,
    },
    utility::strip_non_digits,
};

use std::cmp::Ordering;
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum AddonVersionKey {
    Local,
    Remote,
}

#[derive(Debug, Clone, Eq, PartialEq, PartialOrd, Ord)]
pub enum AddonState {
    Ignored,
    Unknown,
    Completed,
    Downloading,
    Error(String),
    Fingerprint,
    Idle,
    Unpacking,
    Retry,
    Updatable,
}

/// Struct that stores the metadata parsed from an Addon folder's
/// `.toc` file
#[derive(Debug, Clone, Default)]
pub struct AddonFolder {
    /// ID is always the folder name
    pub id: String,
    pub title: String,
    pub interface: Option<String>,
    pub path: PathBuf,
    pub author: Option<String>,
    pub notes: Option<String>,
    pub version: Option<String>,
    pub repository_identifiers: RepositoryIdentifiers,
    pub dependencies: Vec<String>,
    pub fingerprint: Option<u32>,
}

impl PartialEq for AddonFolder {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Eq for AddonFolder {}

impl PartialOrd for AddonFolder {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.id.cmp(&other.id))
    }
}

impl Ord for AddonFolder {
    fn cmp(&self, other: &Self) -> Ordering {
        self.id.cmp(&other.id)
    }
}

#[allow(clippy::too_many_arguments)]
impl AddonFolder {
    pub(crate) fn new(
        id: String,
        title: String,
        interface: Option<String>,
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
            interface,
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

    /// The repository package that this addon is linked against.
    pub(crate) repository: Option<RepositoryPackage>,

    // States for GUI
    #[cfg(feature = "gui")]
    pub details_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub update_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub delete_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub delete_saved_variables_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub ignore_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub unignore_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub website_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub pick_release_channel_state: iced_native::pick_list::State<ReleaseChannel>,
    #[cfg(feature = "gui")]
    pub changelog_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub remote_version_btn_state: iced_native::button::State,
    #[cfg(feature = "gui")]
    pub fuzzy_score: Option<i64>,
}

impl Addon {
    pub fn empty(primary_folder_id: &str) -> Self {
        Addon {
            primary_folder_id: primary_folder_id.to_string(),
            folders: Default::default(),
            release_channel: Default::default(),
            state: AddonState::Idle,
            repository: Default::default(),

            #[cfg(feature = "gui")]
            details_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            update_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            delete_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            delete_saved_variables_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            ignore_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            unignore_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            website_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            pick_release_channel_state: Default::default(),
            #[cfg(feature = "gui")]
            changelog_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            remote_version_btn_state: Default::default(),
            #[cfg(feature = "gui")]
            fuzzy_score: None,
        }
    }

    pub(crate) fn build_with_repo_and_folders(
        repo_package: RepositoryPackage,
        folders: Vec<AddonFolder>,
    ) -> Result<Self, ParseError> {
        if folders.is_empty() {
            return Err(ParseError::BuildAddonEmptyFolders);
        }

        let mut addon = Addon::empty("");
        addon.repository = Some(repo_package);

        addon.update_addon_folders(folders);

        Ok(addon)
    }

    pub fn set_repository(&mut self, repo_package: RepositoryPackage) {
        self.repository = Some(repo_package);
    }

    pub fn set_remote_package_from_repo_package(&mut self, repo_package: &RepositoryPackage) {
        if let Some(repo) = self.repository.as_mut() {
            repo.metadata.remote_packages = repo_package.metadata.remote_packages.clone();
        }
    }

    pub fn update_addon_folders(&mut self, mut folders: Vec<AddonFolder>) {
        if !folders.is_empty() {
            folders.sort_by(|a, b| a.id.cmp(&b.id));

            // Assign the primary folder id based on the first folder alphabetically with
            // a matching repository identifier otherwise just the first
            // folder alphabetically
            let primary_folder_id = if let Some(folder) = folders.iter().find(|f| {
                if let Some(repo) = self.repository_kind() {
                    match repo {
                        RepositoryKind::Curse => {
                            self.repository_id()
                                == f.repository_identifiers
                                    .curse
                                    .as_ref()
                                    .map(i32::to_string)
                                    .as_deref()
                        }
                        RepositoryKind::Tukui => {
                            self.repository_id() == f.repository_identifiers.tukui.as_deref()
                        }
                        RepositoryKind::WowI => {
                            self.repository_id() == f.repository_identifiers.wowi.as_deref()
                        }
                        // For git & townlong sources, prioritize the folder that has a version in it
                        RepositoryKind::TownlongYak => f.version.is_some(),
                        RepositoryKind::Git(_) => f.version.is_some(),
                    }
                } else {
                    false
                }
            }) {
                folder.id.clone()
            } else {
                // Wont fail since we already checked if vec is empty
                folders.get(0).map(|f| f.id.clone()).unwrap()
            };
            self.primary_folder_id = primary_folder_id;
            self.folders = folders;
        }
    }

    pub fn repository(&self) -> Option<&RepositoryPackage> {
        self.repository.as_ref()
    }

    fn metadata(&self) -> Option<&RepositoryMetadata> {
        self.repository().map(|r| &r.metadata)
    }

    /// Returns the repository kind linked to this addon
    pub fn repository_kind(&self) -> Option<RepositoryKind> {
        self.repository.as_ref().map(|r| r.kind)
    }

    /// Returns the version of the addon
    pub fn version(&self) -> Option<&str> {
        if self
            .metadata()
            .map(|m| m.version.as_deref())
            .flatten()
            .is_some()
        {
            self.metadata().map(|m| m.version.as_deref()).flatten()
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
        if let Some(metadata) = self.repository.as_mut().map(|r| &mut r.metadata) {
            metadata.version = Some(version);
        }
    }

    /// Sets the file id of the addon
    pub fn set_file_id(&mut self, file_id: i64) {
        if let Some(metadata) = self.repository.as_mut().map(|r| &mut r.metadata) {
            metadata.file_id = Some(file_id);
        }
    }

    /// Returns the title of the addon.
    pub fn title(&self) -> &str {
        let meta_title = self.metadata().map(|m| m.title.as_deref()).flatten();
        let folder_title = self
            .primary_addon_folder()
            .map(|f| f.title.as_str())
            .unwrap_or_else(|| self.primary_folder_id.as_str());

        meta_title.unwrap_or(folder_title)
    }

    /// Returns the author of the addon.
    pub fn author(&self) -> Option<&str> {
        let meta_author = self.metadata().map(|m| m.author.as_deref()).flatten();
        let folder_author = self
            .primary_addon_folder()
            .map(|f| f.author.as_deref())
            .flatten();

        meta_author.map_or(folder_author, Option::Some)
    }

    /// Returns the game version of the addon.
    pub fn game_version(&self) -> Option<&str> {
        if self
            .metadata()
            .map(|m| m.game_version.as_deref())
            .flatten()
            .filter(|s| !s.is_empty())
            .is_some()
        {
            self.metadata().map(|m| m.game_version.as_deref()).flatten()
        } else {
            self.folders
                .iter()
                .find(|f| f.id == self.primary_folder_id)
                .map(|f| f.interface.as_deref())
                .flatten()
        }
    }

    /// Returns the notes of the addon.
    pub fn notes(&self) -> Option<&str> {
        let meta_notes = self.metadata().map(|m| m.notes.as_deref()).flatten();
        let folder_notes = self
            .primary_addon_folder()
            .map(|f| f.notes.as_deref())
            .flatten();

        meta_notes.map_or(folder_notes, Option::Some)
    }

    /// Returns the website url of the addon.
    pub fn website_url(&self) -> Option<&str> {
        self.metadata().map(|m| m.website_url.as_deref()).flatten()
    }

    /// Returns the changelog url of the addon.
    pub fn changelog_url(&self, default_release_channel: GlobalReleaseChannel) -> Option<String> {
        let url = self.metadata().map(|m| m.changelog_url.clone()).flatten();

        match self.repository_kind() {
            Some(RepositoryKind::Git(GitKind::Github)) => {
                let tag = self
                    .relevant_release_package(default_release_channel)
                    .map(|r| r.version);

                if let Some(tag) = tag {
                    url.map(|url| format!("{}/tag/{}", url, tag))
                } else {
                    url
                }
            }
            Some(RepositoryKind::Curse) => {
                let file = self
                    .relevant_release_package(default_release_channel)
                    .map(|r| r.file_id)
                    .flatten();

                if let Some(file) = file {
                    url.map(|url| format!("{}/{}", url, file))
                } else {
                    url
                }
            }
            Some(_) => url,
            None => None,
        }
    }

    pub async fn changelog(
        &self,
        default_release_channel: GlobalReleaseChannel,
    ) -> Result<Changelog, RepositoryError> {
        let text = if let Some(repo) = self.repository.as_ref() {
            repo.get_changelog(self.release_channel, default_release_channel)
                .await?
        } else {
            None
        };

        Ok(Changelog { text })
    }

    /// Returns the curse id of the addon, if applicable.
    pub fn curse_id(&self) -> Option<i32> {
        if self.repository_kind() == Some(RepositoryKind::Curse) {
            self.repository()
                .map(|r| r.id.parse::<i32>().ok())
                .flatten()
        } else {
            self.primary_addon_folder()
                .map(|f| f.repository_identifiers.curse)
                .flatten()
        }
    }

    /// Returns the tukui id of the addon, if applicable.
    pub fn tukui_id(&self) -> Option<&str> {
        if self.repository_kind() == Some(RepositoryKind::Tukui) {
            self.repository().map(|r| r.id.as_str())
        } else {
            self.primary_addon_folder()
                .map(|f| f.repository_identifiers.tukui.as_deref())
                .flatten()
        }
    }

    /// Returns the wowi id of the addon, if applicable.
    pub fn wowi_id(&self) -> Option<&str> {
        if self.repository_kind() == Some(RepositoryKind::WowI) {
            self.repository().map(|r| r.id.as_str())
        } else {
            self.primary_addon_folder()
                .map(|f| f.repository_identifiers.wowi.as_deref())
                .flatten()
        }
    }

    /// Returns the hub id of the addon, if applicable.
    pub fn hub_id(&self) -> Option<i32> {
        if self.repository_kind() == Some(RepositoryKind::TownlongYak) {
            self.repository()
                .map(|r| r.id.parse::<i32>().ok())
                .flatten()
        } else {
            None
        }
    }

    pub fn remote_packages(&self) -> HashMap<ReleaseChannel, RemotePackage> {
        self.metadata()
            .map(|m| &m.remote_packages)
            .cloned()
            .unwrap_or_default()
    }

    pub fn file_id(&self) -> Option<i64> {
        self.metadata().map(|f| f.file_id).flatten()
    }

    fn primary_addon_folder(&self) -> Option<&AddonFolder> {
        self.folders.iter().find(|f| f.id == self.primary_folder_id)
    }

    /// Returns the repository id for the active repository
    pub fn repository_id(&self) -> Option<&str> {
        self.repository().map(|r| r.id.as_str())
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
        let file_id = self.file_id();

        if file_id.is_none() {
            return self.is_updatable_by_version_comparison(remote_package);
        }

        remote_package.file_id > file_id
    }

    /// We strip both version for non digits, and then
    /// checks if `remote_version` is a sub_slice of `local_version`.
    fn is_updatable_by_version_comparison(&self, remote_package: &RemotePackage) -> bool {
        if let Some(version) = self.version() {
            let srv = strip_non_digits(&remote_package.version);
            let slv = strip_non_digits(&version);

            return !slv.contains(&srv);
        }

        false
    }

    /// Returns the first release_package which is `Some`.
    pub(crate) fn fallback_release_package(&self) -> Option<RemotePackage> {
        let mut remote_packages = self.remote_packages();
        if let Some(stable_package) = remote_packages.remove(&ReleaseChannel::Stable) {
            Some(stable_package)
        } else if let Some(beta_package) = remote_packages.remove(&ReleaseChannel::Beta) {
            Some(beta_package)
        } else {
            remote_packages.remove(&ReleaseChannel::Alpha)
        }
    }

    /// Returns the relevant release_package for the addon.
    /// Logic is that if a release channel above the selected is newer, we return that instead.
    pub fn relevant_release_package(
        &self,
        default_release_channel: GlobalReleaseChannel,
    ) -> Option<RemotePackage> {
        let mut remote_packages = self.remote_packages();

        let stable_package = remote_packages.remove(&ReleaseChannel::Stable);
        let beta_package = remote_packages.remove(&ReleaseChannel::Beta);
        let alpha_package = remote_packages.remove(&ReleaseChannel::Alpha);

        let release_channel = if self.release_channel == ReleaseChannel::Default {
            default_release_channel.convert_to_release_channel()
        } else {
            self.release_channel
        };

        fn should_choose_other(
            base: &Option<RemotePackage>,
            other: &Option<RemotePackage>,
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

        match release_channel {
            ReleaseChannel::Default => None,
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
        Some(self.title().cmp(&other.title()))
    }
}

impl Ord for Addon {
    fn cmp(&self, other: &Self) -> Ordering {
        self.title().cmp(&other.title())
    }
}

impl Eq for Addon {}
