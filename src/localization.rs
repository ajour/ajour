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
    pub static ref LANG: sync::Mutex<String> = sync::Mutex::new("en_US".to_owned());
}

pub fn localized_string(key: &str) -> String {
    let lang = LANG.lock().unwrap().to_string();
    get_text!(LOCALIZATION_CTX, lang, key)
        .expect("no localization found")
        .to_string()
}
