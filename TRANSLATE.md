# Adding a translation
In order to add a translation, there are several steps to take, which are described in this document.

## Pre-requisites
The following tools are necessary to add a new translation and parse the codebase for strings to translate.

1. Cargo-i18n (Simplifies the creation of the translation files)
```
cargo install cargo-i18n
```

2. xtr (This is used by Cargo-i18n to automatically extract strings to translate from the code.)
```
cargo install xtr
```

## Add a new language in i18n.toml
In order to add a new translation, a new target language must be defined in the localization configuration file.

In `i18n.toml`, add a new language code (for a list of ISO 639-1 compatible language codes, see https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)

**For example, if I wanted to add a russian translation to the already present french translation**
```
[gettext]
# (Required) The languages that the software will be translated into.
target_languages = ["fr","ru"]
```

## Create the translation file
To create the translation file (a `.po` file) that will contain your new translations, you simply run the cargo i18n tool from the root of the project.

`cargo i18n`

After this, a new folder with your language code will have been created in `/i18n` with a file named `ajour.po` that contains all the translations to make.

## Testing your translations.
In order to test your translations, you need to pack all the translation files in a binary format (a `.mo` file) that then gets embedded in the binary. In order to do that, after translating all the strings, you run the cargo-i18n tool again, then rebuild and run the app.

```
cargo i18n

cargo build

cargo run
```

**Important: This translation system takes into account the locale of your system (Windows, Mac or Linux) to make a decision on which strings to display in the application. So if your system is not in the proper locale, you will not see your translations.**
