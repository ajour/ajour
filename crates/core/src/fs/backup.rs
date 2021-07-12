use super::Result;
use crate::backup::BackupFolder;
use crate::error::FilesystemError;

use path_slash::PathExt;
use std::fs::File;
use std::io::{BufWriter, Read, Write};
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use zip::{write::FileOptions, CompressionMethod, ZipWriter};

/// A trait defining a way to back things up to the fs
pub trait Backup {
    fn backup(&self, level: Option<i32>) -> Result<()>;
}

/// Back up folders to a zip archive and save on the fs
pub struct ZipBackup {
    src: Vec<BackupFolder>,
    dest: PathBuf,
}

impl ZipBackup {
    pub(crate) fn new(src: Vec<BackupFolder>, dest: impl AsRef<Path>) -> ZipBackup {
        ZipBackup {
            src,
            dest: dest.as_ref().to_owned(),
        }
    }
}

impl Backup for ZipBackup {
    fn backup(&self, _: Option<i32>) -> Result<()> {
        let output = BufWriter::new(File::create(&self.dest)?);

        let mut zip_writer = ZipWriter::new(output);
        let options = FileOptions::default()
            .compression_method(CompressionMethod::Deflated)
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

/// Write each path to the zip archive
fn zip_write(
    path: &Path,
    prefix: &Path,
    buffer: &mut Vec<u8>,
    writer: &mut ZipWriter<BufWriter<File>>,
    options: FileOptions,
) -> Result<()> {
    if !path.exists() {
        return Err(FilesystemError::FileDoesntExist {
            path: path.to_owned(),
        });
    }

    // On windows, convers `\` to `/`
    let normalized_path = path
        .to_slash()
        .ok_or(FilesystemError::NormalizingPathSlash {
            path: path.to_path_buf(),
        })?;
    let normalized_prefix = prefix
        .to_slash()
        .ok_or(FilesystemError::NormalizingPathSlash {
            path: prefix.to_path_buf(),
        })?;

    // Strip prefix from path name and remove leading slash
    let name = normalized_path
        .strip_prefix(&normalized_prefix)
        .ok_or(FilesystemError::StripPrefix {
            prefix: normalized_prefix,
            from: normalized_path.clone(),
        })?
        .trim_start_matches('/');

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

pub struct ZstdBackup {
    src: Vec<BackupFolder>,
    dest: PathBuf,
}

impl ZstdBackup {
    pub(crate) fn new(src: Vec<BackupFolder>, dest: impl AsRef<Path>) -> ZstdBackup {
        ZstdBackup {
            src,
            dest: dest.as_ref().to_owned(),
        }
    }
}

impl Backup for ZstdBackup {
    fn backup(&self, level: Option<i32>) -> Result<()> {
        use zstd::stream::write::Encoder as ZstdEncoder;

        let output = File::create(&self.dest)?;
        let mut enc = ZstdEncoder::new(output, level.unwrap_or_default())?;
        enc.multithread(num_cpus::get() as u32)?;
        let mut tar = tar::Builder::new(enc.auto_finish());

        for folder in &self.src {
            let path = folder.path.strip_prefix(&folder.prefix).unwrap();
            let src_path = folder.prefix.join(&folder.path);
            tar.append_dir_all(path, src_path)?;
        }
        tar.finish()?;

        Ok(())
    }
}
