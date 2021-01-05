mod element;
mod style;
mod update;

use crate::cli::Opts;
use ajour_core::{
    addon::{Addon, AddonFolder, AddonState},
    cache::{
        load_addon_cache, load_fingerprint_cache, AddonCache, AddonCacheEntry, FingerprintCache,
    },
    catalog::get_catalog,
    catalog::{self, Catalog, CatalogAddon},
    config::{ColumnConfig, ColumnConfigV2, Config, Flavor, SelfUpdateChannel},
    error::*,
    fs::PersistentData,
    repository::{GlobalReleaseChannel, ReleaseChannel},
    theme::{load_user_themes, Theme},
    utility::{self, get_latest_release},
};
use ajour_weak_auras::{Aura, AuraStatus};
use ajour_widgets::header;
use async_std::sync::{Arc, Mutex};
use chrono::{DateTime, NaiveDateTime, Utc};
use color_eyre::eyre::{Report, Result};
use iced::{
    button, pick_list, scrollable, text_input, Align, Application, Button, Column, Command,
    Container, Element, HorizontalAlignment, Length, PickList, Row, Scrollable, Settings, Space,
    Subscription, Text, TextInput,
};
use image::ImageFormat;
use isahc::http::Uri;
use std::collections::HashMap;
use std::path::PathBuf;
use std::time::{Duration, Instant};

use element::{DEFAULT_FONT_SIZE, DEFAULT_PADDING};
static WINDOW_ICON: &[u8] = include_bytes!("../../resources/windows/ajour.ico");

#[derive(Debug, Clone, PartialEq)]
pub enum State {
    Start,
    Ready,
    Loading,
}

impl Default for State {
    fn default() -> Self {
        State::Start
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Mode {
    MyAddons(Flavor),
    MyWeakAuras(Flavor),
    Install,
    Catalog,
    Settings,
    About,
}

impl std::fmt::Display for Mode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                Mode::MyAddons(_) => "My Addons",
                Mode::MyWeakAuras(_) => "My WeakAuras",
                Mode::Install => "Install",
                Mode::Catalog => "Catalog",
                Mode::Settings => "Settings",
                Mode::About => "About",
            }
        )
    }
}

#[derive(Debug, Clone)]
#[allow(clippy::large_enum_variant)]
pub enum Interaction {
    Delete(String),
    Expand(ExpandType),
    Ignore(String),
    SelectDirectory(DirectoryType),
    OpenDirectory(PathBuf),
    OpenLink(String),
    Refresh(Mode),
    Unignore(String),
    Update(String),
    UpdateAll(Mode),
    SortColumn(ColumnKey),
    SortCatalogColumn(CatalogColumnKey),
    SortAuraColumn(AuraColumnKey),
    FlavorSelected(Flavor),
    ResizeColumn(Mode, header::ResizeEvent),
    ScaleUp,
    ScaleDown,
    Backup,
    ToggleColumn(bool, ColumnKey),
    ToggleCatalogColumn(bool, CatalogColumnKey),
    ToggleHideIgnoredAddons(bool),
    MoveColumnLeft(ColumnKey),
    MoveColumnRight(ColumnKey),
    MoveCatalogColumnLeft(CatalogColumnKey),
    MoveCatalogColumnRight(CatalogColumnKey),
    ModeSelected(Mode),
    CatalogQuery(String),
    InstallSCMQuery(String),
    InstallSCMURL,
    InstallAddon(Flavor, String, InstallKind),
    CatalogCategorySelected(CatalogCategory),
    CatalogResultSizeSelected(CatalogResultSize),
    CatalogSourceSelected(CatalogSource),
    UpdateAjour,
    ToggleBackupFolder(bool, BackupFolderKind),
    PickSelfUpdateChannel(SelfUpdateChannel),
    PickGlobalReleaseChannel(GlobalReleaseChannel),
    AlternatingRowColorToggled(bool),
    ResetColumns,
    ToggleDeleteSavedVariables(bool),
}

#[derive(Debug)]
#[allow(clippy::large_enum_variant)]
pub enum Message {
    CachesLoaded(Result<(FingerprintCache, AddonCache)>),
    DownloadedAddon((DownloadReason, Flavor, String, Result<(), DownloadError>)),
    Error(Report),
    Interaction(Interaction),
    LatestRelease(Option<utility::Release>),
    None(()),
    Parse(()),
    ParsedAddons((Flavor, Result<Vec<Addon>, ParseError>)),
    UpdateFingerprint((Flavor, String, Result<(), ParseError>)),
    ThemeSelected(String),
    // TODO: Rename to addon specific.
    ReleaseChannelSelected(ReleaseChannel),
    ThemesLoaded(Vec<Theme>),
    UnpackedAddon(
        (
            DownloadReason,
            Flavor,
            String,
            Result<Vec<AddonFolder>, FilesystemError>,
        ),
    ),
    UpdateWowDirectory(Option<PathBuf>),
    UpdateBackupDirectory(Option<PathBuf>),
    RuntimeEvent(iced_native::Event),
    LatestBackup(Option<NaiveDateTime>),
    BackupFinished(Result<NaiveDateTime, FilesystemError>),
    CatalogDownloaded(Result<Catalog, DownloadError>),
    InstallAddonFetched((Flavor, String, Result<Addon, RepositoryError>)),
    AjourUpdateDownloaded(Result<(PathBuf, PathBuf), DownloadError>),
    AddonCacheUpdated(Result<AddonCacheEntry, CacheError>),
    AddonCacheEntryRemoved(Result<Option<AddonCacheEntry>, CacheError>),
    RefreshCatalog(Instant),
    CheckLatestRelease(Instant),
    CheckWeakAurasInstalled((Flavor, bool)),
    ListWeakAurasAccounts((Flavor, Result<Vec<String>, ajour_weak_auras::Error>)),
    WeakAurasAccountSelected(String),
    ParsedAuras((Flavor, Result<Vec<Aura>, ajour_weak_auras::Error>)),
    AurasUpdated((Flavor, Result<Vec<String>, ajour_weak_auras::Error>)),
}

