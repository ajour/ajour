use uuid::Uuid;
use walkdir::DirEntry;

#[derive(Debug, Clone)]
pub struct Addon {
    pub id: String,
    pub title: Option<String>,
    pub version: Option<String>,
    pub dir_entry: DirEntry,
    pub dependencies: Vec<String>,
    pub optional_dependencies: Vec<String>,
    pub required_dependencies: Vec<String>,

    pub delete_btn_state: iced::button::State,
}

/// Struct which stores information about a single Addon.
impl Addon {
    pub fn new(
        title: Option<String>,
        version: Option<String>,
        dir_entry: DirEntry,
        dependencies: Vec<String>,
        optional_dependencies: Vec<String>,
        required_dependencies: Vec<String>,
    ) -> Self {
        return Addon {
            id: Uuid::new_v4().to_simple().to_string(),
            title,
            version,
            dir_entry,
            dependencies,
            optional_dependencies,
            required_dependencies,
            delete_btn_state: Default::default(),
        };
    }
}

