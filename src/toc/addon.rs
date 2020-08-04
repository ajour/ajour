use serde_derive::Deserialize;
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
    pub remote_filename: Option<String>,
    pub path: PathBuf,
    pub dependencies: Vec<String>,
    pub state: AddonState,
    pub wowi_id: Option<String>,

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
        dependencies: Vec<String>,
    ) -> Self {
        let os_title = path.file_name().unwrap();
        let str_title = os_title.to_str().unwrap();

        return Addon {
            id: str_title.to_string(),
            title,
            version,
            remote_version: None,
            remote_filename: None,
            path,
            dependencies,
            state: AddonState::Ajour(None),
            wowi_id,
            update_btn_state: Default::default(),
            delete_btn_state: Default::default(),
        };
    }

    /// Function to apply details to a `Addon`.
    ///
    /// This is used to apply additional information after pulling the
    /// information from a repository.
    pub fn apply_details(&mut self, patch: &AddonDetails) {
        self.remote_version = Some(patch.version.clone());
        self.remote_filename = Some(patch.filename.clone());

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
    /// There's an edgecase where a downloaded addon,
    /// containg multiple folders (addons) can have multiple
    /// parents because one or more have a version attatched.
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
    pub fn combined_dependencies(&self, addons: &Vec<Addon>) -> Vec<String> {
        let addons = &addons.clone();
        let mut dependencies: Vec<String> = Vec::new();

        // Add own dependency to dependencies.
        dependencies.push(self.id.clone());
        // Loops dependencies of the target addon.
        for dependency in &self.dependencies {
            // Find the addon.
            let addon = addons.into_iter().find(|a| &a.id == dependency);
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
    /// This is done by a simple comparision, which means it will also flag
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
                .reverse()
                .then_with(|| self.id.cmp(&other.id)),
        )
    }
}

impl Ord for Addon {
    fn cmp(&self, other: &Self) -> Ordering {
        self.is_updatable()
            .cmp(&other.is_updatable())
            .reverse()
            .then_with(|| self.id.cmp(&other.id))
    }
}

impl Eq for Addon {}

#[derive(Clone, Debug, Deserialize)]
pub struct AddonDetails {
    pub id: String,
    pub version: String,
    pub filename: String,
}
