use ajour_core::parse::file_parsing_regex;
use async_std::task;

fn main() {
    task::block_on(async move {
        file_parsing_regex().await.unwrap();
    });
}
