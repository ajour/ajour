use crate::Result;
use ajour_core::{
    config::{load_config, Flavor},
    fs::PersistentData,
};
use async_std::task;
use std::path::PathBuf;

pub fn path_add(path: PathBuf, flavor: Option<Flavor>) -> Result<()> {
    task::block_on(async {
        log::debug!("Adding {:?} from {:?} to known directories", flavor, &path);
        let mut config = load_config().await?;
        config.add_wow_directories(path, flavor);
        let _ = config.save();

        Ok(())
    })
}
