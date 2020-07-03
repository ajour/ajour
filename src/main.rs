mod gui;
mod toc;

use crate::toc::read_addon_dir;

pub fn main() {
    read_addon_dir("./example-data");
    gui::run();
}
