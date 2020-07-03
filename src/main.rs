
mod toc;
mod window;

use crate::window::Window;
use crate::toc::read_addon_dir;

pub fn main() {
    let window = Window::new();
    read_addon_dir("./example-data");
}

