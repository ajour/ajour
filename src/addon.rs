use crate::{
    config::Flavor,
    curse_api, tukui_api,
    utility::{strip_non_digits, truncate},
    wowinterface_api,
};
use std::cmp::Ordering;
use std::path::PathBuf;

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum AddonState {
    Ajour(Option<String>),
    Loading,
    Updatable,
    Downloading,
    Unpacking,
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
    pub remote_version: Option<String>,
    pub remote_url: Option<String>,
    pub remote_title: Option<String>,
    pub path: PathBuf,
    pub dependencies: Vec<String>,
    pub state: AddonState,
    pub repository_identifiers: RepositoryIdentifiers,
    // If an addon consists of multiple folders, and all of them has a version all will be
    // shown. We try to bundle them together as one, in that case. See: https://github.com/casperstorm/ajour/issues/39
    // When a addon is bundled, the only difference is we use `remote_title` rather than `title` to
    // get a name representing the bundle as a whole.
    pub is_bundle: bool,

    // Readable strings. Truncated to look better in the UI.
    pub readable_local_version: Option<String>,
    pub readable_remote_version: Option<String>,

    // States for GUI
    pub details_btn_state: iced::button::State,
    pub update_btn_state: iced::button::State,
    pub force_btn_state: iced::button::State,
    pub delete_btn_state: iced::button::State,
    pub ignore_btn_state: iced::button::State,
    pub unignore_btn_state: iced::button::State,
}

impl Addon {
    /// Creates a new Addon
    pub fn new(
        title: String,
        author: Option<String>,
        notes: Option<String>,
        version: Option<String>,
        path: PathBuf,
        dependencies: Vec<String>,
        repository_identifiers: RepositoryIdentifiers,
    ) -> Self {
        let os_title = path.file_name().unwrap();
        let str_title = os_title.to_str().unwrap();

        // Converts version to a readable truncated string.
        let readable_local_version = version.clone().map(|v| truncate_version(&v).to_string());

        Addon {
            id: str_title.to_string(),
            title,
            author,
            notes,
            version,
            remote_version: None,
            remote_url: None,
            remote_title: None,
            path,
            dependencies,
            state: AddonState::Ajour(None),
            repository_identifiers,
            is_bundle: false,
            readable_local_version,
            readable_remote_version: None,
            details_btn_state: Default::default(),
            update_btn_state: Default::default(),
            force_btn_state: Default::default(),
            delete_btn_state: Default::default(),
            ignore_btn_state: Default::default(),
            unignore_btn_state: Default::default(),
        }
    }

    /// Packages from Wowinterface.
    ///
    /// This functions takes a `&Vec<Package>` and finds the one matching `self`.
    /// It then updates self, with the information from that package.
    pub fn apply_wowi_packages(&mut self, packages: &[wowinterface_api::Package]) {
        if let Some(wowi_id) = self.repository_identifiers.wowi.as_ref() {
            let package = packages.iter().find(|a| &a.id == wowi_id);
            if let Some(package) = package {
                self.remote_url = Some(crate::wowinterface_api::remote_url(&wowi_id));
                self.remote_title = Some(package.title.clone());
                self.remote_version = Some(package.version.clone());
                self.readable_remote_version = self
                    .remote_version
                    .clone()
                    .map(|v| truncate_version(&v).to_string());

                if self.is_updatable() {
                    self.state = AddonState::Updatable;
                }
            }
        }
    }

    /// Package from Tukui.
    ///
    /// This function takes a `Package` and updates self with the information.
    pub fn apply_tukui_package(&mut self, package: &tukui_api::Package) {
        self.remote_url = Some(package.url.clone());
        self.remote_title = Some(package.name.clone());
        self.remote_version = Some(package.version.clone());
        self.readable_remote_version = self
            .remote_version
            .clone()
            .map(|v| truncate_version(&v).to_string());

        if self.is_updatable() {
            self.state = AddonState::Updatable;
        }
    }

    /// Package from Curse.
    ///
    /// This function takes a `Package` and updates self with the information.
    pub fn apply_curse_package(&mut self, package: &curse_api::Package, flavor: &Flavor) {
        let file = package.latest_files.iter().find(|f| {
            f.release_type == 1 && f.game_version_flavor == format!("wow_{}", flavor.to_string())
        });

        if let Some(file) = file {
            self.remote_url = Some(file.download_url.clone());
            self.remote_title = Some(package.name.clone());
            self.remote_version = Some(file.display_name.clone());
            self.readable_remote_version = self
                .remote_version
                .clone()
                .map(|v| truncate_version(&v).to_string());
        }

        if self.is_updatable() {
            self.state = AddonState::Updatable;
        }
    }

