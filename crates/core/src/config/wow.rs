use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

/// Struct for settings related to World of Warcraft.
#[serde(default)]
#[derive(Deserialize, Serialize, Clone, Debug, PartialEq, Eq)]
pub struct Wow {
    #[serde(default)]
    #[allow(deprecated)]
    pub directory: Option<PathBuf>,

    #[serde(default)]
    pub directories: HashMap<Flavor, PathBuf>,

    #[serde(default)]
    pub flavor: Flavor,
}

impl Default for Wow {
    fn default() -> Self {
        Wow {
            directory: None,
            directories: HashMap::new(),
            flavor: Flavor::Retail,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize, Hash, PartialOrd, Ord)]
pub enum Flavor {
    #[serde(alias = "retail", alias = "wow_retail")]
    Retail,
    #[serde(alias = "RetailPTR")]
    RetailPtr,
    RetailBeta,
    #[serde(alias = "classic", alias = "wow_classic")]
    Classic,
    #[serde(alias = "ClassicPTR")]
    ClassicPtr,
    ClassicBeta,
    #[serde(other)]
    Other,
}

impl Flavor {
    pub const ALL: [Flavor; 6] = [
        Flavor::Retail,
        Flavor::RetailPtr,
        Flavor::RetailBeta,
        Flavor::Classic,
        Flavor::ClassicPtr,
        Flavor::ClassicBeta,
    ];

    /// Returns flavor `String` in CurseForge format
    pub(crate) fn curse_format(self) -> Option<String> {
        match self {
            Flavor::Retail | Flavor::RetailPtr | Flavor::RetailBeta => {
                Some("wow_retail".to_owned())
            }
            Flavor::Classic | Flavor::ClassicPtr | Flavor::ClassicBeta => {
                Some("wow_classic".to_owned())
            }
            _ => None,
        }
    }

    /// Returns flavor `String` in WowUp.Hub format
    pub(crate) fn hub_format(self) -> Option<String> {
        match self {
            Flavor::Retail | Flavor::RetailPtr | Flavor::RetailBeta => Some("retail".to_owned()),
            Flavor::Classic | Flavor::ClassicPtr | Flavor::ClassicBeta => {
                Some("classic".to_owned())
            }
            _ => None,
        }
    }

    /// Returns `Flavor` which self relates to.
    pub fn base_flavor(self) -> Flavor {
        match self {
            Flavor::Retail | Flavor::RetailPtr | Flavor::RetailBeta => Flavor::Retail,
            Flavor::Classic | Flavor::ClassicPtr | Flavor::ClassicBeta => Flavor::Classic,
            _ => Flavor::Other,
        }
    }

    /// Returns `String` which correlate to the folder on disk.
    pub(crate) fn folder_name(self) -> String {
        match self {
            Flavor::Retail => "_retail_".to_owned(),
            Flavor::RetailPtr => "_ptr_".to_owned(),
            Flavor::RetailBeta => "_beta_".to_owned(),
            Flavor::Classic => "_classic_".to_owned(),
            Flavor::ClassicPtr => "_classic_ptr_".to_owned(),
            Flavor::ClassicBeta => "_classic_beta_".to_owned(),
            _ => panic!("Unsupported flavor: {:?}", self),
        }
    }
}

impl Default for Flavor {
    fn default() -> Flavor {
        Flavor::Retail
    }
}

impl std::fmt::Display for Flavor {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                Flavor::Retail => "Retail",
                Flavor::RetailPtr => "Retail PTR",
                Flavor::RetailBeta => "Retail Beta",
                Flavor::Classic => "Classic",
                Flavor::ClassicBeta => "Classic Beta",
                Flavor::ClassicPtr => "Classic PTR",
                _ => panic!("Unsupported flavor: {:?}", self),
            }
        )
    }
}
