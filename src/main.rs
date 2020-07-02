// With the default subsystem, 'console', windows creates an additional console
// window for the program.
// This is silently ignored on non-windows systems.
// See https://msdn.microsoft.com/en-us/library/4cc7ya5b.aspx for more details.
#![windows_subsystem = "windows"]

mod toc;

use crate::toc::read_addon_dir;

fn main() {
    let addons = read_addon_dir("./test-data");
    println!("{:?}", addons);
}

