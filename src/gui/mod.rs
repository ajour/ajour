mod element;
mod style;
mod update;

use crate::{
    addon::{Addon, AddonState},
    config::{load_config, Config, Flavor},
    curse_api,
    error::ClientError,
    tukui_api, wowinterface_api, Result,
};
use iced::{
    button, pick_list, scrollable, Application, Column, Command, Container, Element, Length,
    Settings, Space,
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
    OpenDirectory,
    Settings,
    Refresh,
    UpdateAll,
    Update(String),
    Delete(String),
    Expand(String),
    Ignore(String),
    Unignore(String),
}

#[derive(Debug)]
pub enum Message {
    Parse(Result<Config>),
    ParsedAddons(Result<Vec<Addon>>),
    PartialParsedAddons(Result<Vec<Addon>>),
    DownloadedAddon((String, Result<()>)),
    UnpackedAddon((String, Result<()>)),
    CursePackage((String, Result<curse_api::Package>)),
    CursePackages((String, u32, Result<Vec<curse_api::Package>>)),
    TukuiPackage((String, Result<tukui_api::Package>)),
    WowinterfacePackages((String, Result<Vec<wowinterface_api::Package>>)),
    Interaction(Interaction),
    Error(ClientError),
    UpdateDirectory(Option<PathBuf>),
    FlavorSelected(Flavor),
}

pub struct Ajour {
    state: AjourState,
    update_all_btn_state: button::State,
    refresh_btn_state: button::State,
    settings_btn_state: button::State,
    directory_btn_state: button::State,
    addons_scrollable_state: scrollable::State,
    ignored_addons_scrollable_state: scrollable::State,
    flavor_list_state: pick_list::State<Flavor>,
    addons: Vec<Addon>,
    config: Config,
    expanded_addon: Option<Addon>,
    ignored_addons: Vec<(Addon, button::State)>,
    is_showing_settings: bool,
}

impl Default for Ajour {
    fn default() -> Self {
        Self {
            state: AjourState::Idle,
            update_all_btn_state: Default::default(),
            settings_btn_state: Default::default(),
            refresh_btn_state: Default::default(),
            directory_btn_state: Default::default(),
            addons_scrollable_state: Default::default(),
            ignored_addons_scrollable_state: Default::default(),
            flavor_list_state: Default::default(),
            addons: Vec::new(),
            config: Config::default(),
            expanded_addon: None,
            ignored_addons: Vec::new(),
            is_showing_settings: false,
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
            Command::perform(load_config(), Message::Parse),
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
        // Ignored addons.
        // We find the  corresponding `Addon` from the ignored strings.
        let ignored_strings = &self.config.addons.ignored;
        // let mut ignored_addons = self
        //     .addons
        //     .into_iter()
        //     .filter(|a| ignored_strings.into_iter().any(|i| i == &a.id))
        //     .collect::<Vec<Addon>>();

        // Menu container at the top of the applications.
        // This has all global buttons, such as Settings, Update All, etc.
        let menu_container = element::menu_container(
            &mut self.update_all_btn_state,
            &mut self.refresh_btn_state,
            &mut self.settings_btn_state,
            &self.state,
            &self.addons,
            &self.config,
        );

        // Addon row titles is a row of titles above the addon scrollable.
        // This is to add titles above each section of the addon row, to let
        // the user easily identify what the value is.
        let addon_row_titles = element::addon_row_titles(&self.addons);

        // A scrollable list containing rows.
        // Each row holds data about a single addon.
        let mut addons_scrollable = element::addon_scrollable(&mut self.addons_scrollable_state);

        // Loops though the addons.
        for addon in &mut self
            .addons
            .iter_mut()
            .filter(|a| a.is_parent() && !a.is_ignored(&ignored_strings))
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
        content = content
            .push(addon_row_titles)
            .push(addons_scrollable)
            .push(bottom_space)
            .padding(3); // small padding to make scrollbar fit better.

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
