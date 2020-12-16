use super::{AuraUpdate, Error};
use async_std::{fs, io::prelude::*, path::Path};
use std::fmt::Write;

const ADDON_NAME: &str = "WeakAurasCompanion";
const TOC_NAME: &str = "WeakAurasCompanion.toc";

const TOC_CONTENTS: &str = r"## Interface: 11305
## Title: WeakAuras Companion
## Author: The WeakAuras Team
## Version: 1.1.0
## Notes: Keep your WeakAuras updated!
## X-Category: Interface Enhancements
## DefaultState: Enabled
## LoadOnDemand: 0
## OptionalDeps: WeakAuras,Plater,

data.lua
init.lua
";

const INIT_CONTENTS: &str = r#"-- file generated automatically
local buildTimeTarget = 20190123023201
local waBuildTime = tonumber(WeakAuras and WeakAuras.buildTime or 0)

if waBuildTime and waBuildTime > buildTimeTarget then
  local loadedFrame = CreateFrame("FRAME")
  loadedFrame:RegisterEvent("ADDON_LOADED")
  loadedFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "WeakAurasCompanion" then
      local count = WeakAuras.CountWagoUpdates()
      if count and count > 0 then
        WeakAuras.prettyPrint(WeakAuras.L["There are %i updates to your auras ready to be installed!"]:format(count))
      end
      if WeakAuras.ImportHistory then
        for id, data in pairs(WeakAurasSaved.displays) do
          if data.uid and not WeakAurasSaved.history[data.uid] then
            local slug = WeakAurasCompanion.uids[data.uid]
            if slug then
              local wagoData = WeakAurasCompanion.slugs[slug]
              if wagoData and wagoData.encoded then
                WeakAuras.ImportHistory(wagoData.encoded)
              end
            end
          end
        end
      end
      if WeakAurasCompanion.stash then
        local emptyStash = true
        for _ in pairs(WeakAurasCompanion.stash) do
          emptyStash = false
        end
        if not emptyStash and WeakAuras.StashShow then
          C_Timer.After(5, function() WeakAuras.StashShow() end)
        end
      end
    end
  end)
end

if Plater and Plater.CheckWagoUpdates then
    Plater.CheckWagoUpdates()
end"#;

const DATA_CONTENTS: &str = r"-- file generated automatically
WeakAurasCompanion = {
  slugs = {},
  uids = {},
  ids = {},
  stash = {}
}
";

/// Writes the updates to the `data.lua` file for the
/// companion addon in the specified addon directory.
///
/// Returns the slugs of the auras updated to the data file
pub async fn write_updates(
    addon_dir: impl AsRef<Path>,
    updates: &[AuraUpdate],
) -> Result<Vec<String>, Error> {
    ensure_companion_addon_exists(&addon_dir).await?;

    Ok(CompanionAddon::write_updates(&addon_dir, updates).await?)
}

/// Only pub for testing. This is called inside `write_updates` and doesn't need
/// to be called manually
pub async fn ensure_companion_addon_exists(addon_dir: impl AsRef<Path>) -> Result<(), Error> {
    if !CompanionAddon::exists(&addon_dir).await {
        CompanionAddon::create(&addon_dir).await?
    }

    Ok(())
}

struct CompanionAddon {}

impl CompanionAddon {
    async fn exists(addon_dir: impl AsRef<Path>) -> bool {
        let companion_folder = addon_dir.as_ref().join(ADDON_NAME);
        let toc_file = companion_folder.join(TOC_NAME);
        let init_file = companion_folder.join("init.lua");
        let data_file = companion_folder.join("data.lua");

        companion_folder.is_dir().await
            && toc_file.is_file().await
            && init_file.is_file().await
            && data_file.is_file().await
    }

    async fn create(addon_dir: impl AsRef<Path>) -> Result<(), Error> {
        let companion_folder = addon_dir.as_ref().join(ADDON_NAME);
        let toc_file = companion_folder.join(TOC_NAME);
        let init_file = companion_folder.join("init.lua");
        let data_file = companion_folder.join("data.lua");

        if !companion_folder.exists().await {
            fs::create_dir_all(companion_folder).await?;
        }

        if !toc_file.exists().await {
            fs::write(toc_file, TOC_CONTENTS).await?;
        }

        if !init_file.exists().await {
            fs::write(init_file, INIT_CONTENTS).await?;
        }

        if !data_file.exists().await {
            fs::write(data_file, DATA_CONTENTS).await?;
        }

        Ok(())
    }

    async fn write_updates(
        addon_dir: impl AsRef<Path>,
        updates: &[AuraUpdate],
    ) -> Result<Vec<String>, Error> {
        let companion_folder = addon_dir.as_ref().join(ADDON_NAME);
        let mut data_file = fs::File::create(companion_folder.join("data.lua")).await?;

        let mut output = String::new();

        writeln!(&mut output, "-- file generated automatically")?;
        writeln!(&mut output, "WeakAurasCompanion = {{")?;
        writeln!(&mut output, "  slugs = {{")?;

        for update in updates {
            write!(&mut output, "{}", update.formatted_slug()?)?;
        }

        writeln!(&mut output, "  }},")?;
        writeln!(&mut output, "  uids = {{")?;

        for update in updates {
            write!(&mut output, "{}", update.formatted_uid()?)?;
        }

        writeln!(&mut output, "  }},")?;
        writeln!(&mut output, "  ids = {{")?;

        for update in updates {
            write!(&mut output, "{}", update.formatted_ids()?)?;
        }

        writeln!(&mut output, "  }},")?;
        writeln!(&mut output, "  stash = {{ }}")?;
        writeln!(&mut output, "}}")?;

        data_file.write_all(output.as_bytes()).await?;

        Ok(updates.iter().map(|a| a.slug.clone()).collect())
    }
}