pub struct Ajour {
    state: HashMap<Mode, State>,
    error: Option<Report>,
    mode: Mode,
    addons: HashMap<Flavor, Vec<Addon>>,
    addons_scrollable_state: scrollable::State,
    weakauras_scrollable_state: scrollable::State,
    settings_scrollable_state: scrollable::State,
    about_scrollable_state: scrollable::State,
    config: Config,
    valid_flavors: Vec<Flavor>,
    directory_btn_state: button::State,
    expanded_type: ExpandType,
    self_update_state: SelfUpdateState,
    refresh_btn_state: button::State,
    settings_btn_state: button::State,
    about_btn_state: button::State,
    update_all_btn_state: button::State,
    header_state: HeaderState,
    theme_state: ThemeState,
    fingerprint_cache: Option<Arc<Mutex<FingerprintCache>>>,
    addon_cache: Option<Arc<Mutex<AddonCache>>>,
    retail_btn_state: button::State,
    retail_ptr_btn_state: button::State,
    retail_beta_btn_state: button::State,
    classic_btn_state: button::State,
    classic_ptr_btn_state: button::State,
    addon_mode_btn_state: button::State,
    weakaura_mode_btn_state: button::State,
    catalog_mode_btn_state: button::State,
    install_mode_btn_state: button::State,
    scale_state: ScaleState,
    backup_state: BackupState,
    column_settings: ColumnSettings,
    catalog_column_settings: CatalogColumnSettings,
    onboarding_directory_btn_state: button::State,
    catalog: Option<Catalog>,
    install_addons: HashMap<Flavor, Vec<InstallAddon>>,
    catalog_last_updated: Option<DateTime<Utc>>,
    catalog_search_state: CatalogSearchState,
    catalog_header_state: CatalogHeaderState,
    catalog_categories_per_source_cache: HashMap<String, Vec<CatalogCategory>>,
    website_btn_state: button::State,
    patreon_btn_state: button::State,
    open_config_dir_btn_state: button::State,
    install_from_scm_state: InstallFromSCMState,
    self_update_channel_state: SelfUpdateChannelState,
    default_addon_release_channel_picklist_state: pick_list::State<GlobalReleaseChannel>,
    weak_auras_is_installed: bool,
    weak_auras_state: HashMap<Flavor, WeakAurasState>,
    aura_header_state: AuraHeaderState,
    reset_columns_btn_state: button::State,
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
            state: [(Mode::Catalog, State::Loading)].iter().cloned().collect(),
            error: None,
            mode: Mode::MyAddons(Flavor::Retail),
            addons: HashMap::new(),
            addons_scrollable_state: Default::default(),
            weakauras_scrollable_state: Default::default(),
            settings_scrollable_state: Default::default(),
            about_scrollable_state: Default::default(),
            config: Config::default(),
            valid_flavors: Vec::new(),
            directory_btn_state: Default::default(),
            expanded_type: ExpandType::None,
            self_update_state: Default::default(),
            refresh_btn_state: Default::default(),
            settings_btn_state: Default::default(),
            about_btn_state: Default::default(),
            update_all_btn_state: Default::default(),
            header_state: Default::default(),
            theme_state: Default::default(),
            fingerprint_cache: None,
            addon_cache: None,
            retail_btn_state: Default::default(),
            retail_ptr_btn_state: Default::default(),
            retail_beta_btn_state: Default::default(),
            classic_btn_state: Default::default(),
            classic_ptr_btn_state: Default::default(),
            addon_mode_btn_state: Default::default(),
            weakaura_mode_btn_state: Default::default(),
            catalog_mode_btn_state: Default::default(),
            install_mode_btn_state: Default::default(),
            scale_state: Default::default(),
            backup_state: Default::default(),
            column_settings: Default::default(),
            catalog_column_settings: Default::default(),
            onboarding_directory_btn_state: Default::default(),
            catalog: None,
            install_addons: Default::default(),
            catalog_last_updated: None,
            catalog_search_state: Default::default(),
            catalog_header_state: Default::default(),
            catalog_categories_per_source_cache: Default::default(),
            website_btn_state: Default::default(),
            patreon_btn_state: Default::default(),
            open_config_dir_btn_state: Default::default(),
            install_from_scm_state: Default::default(),
            self_update_channel_state: SelfUpdateChannelState {
                picklist: Default::default(),
                options: SelfUpdateChannel::all(),
            },
            default_addon_release_channel_picklist_state: Default::default(),
            weak_auras_is_installed: Default::default(),
            weak_auras_state: Default::default(),
            aura_header_state: Default::default(),
            reset_columns_btn_state: Default::default(),
        }
    }
}

impl Application for Ajour {
    type Executor = iced::executor::Default;
    type Message = Message;
    type Flags = Config;

    fn new(config: Config) -> (Self, Command<Message>) {
        let init_commands = vec![
            Command::perform(load_caches(), Message::CachesLoaded),
            Command::perform(
                get_latest_release(config.self_update_channel),
                Message::LatestRelease,
            ),
            Command::perform(load_user_themes(), Message::ThemesLoaded),
            Command::perform(get_catalog(), Message::CatalogDownloaded),
        ];

        let mut ajour = Ajour::default();

        apply_config(&mut ajour, config);

        (ajour, Command::batch(init_commands))
    }

    fn title(&self) -> String {
        String::from("Ajour")
    }

    fn scale_factor(&self) -> f64 {
        self.scale_state.scale
    }

    fn subscription(&self) -> Subscription<Self::Message> {
        let runtime_subscription = iced_native::subscription::events().map(Message::RuntimeEvent);
        let catalog_subscription =
            iced_futures::time::every(Duration::from_secs(60 * 5)).map(Message::RefreshCatalog);
        let new_release_subscription = iced_futures::time::every(Duration::from_secs(60 * 60))
            .map(Message::CheckLatestRelease);

        iced::Subscription::batch(vec![
            runtime_subscription,
            catalog_subscription,
            new_release_subscription,
        ])
    }

    fn update(&mut self, message: Message) -> Command<Message> {
        match update::handle_message(self, message) {
            Ok(x) => x,
            Err(e) => Command::perform(async { e }, Message::Error),
        }
    }

