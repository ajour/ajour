mod element;
mod style;
mod update;

use crate::cli::Opts;
use ajour_core::{
    addon::{Addon, AddonFolder, AddonVersionKey, ReleaseChannel},
    catalog::get_catalog,
    catalog::{self, Catalog, CatalogAddon},
    config::{load_config, ColumnConfigV2, Config, Flavor},
    error::ClientError,
    fs::PersistentData,
    parse::FingerprintCollection,
    theme::{load_user_themes, Theme},
    utility::{self, get_latest_release},
    Result,
};
use async_std::sync::{Arc, Mutex};
use chrono::NaiveDateTime;
use iced::{
    button, pick_list, scrollable, text_input, Application, Column, Command, Container, Element,
    Length, PickList, Row, Settings, Space, Subscription, TextInput,
};
use image::ImageFormat;
use isahc::{
    config::{Configurable, RedirectPolicy},
    HttpClient,
};
use std::collections::HashMap;
use std::path::PathBuf;
use widgets::header;

use element::{DEFAULT_FONT_SIZE, DEFAULT_PADDING};
static WINDOW_ICON: &[u8] = include_bytes!("../../resources/windows/ajour.ico");

#[derive(Debug)]
pub enum AjourState {
    Error(ClientError),
    Idle,
    Loading,
    Welcome,
}

#[derive(Debug, Copy, Clone, PartialEq)]
pub enum AjourMode {
    MyAddons,
    Catalog,
}

impl std::fmt::Display for AjourMode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                AjourMode::MyAddons => "My Addons",
                AjourMode::Catalog => "Catalog",
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
    OpenDirectory(DirectoryType),
    OpenLink(String),
    Refresh,
    Settings,
    Unignore(String),
    Update(String),
    UpdateAll,
    SortColumn(ColumnKey),
    SortCatalogColumn(CatalogColumnKey),
    FlavorSelected(Flavor),
    ResizeColumn(AjourMode, header::ResizeEvent),
    ScaleUp,
    ScaleDown,
    Backup,
    ToggleColumn(bool, ColumnKey),
    ToggleCatalogColumn(bool, CatalogColumnKey),
    MoveColumnLeft(ColumnKey),
    MoveColumnRight(ColumnKey),
    MoveCatalogColumnLeft(CatalogColumnKey),
    MoveCatalogColumnRight(CatalogColumnKey),
    ModeSelected(AjourMode),
    CatalogQuery(String),
    CatalogInstall(catalog::Source, Flavor, u32),
    CatalogCategorySelected(CatalogCategory),
    CatalogResultSizeSelected(CatalogResultSize),
    CatalogSourceSelected(CatalogSource),
    UpdateAjour,
}

#[derive(Debug)]
#[allow(clippy::large_enum_variant)]
pub enum Message {
    DownloadedAddon((DownloadReason, Flavor, String, Result<()>)),
    Error(ClientError),
    Interaction(Interaction),
    LatestRelease(Option<utility::Release>),
    None(()),
    Parse(Result<Config>),
    ParsedAddons((Flavor, Result<Vec<Addon>>)),
    UpdateFingerprint((DownloadReason, Flavor, String, Result<()>)),
    ThemeSelected(String),
    ReleaseChannelSelected(ReleaseChannel),
    ThemesLoaded(Vec<Theme>),
    UnpackedAddon((DownloadReason, Flavor, String, Result<Vec<AddonFolder>>)),
    UpdateWowDirectory(Option<PathBuf>),
    UpdateBackupDirectory(Option<PathBuf>),
    RuntimeEvent(iced_native::Event),
    LatestBackup(Option<NaiveDateTime>),
    BackupFinished(Result<NaiveDateTime>),
    CatalogDownloaded(Result<Catalog>),
    CatalogInstallAddonFetched((Flavor, u32, Result<Addon>)),
    FetchedChangelog((Addon, AddonVersionKey, Result<(String, String)>)),
    AjourUpdateDownloaded(Result<(String, PathBuf)>),
}

