<!-- @see (casperstorm): Disable MD024 because `Keep a Changelog` use duplicate
header titles -->
<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The sections should follow the order `Packaging`, `Added`, `Changed`, `Fixed`
and `Removed`.

## [Unreleased]

## [0.5.4] - 2020-12-07

### Added

- Row Highlighting. Rows in `My Addons` and `Catalog` will now highlight on mouseover.
  Clicking a row in `My Addons` will expand it. Clicking a row in `Catalog` will
  launch the website of the addon.
- Ability to retry an update, if it failed during download or unpacking.
- A minimum size to the Ajour window.
- A new Beta self update channel has been added that can be selected to allow self
  updating Ajour to beta releases. Use this if you'd like to help test out newer
  features before they are released, or just want the latest a little quicker than
  our normal release schedule. This can be changed in the settings.
- Periodic self update check. Ajour will now check for self updates while running
  every hour. Previously self updates were only checked on launch.

### Changed

- The old Changelog system has been removed which means you can no longer
  interact with the versions in the `Local` and `Remote` columns.
  Instead, a `Changelog` button has been added to the expanded addon window.

### Fixed

- Fixed issue where some Tukui addons wouldn't get matched correctly.
- Fixed a bug in backup where the zip archive created on Windows didn't open properly
  on Linux and Macos. Fixed by converting Windows `\` path separators to `/` before
  writing to the zip file.

## [0.5.3] - 2020-11-23

### Added

- Added an option to Backup via the command line. Flavors and backup folder sources
  can be specified
  - Pass `ajour backup --help` to get help using this new command
- Two new themes; Ferra and One Dark
- Button in settings to open config data directory

### Changed

- Sorted themes alphabetically in the picker
- Better human readable errors in Ajour gui. Errors and underlying causes
are still logged.

### Fixed

- Fixed bug that caused catalog to fail downloading when `null` values existed
  in the payload
- Ajour starts with zero height and width after being closed minimized
- Removed timeout for downloading the catalog. Users with slow internet can now
  fetch the catalog regardless of how long it will take
- Catalog could cause Ajour to crash if internet connection was slow

## [0.5.2] - 2020-11-20

### Packaging

- Updated Ajour icon on macOS to a "Big Sur" version

### Added

- About view
- Option to hide ignored addons

### Changed

- Date sort catalog descending first, which is more natural
- Settings now use the whole view

### Fixed

- Game Version fallback to TOC could in some cases fail
- Visual glitch when only having 1 flavor
- Load addons into catalog asynchronously
- Only show categories pertaining to the source selected

## [0.5.1] - 2020-11-12

### Added

- WoWInterface addons has been added to the Catalog.
- Catalog will automatically refresh if Ajour is kept open.
  - Underlying catalog data refreshes every night at 00:00 UTC, this refresh
    triggers at 00:05 UTC
- Added ability to toggle which folders get included in Backup (AddOns & WTF)
- Addons can be installed from GitHub and GitLab via the GUI or command line
  - To install via the command line, check out `ajour install --help`

### Fixed

- If we don't get Game Version from API we fallback to the one in the TOC file
  if present.
- Increased width on certain buttons to avoid line breaks.

## [0.5.0] - 2020-11-03

### Packaging

- Ajour can now self update when a new release is available. An "Update" button
  will appear along with a message that a newer release is available. Clicking this
  button will automatically update Ajour and relaunch it as the newer version.
  - On windows, self update may fail if you've placed the executable in Program
    Files due to permissions. Either run as administrator or place the executable
    under your User folder. We recommend placing it as `%APPDATA%\ajour\ajour.exe`
    and pinning to the taskbar or creating a desktop shortcut.
  - On linux, self update only works when running from the AppImage.
- The linux `AppImage` release assets are now built on Ubuntu 16.04 (Xenial) to
  improve support.

### Added

- You can now select which columns you want to see in the Catalog.
- Game version has been added as a optional column to addons in the Catalog.
- Ajour now matches addons against WoWInterface.
- Button to Ajour website in Settings.
- Tukui addons can now be installed via the Catalog.
  - A cache was added to support this feature since tukui addons have fairly
    unreliable metadata in their .toc files.

### Fixed

- Some addons failed to install through the catalog.
- Cancelling when changing wow path will empty list.
- Case-sensitive issue when sorting addons by title.
- Better addon changelog formatting.
- Bug on linux that caused window size to grow / shrink between sessions when a
  <>1.0 scale was set.
- Issue where Ajour sometimes shows a blank screen while content is loading.
- Issue where forked addons from the curse API would show both versions of the
  addon in Ajour instead of only the one actually installed.

## [0.4.4] - 2020-10-23

### Fixed

- Fixed issue where Tukui addons would delete dependency standalone addons
  during update.
- Now correctly shows all sub-addons if they are a seperate addons.
  - An example is Altoholic-Retail (Teelo's Fork). All it's dependencies are
    actually standalone addons. They are now correctly shown.

## [0.4.3] - 2020-10-22

### Fixed

- Fixed the CurseForge API issue by using another api that caches the responses
  (kindly provided by wowup.io).
- Minor improvements to the matching addons which was caused by yesterdays update
  (SORRY!).

## [0.4.2] - 2020-10-21

### Added

- Add fallback measures for displaying addons when fingerprinting fails or we
  can't link an addon to a remote registry.
  - Curse addons that have been locally modified should now display properly in
    Ajour. A `Repair` button will be present which will install the latest version
    of the addon so Ajour can accurately track the addon without local modifications.
  - Addons that can't match to any registry will now show up in Ajour as status
    `Unknown`. Addons that have multiple folders will not be grouped and instead
    we will show one entry for every folder.
  - **NOTE**: The current ongoing issues with the CurseForge fingerprint API
    means some addons will randomly get one of these new statuses, but should be
    ignored until that issue has been resolved.
- Added Latest Release column to both My Addons and Catalog.
- Support for Beta and PTR.
- When pressing on either `local` or `remote` version in MyAddons you will see
  the changelog.
- When pressing on the addon title inside the catalog Ajour will open the addon
  website.

### Fixed

- Fixed bug where orphaned folders could exist after updating an addon if the
  newer version of an addon didnt't include those folders anymore.
- Ensure symlinks are removed in the addons folder prior to extracting an addon,
  so we don't write into the symlink and instead remove the link / create a new folder.
  - This is a request from a developer who symlinks their source code into the
    addons folder and Ajour could accidently overwrite it.
- Fixed catalog install buttons getting stuck when install fails or addon is
  unavailable to download. Button will now show "Retry" if failed and disabled as
  "Unavailable" if the addon is unavailable.
- Added a check on content length of downloaded addons when updating or
  installing and properly set an error message when this occurs so we know the
  update / install failed so use can retry.
- Fixed a bug in the logic for selecting a relevant release channel.

### Changed

- Now only shows the flavors which is detected in your World of Warcraft folder

### Packaging

- Added Forest Night theme

## [0.4.1] - 2020-10-11

### Added

- 10 new themes has been bundled together with the application.
  - The way you define a theme has been refactored so we can define more nuances.
  - This is a breaking changes for old themes, which needs to be refactored to
    the new format. By default if the theme does not conform to the new format,
    Ajour will simply not try to parse it.
- Added a command line option to update all addons with an update without launching
  the GUI. Process will exit after completing.
  - Use `ajour update` from command line
- Ajour can now self update when a new release is available.
  - User is presented with an "Update" buton instead of a "Download" button when
    a new release is available. Upon clicking, the new release will be downloaded
    in the background, replace the existing executable file, and will be relaunched
    as the new version.

### Fixed

- Fixed a case where we would choose alpha even though it was older than stable.
- Fixed fingerprinting where some addons would fail during fingerprinting due to
  invalid UTF-8 characters and missing files. These addons now successfully fingerprint.

## [0.4.0] - 2020-10-06

### Added

- The catalog has been implemented 📦
  - This is long awaited, but we wanted to get it right. You can now easily and
    quickly search, filter and install addons
  - This first release of the catalog will come with CurseForge as source and in
    the next release we will add Tukui as well
- Logic for falling back to root World of Warcraft directory if a sub-folder was
  chosen
  - We solved a UX problem with some coding logic. It was not always clear that
    Ajour requires the World of Warcraft root folder

### Changed

- Tidy up Settings
- Better onboarding the first time you start Ajour
  - We have added a nice button to the welcome message to let users easily get
    going by selecting the World of Warcraft path

## [0.3.5] - 2020-10-01

### Packaging

- Updated Ajour icon.
- Added an alternative build that uses OpenGL. This will allow Ajour to be used
  by the widest possible audience, and resolve issues where users couldn't use Ajour
  with older / certain GPU configurations. An alternative download link will be
  provided to users wanting to try this build over the default.
- Added AppImage release that can be used on linux distro

### Added

- You can now select which release channel you want each addon to use. Currently
  `alpha`, `beta` and `stable` is supported.
- Columns can now be toggled as visible and reordered from settings. In addition,
  3 new optional columns have been added that can be toggled (Channel, Game Version,
  Author).
- Added command line options that can be specified to change the behavior of Ajour
  at runtime.
  - `--data <PATH>` can be specified to use a custom data directory
  - `--aa <true / false>` can be specified to enable / disable Anti-aliasing.
    Anti-aliasing is used by default if not specified.

### Changed

- Ignored addons has been removed from settings, and is now present in the addon
  list with a `ignored` status.
  - Reason for this is to clean up settings view.
- Reworked the controls for selected flavor. It should now be more obvious what
  is selected and what you can select.
- Ajour now does a better job at cache busting by looking at the modified date
  on a Addon folder.

### Fixed

- Ajour now creates the `.config` dir if it does not exist on macOS and Linux.
  - This fixes a crash where Ajour coudn't start if the user didn't have a `.config`
    directory.
- Fixed a issue where Ajour would crash if CurseForge returned Minecraft addons
  instead of a World of Warcraft addons.
  - We have had a incident where a requested World of Warcraft addon was returned
    as a Minecraft plugin called HorsePower. This we did not expect so Ajour would
    crash.

## [0.3.4] - 2020-09-26

### Packaging

- Windows: Ajour now comes bundled with the needed dependencies. This way we avoid
  relying on the system having Microsoft Visual C++ 2015 Redistributable.

### Added

- It is now possible to see when a update was released in the details view of an
  addon.
- A website button has been added to the detail view of each addon.
  - The idea is that with this button, it is easy to open up the addon website
    and view additional information which Ajour might not show.
- Columns can be resized by clicking & dragging the dividers between the column
  headers. This change will be saved and used when starting Ajour.
- Window size will be saved when resizing the application and used when starting
  Ajour.
- UI Scaling has been added to settings. UI scale can be increased or decreased
  and will be saved when changed.
- A backup option has been added to archive the AddOns and WTF folders from each
  flavor installed on the machine to a user chosen directory.
  - Backups created through Ajour are not actively managed once created, so pruning
    old backups and restoring from a backup need to be handled by the user

### Changed

- Detail view has now a more calm look by utlilizing the space to the right, and
  by increasing the opacity of the background slighty to create some levels in the
  design.

## [0.3.3] - 2020-09-17

### Packaging

- Added local logging for debugging the application. An `ajour.log` file is saved
  in the ajour config directory. This file can be shared along with any bug reports
  to help better debug the issue

### Added

- Improve clarity of row titles to reflect current sort state

### Changed

- Made it easier to use Ajour if you play both Classic and Retail by moving the
  control from settings into the menubar
  - Ajour will now parse both Classic and Retail directories on launch. This means
    that when you switch between the two it will now be instantaneously

### Fixed

- Update all will now respect ignored addons, and correctly skip them
- The settings- and detail-window will now be closed on interactions outside of
  it
  - It was a bit confusing that the windows stayed open even though you interacted
    with the application outside of them
- When displaying details for an addon, the title of the addon is highlighted to
  improve visibility of which addon is expanded
- Better toc file parsing
  - We now have better logic catching the values inside the toc file
  - If we for some reason does not find a title for the addon, we fallback and
    use the foldername
- Check for case-insensitive version of `Interface/AddOns` folder for robustness
- Check for & create ajour config folder before launching concurrent init operations
  - The `load_config` and `load_user_themes` operations are launched concurrently
    on startup. Since they both require the config folder, they will both try to
    create it if it doesn't exist. This causes a panic on linux since the `create_dir`
    fs operation fails if the folder already exists

## [0.3.2] - 2020-09-11

### Changed

- Light theme is now a bit more gentle to the eyes. Don't worry, it's still not
  default.
- Switched Refresh and Update All buttons.

## [0.3.1] - 2020-09-11

### Fixed

- Correctly rehashes addon after an update.
  - After an addon was updated we did in some cases not rehash correctly. This
    was due to the fact that a addon can have multiple folders and this was not
    taken into account in this case. Another case was that we replaced the content
    with the new update, but that could again lead to a miscalclulated hash if there
    was a mismatch in amount of files. Thanks to [tarkah](https://github.com/tarkah)
    for these optimizations.

## [0.3.0] - 2020-09-10

### Added

- Fingerprinting is now used to better match addons.
  - This is a bigger refactor, which introduces a whole new way of matching addons.
    We are now doing a hash of each addon, which we then compare with the API to
    see if we need to update or not. It has, however, introduced a longer initial
    load time because we need to hash each addon. The hash is saved locally, so
    we have some logic in place to minimize the amount of times we are hashing.

### Fixed

- Trimming leading and trailing whitespace from toc values.
  - Small issue where some `.toc` files added multiple space before, or after values
    which would confuse our UI.
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
