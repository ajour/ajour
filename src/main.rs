mod config;
mod gui;
mod toc;

pub fn main() {
    // Loads the Config file
    let _ = config::load();

    // Start the GUI
    gui::run();
}
