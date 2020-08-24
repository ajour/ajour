use serde_derive::{Deserialize, Serialize};

/// Struct for addons specific settings.
#[serde(default)]
#[derive(Deserialize, Serialize, Clone, Default, Debug, PartialEq, Eq)]
pub struct Addons {
    #[serde(default = "default_hidden")]
    pub hidden: Vec<String>,
}

fn default_hidden() -> Vec<String> {
    vec![]
}
