use std::path::PathBuf;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct Addon {
    pub id: String,
    pub title: Option<String>,
    pub version: Option<String>,
    pub path: PathBuf,
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
        path: PathBuf,
        dependencies: Vec<String>,
        optional_dependencies: Vec<String>,
        required_dependencies: Vec<String>,
    ) -> Self {
        return Addon {
            id: Uuid::new_v4().to_simple().to_string(),
            title,
            version,
            path,
            dependencies,
            optional_dependencies,
            required_dependencies,
            delete_btn_state: Default::default(),
        };
    }
}

