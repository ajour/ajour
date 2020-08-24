use serde_derive::{Deserialize, Serialize};

/// Struct for tokens to different repositories.
#[serde(default)]
#[derive(Deserialize, Serialize, Clone, Debug, PartialEq, Eq)]
pub struct Tokens {
    #[serde(default)]
    pub wowinterface: Option<String>,
}

impl Default for Tokens {
    fn default() -> Self {
        Tokens { wowinterface: None }
    }
}
