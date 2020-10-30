mod element;
mod style;
mod update;

use crate::cli::Opts;
use crate::VERSION;
use ajour_core::{
    addon::{Addon, AddonState, ReleaseChannel},
    catalog::get_catalog,
    catalog::{self, Catalog, CatalogAddon},
    config::{load_config, ColumnConfigV2, Config, Flavor},
    error::ClientError,
    fs::PersistentData,
    parse::FingerprintCollection,
    theme::{load_user_themes, Theme},
    utility::needs_update,
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
use tr::tr;
use locale_config::Locale;
use i18n_embed::{DesktopLanguageRequester, gettext::{
    gettext_language_loader,
},unic_langid};  
use rust_embed::RustEmbed;

use element::{DEFAULT_FONT_SIZE, DEFAULT_PADDING};
static WINDOW_ICON: &[u8] = include_bytes!("../../resources/windows/ajour.ico");

#[derive(RustEmbed)]
// path to the compiled localization resources,
// as determined by i18n.toml settings
#[folder = "i18n/mo"]
struct Translations;


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
pub enum Interaction {
    Delete(String),
    Expand(String),
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
    MoveColumnLeft(ColumnKey),
    MoveColumnRight(ColumnKey),
    ModeSelected(AjourMode),
    CatalogQuery(String),
    CatalogInstall(catalog::Source, Flavor, u32),
    CatalogCategorySelected(CatalogCategory),
    CatalogResultSizeSelected(CatalogResultSize),
    CatalogFlavorSelected(CatalogFlavor),
    CatalogSourceSelected(CatalogSource),
}

#[derive(Debug)]
pub enum Message {
    DownloadedAddon((Flavor, String, Result<()>)),
    Error(ClientError),
    Interaction(Interaction),
    NeedsUpdate(Result<Option<String>>),
    None(()),
    Parse(Result<Config>),
    ParsedAddons((Flavor, Result<Vec<Addon>>)),
    UpdateFingerprint((Flavor, String, Result<()>)),
    LanguageSelected(String),
    ThemeSelected(String),
    ReleaseChannelSelected(ReleaseChannel),
    ThemesLoaded(Vec<Theme>),
    UnpackedAddon((Flavor, String, Result<()>)),
    UpdateWowDirectory(Option<PathBuf>),
    UpdateBackupDirectory(Option<PathBuf>),
    RuntimeEvent(iced_native::Event),
    LatestBackup(Option<NaiveDateTime>),
    BackupFinished(Result<NaiveDateTime>),
    CatalogDownloaded(Result<Catalog>),
    CatalogInstallAddonFetched(Result<(u32, Flavor, Addon)>),
}

pub struct Ajour {
    addons: HashMap<Flavor, Vec<Addon>>,
    addons_scrollable_state: scrollable::State,
    config: Config,
    directory_btn_state: button::State,
    expanded_addon: Option<Addon>,
    is_showing_settings: bool,
    needs_update: Option<String>,
    new_release_button_state: button::State,
    refresh_btn_state: button::State,
    settings_btn_state: button::State,
    shared_client: Arc<HttpClient>,
    state: AjourState,
    mode: AjourMode,
    update_all_btn_state: button::State,
    header_state: HeaderState,
    language_state: LanguageState,
    theme_state: ThemeState,
    fingerprint_collection: Arc<Mutex<Option<FingerprintCollection>>>,
    retail_btn_state: button::State,
    classic_btn_state: button::State,
    addon_mode_btn_state: button::State,
    catalog_mode_btn_state: button::State,
    scale_state: ScaleState,
    backup_state: BackupState,
    column_settings: ColumnSettings,
    onboarding_directory_btn_state: button::State,
    catalog: Option<Catalog>,
    catalog_search_state: CatalogSearchState,
    catalog_header_state: CatalogHeaderState,
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
            addons: HashMap::new(),
            addons_scrollable_state: Default::default(),
            config: Config::default(),
            directory_btn_state: Default::default(),
            expanded_addon: None,
            is_showing_settings: false,
            needs_update: None,
            new_release_button_state: Default::default(),
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
            language_state: Default::default(),
            theme_state: Default::default(),
            fingerprint_collection: Arc::new(Mutex::new(None)),
            retail_btn_state: Default::default(),
            classic_btn_state: Default::default(),
            addon_mode_btn_state: Default::default(),
            catalog_mode_btn_state: Default::default(),
            scale_state: Default::default(),
            backup_state: Default::default(),
            column_settings: Default::default(),
            onboarding_directory_btn_state: Default::default(),
            catalog: None,
            catalog_search_state: Default::default(),
            catalog_header_state: Default::default(),
        }
    }
}

