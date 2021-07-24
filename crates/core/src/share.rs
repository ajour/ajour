use std::{collections::HashMap, convert::TryFrom, fs, path::Path};

use serde::{Deserialize, Serialize};

use crate::{addon::Addon, config::Flavor, error, repository::RepositoryKind};

#[derive(Debug, Serialize, Deserialize)]
pub struct Data {
    pub flavor: Flavor,
    pub repo_kind: RepositoryKind,
    pub id: String,
    pub name: String,
}

impl TryFrom<(Flavor, Addon)> for Data {
    type Error = ();

    fn try_from((flavor, addon): (Flavor, Addon)) -> Result<Self, Self::Error> {
        let name = addon.title().to_string();
        let repository = addon.repository.ok_or(())?;
        let repo_kind = repository.kind;
        let id = repository.id;

        Ok(Self {
            flavor,
            repo_kind,
            id,
            name,
        })
    }
}

pub fn export(
    addons: HashMap<Flavor, Vec<Addon>>,
    output_dir: impl AsRef<Path>,
) -> Result<(), error::FilesystemError> {
    let data = addons
        .into_iter()
        .map(|(flavor, addons)| {
            (
                flavor,
                addons
                    .into_iter()
                    .map(|a| Data::try_from((flavor, a)))
                    .flatten()
                    .collect::<Vec<_>>(),
            )
        })
        .collect::<HashMap<_, Vec<_>>>();

    let file = output_dir.as_ref().join("ajour-addons.yml");

    let contents = serde_yaml::to_string(&data)?;

    fs::write(file, contents)?;

    Ok(())
}

pub struct Parsed {
    pub data: Vec<Data>,
    pub ignored: usize,
}

pub fn parse_only_needed(
    existing_addons: HashMap<Flavor, Vec<Addon>>,
    path: impl AsRef<Path>,
) -> Result<HashMap<Flavor, Parsed>, error::FilesystemError> {
    let file = fs::File::open(&path)?;
    let data = serde_yaml::from_reader::<_, HashMap<Flavor, Vec<Data>>>(file)?;

    Ok(data
        .into_iter()
        .map(|(flavor, data)| {
            let original_len = data.len();
            let needed = data
                .into_iter()
                .filter(|data| {
                    if let Some(existing) = existing_addons.get(&flavor) {
                        !existing.iter().any(|a| {
                            if let Some(existing_repo) = a.repository() {
                                let kind = data.repo_kind;

                                existing_repo.id == data.id && existing_repo.kind == kind
                            } else {
                                false
                            }
                        })
                    } else {
                        true
                    }
                })
                .collect::<Vec<_>>();

            let ignored = original_len - needed.len();

            (
                flavor,
                Parsed {
                    data: needed,
                    ignored,
                },
            )
        })
        .collect())
}
