use std::str::FromStr;

use super::config_dir;
use crate::error::ThemeError;
use crate::theme::Theme;

use async_std::fs::{self, create_dir_all, read_dir, read_to_string};
use async_std::stream::StreamExt;
use isahc::http::Uri;

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

pub async fn import_theme(url: String) -> Result<(String, Vec<Theme>), ThemeError> {
    let uri = Uri::from_str(&url)?;

    let query = uri.query().ok_or(ThemeError::MissingQuery)?;

    let theme = serde_urlencoded::from_str::<Vec<(String, String)>>(query)?
        .into_iter()
        .find(|(name, _)| name == "theme")
        .map(|(_, theme_json)| serde_json::from_str::<Theme>(&theme_json))
        .ok_or(ThemeError::MissingQuery)??;

    let name = &theme.name;

    let theme_dir = config_dir().join("themes");

    let current_themes = load_user_themes().await;
    let shipped_themes = Theme::all();

    // Check if theme name / filename collision
    if current_themes.iter().any(|t| &t.name == name)
        || shipped_themes.iter().any(|(t, _)| t == name)
        || theme_dir.join(format!("{}.yml", name)).exists()
        || theme_dir.join(format!("{}.yaml", name)).exists()
    {
        return Err(ThemeError::NameCollision { name: name.clone() });
    }

    fs::write(
        theme_dir.join(format!("{}.yml", name)),
        &serde_yaml::to_vec(&theme)?,
    )
    .await?;

    let new_themes = load_user_themes().await;

    Ok((name.clone(), new_themes))
}
