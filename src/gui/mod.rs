mod element;
mod style;
mod update;

use crate::{
    addon::{Addon, AddonState},
    config::{load_config, Config, Flavor},
    curse_api,
    error::ClientError,
    tukui_api,
    utility::needs_update,
    wowinterface_api, Result,
};
use async_std::sync::Arc;
use iced::{
    button, pick_list, scrollable, Application, Column, Command, Container, Element, Length,
    Settings, Space,
};
use isahc::{
    config::{Configurable, RedirectPolicy},
    HttpClient,
};
use std::path::PathBuf;

use image::ImageFormat;
static WINDOW_ICON: &[u8] = include_bytes!("../../resources/windows/ajour.ico");

#[derive(Debug)]
pub enum AjourState {
    Idle,
    Error(ClientError),
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
}

#[derive(Debug)]
pub enum Message {
    CursePackage((String, Result<curse_api::Package>)),
    CursePackages((String, u32, Result<Vec<curse_api::Package>>)),
    DownloadedAddon((String, Result<()>)),
    Error(ClientError),
    FlavorSelected(Flavor),
    Interaction(Interaction),
    NeedsUpdate(Result<Option<String>>),
    None(()),
    Parse(Result<Config>),
    ParsedAddons(Result<Vec<Addon>>),
    PartialParsedAddons(Result<Vec<Addon>>),
    TukuiPackage((String, Result<tukui_api::Package>)),
    UnpackedAddon((String, Result<()>)),
    UpdateDirectory(Option<PathBuf>),
    WowinterfacePackages((String, Result<Vec<wowinterface_api::Package>>)),
}

pub struct Ajour {
    addons: Vec<Addon>,
    addons_scrollable_state: scrollable::State,
    config: Config,
    directory_btn_state: button::State,
    expanded_addon: Option<Addon>,
    flavor_list_state: pick_list::State<Flavor>,
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
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
            addons: Vec::new(),
            addons_scrollable_state: Default::default(),
            config: Config::default(),
            directory_btn_state: Default::default(),
            expanded_addon: None,
            flavor_list_state: Default::default(),
            ignored_addons: Vec::new(),
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

            state: AjourState::Idle,
            update_all_btn_state: Default::default(),
            sort_state: Default::default(),
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
            Command::perform(needs_update(), Message::NeedsUpdate),
        ];

        (Ajour::default(), Command::batch(init_commands))
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
        let has_addons = !&self.addons.is_empty();
        let has_wow_path = self.config.wow.directory.is_some();

        // Ignored addons.
        // We find the  corresponding `Addon` from the ignored strings.
        let ignored_strings = &self.config.addons.ignored;

        // Menu container at the top of the applications.
        // This has all global buttons, such as Settings, Update All, etc.
        let menu_container = element::menu_container(
            &mut self.update_all_btn_state,
            &mut self.refresh_btn_state,
            &mut self.settings_btn_state,
            &self.state,
            &self.addons,
            &self.config,
            self.needs_update.as_deref(),
            &mut self.new_release_button_state,
        );

        // Addon row titles is a row of titles above the addon scrollable.
        // This is to add titles above each section of the addon row, to let
        // the user easily identify what the value is.
        let addon_row_titles = element::addon_row_titles(&self.addons, &mut self.sort_state);

        // A scrollable list containing rows.
        // Each row holds data about a single addon.
        let mut addons_scrollable = element::addon_scrollable(&mut self.addons_scrollable_state);

        // Loops though the addons.
        for addon in &mut self
            .addons
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
            let addon_data_cell = element::addon_data_cell(addon, is_addon_expanded);

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
                &mut self.directory_btn_state,
                &mut self.flavor_list_state,
                &mut self.ignored_addons_scrollable_state,
                &mut self.ignored_addons,
                &self.config,
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

        // If we have no addons, and no path we assume onboarding.
        if !has_addons && !has_wow_path {
            let status_container = element::status_container(
                "Welcome to Ajour!",
                "To get started, go to Settings and select your World of Warcraft directory.",
            );
            content = content.push(status_container);
        }

        // Small padding to make UI fit better.
        content = content.padding(3);

        // Finally wraps everything in a container.
        Container::new(content)
            .width(Length::Fill)
            .height(Length::Fill)
            .style(style::Content)
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
