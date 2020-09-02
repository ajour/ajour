# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The sections should follow the order `Packaging`, `Added`, `Changed`, `Fixed` and `Removed`.

## [Unreleased]
### Fixed
- UTF-8 issue in .toc file
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