    /// Packages from Curse.
    ///
    /// This functions takes a `&Vec<Package>` and finds the one matching `self`.
    /// This is a slighty more complicated function, because it comes from a search
    /// result, meaning none of the packages might match.
    ///
    /// The following is being done to check if we have a match:
    /// 1. Loops each packages, and find the `File` which is stable and has right flavor.
    /// 2. Then we loop each `Module` in the `File` and match filename with `self`.
    /// 3. If tf we find a `Module` from step 2, we know we can update `self`
    pub fn apply_curse_packages(&mut self, packages: &[curse_api::Package], flavor: &Flavor) {
        for package in packages {
            let file = package.latest_files.iter().find(|f| {
                f.release_type == 1 // 1 is stable, 2 is beta, 3 is alpha.
                    && !f.is_alternate
                    && f.game_version_flavor == format!("wow_{}", flavor.to_string())
            });
            if let Some(file) = file {
                let module = file.modules.iter().find(|m| m.foldername == self.id);
                if module.is_some() {
                    self.remote_url = Some(file.download_url.clone());
                    self.remote_title = Some(package.name.clone());
                    self.remote_version = Some(file.display_name.clone());
                    self.readable_remote_version = self
                        .remote_version
                        .clone()
                        .map(|v| truncate_version(&v).to_string());

                    if self.is_updatable() {
                        self.state = AddonState::Updatable;
                    }

                    // Breaks out on first hit.
                    break;
                }
            }
        }
    }

    /// Function returns a `bool` which indicates if a addon is a parent.
    /// For now we have the following requirements to be a parent `Addon`:
    ///
    /// - Has to have a version.
    /// - None of its dependency addons have titles that are substrings of its own title.
    pub fn is_parent(&self) -> bool {
        match self.version {
            Some(_) => {
                for dependency in &self.dependencies {
                    if self.id.contains(dependency) {
                        return false;
                    }
                }

                true
            }
            None => false,
        }
    }

    /// Function returns a `bool` indicating if the user has manually ignored the addon.
    pub fn is_ignored(&self, ignored: &[String]) -> bool {
        ignored.iter().any(|i| i == &self.id)
    }

    /// Takes a `Addon` and updates self.
    /// Used when we reparse a single `Addon`.
    pub fn update_addon(&mut self, other: &Addon) {
        self.title = other.title.clone();
        self.version = other.version.clone();
        self.dependencies = other.dependencies.clone();
        self.repository_identifiers = other.repository_identifiers.clone();
    }

    /// Check if the `Addon` is updatable.
    /// We strip both version for non digits, and then
    /// checks if `remote_version` is a sub_slice of `local_version`.
    ///
    /// Eg:
    /// local_version: 4.10.5 => 4105.
    /// remote_version: Rematch_4_10_5.zip => 4105.
    /// Since `4105` is a sub_slice of `4105` it's not updatable.
    fn is_updatable(&self) -> bool {
        match (&self.remote_version, &self.version) {
            (Some(rv), Some(lv)) => {
                let srv = strip_non_digits(&rv);
                let slv = strip_non_digits(&lv);

                if let (Some(srv), Some(slv)) = (srv, slv) {
                    return !slv.contains(&srv);
                }

                false
            }
            _ => false,
        }
    }
}

/// Used to truncate version label to be presented in the GUI.
fn truncate_version(version: &str) -> &str {
    // Split at \n. If it fails, i fall back to org. version.
    let version = version.split("\n").next().unwrap_or(version);
    // Hardcoded a number which fits the width of local and remote container.
    truncate(version, 24)
}

impl PartialEq for Addon {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl PartialOrd for Addon {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(
            self.is_updatable()
                .cmp(&other.is_updatable())
                .then_with(|| self.remote_version.cmp(&other.remote_version))
                .reverse()
                .then_with(|| self.title.cmp(&other.title)),
        )
    }
}

impl Ord for Addon {
    fn cmp(&self, other: &Self) -> Ordering {
        self.is_updatable()
            .cmp(&other.is_updatable())
            .then_with(|| self.remote_version.cmp(&other.remote_version))
            .reverse()
            .then_with(|| self.title.cmp(&other.title))
    }
}

impl Eq for Addon {}
