use crate::{config::Flavor, curse_api, tukui_api, utility::strip_non_digits};
use std::cmp::Ordering;
use std::path::PathBuf;

#[derive(Debug, Clone, Eq, PartialEq, PartialOrd, Ord)]
pub enum AddonState {
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
    pub remote_version: Option<String>,
    pub remote_url: Option<String>,
    pub path: PathBuf,
    pub dependencies: Vec<String>,
    pub state: AddonState,
    pub wowi_id: Option<String>,
    pub tukui_id: Option<String>,
    pub curse_id: Option<u32>,
    pub fingerprint: Option<u32>,

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
            remote_version: None,
            remote_url: None,
            path,
            dependencies,
            state: AddonState::Ajour(None),
            wowi_id,
            tukui_id,
            curse_id,
            fingerprint: None,
            details_btn_state: Default::default(),
            update_btn_state: Default::default(),
            force_btn_state: Default::default(),
            delete_btn_state: Default::default(),
            ignore_btn_state: Default::default(),
            unignore_btn_state: Default::default(),
        }
    }

    /// Package from Tukui.
    ///
    /// This function takes a `Package` and updates self with the information.
    pub fn apply_tukui_package(&mut self, package: &tukui_api::TukuiPackage) {
        self.remote_version = Some(package.version.clone());
        self.remote_url = Some(package.url.clone());

        if self.is_updatable() {
            self.state = AddonState::Updatable;
        }
    }

    /// Package from Curse.
    ///
    /// This function takes a `Package` and updates self with the information
    pub fn apply_curse_package(&mut self, package: &curse_api::Package) {
        self.title = package.name.clone();
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
        // We try to find the latest stable release. If we can't find that.
        // We will fallback to latest beta release. And lastly we give up.
        let file = if let Some(file) = info.latest_files.iter().find(|f| {
            f.release_type == 1 // 1 is stable, 2 is beta, 3 is alpha.
                && !f.is_alternate
                && f.game_version_flavor == flavor
        }) {
            Some(file)
        } else if let Some(file) = info.latest_files.iter().find(|f| {
            f.release_type == 2 // 1 is stable, 2 is beta, 3 is alpha.
                && !f.is_alternate
                && f.game_version_flavor == flavor
        }) {
            Some(file)
        } else {
            None
        };

        if let Some(file) = file {
            self.remote_version = Some(file.display_name.clone());
            self.remote_url = Some(file.download_url.clone());

            if file.id > info.file.id {
                self.state = AddonState::Updatable;
            }
        }
        self.dependencies = dependencies;
        self.version = Some(info.file.display_name.clone());
        self.curse_id = Some(info.id);
    }

    /// Function returns a `bool` indicating if the user has manually ignored the addon.
    pub fn is_ignored(&self, ignored: Option<&Vec<String>>) -> bool {
        match ignored {
            Some(ignored) => ignored.iter().any(|i| i == &self.id),
            _ => false,
        }
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

impl PartialEq for Addon {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl PartialOrd for Addon {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(
            self.title
                .cmp(&other.title)
                .then_with(|| self.remote_version.cmp(&other.remote_version).reverse()),
        )
    }
}

impl Ord for Addon {
    fn cmp(&self, other: &Self) -> Ordering {
        self.title
            .cmp(&other.title)
            .then_with(|| self.remote_version.cmp(&other.remote_version).reverse())
    }
}

impl Eq for Addon {}