pub struct Ajour {
    addons: HashMap<Flavor, Vec<Addon>>,
    addons_scrollable_state: scrollable::State,
    config: Config,
    valid_flavors: Vec<Flavor>,
    directory_btn_state: button::State,
    expanded_type: ExpandType,
    is_showing_settings: bool,
    self_update_state: SelfUpdateState,
    refresh_btn_state: button::State,
    settings_btn_state: button::State,
    shared_client: Arc<HttpClient>,
    state: AjourState,
    mode: AjourMode,
    update_all_btn_state: button::State,
    header_state: HeaderState,
    theme_state: ThemeState,
    fingerprint_collection: Arc<Mutex<Option<FingerprintCollection>>>,
    retail_btn_state: button::State,
    retail_ptr_btn_state: button::State,
    retail_beta_btn_state: button::State,
    classic_btn_state: button::State,
    classic_ptr_btn_state: button::State,
    addon_mode_btn_state: button::State,
    catalog_mode_btn_state: button::State,
    scale_state: ScaleState,
    backup_state: BackupState,
    column_settings: ColumnSettings,
    catalog_column_settings: CatalogColumnSettings,
    onboarding_directory_btn_state: button::State,
    catalog: Option<Catalog>,
    catalog_install_statuses: Vec<(Flavor, u32, CatalogInstallStatus)>,
    catalog_search_state: CatalogSearchState,
    catalog_header_state: CatalogHeaderState,
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
            addons: HashMap::new(),
            addons_scrollable_state: Default::default(),
            config: Config::default(),
            valid_flavors: Vec::new(),
            directory_btn_state: Default::default(),
            expanded_type: ExpandType::None,
            is_showing_settings: false,
            self_update_state: Default::default(),
            refresh_btn_state: Default::default(),
            settings_btn_state: Default::default(),
            shared_client: Arc::new(
                HttpClient::builder()
                    .redirect_policy(RedirectPolicy::Follow)
                    .max_connections_per_host(6)
                    .build()
                    .unwrap(),
            ),
            state: AjourState::Loading,
            mode: AjourMode::MyAddons,
            update_all_btn_state: Default::default(),
            header_state: Default::default(),
            theme_state: Default::default(),
            fingerprint_collection: Arc::new(Mutex::new(None)),
            retail_btn_state: Default::default(),
            retail_ptr_btn_state: Default::default(),
            retail_beta_btn_state: Default::default(),
            classic_btn_state: Default::default(),
            classic_ptr_btn_state: Default::default(),
            addon_mode_btn_state: Default::default(),
            catalog_mode_btn_state: Default::default(),
            scale_state: Default::default(),
            backup_state: Default::default(),
            column_settings: Default::default(),
            catalog_column_settings: Default::default(),
            onboarding_directory_btn_state: Default::default(),
            catalog: None,
            catalog_install_statuses: vec![],
            catalog_search_state: Default::default(),
            catalog_header_state: Default::default(),
        }
    }
}

impl Application for Ajour {
    type Executor = iced::executor::Default;
    type Message = Message;
    type Flags = f64;

    fn new(scale: f64) -> (Self, Command<Message>) {
        let init_commands = vec![
            Command::perform(load_config(), Message::Parse),
            Command::perform(get_latest_release(), Message::LatestRelease),
            Command::perform(load_user_themes(), Message::ThemesLoaded),
            Command::perform(get_catalog(), Message::CatalogDownloaded),
        ];

        let mut ajour = Ajour::default();
        ajour.scale_state.scale = scale;

        (ajour, Command::batch(init_commands))
    }

    fn title(&self) -> String {
        String::from("Ajour")
    }

    fn scale_factor(&self) -> f64 {
        self.scale_state.scale
    }

