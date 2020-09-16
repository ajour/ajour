# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The sections should follow the order `Packaging`, `Added`, `Changed`, `Fixed` and `Removed`.

## [Unreleased]
### Packaging
- Added local logging for debugging the application. An `ajour.log` file is saved in the ajour config directory. This file can be shared along with any bug reports to help better debug the issue
### Added
- Improve clarity of row titles to reflect current sort state
  - A little up-, or down-arrow has been added to indicate sort direction, and a color has been added to the selected colum
### Changed
- Made it easier to use Ajour if you play both Classic and Retail by moving the control from settings into the menubar
  - Ajour will now parse both Classic and Retail directories on launch. This means that when you switch between the two it will now be instantaneously
### Fixed
- Update all will now respect ignored addons, and correctly skip them
- The settings- and detail-window will now be closed on interactions outside of it
  - It was a bit confusing that the windows stayed open even though you interacted with the application outside of them
- When displaying details for an addon, the title of the addon is highlighted to improve visibility of which addon is expanded
- Better toc file parsing
  - We now have better logic catching the values inside the toc file
  - If we for some reason does not find a title for the addon, we fallback and use the foldername
- Check for case-insensitive version of `Interface/AddOns` folder for robustness
- Check for & create ajour config folder before launching concurrent init operations
  - The `load_config` and `load_user_themes` operations are launched concurrently on startup. Since they both require the config folder, they will both try to create it if it doesn't exist. This causes a panic on linux since the `create_dir` fs operation fails if the folder already exists

## [0.3.2] - 2020-09-11
### Changed
- Light theme is now a bit more gentle to the eyes. Don't worry, it's still not default.
- Switched Refresh and Update All buttons.

## [0.3.1] - 2020-09-11
### Fixed
- Correctly rehashes addon after an update.
  - After an addon was updated we did in some cases not rehash correctly. This was due to the fact that a addon can have multiple folders and this was not taken into account in this case. Another case was that we replaced the content with the new update, but that could again lead to a miscalclulated hash if there was a mismatch in amount of files. Thanks to [tarkah](https://github.com/tarkah) for these optimizations.

## [0.3.0] - 2020-09-10
### Added
- Fingerprinting is now used to better match addons.
  - This is a bigger refactor, which introduces a whole new way of matching addons. We are now doing a hash of each addon, which we then compare with the API to see if we need to update or not. It has, however, introduced a longer initial load time because we need to hash each addon. The hash is saved locally, so we have some logic in place to minimize the amount of times we are hashing.
### Fixed
- Trimming leading and trailing whitespace from toc values.
  - Small issue where some `.toc` files added multiple space before, or after values which would confuse our UI. 
- UI glitch in settings has been removed.
## [0.2.5] - 2020-09-05
### Added
- Make columns sortable (by [tarkah](https://github.com/tarkah))
- Support for user themes and theme selection (by [tarkah](https://github.com/tarkah))
### Fixed
- UTF-8 issue in .toc file
- Updated copy, and improved onboarding experience
## [0.2.4] - 2020-09-02
### Added
- Ajour checks itself for updates (by [tarkah](https://github.com/tarkah))
- Tukui now handle classic flavor
### Changed
- Removed details button. Title is now clickable.
### Fixed
- Parsing issue with Tukui addons.

## [0.2.3] - 2020-08-30
### Added
- New logic for bundling together addons
- Author information in addon details
- Ignore and unignore addons

### Changed
- Throttle # of connections to api

## [0.2.2] - 2020-08-27
### Added
- Select game flavor in Settings

### Fixed
- Large addons were not being timedout
- Linux users were not able to select a folder in file dialog

## [0.2.1] - 2020-08-26
### Added
- Settings view
- File dialog to select World of Warcraft pth from settings view
- Force download button on addons

### Fixed
- Better copy for many strings
