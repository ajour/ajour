use super::Flavor;
use serde_derive::{Deserialize, Serialize};
use std::collections::HashMap;

/// Struct for addons specific settings.
#[serde(default)]
#[derive(Deserialize, Serialize, Clone, Debug, PartialEq, Eq)]
pub struct Addons {
    #[serde(default)]
    pub ignored: HashMap<Flavor, Vec<String>>,
}

impl Default for Addons {
    fn default() -> Self {
        Addons {
            ignored: HashMap::new(),
        }
    }
}
