use std::path::PathBuf;
use std::cmp::Ordering;

#[derive(Debug, Clone)]
/// Struct which stores information about a single Addon.
///
/// `id`: Unique identifier for each addon.
/// This is actually the folder name toc files
/// use to reference other addons which is why
/// it is chosen to be the identifier.
///
/// `title`: Readable title to be used in the GUI.
///
/// `version`: Each addon can have a version.
/// If there is no version, it is most likely because
/// it is dependent on another addon.
///
/// `path`: A `PathBuf` to this addon folder.
///
/// `dependencies`: A list of `id's` to other addons
/// which this addon is dependent on.
pub struct Addon {
    pub id: String,
    pub title: String,
    pub version: Option<String>,
    pub path: PathBuf,
    pub dependencies: Vec<String>,

    pub delete_btn_state: iced::button::State,
}

impl Addon {
    /// Creates a new Addon
    pub fn new(
        title: String,
        version: Option<String>,
        path: PathBuf,
        dependencies: Vec<String>,
    ) -> Self {
        let os_title = path.file_name().unwrap();
        let str_title = os_title.to_str().unwrap();

        return Addon {
            id: str_title.to_string(),
            title,
            version,
            path,
            dependencies,
            delete_btn_state: Default::default(),
        };
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
                },
                // If we can't find the addon, we will just skip it.
                None => continue
            };
        }

        dependencies.sort();
        dependencies.dedup();
        dependencies
    }
}

impl PartialEq for Addon {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl PartialOrd for Addon {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.id.cmp(&other.id))
    }
}

impl Ord for Addon {
    fn cmp(&self, other: &Self) -> Ordering {
        self.id.cmp(&other.id)
    }
}

impl Eq for Addon { }
