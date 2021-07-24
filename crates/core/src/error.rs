use crate::{config::Flavor, repository::ReleaseChannel};

use std::path::PathBuf;

#[derive(thiserror::Error, Debug)]
pub enum FilesystemError {
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error(transparent)]
    SerdeYaml(#[from] serde_yaml::Error),
    #[error(transparent)]
    Zip(#[from] zip::result::ZipError),
    #[error(transparent)]
    WalkDir(#[from] walkdir::Error),
    #[error("File doesn't exist: {path:?}")]
    FileDoesntExist { path: PathBuf },
    #[cfg(target_os = "macos")]
    #[error("Could not file bin name {bin_name} in archive")]
    BinMissingFromTar { bin_name: String },
    #[error("Failed to normalize path slashes for {path:?}")]
    NormalizingPathSlash { path: PathBuf },
    #[error("Could not strip prefix {prefix:?} from {from:?}")]
    StripPrefix { prefix: String, from: String },
    #[error(transparent)]
    SerdeJson(#[from] serde_json::Error),
}

#[derive(thiserror::Error, Debug)]
pub enum CacheError {
    #[error("No repository information to create cache entry from addon {title}")]
    AddonMissingRepo { title: String },
    #[error(transparent)]
    Filesystem(#[from] FilesystemError),
}

#[derive(thiserror::Error, Debug)]
pub enum DownloadError {
    #[error("Body len != content len: {body_length} != {content_length}")]
    ContentLength {
        content_length: u64,
        body_length: u64,
    },
    #[error("Invalid status code {code} for url {url}")]
    InvalidStatusCode {
        code: isahc::http::StatusCode,
        url: String,
    },
    #[error("No new release binary available for {bin_name}")]
    MissingSelfUpdateRelease { bin_name: String },
    #[error("Catalog failed to download")]
    CatalogFailed,
    #[error("Self update for linux only works from AppImage")]
    SelfUpdateLinuxNonAppImage,
    #[error(transparent)]
    Isahc(#[from] isahc::Error),
    #[error(transparent)]
    Http(#[from] isahc::http::Error),
    #[error(transparent)]
    Var(#[from] std::env::VarError),
    #[error(transparent)]
    SerdeJson(#[from] serde_json::Error),
    #[error(transparent)]
    Filesystem(#[from] FilesystemError),
}

impl From<std::io::Error> for DownloadError {
    fn from(e: std::io::Error) -> Self {
        DownloadError::Filesystem(FilesystemError::Io(e))
    }
}

#[derive(thiserror::Error, Debug)]
pub enum RepositoryError {
    #[error("No repository set for addon")]
    AddonNoRepository,
    #[error("Failed to parse curse id as u32: {id}")]
    CurseIdConversion { id: String },
    #[error("File id must be provided for curse changelog request")]
    CurseChangelogFileId,
    #[error("No package found for curse id {id}")]
    CurseMissingPackage { id: String },
    #[error("No package found for WowI id {id}")]
    WowIMissingPackage { id: String },
    #[error("No package found for Hub id {id}")]
    HubMissingPackage { id: String },
    #[error("No remote package found for channel {channel}")]
    MissingPackageChannel { channel: ReleaseChannel },
    #[error("Git repo must be created with `from_source_url`")]
    GitWrongConstructor,
    #[error("Invalid url {url}")]
    GitInvalidUrl { url: String },
    #[error("No valid host in {url}")]
    GitMissingHost { url: String },
    #[error("Invalid host {host}, only github.com and gitlab.com are supported")]
    GitInvalidHost { host: String },
    #[error("Author not present in {url}")]
    GitMissingAuthor { url: String },
    #[error("Repo not present in {url}")]
    GitMissingRepo { url: String },
    #[error("No release at {url}")]
    GitMissingRelease { url: String },
    #[error("No zip available for {flavor} at {url}")]
    GitNoZip { flavor: Flavor, url: String },
    #[error("Tag name must be specified for git changelog")]
    GitChangelogTagName,
    #[error(transparent)]
    Download(#[from] DownloadError),
    #[error(transparent)]
    Filesystem(#[from] FilesystemError),
    #[error(transparent)]
    Uri(#[from] isahc::http::uri::InvalidUri),
    #[error(transparent)]
    SerdeJson(#[from] serde_json::Error),
}

impl From<std::io::Error> for RepositoryError {
    fn from(e: std::io::Error) -> Self {
        RepositoryError::Filesystem(FilesystemError::Io(e))
    }
}

impl From<isahc::Error> for RepositoryError {
    fn from(e: isahc::Error) -> Self {
        RepositoryError::Download(DownloadError::Isahc(e))
    }
}

#[derive(thiserror::Error, Debug)]
pub enum ParseError {
    #[error("Addon directory not found: {path:?}")]
    MissingAddonDirectory { path: PathBuf },
    #[error("No folders passed to addon")]
    BuildAddonEmptyFolders,
    #[error("No parent directory for {dir:?}")]
    NoParentDirectory { dir: PathBuf },
    #[error("Invalid UTF8 path: {path:?}")]
    InvalidUtf8Path { path: PathBuf },
    #[error("Path is not a file or doesn't exist: {path:?}")]
    InvalidFile { path: PathBuf },
    #[error("Invalid extension for path: {path:?}")]
    InvalidExt { path: PathBuf },
    #[error("Extension not in file parsing regex: {ext}")]
    ParsingRegexMissingExt { ext: String },
    #[error("Inclusion regex error for group {group} on pos {pos}, line: {line}")]
    InclusionRegexError {
        group: usize,
        pos: usize,
        line: String,
    },
    #[error(transparent)]
    StripPrefix(#[from] std::path::StripPrefixError),
    #[error(transparent)]
    GlobPattern(#[from] glob::PatternError),
    #[error(transparent)]
    Glob(#[from] glob::GlobError),
    #[error(transparent)]
    FancyRegex(#[from] fancy_regex::Error),
    #[error(transparent)]
    Download(#[from] DownloadError),
    #[error(transparent)]
    Filesystem(#[from] FilesystemError),
    #[error(transparent)]
    Cache(#[from] CacheError),
}

impl From<std::io::Error> for ParseError {
    fn from(e: std::io::Error) -> Self {
        ParseError::Filesystem(FilesystemError::Io(e))
    }
}

#[derive(thiserror::Error, Debug)]
pub enum ThemeError {
    #[error(transparent)]
    InvalidUri(#[from] isahc::http::uri::InvalidUri),
    #[error(transparent)]
    UrlEncoded(#[from] serde_urlencoded::de::Error),
    #[error(transparent)]
    SerdeYaml(#[from] serde_yaml::Error),
    #[error(transparent)]
    SerdeJson(#[from] serde_json::Error),
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error("Url is missing theme from query")]
    MissingQuery,
    #[error("Theme already exists with name: {name}")]
    NameCollision { name: String },
}
