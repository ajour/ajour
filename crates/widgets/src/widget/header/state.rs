use iced_native::Point;

#[derive(Debug, Default)]
pub struct State {
    pub resize_hovering: bool,
    pub resizing: bool,
    pub starting_cursor_pos: Option<Point>,
    pub starting_left_width: f32,
    pub starting_right_width: f32,
    pub resizing_idx: usize,
}
