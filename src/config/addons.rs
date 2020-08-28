use serde_derive::{Deserialize, Serialize};

/// Struct for addons specific settings.
#[serde(default)]
#[derive(Deserialize, Serialize, Clone, Debug, PartialEq, Eq)]
pub struct Addons {
    #[serde(default)]
    pub ignored: Vec<String>,
}

impl Default for Addons {
    fn default() -> Self {
        Addons { ignored: vec![] }
    }
}
