use crate::{curse_api, tukui_api, utility::strip_non_digits, wowinterface_api};
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
    pub notes: Option<String>,
    pub version: Option<String>,
    pub remote_version: Option<String>,
    pub remote_url: Option<String>,
    pub path: PathBuf,
    pub dependencies: Vec<String>,
    pub state: AddonState,
    pub repository_identifiers: RepositoryIdentifiers,

    // States for GUI
    pub details_btn_state: iced::button::State,
    pub update_btn_state: iced::button::State,
    pub delete_btn_state: iced::button::State,
}

impl Addon {
    /// Creates a new Addon
    pub fn new(
        title: String,
        notes: Option<String>,
        version: Option<String>,
        path: PathBuf,
        dependencies: Vec<String>,
        repository_identifiers: RepositoryIdentifiers,
    ) -> Self {
        let os_title = path.file_name().unwrap();
        let str_title = os_title.to_str().unwrap();

        Addon {
            id: str_title.to_string(),
            title,
            notes,
            version,
            remote_version: None,
            remote_url: None,
            path,
            dependencies,
            state: AddonState::Ajour(None),
            repository_identifiers,
            details_btn_state: Default::default(),
            update_btn_state: Default::default(),
            delete_btn_state: Default::default(),
        }
    }

    /// Packages from Wowinterface.
    ///
    /// This functions takes a `&Vec<Package>` and finds the one matching `self`.
    /// It then updates self, with the information from that package.
    pub fn apply_wowi_packages(&mut self, packages: &[wowinterface_api::Package]) {
        let wowi_id = self.repository_identifiers.wowi.as_ref().unwrap();
        let package = packages.iter().find(|a| &a.id == wowi_id);
        if let Some(package) = package {
            self.remote_version = Some(package.version.clone());
            self.remote_url = Some(crate::wowinterface_api::remote_url(&wowi_id));

            if self.is_updatable() {
                self.state = AddonState::Updatable;
            }
        }
    }

    /// Package from Tukui.
    ///
    /// This function takes a `Package` and updates self with the information.
    pub fn apply_tukui_package(&mut self, package: &tukui_api::Package) {
        self.remote_version = Some(package.version.clone());
        self.remote_url = Some(package.url.clone());

        if self.is_updatable() {
            self.state = AddonState::Updatable;
        }
    }

    /// Package from Curse.
    ///
    /// This function takes a `Package` and updates self with the information.
    pub fn apply_curse_package(&mut self, package: &curse_api::Package, flavor: &str) {
        let file = package
            .latest_files
            .iter()
            .find(|f| f.release_type == 1 && f.game_version_flavor == format!("wow_{}", flavor));

        if let Some(file) = file {
            self.remote_version = Some(file.display_name.clone());
            self.remote_url = Some(file.download_url.clone());
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
    pub fn apply_curse_packages(&mut self, packages: &[curse_api::Package], flavor: &str) {
        for package in packages {
            let file = package.latest_files.iter().find(|f| {
                f.release_type == 1 // 1 is stable, 2 is beta, 3 is alpha.
                    && !f.is_alternate
                    && f.game_version_flavor == format!("wow_{}", flavor)
            });
            if let Some(file) = file {
                let module = file.modules.iter().find(|m| m.foldername == self.id);
                if module.is_some() {
                    self.remote_version = Some(file.display_name.clone());
                    self.remote_url = Some(file.download_url.clone());
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

    /// Function returns a `Vec<String>` which contains all combined dependencies.
    ///
    /// Example:
    /// `Foo` - dependencies: [`Bar`, `Baz`]
    /// `Bar` - dependencies: [`Foo`]
    /// `Baz` - dependencies: [`Foo`]
    ///
    /// If `Baz` is self, we will return [`Foo`, `Bar`, `Baz`]
    pub fn combined_dependencies(&self, addons: &[Addon]) -> Vec<String> {
        let addons = &addons.to_owned();
        let mut dependencies: Vec<String> = Vec::new();

        // Add own dependency to dependencies.
        dependencies.push(self.id.clone());
        // Loops dependencies of the target addon.
        for dependency in &self.dependencies {
            // Find the addon.
            let addon = addons.iter().find(|a| &a.id == dependency);
            match addon {
                Some(addon) => {
                    // If target_addon is a parent, and the dependency addon is a parent
                    // we skip it.
                    if self.is_parent() && addon.is_parent() {
                        continue;
                    }

                    // Add dependency to dependencies.
                    dependencies.push(dependency.clone());
                    // Loops the dependencies of the found addon.
                    for dependency in &addon.dependencies {
                        dependencies.push(dependency.clone());
                    }
                }
                // If we can't find the addon, we will just skip it.
                None => continue,
            };
        }

        dependencies.sort();
        dependencies.dedup();
        dependencies
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
