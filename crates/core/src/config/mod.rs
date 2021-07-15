use crate::catalog;
use crate::error::FilesystemError;
use crate::repository::CompressionFormat;
use glob::MatchOptions;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fmt::{self, Display, Formatter};
use std::fs::create_dir_all;
use std::path::{Path, PathBuf};

mod addons;
mod wow;

use crate::fs::PersistentData;

pub use crate::config::addons::Addons;
pub use crate::config::wow::{Flavor, Wow};

/// Config struct.
#[derive(Deserialize, Serialize, Debug, PartialEq, Default, Clone)]
pub struct Config {
    #[serde(default)]
    pub wow: Wow,

    #[serde(default)]
    pub addons: Addons,

    pub theme: Option<String>,

    #[serde(default)]
    pub column_config: ColumnConfig,

    pub window_size: Option<(u32, u32)>,

    pub scale: Option<f64>,

    pub backup_directory: Option<PathBuf>,

    #[serde(default)]
    pub backup_addons: bool,

    #[serde(default)]
    pub backup_wtf: bool,

    #[serde(default)]
    pub backup_config: bool,

    #[serde(default)]
    pub backup_screenshots: bool,

    #[serde(default)]
    pub hide_ignored_addons: bool,

    #[serde(default)]
    pub self_update_channel: SelfUpdateChannel,

    #[serde(default)]
    pub weak_auras_account: HashMap<Flavor, String>,

    #[serde(default = "default_true")]
    pub alternating_row_colors: bool,

    #[serde(default)]
    pub language: Language,

    #[serde(default)]
    pub catalog_source: Option<catalog::Source>,

    #[serde(default)]
    pub auto_update: bool,

    #[serde(default)]
    pub compression_format: CompressionFormat,

    #[serde(default)]
    pub zstd_compression_level: i32,

    #[serde(default)]
    #[cfg(target_os = "windows")]
    pub close_to_tray: bool,

    #[serde(default)]
    #[cfg(target_os = "windows")]
    pub autostart: bool,

    #[serde(default)]
    #[cfg(target_os = "windows")]
    pub start_closed_to_tray: bool,
}

impl Config {
    pub fn add_wow_directories(&mut self, path: PathBuf, flavor: Option<Flavor>) {
        if let Some(flavor) = flavor {
            // If a flavor is supplied we only update path for that specific flavor.
            let flavor_path = self.get_flavor_directory_for_flavor(&flavor, &path);
            if flavor_path.exists() {
                self.wow.directories.insert(flavor, flavor_path);
            }
        } else {
            // If no flavor is supplied it will find as many flavors as possible in the path.
            let flavors = &Flavor::ALL[..];
            for flavor in flavors {
                let flavor_path = self.get_flavor_directory_for_flavor(flavor, &path);
                if flavor_path.exists() {
                    self.wow.directories.insert(*flavor, flavor_path);
                }
            }
        }
    }

    /// Returns a `PathBuf` to the flavor directory.
    pub fn get_flavor_directory_for_flavor(&self, flavor: &Flavor, path: &Path) -> PathBuf {
        path.join(&flavor.folder_name())
    }

    /// Returns a `Option<PathBuf>` to the root directory of the Flavor.
    pub fn get_root_directory_for_flavor(&self, flavor: &Flavor) -> Option<PathBuf> {
        self.wow
            .directories
            .get(flavor)
            .map(|p| p.parent().unwrap().to_path_buf())
    }

    /// Returns a `Option<PathBuf>` to the directory containing the addons.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_addon_directory_for_flavor(&self, flavor: &Flavor) -> Option<PathBuf> {
        self.get_directory_for_flavor(flavor, "Interface/AddOns")
    }

    /// Returns a `Option<PathBuf>` to the directory which will hold the
    /// temporary zip archives.
    /// This will return `None` if flavor does not have a directory.
    pub fn get_download_directory_for_flavor(&self, flavor: Flavor) -> Option<PathBuf> {
        self.wow.directories.get(&flavor).cloned()
    }

    /// Returns a `Option<PathBuf>` to the WTF directory.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_wtf_directory_for_flavor(&self, flavor: &Flavor) -> Option<PathBuf> {
        self.get_directory_for_flavor(flavor, "WTF")
    }

    /// Returns a `Option<PathBuf>` to the Screenshots directory.
    /// This will return `None` if no `wow_directory` is set in the config.
    pub fn get_screenshots_directory_for_flavor(&self, flavor: &Flavor) -> Option<PathBuf> {
        self.get_directory_for_flavor(flavor, "Screenshots")
    }

    /// Return a `Option<PathBuf` to a directory.
    /// This will return none if no `wow_directory` is set in the config.
    fn get_directory_for_flavor(&self, flavor: &Flavor, relative_path: &str) -> Option<PathBuf> {
        let wow_flavor_dir = self.wow.directories.get(flavor);
        match wow_flavor_dir {
            Some(wow_flavor_dir) => {
                let mut dir = wow_flavor_dir.join(relative_path);

                // If dir doesn't exist, it could have been modified by the user.
                // Check for a case-insensitive version and use that instead.
                if !dir.exists() {
                    let options = MatchOptions {
                        case_sensitive: false,
                        ..Default::default()
                    };

                    let pattern = format!(
                        "{}/{}",
                        wow_flavor_dir.display(),
                        get_pattern_format(relative_path)
                    );

                    for path in glob::glob_with(&pattern, options).unwrap().flatten() {
                        dir = path;
                    }
                }

                if wow_flavor_dir.exists() && !dir.exists() {
                    let _ = create_dir_all(&dir);
                }

                Some(dir)
            }
            None => None,
        }
    }
}

