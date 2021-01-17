use json_gettext::{get_text, static_json_gettext_build, JSONGetText};
use once_cell::sync::{Lazy, OnceCell};

use std::sync::RwLock;

pub static LOCALIZATION_CTX: Lazy<JSONGetText<'static>> = Lazy::new(|| {
    static_json_gettext_build!(
        "en_US",
        "en_US",
        "locale/en_US.json",
        "da_DK",
        "locale/da_DK.json",
        "de_DE",
        "locale/de_DE.json",
        "fr_FR",
        "locale/fr_FR.json",
        "ru_RU",
        "locale/ru_RU.json",
        "se_SE",
        "locale/se_SE.json",
        "es_ES",
        "locale/es_ES.json"
    )
    .unwrap()
});

pub static LANG: OnceCell<RwLock<&'static str>> = OnceCell::new();

pub fn localized_string(key: &str) -> String {
    let lang = LANG.get().expect("LANG not set").read().unwrap();

    if let Some(text) = get_text!(LOCALIZATION_CTX, *lang, key) {
        text.to_string()
    } else {
        key.to_owned()
    }
}

/// Returns a localized `timeago::Formatter`.
/// If user has chosen a language whic his not supported by `timeago` we fallback to english.
pub fn localized_timeago_formatter() -> timeago::Formatter<Box<dyn timeago::Language>> {
    let lang = LANG.get().expect("LANG not set").read().unwrap();
    let isolang = isolang::Language::from_locale(&lang).unwrap();

    // this step might fail if timeago does not support the chosen language.
    // In that case we fallback to `en_US`.
    if let Some(timeago_lang) = timeago::from_isolang(isolang) {
        timeago::Formatter::with_language(timeago_lang)
    } else {
        timeago::Formatter::with_language(Box::new(timeago::English))
    }
}

#[cfg(test)]
mod test {
    use serde::Deserialize;
    use std::fs;
    use std::path::PathBuf;

    #[test]
    fn test_valid_locales() {
        let cargo_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let locale_dir = cargo_dir.join("locale");

        let dir_entries = fs::read_dir(&locale_dir).unwrap();

        for entry in dir_entries.filter_map(Result::ok) {
            let path = entry.path();
            let file = fs::File::open(path).unwrap();

            let locale: Locale = serde_json::from_reader(&file).unwrap();

            dbg!(&locale);
        }
    }

    #[derive(Debug, Deserialize)]
    #[serde(rename_all = "kebab-case")]
    struct Locale {
        addon: String,
        about: String,
        addons: String,
        addons_loaded: String,
        ajour: String,
        all_categories: String,
        alternate_row_colors: String,
        aura: String,
        author: String,
        authors: String,
        backup: String,
        backup_description: String,
        backup_latest: String,
        backup_never: String,
        backup_now: String,
        backup_progress: String,
        catalog: String,
        changelog: String,
        changelog_for: String,
        changelog_press_full_changelog: String,
        channel: String,
        columns: String,
        completed: String,
        delete: String,
        delete_saved_variables: String,
        description: String,
        downloading: String,
        game_version: String,
        failed: String,
        full_changelog: String,
        global_release_channel: String,
        hashing: String,
        hide_addons: String,
        ignore: String,
        ignored: String,
        install: String,
        install_for_flavor: String,
        install_from_url: String,
        install_from_url_description: String,
        install_from_url_example: String,
        installed: String,
        language: String,
        latest_release: String,
        loading: String,
        loading_catalog: String,
        local: String,
        my_addons: String,
        my_weakauras: String,
        new_update_available: String,
        no_addon_description: String,
        no_addons_for_flavor: String,
        no_changelog: String,
        no_directory: String,
        no_known_weakauras: String,
        num_downloads: String,
        open_data_directory: String,
        parsing_addons: String,
        parsing_weakauras: String,
        patreon: String,
        patreon_http: String,
        refresh: String,
        release_channel_no_release: String,
        remote: String,
        remote_release_channel: String,
        reset_columns: String,
        retry: String,
        search_for_addon: String,
        scale: String,
        select_account: String,
        select_directory: String,
        settings: String,
        setup_ajour_description: String,
        setup_ajour_title: String,
        setup_weakauras_description: String,
        setup_weakauras_title: String,
        source: String,
        status: String,
        summary: String,
        theme: String,
        ui: String,
        unavailable: String,
        unignore: String,
        unknown: String,
        unpacking: String,
        update: String,
        update_all: String,
        ajour_update_channel: String,
        updating: String,
        weakaura_updates_queued: String,
        weakauras_loaded: String,
        website: String,
        website_http: String,
        welcome_to_ajour_description: String,
        woops: String,
        wow_directory: String,
        wtf: String,
        channel_default: String,
        channel_stable: String,
        channel_beta: String,
        channel_alpha: String,
        catalog_results: String,
    }
}
