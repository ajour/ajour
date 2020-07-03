mod toc;
mod window;

use crate::toc::read_addon_dir;
use crate::window::Window;

pub fn main() {
    read_addon_dir("./example-data");

    // Creates the window.
    let _window = Window::new((1050, 620));
}
