use crate::{curse_api, tukui_api, wowinterface_api};
use std::cmp::Ordering;
use std::path::PathBuf;

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum AddonState {
    Ajour(Option<String>),
    Updatable,
    Downloading,
    Unpacking,
}

#[derive(Debug, Clone)]
/// Struct which stores information about a single Addon.
pub struct Addon {
    pub id: String,
    pub title: String,
    pub version: Option<String>,
    pub remote_version: Option<String>,
    pub remote_url: Option<String>,
    pub path: PathBuf,
    pub dependencies: Vec<String>,
    pub state: AddonState,
    pub wowi_id: Option<String>,
    pub tukui_id: Option<String>,
    pub curse_id: Option<u32>,

    pub update_btn_state: iced::button::State,
    pub delete_btn_state: iced::button::State,
}

impl Addon {
    /// Creates a new Addon
    pub fn new(
        title: String,
        version: Option<String>,
        path: PathBuf,
        wowi_id: Option<String>,
        tukui_id: Option<String>,
        curse_id: Option<u32>,
        dependencies: Vec<String>,
    ) -> Self {
        let os_title = path.file_name().unwrap();
        let str_title = os_title.to_str().unwrap();

        Addon {
            id: str_title.to_string(),
            title,
            version,
            remote_version: None,
            remote_url: None,
            path,
            dependencies,
            state: AddonState::Ajour(None),
            wowi_id,
            tukui_id,
            curse_id,
            update_btn_state: Default::default(),
            delete_btn_state: Default::default(),
        }
    }

    /// TBA
    pub fn apply_wowi_package(&mut self, package: &wowinterface_api::Package) {
        let id = self.wowi_id.clone().unwrap();
        self.remote_version = Some(package.version.clone());
        self.remote_url = Some(crate::wowinterface_api::remote_url(&id));

        if self.is_updatable() {
            self.state = AddonState::Updatable;
        }
    }

    /// TBA
    pub fn apply_tukui_package(&mut self, package: &tukui_api::Package) {
        self.remote_version = Some(package.version.clone());
        self.remote_url = Some(package.url.clone());

        if self.is_updatable() {
            self.state = AddonState::Updatable;
        }
    }

    pub fn apply_curse_package(&mut self, package: &curse_api::Package, flavor: &str) {
        let file = package
            .latest_files
            .iter()
            .find(|f| f.release_type == 1 && f.game_version_flavor == format!("wow_{}", flavor));

        if let Some(file) = file {
            self.remote_version = Some(file.display_name.clone());
        }
        // self.remote_version = Some(package.version.clone());
        // self.remote_url = Some(package.url.clone());

        if self.is_updatable() {
            self.state = AddonState::Updatable;
        }
    }

    /// Function returns a `bool` which indicates
    /// if a addon is a parent.
    ///
    /// A parent addon can have dependencies which upon
    /// deletion will be deleted. A parent cannot delete
    /// another parent addon.
    ///
    /// There's an edge case where a downloaded addon,
    /// containing multiple folders (addons) can have multiple
    /// parents because one or more have a version attached.
    pub fn is_parent(&self) -> bool {
        self.version.is_some()
    }

    /// Function returns a `Vec<String>` which contains
    /// all combined dependencies.
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

    /// Check if the `Addon` is updatable.
    /// This is done by a simple comparison, which means it will also flag
    /// the addon as updatable if the `remote_version` is LOWER than
    /// `version`.
    fn is_updatable(&self) -> bool {
        match self.remote_version {
            Some(_) => self.version != self.remote_version,
            None => false,
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
                .then_with(|| self.id.cmp(&other.id)),
        )
    }
}

impl Ord for Addon {
    fn cmp(&self, other: &Self) -> Ordering {
        self.is_updatable()
            .cmp(&other.is_updatable())
            .then_with(|| self.remote_version.cmp(&other.remote_version))
            .reverse()
            .then_with(|| self.id.cmp(&other.id))
    }
}

impl Eq for Addon {}
