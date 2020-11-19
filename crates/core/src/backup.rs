use crate::error::FilesystemError;
use crate::fs::backup::{Backup, ZipBackup};

use chrono::{Local, NaiveDateTime};
use std::convert::TryFrom;
use std::path::{Path, PathBuf};

/// Creates a .zip archive from the list of source folders and
/// saves it to the dest folder.
pub async fn backup_folders(
    src_folders: Vec<BackupFolder>,
    mut dest: PathBuf,
) -> Result<NaiveDateTime, FilesystemError> {
    let now = Local::now();

    dest.push(format!(
        "ajour_backup_{}.zip",
        now.format("%Y-%m-%d_%H-%M-%S")
    ));

    let zip_backup = ZipBackup::new(src_folders, &dest);

    zip_backup.backup()?;

    // Won't fail since we pass it the correct format
    let as_of = Archive::try_from(dest).unwrap().as_of;

    Ok(as_of)
}

/// Finds the latest archive in the supplied backup folder and returns
/// the datetime it was saved
pub async fn latest_backup(backup_dir: PathBuf) -> Option<NaiveDateTime> {
    let pattern = format!("{}/ajour_backup_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].zip", &backup_dir.display());

    let mut backups = vec![];

    for entry in glob::glob(&pattern).unwrap() {
        if let Ok(path) = entry {
            if let Ok(archive) = Archive::try_from(path) {
                backups.push(archive.as_of);
            }
        }
    }

    // Apparently NaiveDateTime sorts in Desc order by default, no need to reverse
    backups.sort();
    backups.pop()
}

/// Specifies a folder that we want backed up. `prefix` will get stripped out of
/// the path of each entry in the archive.
pub struct BackupFolder {
    pub path: PathBuf,
    pub prefix: PathBuf,
}

impl BackupFolder {
    pub fn new(path: impl AsRef<Path>, prefix: impl AsRef<Path>) -> BackupFolder {
        BackupFolder {
            path: path.as_ref().to_owned(),
            prefix: prefix.as_ref().to_owned(),
        }
    }
}

/// Metadata for our archive saved on the filesystem. Converted from a `PathBuf` with
/// the correct naming convention
struct Archive {
    pub as_of: NaiveDateTime,
}

impl TryFrom<PathBuf> for Archive {
    type Error = chrono::ParseError;

    fn try_from(path: PathBuf) -> Result<Archive, chrono::ParseError> {
        let file_stem = path.file_stem().unwrap().to_str().unwrap();

        let date_str = format!(
            "{} {}",
            file_stem.split('_').nth(2).unwrap_or_default(),
            file_stem.split('_').nth(3).unwrap_or_default()
        );

        let as_of = NaiveDateTime::parse_from_str(&date_str, "%Y-%m-%d %H-%M-%S")?;

        Ok(Archive { as_of })
    }
}
