use json_gettext::{get_text, static_json_gettext_build, JSONGetText};

use std::sync;

lazy_static::lazy_static! {
    pub static ref LOCALIZATION_CTX: JSONGetText<'static> = {
        static_json_gettext_build!(
            "en_US",
            "en_US",
            "locale/en_US.json",
            "da_DK",
            "locale/da_DK.json"
        ).unwrap()
    };
    pub static ref LANG: sync::Mutex<&'static str> = sync::Mutex::new("en_US");
}

pub fn localized_string(key: &str) -> String {
    let lang = LANG.lock().unwrap();
    get_text!(LOCALIZATION_CTX, *lang, key)
        .expect("no localization found")
        .to_string()
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
        about: String,
        addon: String,
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
        channel: String,
        columns: String,
        completed: String,
        delete: String,
        delete_saved_variables: String,
        description: String,
        downloading: String,
        failed: String,
        game_version: String,
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
        last_backup: String,
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
        not_available_abbreviation: String,
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
        scale: String,
        search_for_addon: String,
        select_account: String,
        select_directory: String,
        settings: String,
        setup_to_ajour_description: String,
        setup_to_ajour_title: String,
        setup_weakauras_description: String,
        setup_weakauras_title: String,
        source: String,
        status: String,
        summary: String,
        theme: String,
        ui: String,
        unavilable: String,
        unignore: String,
        unknown: String,
        unpacking: String,
        update: String,
        update_all: String,
        update_channel: String,
        updating: String,
        weakaura_updates_queued: String,
        weakauras_loaded: String,
        website: String,
        website_http: String,
        welcome_to_ajour_description: String,
        woops: String,
        wow_directory: String,
        wtf: String,
    }
}
