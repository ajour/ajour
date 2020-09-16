use super::config_dir;
use crate::theme::Theme;

use async_std::fs::{create_dir_all, read_dir, read_to_string};
use async_std::stream::StreamExt;

/// Loads all user defined `.yml` files from the themes
/// folder. Will only return themes that succesfully deserialize
/// from yaml format to `Theme`.
pub async fn load_user_themes() -> Vec<Theme> {
    let mut themes = vec![];

    let theme_dir = config_dir().join("themes");

    if !theme_dir.exists() {
        let _ = create_dir_all(&theme_dir).await;
    }

    if let Ok(mut dir_entries) = read_dir(theme_dir).await {
        while let Some(entry) = dir_entries.next().await {
            if let Ok(item) = entry {
                let path = item.path();

                let extension = path.extension().unwrap_or_default();

                if extension == "yaml" || extension == "yml" {
                    if let Ok(theme_str) = read_to_string(path).await {
                        if let Ok(theme) = serde_yaml::from_str(&theme_str) {
                            themes.push(theme);
                        }
                    }
                }
            }
        }
    }

    log::debug!("loaded {} user themes", themes.len());

    themes
}
