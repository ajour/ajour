use crate::error::ClientError;
use crate::Result;

use std::fs::File;
use std::io::{BufWriter, Read, Write};
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use zip::{write::FileOptions, CompressionMethod, ZipWriter};

pub trait Backup {
    fn backup(&self) -> Result<()>;
}

pub struct BackupFolder {
    path: PathBuf,
    prefix: PathBuf,
}

impl BackupFolder {
    fn new(path: impl AsRef<Path>, prefix: impl AsRef<Path>) -> BackupFolder {
        BackupFolder {
            path: path.as_ref().to_owned(),
            prefix: prefix.as_ref().to_owned(),
        }
    }
}

pub struct ZipBackup {
    src: Vec<BackupFolder>,
    dest: PathBuf,
}

impl ZipBackup {
    pub fn new(src: Vec<BackupFolder>, dest: impl AsRef<Path>) -> ZipBackup {
        ZipBackup {
            src,
            dest: dest.as_ref().to_owned(),
        }
    }
}

impl Backup for ZipBackup {
    fn backup(&self) -> Result<()> {
        let output = BufWriter::new(File::create(&self.dest)?);

        let mut zip_writer = ZipWriter::new(output);
        let options = FileOptions::default()
            .compression_method(CompressionMethod::Bzip2)
            .unix_permissions(0o755);

        let mut buffer = vec![];

        for folder in &self.src {
            let prefix = &folder.prefix;
            let path = &folder.path;

            zip_write(path, prefix, &mut buffer, &mut zip_writer, options)?;

            for entry in WalkDir::new(path)
                .into_iter()
                .filter_map(std::result::Result::ok)
            {
                let path = entry.path();

                zip_write(path, prefix, &mut buffer, &mut zip_writer, options)?;
            }
        }

        zip_writer.finish()?;

        Ok(())
    }
}

fn zip_write(
    path: &Path,
    prefix: &Path,
    buffer: &mut Vec<u8>,
    writer: &mut ZipWriter<BufWriter<File>>,
    options: FileOptions,
) -> Result<()> {
    if !path.exists() {
        return Err(ClientError::Custom(format!(
            "path doesn't exist while backing up folder: {:?}",
            path
        )));
    }

    let name = path.strip_prefix(prefix).unwrap().to_str().unwrap();

    if path.is_dir() {
        writer.add_directory(name, options)?;
    } else {
        writer.start_file(name, options)?;

        let mut file = File::open(path)?;
        file.read_to_end(buffer)?;

        writer.write_all(buffer)?;
        buffer.clear();
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{Config, Flavor};
    use crate::fs::PersistentData;
    use chrono::Local;

    #[test]
    fn test_zip_backup() {
        let config: Config = Config::load().unwrap();

        let mut src_folders = vec![];

        let wow_dir = config.wow.directory.as_ref().unwrap();

        for flavor in Flavor::ALL.iter() {
            let addon_dir = config.get_addon_directory_for_flavor(flavor).unwrap();
            let wtf_dir = config.get_wtf_directory_for_flavor(flavor).unwrap();

            src_folders.push(BackupFolder::new(&addon_dir, wow_dir));
            src_folders.push(BackupFolder::new(&wtf_dir, wow_dir));
        }

        let now = Local::now();
        let dest = format!(
            "C:\\TempPath\\ajour_backup_{}.zip",
            now.format("%Y-%m-%d_%H-%M-%S")
        );

        let zip_backup = ZipBackup::new(src_folders, dest);

        zip_backup.backup().unwrap();
    }
}