    fn subscription(&self) -> Subscription<Self::Message> {
        iced_native::subscription::events().map(Message::RuntimeEvent)
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

        // Menu container at the top of the applications.
        // This has all global buttons, such as Settings, Update All, etc.
        let menu_container = element::menu_container(
            color_palette,
            &self.mode,
            &self.state,
            &self.config,
            &self.valid_flavors,
            &mut self.settings_btn_state,
            &mut self.addon_mode_btn_state,
            &mut self.catalog_mode_btn_state,
            &mut self.retail_btn_state,
            &mut self.retail_ptr_btn_state,
            &mut self.retail_beta_btn_state,
            &mut self.classic_btn_state,
            &mut self.classic_ptr_btn_state,
            &mut self.self_update_state,
        );

        let column_config = self.header_state.column_config();
        let catalog_column_config = self.catalog_header_state.column_config();

        // This column gathers all the other elements together.
        let mut content = Column::new().push(menu_container);

        // This ensure we only draw settings, when we need to.
        if self.is_showing_settings {
            // Settings container, containing all data releated to settings.
            let settings_container = element::settings_container(
                color_palette,
                &mut self.directory_btn_state,
                &self.config,
                &self.mode,
                &mut self.theme_state,
                &mut self.scale_state,
                &mut self.backup_state,
                &mut self.column_settings,
                &column_config,
                &mut self.catalog_column_settings,
                &catalog_column_config,
            );

            // Space below settings.
            let space = Space::new(Length::Fill, Length::Units(DEFAULT_PADDING));

            // Adds the settings container.
            content = content.push(settings_container).push(space);
        }

        // Spacer between menu and content.
        content = content.push(Space::new(Length::Units(0), Length::Units(DEFAULT_PADDING)));

        match self.mode {
            AjourMode::MyAddons => {
                // Get mutable addons for current flavor.
                let addons = self.addons.entry(flavor).or_default();

                // Check if we have any addons.
                let has_addons = !&addons.is_empty();

                // Menu for addons.
                let menu_addons_container = element::menu_addons_container(
                    color_palette,
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
                let addon_row_titles = element::addon_row_titles(
                    color_palette,
                    addons,
                    &mut self.header_state.state,
                    &mut self.header_state.columns,
                    self.header_state.previous_column_key,
                    self.header_state.previous_sort_direction,
                );

                // A scrollable list containing rows.
                // Each row holds data about a single addon.
                let mut addons_scrollable =
                    element::addon_scrollable(color_palette, &mut self.addons_scrollable_state);

                // Loops though the addons.
                for addon in addons {
                    // Checks if the current addon is expanded.
                    let is_addon_expanded = match &self.expanded_type {
                        ExpandType::Details(a) => a.primary_folder_id == addon.primary_folder_id,
                        ExpandType::Changelog(c) => match c {
                            Changelog::Request(a, _) => {
                                a.primary_folder_id == addon.primary_folder_id
                            }
                            Changelog::Loading(a, _) => {
                                a.primary_folder_id == addon.primary_folder_id
                            }
                            Changelog::Some(a, _, _) => {
                                a.primary_folder_id == addon.primary_folder_id
                            }
                        },
                        ExpandType::None => false,
                    };

                    // A container cell which has all data about the current addon.
                    // If the addon is expanded, then this is also included in this container.
                    let addon_data_cell = element::addon_data_cell(
                        color_palette,
                        addon,
                        is_addon_expanded,
                        &self.expanded_type,
                        &column_config,
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
            AjourMode::Catalog => {
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
                        .height(Length::Units(35))
                        .center_y();

                    let catalog_row_titles = element::catalog_row_titles(
                        color_palette,
                        catalog,
                        &mut self.catalog_header_state.state,
                        &mut self.catalog_header_state.columns,
                        self.catalog_header_state.previous_column_key,
                        self.catalog_header_state.previous_sort_direction,
                    );

                    let mut catalog_scrollable = element::addon_scrollable(
                        color_palette,
                        &mut self.catalog_search_state.scrollable_state,
                    );

                    for addon in self.catalog_search_state.catalog_rows.iter_mut() {
                        // TODO: We should make this prettier with new sources coming in.
                        let installed_for_flavor = addons.iter().any(|a| {
                            a.curse_id() == Some(addon.addon.id)
                                || a.tukui_id() == Some(&addon.addon.id.to_string())
                        });

                        let statuses = self
                            .catalog_install_statuses
                            .iter()
                            .filter(|(_, i, _)| addon.addon.id == *i)
                            .map(|(flavor, _, status)| (*flavor, *status))
                            .collect();

                        let catalog_data_cell = element::catalog_data_cell(
                            color_palette,
                            &self.config,
                            addon,
                            &catalog_column_config,
                            installed_for_flavor,
                            statuses,
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
        }

        // Status messages.
        let container: Option<Container<Message>> = match self.state {
            AjourState::Welcome => Some(element::status_container(
                color_palette,
                "Welcome to Ajour!",
                "Please select your World of Warcraft directory",
                Some(&mut self.onboarding_directory_btn_state),
            )),
            AjourState::Idle => match self.mode {
                AjourMode::MyAddons => {
                    if !has_addons {
                        Some(element::status_container(
                            color_palette,
                            "Woops!",
                            &format!("You have no {} addons.", flavor.to_string().to_lowercase()),
                            None,
                        ))
                    } else {
                        None
                    }
                }
                AjourMode::Catalog => None,
            },
            AjourState::Loading => match self.mode {
                AjourMode::MyAddons => Some(element::status_container(
                    color_palette,
                    "Loading..",
                    "Currently parsing addons.",
                    None,
                )),
                AjourMode::Catalog => Some(element::status_container(
                    color_palette,
                    "Loading..",
                    "Currently loading addon catalog.",
                    None,
                )),
            },
            _ => None,
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

    let mut settings = Settings::default();
    settings.window.size = config.window_size.unwrap_or((900, 620));

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

    settings.flags = config.scale.unwrap_or(1.0);

    // Runs the GUI.
    Ajour::run(settings).expect("running Ajour gui");
}

#[derive(Debug, Clone)]
pub struct ChangelogPayload {
    changelog: String,
    url: String,
}

#[derive(Debug, Clone)]
pub enum Changelog {
    Request(Addon, AddonVersionKey),
    Loading(Addon, AddonVersionKey),
    Some(Addon, ChangelogPayload, AddonVersionKey),
}

#[derive(Debug, Clone)]
pub enum ExpandType {
    Details(Addon),
    Changelog(Changelog),
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
                    width: Length::Units(85),
                    hidden: false,
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
            source: CatalogSource::All,
            sources: CatalogSource::all(),
            sources_state: Default::default(),
        }
    }
}

pub struct CatalogRow {
    website_state: button::State,
    install_button_state: button::State,
    addon: CatalogAddon,
}

impl From<CatalogAddon> for CatalogRow {
    fn from(addon: CatalogAddon) -> Self {
        Self {
            website_state: Default::default(),
            install_button_state: Default::default(),
            addon,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum CatalogInstallStatus {
    Downloading,
    Unpacking,
    Fingerprint,
    Completed,
    Retry,
    Unavilable,
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
    All,
    Choice(catalog::Source),
}

impl CatalogSource {
    pub fn all() -> Vec<CatalogSource> {
        vec![
            CatalogSource::All,
            CatalogSource::Choice(catalog::Source::Curse),
            // FIXME: Uncomment once Tukui catalog is enabled
            //CatalogSource::Choice(catalog::Source::Tukui),
        ]
    }
}

impl std::fmt::Display for CatalogSource {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            CatalogSource::All => "All Sources",
            CatalogSource::Choice(source) => match source {
                catalog::Source::Curse => "Curse",
                catalog::Source::Tukui => "Tukui",
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
        themes.push(("Dark".to_string(), Theme::dark()));
        themes.push(("Light".to_string(), Theme::light()));
        themes.push(("Alliance".to_string(), Theme::alliance()));
        themes.push(("Horde".to_string(), Theme::horde()));
        themes.push(("Ayu".to_string(), Theme::ayu()));
        themes.push(("Dracula".to_string(), Theme::dracula()));
        themes.push(("Forest Night".to_string(), Theme::forest_night()));
        themes.push(("Gruvbox".to_string(), Theme::gruvbox()));
        themes.push(("Nord".to_string(), Theme::nord()));
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
