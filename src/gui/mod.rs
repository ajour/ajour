mod element;
mod style;
mod update;

use crate::{
    addon::{Addon, AddonState},
    config::{Config, Flavor},
    error::ClientError,
    fs::config_dir,
    parse::FingerprintCollection,
    theme::{ColorPalette, Theme},
    Result,
};
use async_std::sync::{Arc, Mutex};
use iced::{
    button, pick_list, scrollable, Application, Column, Command, Container, Element, Length,
    Settings, Space,
};
use isahc::{
    config::{Configurable, RedirectPolicy},
    HttpClient,
};
use std::collections::HashMap;
use std::path::PathBuf;

use image::ImageFormat;
static WINDOW_ICON: &[u8] = include_bytes!("../../resources/windows/ajour.ico");

#[derive(Debug)]
pub enum AjourState {
    Error(ClientError),
    Idle,
    Loading,
    Welcome,
}

#[derive(Debug, Clone)]
pub enum Interaction {
    Delete(String),
    Expand(String),
    Ignore(String),
    OpenDirectory,
    OpenLink(String),
    Refresh,
    Settings,
    Unignore(String),
    Update(String),
    UpdateAll,
    SortColumn(SortKey),
    FlavorSelected(Flavor),
}

#[derive(Debug)]
pub enum Message {
    ConfigDirExists(PathBuf),
    DownloadedAddon((String, Result<()>)),
    Error(ClientError),
    Interaction(Interaction),
    NeedsUpdate(Result<Option<String>>),
    None(()),
    Parse(Result<Config>),
    ParsedAddons(Result<(Flavor, Vec<Addon>)>),
    UpdateFingerprint((String, Result<()>)),
    ThemeSelected(String),
    ThemesLoaded(Vec<Theme>),
    UnpackedAddon((String, Result<()>)),
    UpdateDirectory(Option<PathBuf>),
}

pub struct Ajour {
    addons: HashMap<Flavor, Vec<Addon>>,
    addons_scrollable_state: scrollable::State,
    config: Config,
    directory_btn_state: button::State,
    expanded_addon: Option<Addon>,
    ignored_addons: Vec<(Addon, button::State)>,
    ignored_addons_scrollable_state: scrollable::State,
    is_showing_settings: bool,
    needs_update: Option<String>,
    new_release_button_state: button::State,
    refresh_btn_state: button::State,
    settings_btn_state: button::State,
    shared_client: Arc<HttpClient>,
    state: AjourState,
    update_all_btn_state: button::State,
    sort_state: SortState,
    theme_state: ThemeState,
    fingerprint_collection: Arc<Mutex<Option<FingerprintCollection>>>,
    retail_btn_state: button::State,
    classic_btn_state: button::State,
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
            addons: HashMap::new(),
            addons_scrollable_state: Default::default(),
            config: Config::default(),
            directory_btn_state: Default::default(),
            expanded_addon: None,
            ignored_addons: Default::default(),
            ignored_addons_scrollable_state: Default::default(),
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
            update_all_btn_state: Default::default(),
            sort_state: Default::default(),
            theme_state: Default::default(),
            fingerprint_collection: Arc::new(Mutex::new(None)),
            retail_btn_state: Default::default(),
            classic_btn_state: Default::default(),
        }
    }
}

impl Application for Ajour {
    type Executor = iced::executor::Default;
    type Message = Message;
    type Flags = ();

    fn new(_flags: ()) -> (Self, Command<Message>) {
        (
            Ajour::default(),
            // Will create the config directory if it doesn't exist. This needs to happen before
            // we can safely perform all of our init operations concurrently
            Command::perform(async { config_dir() }, Message::ConfigDirExists),
        )
    }

