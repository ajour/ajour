mod config;
mod gui;
mod toc;

pub fn main() {
    let config = config::load();
    println!("config: {:?}", config);
    gui::run();
}
