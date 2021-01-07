use crate::gui::{LANG, LOCALIZATION_CTX};
use json_gettext::get_text;

pub fn localized_string(key: &str) -> String {
    let lang = LANG.lock().unwrap().to_string();
    get_text!(LOCALIZATION_CTX, lang, key)
        .expect("no localization found")
        .to_string()
}