    fn view(&mut self) -> Element<Message> {
        // Get color palette of chosen theme.
        let color_palette = self
            .theme_state
            .themes
            .iter()
            .find(|(name, _)| name == &self.theme_state.current_theme_name)
            .as_ref()
            .unwrap_or(&&("Dark".to_string(), Theme::dark()))
            .1
            .palette;

        let flavor = self.config.wow.flavor;

        // Check if we have any addons.
        let has_addons = {
            let addons = self.addons.entry(flavor).or_default();

            !&addons.is_empty()
        };

        // Check if we have any auras.
        let has_auras = {
            let aura_state = self.weak_auras_state.entry(flavor).or_default();

            !aura_state.auras.is_empty()
        };

        // Used to display changelog later in the About screen.
        let release_copy = if let Some(release) = &self.self_update_state.latest_release {
            Some(release.clone())
        } else {
            None
        };

        // Menu container at the top of the applications.
        let menu_container = element::menu::data_container(
            color_palette,
            &self.mode,
            &self.state,
            self.error.as_ref(),
            &self.config,
            &self.valid_flavors,
            &mut self.settings_btn_state,
            &mut self.about_btn_state,
            &mut self.addon_mode_btn_state,
            &mut self.weakaura_mode_btn_state,
            &mut self.catalog_mode_btn_state,
            &mut self.install_mode_btn_state,
            &mut self.retail_btn_state,
            &mut self.retail_ptr_btn_state,
            &mut self.retail_beta_btn_state,
            &mut self.classic_btn_state,
            &mut self.classic_ptr_btn_state,
            &mut self.self_update_state,
            self.weak_auras_is_installed,
        );

        let column_config = self.header_state.column_config();
        let catalog_column_config = self.catalog_header_state.column_config();
        let aura_column_config = self.aura_header_state.column_config();

        // This column gathers all the other elements together.
        let mut content = Column::new().push(menu_container);

        // Spacer between menu and content.
        content = content.push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)));

        match self.mode {
            Mode::MyAddons(flavor) => {
                // Get mutable addons for current flavor.
                let addons = self.addons.entry(flavor).or_default();

                // Check if we have any addons.
                let has_addons = !&addons.is_empty();

                // Menu for addons.
                let menu_addons_container = element::my_addons::menu_container(
                    color_palette,
                    flavor,
                    &mut self.update_all_btn_state,
                    &mut self.refresh_btn_state,
                    &self.state,
                    addons,
                    &self.config,
                );
                content = content.push(menu_addons_container);

                // Addon row titles is a row of titles above the addon scrollable.
                // This is to add titles above each section of the addon row, to let
                // the user easily identify what the value is.
                let addon_row_titles = element::my_addons::titles_row_header(
                    color_palette,
                    addons,
                    &mut self.header_state.state,
                    &mut self.header_state.columns,
                    self.header_state.previous_column_key,
                    self.header_state.previous_sort_direction,
                );

                // A scrollable list containing rows.
                // Each row holds data about a single addon.
                let mut addons_scrollable = Scrollable::new(&mut self.addons_scrollable_state)
                    .spacing(1)
                    .height(Length::FillPortion(1))
                    .style(style::Scrollable(color_palette));

                // Loops though the addons.
                for (idx, addon) in addons.iter_mut().enumerate() {
                    // If hiding ignored addons, we will skip it.
                    if addon.state == AddonState::Ignored && self.config.hide_ignored_addons {
                        continue;
                    }

                    // Checks if the current addon is expanded.
                    let is_addon_expanded = match &self.expanded_type {
                        ExpandType::Details(a) => a.primary_folder_id == addon.primary_folder_id,
                        ExpandType::None => false,
                    };

                    let is_odd = if self.config.alternating_row_colors {
                        Some(idx % 2 != 0)
                    } else {
                        None
                    };

                    // A container cell which has all data about the current addon.
                    // If the addon is expanded, then this is also included in this container.
                    let addon_data_cell = element::my_addons::data_row_container(
                        color_palette,
                        addon,
                        is_addon_expanded,
                        &self.expanded_type,
                        &self.config,
                        &column_config,
                        is_odd,
                    );

                    // Adds the addon data cell to the scrollable.
                    addons_scrollable = addons_scrollable.push(addon_data_cell);
                }

                // Bottom space below the scrollable.
                let bottom_space =
                    Space::new(Length::FillPortion(1), Length::Units(DEFAULT_PADDING));

                // Adds the rest of the elements to the content column.
                if has_addons {
                    content = content
                        .push(addon_row_titles)
                        .push(addons_scrollable)
                        .push(bottom_space)
                }
            }
            Mode::MyWeakAuras(flavor) => {
                let weak_auras_state = self.weak_auras_state.entry(flavor).or_default();

                let num_auras = weak_auras_state.auras.len();
                let num_available = weak_auras_state
                    .auras
                    .iter()
                    .filter(|a| a.has_update())
                    .count();
                let is_updating = weak_auras_state.is_updating;
                let updates_queued = weak_auras_state
                    .auras
                    .iter()
                    .filter(|a| a.status() == AuraStatus::UpdateQueued)
                    .count()
                    == num_available
                    && num_available > 0;

                // Menu for WeakAuras.
                let menu_container = element::my_weakauras::menu_container(
                    color_palette,
                    flavor,
                    &mut self.update_all_btn_state,
                    &mut self.refresh_btn_state,
                    &self.state,
                    num_auras,
                    num_available > 0,
                    is_updating,
                    updates_queued,
                    &mut weak_auras_state.account_picklist,
                    &weak_auras_state.accounts,
                    weak_auras_state.chosen_account.clone(),
                );

                content = content.push(menu_container);

                // Addon row titles is a row of titles above the addon scrollable.
                // This is to add titles above each section of the addon row, to let
                // the user easily identify what the value is.
                let aura_row_titles = element::my_weakauras::titles_row_header(
                    color_palette,
                    &weak_auras_state.auras,
                    &mut self.aura_header_state.state,
                    &mut self.aura_header_state.columns,
                    self.aura_header_state.previous_column_key,
                    self.aura_header_state.previous_sort_direction,
                );

                // A scrollable list containing rows.
                // Each row holds data about a single WeakAura.
                let mut scrollable = Scrollable::new(&mut self.weakauras_scrollable_state)
                    .spacing(1)
                    .height(Length::FillPortion(1))
                    .style(style::Scrollable(color_palette));

                for (idx, aura) in weak_auras_state.auras.iter().enumerate() {
                    let is_odd = if self.config.alternating_row_colors {
                        Some(idx % 2 != 0)
                    } else {
                        None
                    };

                    let row = element::my_weakauras::data_row_container(
                        color_palette,
                        aura,
                        &aura_column_config,
                        is_odd,
                    );

                    scrollable = scrollable.push(row);
                }

                //Bottom space below the scrollable.
                let bottom_space =
                    Space::new(Length::FillPortion(1), Length::Units(DEFAULT_PADDING));

                if num_auras > 0 {
                    content = content
                        .push(aura_row_titles)
                        .push(scrollable)
                        .push(bottom_space)
                }
            }
            Mode::Install => {
                let query = self
                    .install_from_scm_state
                    .query
                    .as_deref()
                    .unwrap_or_default();
                let url = query.parse::<Uri>().ok();
                let is_valid_url = url
                    .map(|url| {
                        let host = url.host().map(|h| h.to_lowercase());

                        host.as_deref() == Some("gitlab.com")
                            || host.as_deref() == Some("github.com")
                    })
                    .unwrap_or_default();

                let default = vec![];
                let addons = self.addons.get(&flavor).unwrap_or(&default);

                let installed = addons
                    .iter()
                    .filter_map(|a| {
                        let id = a.repository_id()?;

                        let a = id.parse::<Uri>().ok()?;
                        let b = query.parse::<Uri>().ok()?;

                        if a.host().map(|s| s.to_lowercase()) == b.host().map(|s| s.to_lowercase())
                            && a.path().to_lowercase() == b.path().to_lowercase()
                        {
                            Some(a)
                        } else {
                            None
                        }
                    })
                    .count()
                    > 0;

                let install_status = self
                    .install_addons
                    .entry(flavor)
                    .or_default()
                    .iter()
                    .find(|a| a.kind == InstallKind::Source)
                    .map(|a| a.status.clone());

                let install_for_flavor = format!("Install for {}", self.config.wow.flavor);
                let install_text = Text::new(if installed {
                    "Installed"
                } else {
                    match install_status {
                        Some(InstallStatus::Downloading) => "Downloading",
                        Some(InstallStatus::Unpacking) => "Unpacking",
                        Some(InstallStatus::Retry) => "Retry",
                        Some(InstallStatus::Unavilable) => "Unavilable",
                        Some(InstallStatus::Error(_)) | None => &install_for_flavor,
                    }
                })
                .size(DEFAULT_FONT_SIZE);

                let install_button_title_container = Container::new(install_text)
                    .center_x()
                    .center_y()
                    .width(Length::Units(150))
                    .height(Length::Units(24));

                let mut install_button = Button::new(
                    &mut self.install_from_scm_state.install_button_state,
                    install_button_title_container,
                )
                .style(style::DefaultBoxedButton(color_palette));

                if matches!(install_status, None) && !installed && is_valid_url {
                    install_button = install_button.on_press(Interaction::InstallSCMURL);
                }

                let install_button: Element<Interaction> = install_button.into();

                let mut install_scm_query = TextInput::new(
                    &mut self.install_from_scm_state.query_state,
                    "E.g.: https://github.com/author/repository",
                    query,
                    Interaction::InstallSCMQuery,
                )
                .size(DEFAULT_FONT_SIZE)
                .padding(10)
                .width(Length::Units(350))
                .style(style::CatalogQueryInput(color_palette));

                if !installed
                    && !matches!(install_status, Some(InstallStatus::Error(_)))
                    && is_valid_url
                {
                    install_scm_query = install_scm_query.on_submit(Interaction::InstallSCMURL);
                }

                let install_scm_query: Element<Interaction> = install_scm_query.into();

                let description = Text::new("Install an addon directly from either GitHub or GitLab\nThe addon must be published as a release asset")
                    .size(DEFAULT_FONT_SIZE)
                    .width(Length::Fill)
                    .horizontal_alignment(HorizontalAlignment::Center);
                let description_container = Container::new(description)
                    .width(Length::Fill)
                    .style(style::NormalBackgroundContainer(color_palette));

                let query_row = Row::new()
                    .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                    .push(install_scm_query.map(Message::Interaction))
                    .push(install_button.map(Message::Interaction))
                    .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                    .align_items(Align::Center)
                    .spacing(1);

                // Empty error initially to keep design aligned.
                let mut error_text: String = String::from(" ");
                if let Some(InstallStatus::Error(error)) = install_status {
                    error_text = error;
                }

                let column = Column::new()
                    .push(description_container)
                    .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
                    .push(query_row)
                    .push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)))
                    .push(
                        Container::new(Text::new(error_text).size(DEFAULT_FONT_SIZE))
                            .style(style::NormalErrorBackgroundContainer(color_palette)),
                    )
                    .align_items(Align::Center);

                let container = Container::new(column)
                    .width(Length::Fill)
                    .center_y()
                    .center_x()
                    .height(Length::Fill);

                content = content.push(container);
            }
            Mode::Catalog => {
                if let Some(catalog) = &self.catalog {
                    let default = vec![];
                    let addons = self.addons.get(&flavor).unwrap_or(&default);

                    let query = self
                        .catalog_search_state
                        .query
                        .as_deref()
                        .unwrap_or_default();

                    let catalog_query = TextInput::new(
                        &mut self.catalog_search_state.query_state,
                        "Search for an addon...",
                        query,
                        Interaction::CatalogQuery,
                    )
                    .size(DEFAULT_FONT_SIZE)
                    .padding(10)
                    .width(Length::FillPortion(3))
                    .style(style::CatalogQueryInput(color_palette));

                    let catalog_query: Element<Interaction> = catalog_query.into();

                    let source_picklist = PickList::new(
                        &mut self.catalog_search_state.sources_state,
                        &self.catalog_search_state.sources,
                        Some(self.catalog_search_state.source),
                        Interaction::CatalogSourceSelected,
                    )
                    .text_size(14)
                    .width(Length::Fill)
                    .style(style::SecondaryPickList(color_palette));

                    let source_picklist: Element<Interaction> = source_picklist.into();
                    let source_picklist_container =
                        Container::new(source_picklist.map(Message::Interaction))
                            .center_y()
                            .style(style::NormalForegroundContainer(color_palette))
                            .height(Length::Fill)
                            .width(Length::FillPortion(1));

                    let category_picklist = PickList::new(
                        &mut self.catalog_search_state.categories_state,
                        &self.catalog_search_state.categories,
                        Some(self.catalog_search_state.category.clone()),
                        Interaction::CatalogCategorySelected,
                    )
                    .text_size(14)
                    .width(Length::Fill)
                    .style(style::SecondaryPickList(color_palette));

                    let category_picklist: Element<Interaction> = category_picklist.into();
                    let category_picklist_container =
                        Container::new(category_picklist.map(Message::Interaction))
                            .center_y()
                            .style(style::NormalForegroundContainer(color_palette))
                            .height(Length::Fill)
                            .width(Length::FillPortion(1));

                    let result_size_picklist = PickList::new(
                        &mut self.catalog_search_state.result_sizes_state,
                        &self.catalog_search_state.result_sizes,
                        Some(self.catalog_search_state.result_size),
                        Interaction::CatalogResultSizeSelected,
                    )
                    .text_size(14)
                    .width(Length::Fill)
                    .style(style::SecondaryPickList(color_palette));

                    let result_size_picklist: Element<Interaction> = result_size_picklist.into();
                    let result_size_picklist_container =
                        Container::new(result_size_picklist.map(Message::Interaction))
                            .center_y()
                            .style(style::NormalForegroundContainer(color_palette))
                            .height(Length::Fill)
                            .width(Length::FillPortion(1));

                    let catalog_query_row = Row::new()
                        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                        .push(catalog_query.map(Message::Interaction))
                        .push(source_picklist_container)
                        .push(category_picklist_container)
                        .push(result_size_picklist_container)
                        .push(Space::new(
                            Length::Units(DEFAULT_PADDING + 5),
                            Length::Units(0),
                        ))
                        .spacing(1);

                    let catalog_query_container = Container::new(catalog_query_row)
                        .width(Length::Fill)
                        .height(Length::Units(34))
                        .center_y();

                    let catalog_row_titles = element::catalog::titles_row_header(
                        color_palette,
                        catalog,
                        &mut self.catalog_header_state.state,
                        &mut self.catalog_header_state.columns,
                        self.catalog_header_state.previous_column_key,
                        self.catalog_header_state.previous_sort_direction,
                    );

                    let mut catalog_scrollable =
                        Scrollable::new(&mut self.catalog_search_state.scrollable_state)
                            .spacing(1)
                            .height(Length::FillPortion(1))
                            .style(style::Scrollable(color_palette));

                    let install_addons = self.install_addons.entry(flavor).or_default();

                    for (idx, addon) in self
                        .catalog_search_state
                        .catalog_rows
                        .iter_mut()
                        .enumerate()
                    {
                        let is_odd = if self.config.alternating_row_colors {
                            Some(idx % 2 != 0)
                        } else {
                            None
                        };

                        // TODO (tarkah): We should make this prettier with new sources coming in.
                        let installed_for_flavor = addons.iter().any(|a| {
                            a.curse_id() == Some(addon.addon.id)
                                || a.tukui_id() == Some(&addon.addon.id.to_string())
                                || a.wowi_id() == Some(&addon.addon.id.to_string())
                        });

                        let install_addon = install_addons.iter().find(|a| {
                            addon.addon.id.to_string() == a.id
                                && matches!(a.kind, InstallKind::Catalog { .. })
                        });

                        let catalog_data_cell = element::catalog::data_row_container(
                            color_palette,
                            &self.config,
                            addon,
                            &catalog_column_config,
                            installed_for_flavor,
                            install_addon,
                            is_odd,
                        );

                        catalog_scrollable = catalog_scrollable.push(catalog_data_cell);
                    }

                    // Bottom space below the scrollable.
                    let bottom_space =
                        Space::new(Length::FillPortion(1), Length::Units(DEFAULT_PADDING));

                    content = content
                        .push(catalog_query_container)
                        .push(Space::new(Length::Fill, Length::Units(5)))
                        .push(catalog_row_titles)
                        .push(catalog_scrollable)
                        .push(bottom_space)
                }
            }
            Mode::Settings => {
                let settings_container = element::settings::data_container(
                    color_palette,
                    &mut self.settings_scrollable_state,
                    &mut self.directory_btn_state,
                    &self.config,
                    &mut self.theme_state,
                    &mut self.scale_state,
                    &mut self.backup_state,
                    &mut self.column_settings,
                    &column_config,
                    &mut self.catalog_column_settings,
                    &catalog_column_config,
                    &mut self.open_config_dir_btn_state,
                    &mut self.self_update_channel_state,
                    &mut self.default_addon_release_channel_picklist_state,
                    &mut self.reset_columns_btn_state,
                );

                content = content.push(settings_container)
            }
            Mode::About => {
                let about_container = element::about::data_container(
                    color_palette,
                    &release_copy,
                    &mut self.about_scrollable_state,
                    &mut self.website_btn_state,
                    &mut self.patreon_btn_state,
                );

                content = content.push(about_container)
            }
        }

        let container: Option<Container<Message>> = match self.mode {
            Mode::MyAddons(flavor) => {
                let state = self
                    .state
                    .get(&Mode::MyAddons(flavor))
                    .cloned()
                    .unwrap_or_default();
                match state {
                    State::Start => Some(element::status::data_container(
                        color_palette,
                        "Welcome to Ajour!",
                        "Please select your World of Warcraft directory",
                        Some(&mut self.onboarding_directory_btn_state),
                    )),
                    State::Loading => Some(element::status::data_container(
                        color_palette,
                        "Loading..",
                        &format!("Currently parsing {} addons.", flavor.to_string()),
                        None,
                    )),
                    State::Ready => {
                        if !has_addons {
                            Some(element::status::data_container(
                                color_palette,
                                "Woops!",
                                &format!(
                                    "You have no {} addons.",
                                    flavor.to_string().to_lowercase()
                                ),
                                None,
                            ))
                        } else {
                            None
                        }
                    }
                }
            }
            Mode::Settings => None,
            Mode::About => None,
            Mode::Install => None,
            Mode::MyWeakAuras(flavor) => {
                let state = self
                    .state
                    .get(&Mode::MyWeakAuras(flavor))
                    .cloned()
                    .unwrap_or_default();

                match state {
                    State::Start => Some(element::status::data_container(
                        color_palette,
                        "Manage your WeakAuras with Ajour!",
                        "Please select an Account to manage",
                        None,
                    )),
                    State::Loading => Some(element::status::data_container(
                        color_palette,
                        "Loading..",
                        &format!("Currently parsing {} WeakAuras.", flavor.to_string()),
                        None,
                    )),
                    State::Ready => {
                        if !has_auras {
                            Some(element::status::data_container(
                                color_palette,
                                "Woops!",
                                &format!(
                                    "You have no known {} WeakAuras.",
                                    flavor.to_string().to_lowercase()
                                ),
                                None,
                            ))
                        } else {
                            None
                        }
                    }
                }
            }
            Mode::Catalog => {
                let state = self.state.get(&Mode::Catalog).cloned().unwrap_or_default();
                match state {
                    State::Start => None,
                    State::Loading => Some(element::status::data_container(
                        color_palette,
                        "Loading..",
                        "Currently loading catalog.",
                        None,
                    )),
                    State::Ready => None,
                }
            }
        };

        if let Some(c) = container {
            content = content.push(c);
        };

        // Finally wraps everything in a container.
        Container::new(content)
            .width(Length::Fill)
            .height(Length::Fill)
            .style(style::NormalBackgroundContainer(color_palette))
            .into()
    }
}

