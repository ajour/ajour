use regex::Regex;
use std::path::PathBuf;
use uuid::Uuid;

#[derive(Debug, Clone)]
/// Struct which stores information about a single Addon.
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
        return Addon {
            id: Uuid::new_v4().to_simple().to_string(),
            title,
            version,
            path,
            dependencies,
            delete_btn_state: Default::default(),
        };
    }

    /// Function returns a readable title used for GUI
    ///
    /// Function is needed because coloring is possible
    /// in toc files, which can make the title nonreadable
    /// due to color escape sequences.
    ///
    /// Example 1: |cff1784d1ElvUI|r becomes ElvUI.
    /// Example 2: BigWigs [|cffeda55fUldir|r] becomes BigWigs [Uldir].
    pub fn readable_title(&self) -> String {
        let re = Regex::new(r"\|[a-fA-F\d]{9}([^|]+)\|r?").unwrap();
        re.replace_all(&*self.title, "$1").to_string()
    }

    /// Function returns folder name of the addon.
    ///
    /// Addons can reference other addons in their toc file.
    /// The way they do this, is by their folder name.
    pub fn folder_title(&self) -> String {
        // TODO: Handle the unwraps better.
        let os_title = self.path.file_name().unwrap();
        let str_title = os_title.to_str().unwrap();

        str_title.to_string()
    }

    /// Function returns a `Vec<PathBufs>` which has a `PathBuf`
    /// for each dependency the addon has.
    pub fn dependency_paths(&self, addons: &Vec<Addon>) -> Vec<PathBuf> {
        let mut paths: Vec<PathBuf> = Vec::new();
        // Loops through all addons. If a dependency is equal to a given
        // addon, we add the path to the Vec.
        for dependency in &self.dependencies {
            for addon in addons {
                if dependency == &addon.folder_title() {
                    paths.push(addon.path.clone());
                }
            }
        }

        // Add this addons path to the Vec.
        paths.push(self.path.clone());

        // Ensure that we don't have any duplicates.
        paths.dedup();
        paths
    }
}
