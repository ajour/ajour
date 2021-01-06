use json_gettext::{get_text, static_json_gettext_build, JSONGetText, JSONGetTextValue};
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

pub fn suported_langauges() -> HashMap<String, String> {
    [
        ("Danish".to_owned(), "da_DK".to_owned()),
        ("English".to_owned(), "en_US".to_owned()),
    ]
    .iter()
    .cloned()
    .collect()
}