/// Starts the GUI.
/// This function does not return.
pub fn run(opts: Opts) {
    let config: Config = Config::load_or_default().expect("loading config on application startup");

    log::debug!("config loaded:\n{:#?}", &config);

    let mut settings = Settings::default();
    settings.window.size = config.window_size.unwrap_or((900, 620));

    #[cfg(not(target_os = "linux"))]
    // TODO (casperstorm): Due to an upstream bug, min_size causes the window to become unresizable
    // on Linux.
    // @see: https://github.com/casperstorm/ajour/issues/427
    {
        settings.window.min_size = Some((600, 300));
    }

    #[cfg(feature = "wgpu")]
    {
        let antialiasing = opts.antialiasing.unwrap_or(true);
        log::debug!("antialiasing: {}", antialiasing);
        settings.antialiasing = antialiasing;
    }

    #[cfg(feature = "opengl")]
    {
        let antialiasing = opts.antialiasing.unwrap_or(false);
        log::debug!("antialiasing: {}", antialiasing);
        settings.antialiasing = antialiasing;
    }

    // Sets the Window icon.
    let image = image::load_from_memory_with_format(WINDOW_ICON, ImageFormat::Ico)
        .expect("loading icon")
        .to_rgba();
    let (width, height) = image.dimensions();
    let icon = iced::window::Icon::from_rgba(image.into_raw(), width, height);
    settings.window.icon = Some(icon.unwrap());

    settings.flags = config;

    // Runs the GUI.
    Ajour::run(settings).expect("running Ajour gui");
}