/// This method will take a relative path and make a case insentitive pattern
// For some reason the case insensitive pattern doesn't work
// unless we add an actual pattern symbol, hence the `?`.
fn get_pattern_format(relative_path: &str) -> String {
    let splitted_string = relative_path.split('/');
    let mut return_string: Vec<String> = vec![];
    for path in splitted_string {
        let mut to_lower_case = path.to_lowercase();
        to_lower_case.replace_range(0..1, "?");
        return_string.push(to_lower_case);
    }
    return_string.join("/")
}

impl PersistentData for Config {
    fn relative_path() -> PathBuf {
        PathBuf::from("ajour.yml")
    }
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Clone)]
pub enum ColumnConfig {
    V1 {
        local_version_width: u16,
        remote_version_width: u16,
        status_width: u16,
    },
    V2 {
        columns: Vec<ColumnConfigV2>,
    },
    V3 {
        my_addons_columns: Vec<ColumnConfigV2>,
        catalog_columns: Vec<ColumnConfigV2>,
        #[serde(default)]
        aura_columns: Vec<ColumnConfigV2>,
    },
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Clone)]
pub struct ColumnConfigV2 {
    pub key: String,
    pub width: Option<u16>,
    pub hidden: bool,
}

impl Default for ColumnConfig {
    fn default() -> Self {
        ColumnConfig::V1 {
            local_version_width: 150,
            remote_version_width: 150,
            status_width: 85,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SelfUpdateChannel {
    Stable,
    Beta,
}

impl SelfUpdateChannel {
    pub const fn all() -> [Self; 2] {
        [SelfUpdateChannel::Stable, SelfUpdateChannel::Beta]
    }
}

impl Default for SelfUpdateChannel {
    fn default() -> Self {
        SelfUpdateChannel::Stable
    }
}

impl Display for SelfUpdateChannel {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let s = match self {
            SelfUpdateChannel::Stable => "Stable",
            SelfUpdateChannel::Beta => "Beta",
        };

        write!(f, "{}", s)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize, Hash, PartialOrd, Ord)]
pub enum Language {
    Czech,
    Norwegian,
    English,
    Danish,
    German,
    French,
    Hungarian,
    Portuguese,
    Polish,
    Russian,
    Slovak,
    Swedish,
    Spanish,
    Turkish,
    Ukrainian,
}

impl std::fmt::Display for Language {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                Language::Czech => "Čeština",
                Language::Danish => "Dansk",
                Language::English => "English",
                Language::French => "Français",
                Language::German => "Deutsch",
                Language::Hungarian => "Magyar",
                Language::Norwegian => "Norsk Bokmål",
                Language::Portuguese => "Português",
                Language::Polish => "Polski",
                Language::Russian => "Pусский",
                Language::Slovak => "Slovenčina",
                Language::Spanish => "Español",
                Language::Swedish => "Svenska",
                Language::Turkish => "Türkçe",
                Language::Ukrainian => "Yкраїнська",
            }
        )
    }
}

impl Language {
    // Alphabetically sorted based on their local name (@see `impl Display`).
    pub const ALL: [Language; 15] = [
        Language::Czech,
        Language::Danish,
        Language::German,
        Language::English,
        Language::Spanish,
        Language::French,
        Language::Hungarian,
        Language::Norwegian,
        Language::Portuguese,
        Language::Polish,
        Language::Russian,
        Language::Slovak,
        Language::Swedish,
        Language::Turkish,
        Language::Ukrainian,
    ];

    pub const fn language_code(self) -> &'static str {
        match self {
            Language::Czech => "cs_CZ",
            Language::English => "en_US",
            Language::Danish => "da_DK",
            Language::German => "de_DE",
            Language::French => "fr_FR",
            Language::Russian => "ru_RU",
            Language::Swedish => "se_SE",
            Language::Spanish => "es_ES",
            Language::Hungarian => "hu_HU",
            Language::Norwegian => "nb_NO",
            Language::Slovak => "sk_SK",
            Language::Turkish => "tr_TR",
            Language::Portuguese => "pt_PT",
            Language::Polish => "pl_PL",
            Language::Ukrainian => "uk_UA",
        }
    }
}

impl Default for Language {
    fn default() -> Language {
        Language::English
    }
}

/// Returns a Config.
///
/// This functions handles the initialization of a Config.
pub async fn load_config() -> Result<Config, FilesystemError> {
    log::debug!("loading config");

    Ok(Config::load_or_default()?)
}

const fn default_true() -> bool {
    true
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_get_format_interface_addons() {
        assert_eq!(
            get_pattern_format("Interface/Addons"),
            String::from("?nterface/?ddons")
        );
        assert_eq!(
            get_pattern_format("iNtErFaCe/aDdoNs"),
            String::from("?nterface/?ddons")
        );
    }

    #[test]
    fn test_get_format_wtf() {
        assert_eq!(get_pattern_format("WTF"), String::from("?tf"));
        assert_eq!(get_pattern_format("wTF"), String::from("?tf"));
        assert_eq!(get_pattern_format("Wtf"), String::from("?tf"));
        assert_eq!(get_pattern_format("wTf"), String::from("?tf"));
    }

    #[test]
    fn test_get_format_screenshots() {
        assert_eq!(
            get_pattern_format("Screenshots"),
            String::from("?creenshots")
        );
        assert_eq!(
            get_pattern_format("sCREENSHOTS"),
            String::from("?creenshots")
        );
        assert_eq!(
            get_pattern_format("ScreeNShots"),
            String::from("?creenshots")
        );
    }
}