impl Application for Ajour {
    type Executor = iced::executor::Default;
    type Message = Message;
    type Flags = ();

    fn new(_flags: ()) -> (Self, Command<Message>) {
        let init_commands = vec![
            Command::perform(load_config(), Message::Parse),
            Command::perform(needs_update(VERSION), Message::NeedsUpdate),
            Command::perform(load_user_themes(), Message::ThemesLoaded),
            Command::perform(get_catalog(), Message::CatalogDownloaded),
        ];

        (Ajour::default(), Command::batch(init_commands))
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
        // Clone config to be used. 
        // FIXME: This could be done prettier.
        let cloned_config = self.config.clone();
        
        // let translations = Translations {};

        // // Create the GettextLanguageLoader, pulling in settings from `i18n.toml`
        // // at compile time using the macro.
        // let language_loader = gettext_language_loader!();

        // // Use the language requester for the desktop platform (linux, windows, mac).
        // // There is also a requester available for the web-sys WASM platform called
        // // WebLanguageRequester, or you can implement your own.
        // //let requested_languages = DesktopLanguageRequester::requested_languages();
        
        // let mut li: unic_langid::LanguageIdentifier = self.language_state.current_language_name.parse()
        // .expect("Parsing failed.");
        // let mut requested_languages = Vec::new();
        // requested_languages.push(li);

        // log::debug!("Requested languages {:?}", requested_languages);

        // let _result = i18n_embed::select(
        //     &language_loader, &translations, &requested_languages);

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
        let other_flavor = if flavor == Flavor::Retail {
            Flavor::Classic
        } else {
            Flavor::Retail
        };

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
            &mut self.settings_btn_state,
            &mut self.addon_mode_btn_state,
            &mut self.catalog_mode_btn_state,
            self.needs_update.as_deref(),
            &mut self.new_release_button_state,
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
                &cloned_config,
                &mut self.language_state,
                &mut self.theme_state,
                &mut self.scale_state,
                &mut self.backup_state,
                &mut self.column_settings,
                &column_config,
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
                    &mut self.retail_btn_state,
                    &mut self.classic_btn_state,
                    &self.state,
                    addons,
                    &mut self.config,
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
                    let is_addon_expanded = match &self.expanded_addon {
                        Some(expanded_addon) => addon.id == expanded_addon.id,
                        None => false,
                    };

                    // A container cell which has all data about the current addon.
                    // If the addon is expanded, then this is also included in this container.
                    let addon_data_cell = element::addon_data_cell(
                        color_palette,
                        addon,
                        is_addon_expanded,
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
                    let other_flavor_addons = self.addons.get(&other_flavor).unwrap_or(&default);

                    let query = self
                        .catalog_search_state
                        .query
                        .as_deref()
                        .unwrap_or_default();

                    let catalog_query = TextInput::new(
                        &mut self.catalog_search_state.query_state,
                        &tr!("Search for an addon..."),
                        query,
                        Interaction::CatalogQuery,
                    )
                    .size(DEFAULT_FONT_SIZE)
                    .padding(10)
                    .width(Length::FillPortion(1))
                    .style(style::CatalogQueryInput(color_palette));

                    let catalog_query: Element<Interaction> = catalog_query.into();

                    let flavor_picklist = PickList::new(
                        &mut self.catalog_search_state.flavors_state,
                        &self.catalog_search_state.flavors,
                        Some(self.catalog_search_state.flavor),
                        Interaction::CatalogFlavorSelected,
                    )
                    .text_size(14)
                    .width(Length::Fill)
                    .style(style::SecondaryPickList(color_palette));

                    let flavor_picklist: Element<Interaction> = flavor_picklist.into();
                    let flavor_picklist_container =
                        Container::new(flavor_picklist.map(Message::Interaction))
                            .center_y()
                            .style(style::SurfaceContainer(color_palette))
                            .height(Length::Fill)
                            .width(Length::FillPortion(1));

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
                            .style(style::SurfaceContainer(color_palette))
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
                            .style(style::SurfaceContainer(color_palette))
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
                            .style(style::SurfaceContainer(color_palette))
                            .height(Length::Fill)
                            .width(Length::FillPortion(1));

                    let catalog_query_row = Row::new()
                        .push(Space::new(Length::Units(DEFAULT_PADDING), Length::Units(0)))
                        .push(catalog_query.map(Message::Interaction))
                        .push(flavor_picklist_container)
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
                        let retail_installed = if flavor == Flavor::Retail {
                            addons.iter().any(|a| {
                                a.curse_id == Some(addon.addon.id)
                                    || a.tukui_id == Some(addon.addon.id.to_string())
                            })
                        } else {
                            other_flavor_addons.iter().any(|a| {
                                a.curse_id == Some(addon.addon.id)
                                    || a.tukui_id == Some(addon.addon.id.to_string())
                            })
                        };
                        let retail_downloading = if flavor == Flavor::Retail {
                            addons.iter().any(|a| {
                                (a.curse_id == Some(addon.addon.id)
                                    || a.tukui_id == Some(addon.addon.id.to_string()))
                                    && a.state == AddonState::Downloading
                            })
                        } else {
                            other_flavor_addons.iter().any(|a| {
                                (a.curse_id == Some(addon.addon.id)
                                    || a.tukui_id == Some(addon.addon.id.to_string()))
                                    && a.state == AddonState::Downloading
                            })
                        };

                        let classic_installed = if flavor == Flavor::Classic {
                            addons.iter().any(|a| {
                                a.curse_id == Some(addon.addon.id)
                                    || a.tukui_id == Some(addon.addon.id.to_string())
                            })
                        } else {
                            other_flavor_addons.iter().any(|a| {
                                a.curse_id == Some(addon.addon.id)
                                    || a.tukui_id == Some(addon.addon.id.to_string())
                            })
                        };
                        let classic_downloading = if flavor == Flavor::Classic {
                            addons.iter().any(|a| {
                                (a.curse_id == Some(addon.addon.id)
                                    || a.tukui_id == Some(addon.addon.id.to_string()))
                                    && a.state == AddonState::Downloading
                            })
                        } else {
                            other_flavor_addons.iter().any(|a| {
                                (a.curse_id == Some(addon.addon.id)
                                    || a.tukui_id == Some(addon.addon.id.to_string()))
                                    && a.state == AddonState::Downloading
                            })
                        };

                        let catalog_data_cell = element::catalog_data_cell(
                            color_palette,
                            addon,
                            &catalog_column_config,
                            retail_downloading,
                            retail_installed,
                            classic_downloading,
                            classic_installed,
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
                &tr!("Welcome to Ajour!"),
                &tr!("Please select your World of Warcraft directory"),
                Some(&mut self.onboarding_directory_btn_state),
            )),
            AjourState::Idle => match self.mode {
                AjourMode::MyAddons => {
                    if !has_addons {
                        Some(element::status_container(
                            color_palette,
                            &tr!("Woops!"),
                            &tr!("You have no {} addons.", flavor.to_string().to_lowercase()),
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
                    &tr!("Loading.."),
                    &tr!("Currently parsing addons."),
                    None,
                )),
                AjourMode::Catalog => Some(element::status_container(
                    color_palette,
                    &tr!("Loading.."),
                    &tr!("Currently loading addon catalog."),
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
            .style(style::Content(color_palette))
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

    // Runs the GUI.
    Ajour::run(settings);
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
}

impl ColumnKey {
    fn title(self) -> String {
        use ColumnKey::*;

        let title = match self {
            Title => tr!("Addon"),
            LocalVersion => tr!("Local"),
            RemoteVersion => tr!("Remote"),
            Status => tr!("Status"),
            Channel => tr!("Channel"),
            Author => tr!("Author"),
            GameVersion => tr!("Game Version"),
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
    InstallRetail,
    InstallClassic,
}

impl CatalogColumnKey {
    fn title(self) -> String {
        use CatalogColumnKey::*;

        let title = match self {
            Title => "Addon",
            Description => "Description",
            Source => "Source",
            NumDownloads => "# Downloads",
            CatalogColumnKey::InstallRetail => "",
            CatalogColumnKey::InstallClassic => "",
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
            CatalogColumnKey::InstallRetail => "install_retail",
            CatalogColumnKey::InstallClassic => "install_classic",
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
            "install_retail" => CatalogColumnKey::InstallRetail,
            "install_classic" => CatalogColumnKey::InstallClassic,
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
    fn column_config(&self) -> Vec<(CatalogColumnKey, Length)> {
        self.columns.iter().map(|c| (c.key, c.width)).collect()
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
                    width: Length::Units(150),
                },
                CatalogColumnState {
                    key: CatalogColumnKey::Description,
                    btn_state: Default::default(),
                    width: Length::Fill,
                },
                CatalogColumnState {
                    key: CatalogColumnKey::Source,
                    btn_state: Default::default(),
                    width: Length::Units(85),
                },
                CatalogColumnState {
                    key: CatalogColumnKey::NumDownloads,
                    btn_state: Default::default(),
                    width: Length::Units(105),
                },
                CatalogColumnState {
                    key: CatalogColumnKey::InstallRetail,
                    btn_state: Default::default(),
                    width: Length::Units(85),
                },
                CatalogColumnState {
                    key: CatalogColumnKey::InstallClassic,
                    btn_state: Default::default(),
                    width: Length::Units(85),
                },
            ],
        }
    }
}

pub struct CatalogColumnState {
    key: CatalogColumnKey,
    btn_state: button::State,
    width: Length,
}

impl From<&CatalogColumnState> for ColumnConfigV2 {
    fn from(column: &CatalogColumnState) -> Self {
        // Only `CatalogColumnKey::Description` should be saved as Length::Fill -> width: None
        let width = if let Length::Units(width) = column.width {
            Some(width)
        } else {
            None
        };

        ColumnConfigV2 {
            key: column.key.as_string(),
            width,
            hidden: false,
        }
    }
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
    pub flavor: CatalogFlavor,
    pub flavors: Vec<CatalogFlavor>,
    pub flavors_state: pick_list::State<CatalogFlavor>,
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
            flavor: CatalogFlavor::All,
            flavors: CatalogFlavor::all(),
            flavors_state: Default::default(),
            source: CatalogSource::All,
            sources: CatalogSource::all(),
            sources_state: Default::default(),
        }
    }
}

pub struct CatalogRow {
    retail_install_state: button::State,
    classic_install_state: button::State,
    addon: CatalogAddon,
}

impl From<CatalogAddon> for CatalogRow {
    fn from(addon: CatalogAddon) -> Self {
        Self {
            retail_install_state: Default::default(),
            classic_install_state: Default::default(),
            addon,
        }
    }
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
pub enum CatalogFlavor {
    All,
    Choice(Flavor),
}

impl CatalogFlavor {
    pub fn all() -> Vec<CatalogFlavor> {
        vec![
            CatalogFlavor::All,
            CatalogFlavor::Choice(Flavor::Retail),
            CatalogFlavor::Choice(Flavor::Classic),
        ]
    }
}

impl std::fmt::Display for CatalogFlavor {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            CatalogFlavor::All => tr!("Both Flavors"),
            CatalogFlavor::Choice(flavor) => match flavor {
                Flavor::Retail => tr!("Retail"),
                Flavor::Classic => tr!("Classic"),
            },
        };
        write!(f, "{}", s)
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

pub struct LanguageState {
    languages: Vec<String>,
    current_language_name: String,
    pick_list_state: pick_list::State<String>,
}

impl Default for LanguageState{
    fn default() -> Self {
        let mut languages = vec![];
        languages.push("EN".to_string());
        languages.push("FR".to_string());

        LanguageState {
            languages,
            current_language_name: "EN".to_string(),
            pick_list_state: Default::default(),
        }
    }
}

impl Default for ThemeState {
    fn default() -> Self {
        let mut themes = vec![];
        themes.push(("Dark".to_string(), Theme::dark()));
        themes.push(("Light".to_string(), Theme::light()));

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
