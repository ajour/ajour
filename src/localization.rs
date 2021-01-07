use json_gettext::{get_text, static_json_gettext_build, JSONGetText};
use std::collections::HashMap;

pub fn build_ctx() -> JSONGetText<'static> {
    static_json_gettext_build!(
        "en_US",
        "en_US",
        "locale/en_US.json",
        "da_DK",
        "locale/da_DK.json"
    )
    .unwrap()
}

pub fn localized_string(ctx: &JSONGetText, lang: &str, key: &str) -> String {
    get_text!(ctx, lang, key)
        .expect("no localization found")
        .as_str()
        .expect("string conversion failed")
        .to_owned()
}

pub fn suported_langauges() -> HashMap<String, String> {
    [
        ("Danish".to_owned(), "da_DK".to_owned()),
        ("English".to_owned(), "en_US".to_owned()),
    ]
    .iter()
    .cloned()
    .collect()
}
