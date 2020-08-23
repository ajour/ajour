use serde_derive::Deserialize;

/// Struct for addons specific settings.
#[serde(default)]
#[derive(Deserialize, Clone, Default, Debug, PartialEq, Eq)]
pub struct Addons {
    #[serde(default = "default_ignore")]
    pub ignore: Vec<String>,
}

fn default_ignore() -> Vec<String> {
    vec![]
}