pub struct InstallFromSCMState {
    pub query: Option<String>,
    pub query_state: text_input::State,
    pub install_button_state: button::State,
}

impl Default for InstallFromSCMState {
    fn default() -> Self {
        InstallFromSCMState {
            query: None,
            query_state: Default::default(),
            install_button_state: Default::default(),
        }
    }
}

#[derive(Debug, Clone)]
pub enum ExpandType {
    Details(Addon),
    None,
}

#[derive(Debug, Clone, Copy)]
pub enum DirectoryType {
    Wow,
    Backup,
}

#[derive(Debug, Clone, Copy, PartialEq, Hash, Eq)]
pub enum ColumnKey {
    Title,
    LocalVersion,
    RemoteVersion,
    Status,
    Channel,
    Author,
    GameVersion,
    DateReleased,
    Source,
}

impl ColumnKey {
    fn title(self) -> String {
        use ColumnKey::*;

        let title = match self {
            Title => "Addon",
            LocalVersion => "Local",
            RemoteVersion => "Remote",
            Status => "Status",
            Channel => "Channel",
            Author => "Author",
            GameVersion => "Game Version",
            DateReleased => "Latest Release",
            Source => "Source",
        };

        title.to_string()
    }

    fn as_string(self) -> String {
        use ColumnKey::*;

        let s = match self {
            Title => "title",
            LocalVersion => "local",
            RemoteVersion => "remote",
            Status => "status",
            Channel => "channel",
            Author => "author",
            GameVersion => "game_version",
            DateReleased => "date_released",
            Source => "source",
        };

        s.to_string()
    }
}

