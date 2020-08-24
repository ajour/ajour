use serde_derive::{Deserialize, Serialize};

/// Struct for tokens to different repositories.
#[serde(default)]
#[derive(Deserialize, Serialize, Clone, Default, Debug, PartialEq, Eq)]
pub struct Tokens {
    #[serde(default = "default_wowinterface")]
    pub wowinterface: Option<String>,
}

fn default_wowinterface() -> Option<String> {
    None
}