    fn title(&self) -> String {
        String::from("Ajour")
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

        // Get addons for current flavor.
        let flavor = self.config.wow.flavor;
        let addons = self.addons.entry(flavor).or_insert_with(Vec::new);

        // Check if we have any addons.
        let has_addons = !&addons.is_empty();

        // Ignored addons.
        // We find the  corresponding `Addon` from the ignored strings.
        let ignored_strings = &self.config.addons.ignored;

        // Menu container at the top of the applications.
        // This has all global buttons, such as Settings, Update All, etc.
        let menu_container = element::menu_container(
            color_palette,
            &mut self.update_all_btn_state,
            &mut self.refresh_btn_state,
            &mut self.retail_btn_state,
            &mut self.classic_btn_state,
            &mut self.settings_btn_state,
            &self.state,
            addons,
            &self.config,
            self.needs_update.as_deref(),
            &mut self.new_release_button_state,
        );

        // Addon row titles is a row of titles above the addon scrollable.
        // This is to add titles above each section of the addon row, to let
        // the user easily identify what the value is.
        let addon_row_titles =
            element::addon_row_titles(color_palette, addons, &mut self.sort_state);

        // A scrollable list containing rows.
        // Each row holds data about a single addon.
        let mut addons_scrollable =
            element::addon_scrollable(color_palette, &mut self.addons_scrollable_state);

        // Loops though the addons.
        for addon in &mut addons
            .iter_mut()
            .filter(|a| !a.is_ignored(&ignored_strings))
        {
            // Checks if the current addon is expanded.
            let is_addon_expanded = match &self.expanded_addon {
                Some(expanded_addon) => addon.id == expanded_addon.id,
                None => false,
            };

            // A container cell which has all data about the current addon.
            // If the addon is expanded, then this is also included in this container.
            let addon_data_cell = element::addon_data_cell(color_palette, addon, is_addon_expanded);

            // Adds the addon data cell to the scrollable.
            addons_scrollable = addons_scrollable.push(addon_data_cell);
        }

        // Bottom space below the scrollable.
        let bottom_space = Space::new(Length::FillPortion(1), Length::Units(10));

        // This column gathers all the other elements together.
        let mut content = Column::new().push(menu_container);

        // This ensure we only draw settings, when we need to.
        if self.is_showing_settings {
            // Settings container, containing all data releated to settings.
            let settings_container = element::settings_container(
                color_palette,
                &mut self.directory_btn_state,
                &mut self.ignored_addons_scrollable_state,
                &mut self.ignored_addons,
                &self.config,
                &mut self.theme_state,
            );

            // Space below settings.
            let space = Space::new(Length::Fill, Length::Units(10));

            // Adds the settings container.
            content = content.push(settings_container).push(space);
        }

        // Adds the rest of the elements to the content column.
        if has_addons {
            content = content
                .push(addon_row_titles)
                .push(addons_scrollable)
                .push(bottom_space)
        }

        // Status messages.
        let container: Option<Container<Message>> = match self.state {
            AjourState::Welcome => Some(element::status_container(
                color_palette,
                "Welcome to Ajour!",
                "To get started, go to Settings and select your World of Warcraft directory.",
            )),
            AjourState::Idle => {
                if !has_addons {
                    Some(element::status_container(
                        color_palette,
                        "Woops!",
                        "It seems you have no addons in your AddOn directory.",
                    ))
                } else {
                    None
                }
            }
            AjourState::Loading => Some(element::status_container(
                color_palette,
                "Loading..",
                "Currently parsing addons.",
            )),
            _ => None,
        };

        if let Some(c) = container {
            content = content.push(c);
        };

        // Small padding to make UI fit better.
        content = content.padding(3);

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
pub fn run() {
    let mut settings = Settings::default();
    settings.window.size = (900, 620);
    // Enforce the usage of dedicated gpu if available.
    settings.antialiasing = true;

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

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum SortKey {
    Title,
    LocalVersion,
    RemoteVersion,
    Status,
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

#[derive(Default)]
pub struct SortState {
    previous_sort_key: Option<SortKey>,
    previous_sort_direction: Option<SortDirection>,
    title_btn_state: button::State,
    local_version_btn_state: button::State,
    remote_version_btn_state: button::State,
    status_btn_state: button::State,
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

        ThemeState {
            themes,
            current_theme_name: "Dark".to_string(),
            pick_list_state: Default::default(),
        }
    }
}