impl From<&str> for ColumnKey {
    fn from(s: &str) -> Self {
        match s {
            "title" => ColumnKey::Title,
            "local" => ColumnKey::LocalVersion,
            "remote" => ColumnKey::RemoteVersion,
            "status" => ColumnKey::Status,
            "channel" => ColumnKey::Channel,
            "author" => ColumnKey::Author,
            "game_version" => ColumnKey::GameVersion,
            "date_released" => ColumnKey::DateReleased,
            "source" => ColumnKey::Source,
            _ => panic!(format!("Unknown ColumnKey for {}", s)),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum SortDirection {
    Asc,
    Desc,
}

impl SortDirection {
    fn toggle(self) -> SortDirection {
        match self {
            SortDirection::Asc => SortDirection::Desc,
            SortDirection::Desc => SortDirection::Asc,
        }
    }
}

pub struct HeaderState {
    state: header::State,
    previous_column_key: Option<ColumnKey>,
    previous_sort_direction: Option<SortDirection>,
    columns: Vec<ColumnState>,
}

impl HeaderState {
    fn column_config(&self) -> Vec<(ColumnKey, Length, bool)> {
        self.columns
            .iter()
            .map(|c| (c.key, c.width, c.hidden))
            .collect()
    }
}

impl Default for HeaderState {
    fn default() -> Self {
        Self {
            state: Default::default(),
            previous_column_key: None,
            previous_sort_direction: None,
            columns: vec![
                ColumnState {
                    key: ColumnKey::Title,
                    btn_state: Default::default(),
                    width: Length::Fill,
                    hidden: false,
                    order: 0,
                },
                ColumnState {
                    key: ColumnKey::LocalVersion,
                    btn_state: Default::default(),
                    width: Length::Units(150),
                    hidden: false,
                    order: 1,
                },
                ColumnState {
                    key: ColumnKey::RemoteVersion,
                    btn_state: Default::default(),
                    width: Length::Units(150),
                    hidden: false,
                    order: 2,
                },
                ColumnState {
                    key: ColumnKey::Status,
                    btn_state: Default::default(),
                    width: Length::Units(85),
                    hidden: false,
                    order: 3,
                },
                ColumnState {
                    key: ColumnKey::Channel,
                    btn_state: Default::default(),
                    width: Length::Units(85),
                    hidden: true,
                    order: 4,
                },
                ColumnState {
                    key: ColumnKey::Author,
                    btn_state: Default::default(),
                    width: Length::Units(85),
                    hidden: true,
                    order: 5,
                },
                ColumnState {
                    key: ColumnKey::GameVersion,
                    btn_state: Default::default(),
                    width: Length::Units(110),
                    hidden: true,
                    order: 6,
                },
                ColumnState {
                    key: ColumnKey::DateReleased,
                    btn_state: Default::default(),
                    width: Length::Units(110),
                    hidden: true,
                    order: 7,
                },
                ColumnState {
                    key: ColumnKey::Source,
                    btn_state: Default::default(),
                    width: Length::Units(110),
                    hidden: true,
                    order: 8,
                },
            ],
        }
    }
}

pub struct ColumnState {
    key: ColumnKey,
    btn_state: button::State,
    width: Length,
    hidden: bool,
    order: usize,
}

impl From<&ColumnState> for ColumnConfigV2 {
    fn from(column: &ColumnState) -> Self {
        // Only `ColumnKey::Title` should be saved as Length::Fill -> width: None
        let width = if let Length::Units(width) = column.width {
            Some(width)
        } else {
            None
        };

        ColumnConfigV2 {
            key: column.key.as_string(),
            width,
            hidden: column.hidden,
        }
    }
}

pub struct ColumnSettings {
    pub scrollable_state: scrollable::State,
    pub columns: Vec<ColumnSettingState>,
}

impl Default for ColumnSettings {
    fn default() -> Self {
        ColumnSettings {
            scrollable_state: Default::default(),
            columns: vec![
                ColumnSettingState {
                    key: ColumnKey::Title,
                    order: 0,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                ColumnSettingState {
                    key: ColumnKey::LocalVersion,
                    order: 1,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                ColumnSettingState {
                    key: ColumnKey::RemoteVersion,
                    order: 2,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                ColumnSettingState {
                    key: ColumnKey::Status,
                    order: 3,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                ColumnSettingState {
                    key: ColumnKey::Channel,
                    order: 4,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                ColumnSettingState {
                    key: ColumnKey::Author,
                    order: 5,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                ColumnSettingState {
                    key: ColumnKey::GameVersion,
                    order: 6,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                ColumnSettingState {
                    key: ColumnKey::DateReleased,
                    order: 7,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                ColumnSettingState {
                    key: ColumnKey::Source,
                    order: 8,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
            ],
        }
    }
}

pub struct ColumnSettingState {
    pub key: ColumnKey,
    pub order: usize,
    pub up_btn_state: button::State,
    pub down_btn_state: button::State,
}

#[derive(Debug, Clone, Copy, PartialEq, Hash, Eq)]
pub enum CatalogColumnKey {
    Title,
    Description,
    Source,
    NumDownloads,
    GameVersion,
    DateReleased,
    Install,
}

impl CatalogColumnKey {
    fn title(self) -> String {
        use CatalogColumnKey::*;

        let title = match self {
            Title => "Addon",
            Description => "Description",
            Source => "Source",
            NumDownloads => "# Downloads",
            GameVersion => "Game Version",
            DateReleased => "Latest Release",
            CatalogColumnKey::Install => "Status",
        };

        title.to_string()
    }

    fn as_string(self) -> String {
        use CatalogColumnKey::*;

        let s = match self {
            Title => "addon",
            Description => "description",
            Source => "source",
            NumDownloads => "num_downloads",
            GameVersion => "game_version",
            DateReleased => "date_released",
            CatalogColumnKey::Install => "install",
        };

        s.to_string()
    }
}

impl From<&str> for CatalogColumnKey {
    fn from(s: &str) -> Self {
        match s {
            "addon" => CatalogColumnKey::Title,
            "description" => CatalogColumnKey::Description,
            "source" => CatalogColumnKey::Source,
            "num_downloads" => CatalogColumnKey::NumDownloads,
            "install" => CatalogColumnKey::Install,
            "game_version" => CatalogColumnKey::GameVersion,
            "date_released" => CatalogColumnKey::DateReleased,
            _ => panic!(format!("Unknown CatalogColumnKey for {}", s)),
        }
    }
}

pub struct CatalogHeaderState {
    state: header::State,
    previous_column_key: Option<CatalogColumnKey>,
    previous_sort_direction: Option<SortDirection>,
    columns: Vec<CatalogColumnState>,
}

impl CatalogHeaderState {
    fn column_config(&self) -> Vec<(CatalogColumnKey, Length, bool)> {
        self.columns
            .iter()
            .map(|c| (c.key, c.width, c.hidden))
            .collect()
    }
}

impl Default for CatalogHeaderState {
    fn default() -> Self {
        Self {
            state: Default::default(),
            previous_column_key: None,
            previous_sort_direction: None,
            columns: vec![
                CatalogColumnState {
                    key: CatalogColumnKey::Title,
                    btn_state: Default::default(),
                    width: Length::Fill,
                    hidden: false,
                    order: 0,
                },
                CatalogColumnState {
                    key: CatalogColumnKey::Description,
                    btn_state: Default::default(),
                    width: Length::Units(150),
                    hidden: false,
                    order: 1,
                },
                CatalogColumnState {
                    key: CatalogColumnKey::Source,
                    btn_state: Default::default(),
                    width: Length::Units(110),
                    hidden: true,
                    order: 2,
                },
                CatalogColumnState {
                    key: CatalogColumnKey::NumDownloads,
                    btn_state: Default::default(),
                    width: Length::Units(105),
                    hidden: true,
                    order: 3,
                },
                CatalogColumnState {
                    key: CatalogColumnKey::GameVersion,
                    btn_state: Default::default(),
                    width: Length::Units(105),
                    hidden: true,
                    order: 4,
                },
                CatalogColumnState {
                    key: CatalogColumnKey::DateReleased,
                    btn_state: Default::default(),
                    width: Length::Units(105),
                    hidden: false,
                    order: 5,
                },
                CatalogColumnState {
                    key: CatalogColumnKey::Install,
                    btn_state: Default::default(),
                    width: Length::Units(85),
                    hidden: false,
                    order: 6,
                },
            ],
        }
    }
}

pub struct CatalogColumnState {
    key: CatalogColumnKey,
    btn_state: button::State,
    width: Length,
    hidden: bool,
    order: usize,
}

impl From<&CatalogColumnState> for ColumnConfigV2 {
    fn from(column: &CatalogColumnState) -> Self {
        // Only `CatalogColumnKey::Title` should be saved as Length::Fill -> width: None
        let width = if let Length::Units(width) = column.width {
            Some(width)
        } else {
            None
        };

        ColumnConfigV2 {
            key: column.key.as_string(),
            width,
            hidden: column.hidden,
        }
    }
}

pub struct CatalogColumnSettings {
    pub scrollable_state: scrollable::State,
    pub columns: Vec<CatalogColumnSettingState>,
}

impl Default for CatalogColumnSettings {
    fn default() -> Self {
        CatalogColumnSettings {
            scrollable_state: Default::default(),
            columns: vec![
                CatalogColumnSettingState {
                    key: CatalogColumnKey::Title,
                    order: 0,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                CatalogColumnSettingState {
                    key: CatalogColumnKey::Description,
                    order: 1,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                CatalogColumnSettingState {
                    key: CatalogColumnKey::Source,
                    order: 2,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                CatalogColumnSettingState {
                    key: CatalogColumnKey::NumDownloads,
                    order: 3,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                CatalogColumnSettingState {
                    key: CatalogColumnKey::GameVersion,
                    order: 4,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                CatalogColumnSettingState {
                    key: CatalogColumnKey::DateReleased,
                    order: 5,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
                CatalogColumnSettingState {
                    key: CatalogColumnKey::Install,
                    order: 6,
                    up_btn_state: Default::default(),
                    down_btn_state: Default::default(),
                },
            ],
        }
    }
}

pub struct CatalogColumnSettingState {
    pub key: CatalogColumnKey,
    pub order: usize,
    pub up_btn_state: button::State,
    pub down_btn_state: button::State,
}

pub struct CatalogSearchState {
    pub catalog_rows: Vec<CatalogRow>,
    pub scrollable_state: scrollable::State,
    pub query: Option<String>,
    pub query_state: text_input::State,
    pub result_size: CatalogResultSize,
    pub result_sizes: Vec<CatalogResultSize>,
    pub result_sizes_state: pick_list::State<CatalogResultSize>,
    pub category: CatalogCategory,
    pub categories: Vec<CatalogCategory>,
    pub categories_state: pick_list::State<CatalogCategory>,
    pub source: CatalogSource,
    pub sources: Vec<CatalogSource>,
    pub sources_state: pick_list::State<CatalogSource>,
}

impl Default for CatalogSearchState {
    fn default() -> Self {
        CatalogSearchState {
            catalog_rows: Default::default(),
            scrollable_state: Default::default(),
            query: None,
            query_state: Default::default(),
            result_size: Default::default(),
            result_sizes: CatalogResultSize::all(),
            result_sizes_state: Default::default(),
            category: Default::default(),
            categories: Default::default(),
            categories_state: Default::default(),
            source: CatalogSource::Choice(catalog::Source::Curse),
            sources: CatalogSource::all(),
            sources_state: Default::default(),
        }
    }
}

pub struct CatalogRow {
    install_button_state: button::State,
    addon: CatalogAddon,
}

impl From<CatalogAddon> for CatalogRow {
    fn from(addon: CatalogAddon) -> Self {
        Self {
            install_button_state: Default::default(),
            addon,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct InstallAddon {
    id: String,
    kind: InstallKind,
    status: InstallStatus,
    addon: Option<Addon>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum InstallStatus {
    Downloading,
    Unpacking,
    Retry,
    Unavilable,
    Error(String),
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum InstallKind {
    Catalog { source: catalog::Source },
    Source,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum CatalogCategory {
    All,
    Choice(String),
}

impl std::fmt::Display for CatalogCategory {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CatalogCategory::All => write!(f, "All Categories"),
            CatalogCategory::Choice(name) => write!(f, "{}", name),
        }
    }
}

impl Default for CatalogCategory {
    fn default() -> Self {
        CatalogCategory::All
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum CatalogResultSize {
    _25,
    _50,
    _100,
    _500,
}

impl Default for CatalogResultSize {
    fn default() -> Self {
        CatalogResultSize::_25
    }
}

impl CatalogResultSize {
    pub fn all() -> Vec<CatalogResultSize> {
        vec![
            CatalogResultSize::_25,
            CatalogResultSize::_50,
            CatalogResultSize::_100,
            CatalogResultSize::_500,
        ]
    }

    pub fn as_usize(self) -> usize {
        match self {
            CatalogResultSize::_25 => 25,
            CatalogResultSize::_50 => 50,
            CatalogResultSize::_100 => 100,
            CatalogResultSize::_500 => 500,
        }
    }
}

impl std::fmt::Display for CatalogResultSize {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Results: {}", self.as_usize())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum CatalogSource {
    Choice(catalog::Source),
}

impl CatalogSource {
    pub fn all() -> Vec<CatalogSource> {
        vec![
            CatalogSource::Choice(catalog::Source::Curse),
            CatalogSource::Choice(catalog::Source::Tukui),
            CatalogSource::Choice(catalog::Source::WowI),
        ]
    }
}

impl std::fmt::Display for CatalogSource {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            CatalogSource::Choice(source) => match source {
                catalog::Source::Curse => "Curse",
                catalog::Source::Tukui => "Tukui",
                catalog::Source::WowI => "WowInterface",
            },
        };
        write!(f, "{}", s)
    }
}

pub struct ThemeState {
    themes: Vec<(String, Theme)>,
    current_theme_name: String,
    pick_list_state: pick_list::State<String>,
}

impl Default for ThemeState {
    fn default() -> Self {
        let mut themes = vec![];
        themes.push(("Alliance".to_string(), Theme::alliance()));
        themes.push(("Ayu".to_string(), Theme::ayu()));
        themes.push(("Dark".to_string(), Theme::dark()));
        themes.push(("Dracula".to_string(), Theme::dracula()));
        themes.push(("Ferra".to_string(), Theme::ferra()));
        themes.push(("Forest Night".to_string(), Theme::forest_night()));
        themes.push(("Gruvbox".to_string(), Theme::gruvbox()));
        themes.push(("Horde".to_string(), Theme::horde()));
        themes.push(("Light".to_string(), Theme::light()));
        themes.push(("Nord".to_string(), Theme::nord()));
        themes.push(("One Dark".to_string(), Theme::one_dark()));
        themes.push(("Outrun".to_string(), Theme::outrun()));
        themes.push(("Solarized Dark".to_string(), Theme::solarized_dark()));
        themes.push(("Solarized Light".to_string(), Theme::solarized_light()));
        themes.push(("Sort".to_string(), Theme::sort()));

        ThemeState {
            themes,
            current_theme_name: "Dark".to_string(),
            pick_list_state: Default::default(),
        }
    }
}

pub struct ScaleState {
    scale: f64,
    up_btn_state: button::State,
    down_btn_state: button::State,
}

impl Default for ScaleState {
    fn default() -> Self {
        ScaleState {
            scale: 1.0,
            up_btn_state: Default::default(),
            down_btn_state: Default::default(),
        }
    }
}

#[derive(Debug, Clone)]
pub enum BackupFolderKind {
    AddOns,
    WTF,
}

#[derive(Default)]
pub struct BackupState {
    backing_up: bool,
    last_backup: Option<NaiveDateTime>,
    directory_btn_state: button::State,
    backup_now_btn_state: button::State,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DownloadReason {
    Update,
    Install,
}

#[derive(Debug, Clone, Copy)]
pub enum SelfUpdateStatus {
    InProgress,
    Failed,
}

impl std::fmt::Display for SelfUpdateStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            SelfUpdateStatus::InProgress => "Updating",
            SelfUpdateStatus::Failed => "Failed",
        };
        write!(f, "{}", s)
    }
}

#[derive(Default, Debug)]
pub struct SelfUpdateState {
    latest_release: Option<utility::Release>,
    status: Option<SelfUpdateStatus>,
    btn_state: button::State,
}

#[derive(Debug)]
pub struct SelfUpdateChannelState {
    picklist: pick_list::State<SelfUpdateChannel>,
    options: [SelfUpdateChannel; 2],
}

#[derive(Debug, Default)]
pub struct WeakAurasState {
    chosen_account: Option<String>,
    account_picklist: pick_list::State<String>,
    accounts: Vec<String>,
    auras: Vec<Aura>,
    is_updating: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Hash, Eq)]
pub enum AuraColumnKey {
    Title,
    LocalVersion,
    RemoteVersion,
    Author,
    Status,
}

impl AuraColumnKey {
    fn title(self) -> String {
        use AuraColumnKey::*;

        let title = match self {
            Title => "Aura",
            LocalVersion => "Local",
            RemoteVersion => "Remote",
            Author => "Author",
            Status => "Status",
        };

        title.to_string()
    }

    fn as_string(self) -> String {
        use AuraColumnKey::*;

        let s = match self {
            Title => "title",
            LocalVersion => "local",
            RemoteVersion => "remote",
            Author => "author",
            Status => "status",
        };

        s.to_string()
    }
}

impl From<&str> for AuraColumnKey {
    fn from(s: &str) -> Self {
        match s {
            "title" => AuraColumnKey::Title,
            "local" => AuraColumnKey::LocalVersion,
            "remote" => AuraColumnKey::RemoteVersion,
            "author" => AuraColumnKey::Author,
            "status" => AuraColumnKey::Status,
            _ => panic!(format!("Unknown AuraColumnKey for {}", s)),
        }
    }
}

pub struct AuraHeaderState {
    state: header::State,
    previous_column_key: Option<AuraColumnKey>,
    previous_sort_direction: Option<SortDirection>,
    columns: Vec<AuraColumnState>,
}

impl AuraHeaderState {
    fn column_config(&self) -> Vec<(AuraColumnKey, Length, bool)> {
        self.columns
            .iter()
            .map(|c| (c.key, c.width, c.hidden))
            .collect()
    }
}

impl Default for AuraHeaderState {
    fn default() -> Self {
        Self {
            state: Default::default(),
            previous_column_key: None,
            previous_sort_direction: None,
            columns: vec![
                AuraColumnState {
                    key: AuraColumnKey::Title,
                    btn_state: Default::default(),
                    width: Length::Fill,
                    hidden: false,
                },
                AuraColumnState {
                    key: AuraColumnKey::LocalVersion,
                    btn_state: Default::default(),
                    width: Length::Units(120),
                    hidden: false,
                },
                AuraColumnState {
                    key: AuraColumnKey::RemoteVersion,
                    btn_state: Default::default(),
                    width: Length::Units(120),
                    hidden: false,
                },
                AuraColumnState {
                    key: AuraColumnKey::Author,
                    btn_state: Default::default(),
                    width: Length::Units(85),
                    hidden: false,
                },
                AuraColumnState {
                    key: AuraColumnKey::Status,
                    btn_state: Default::default(),
                    width: Length::Units(110),
                    hidden: false,
                },
            ],
        }
    }
}

pub struct AuraColumnState {
    key: AuraColumnKey,
    btn_state: button::State,
    width: Length,
    hidden: bool,
}

impl From<&AuraColumnState> for ColumnConfigV2 {
    fn from(column: &AuraColumnState) -> Self {
        // Only `AuraColumnState::Title` should be saved as Length::Fill -> width: None
        let width = if let Length::Units(width) = column.width {
            Some(width)
        } else {
            None
        };

        ColumnConfigV2 {
            key: column.key.as_string(),
            width,
            hidden: column.hidden,
        }
    }
}

async fn load_caches() -> Result<(FingerprintCache, AddonCache)> {
    let fingerprint_cache = load_fingerprint_cache().await?;
    let addon_cache = load_addon_cache().await?;

    Ok((fingerprint_cache, addon_cache))
}

fn apply_config(ajour: &mut Ajour, config: Config) {
    // Set column widths from the config
    match &config.column_config {
        ColumnConfig::V1 {
            local_version_width,
            remote_version_width,
            status_width,
        } => {
            ajour
                .header_state
                .columns
                .get_mut(1)
                .as_mut()
                .unwrap()
                .width = Length::Units(*local_version_width);
            ajour
                .header_state
                .columns
                .get_mut(2)
                .as_mut()
                .unwrap()
                .width = Length::Units(*remote_version_width);
            ajour
                .header_state
                .columns
                .get_mut(3)
                .as_mut()
                .unwrap()
                .width = Length::Units(*status_width);
        }
        ColumnConfig::V2 { columns } => {
            ajour.header_state.columns.iter_mut().for_each(|a| {
                if let Some((idx, column)) = columns
                    .iter()
                    .enumerate()
                    .filter_map(|(idx, column)| {
                        if column.key == a.key.as_string() {
                            Some((idx, column))
                        } else {
                            None
                        }
                    })
                    .next()
                {
                    a.width = column.width.map_or(Length::Fill, Length::Units);
                    a.hidden = column.hidden;
                    a.order = idx;
                }
            });

            ajour.column_settings.columns.iter_mut().for_each(|a| {
                if let Some(idx) = columns
                    .iter()
                    .enumerate()
                    .filter_map(|(idx, column)| {
                        if column.key == a.key.as_string() {
                            Some(idx)
                        } else {
                            None
                        }
                    })
                    .next()
                {
                    a.order = idx;
                }
            });

            // My Addons
            ajour.header_state.columns.sort_by_key(|c| c.order);
            ajour.column_settings.columns.sort_by_key(|c| c.order);
        }
        ColumnConfig::V3 {
            my_addons_columns,
            catalog_columns,
            aura_columns,
        } => {
            ajour.header_state.columns.iter_mut().for_each(|a| {
                if let Some((idx, column)) = my_addons_columns
                    .iter()
                    .enumerate()
                    .filter_map(|(idx, column)| {
                        if column.key == a.key.as_string() {
                            Some((idx, column))
                        } else {
                            None
                        }
                    })
                    .next()
                {
                    // Always force "Title" column as Length::Fill
                    //
                    // Shouldn't be an issue here, as it was for catalog column fix
                    // below, but will cover things in case anyone accidently manually
                    // modifies their config and sets a fixed width on this column.
                    a.width = if a.key == ColumnKey::Title {
                        Length::Fill
                    } else {
                        column.width.map_or(Length::Fill, Length::Units)
                    };

                    a.hidden = column.hidden;
                    a.order = idx;
                }
            });

            ajour.column_settings.columns.iter_mut().for_each(|a| {
                if let Some(idx) = my_addons_columns
                    .iter()
                    .enumerate()
                    .filter_map(|(idx, column)| {
                        if column.key == a.key.as_string() {
                            Some(idx)
                        } else {
                            None
                        }
                    })
                    .next()
                {
                    a.order = idx;
                }
            });

            ajour
                .catalog_column_settings
                .columns
                .iter_mut()
                .for_each(|a| {
                    if let Some(idx) = catalog_columns
                        .iter()
                        .enumerate()
                        .filter_map(|(idx, column)| {
                            if column.key == a.key.as_string() {
                                Some(idx)
                            } else {
                                None
                            }
                        })
                        .next()
                    {
                        a.order = idx;
                    }
                });

            ajour.catalog_header_state.columns.iter_mut().for_each(|a| {
                if let Some((idx, column)) = catalog_columns
                    .iter()
                    .enumerate()
                    .filter_map(|(idx, column)| {
                        if column.key == a.key.as_string() {
                            Some((idx, column))
                        } else {
                            None
                        }
                    })
                    .next()
                {
                    // Always force "Title" column as Length::Fill
                    //
                    // An older version of ajour used a different column as the fill
                    // column and some users have migration issues when updating to
                    // a newer version, causing NO columns to be set as Fill and
                    // making resizing columns work incorrectly
                    a.width = if a.key == CatalogColumnKey::Title {
                        Length::Fill
                    } else {
                        column.width.map_or(Length::Fill, Length::Units)
                    };

                    a.hidden = column.hidden;
                    a.order = idx;
                }
            });

            ajour.aura_header_state.columns.iter_mut().for_each(|a| {
                if let Some((_idx, column)) = aura_columns
                    .iter()
                    .enumerate()
                    .filter_map(|(idx, column)| {
                        if column.key == a.key.as_string() {
                            Some((idx, column))
                        } else {
                            None
                        }
                    })
                    .next()
                {
                    // Always force "Title" column as Length::Fill
                    //
                    // An older version of ajour used a different column as the fill
                    // column and some users have migration issues when updating to
                    // a newer version, causing NO columns to be set as Fill and
                    // making resizing columns work incorrectly
                    a.width = if a.key == AuraColumnKey::Title {
                        Length::Fill
                    } else {
                        column.width.map_or(Length::Fill, Length::Units)
                    };
                }
            });

            // My Addons
            ajour.header_state.columns.sort_by_key(|c| c.order);
            ajour.column_settings.columns.sort_by_key(|c| c.order);

            // Catalog
            ajour.catalog_header_state.columns.sort_by_key(|c| c.order);
            ajour
                .catalog_column_settings
                .columns
                .sort_by_key(|c| c.order);

            // No sorting on Aura columns currently
        }
    }

    // Use theme from config. Set to "Dark" if not defined.
    ajour.theme_state.current_theme_name = config.theme.as_deref().unwrap_or("Dark").to_string();

    // Use scale from config. Set to 1.0 if not defined.
    ajour.scale_state.scale = config.scale.unwrap_or(1.0);

    // Set the inital mode flavor
    ajour.mode = Mode::MyAddons(config.wow.flavor);

    ajour.config = config;
}
