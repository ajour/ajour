use ajour_core::config::Flavor;
use ajour_core::repository::{ReleaseChannel, RepositoryPackage};
use ajour_core::Result;

use async_std::task;
use isahc::http::Uri;

pub fn install_from_source(url: Uri) -> Result<()> {
    task::block_on(async {
        let mut repo_package = RepositoryPackage::from_source_url(Flavor::Retail, url)?;
        repo_package.resolve_metadata().await?;

        dbg!(&repo_package);

        let change_log = repo_package
            .get_changelog(ReleaseChannel::Stable, false)
            .await?;

        dbg!(&change_log);

        Result::Ok(())
    })
}
