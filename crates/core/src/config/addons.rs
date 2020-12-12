use super::Flavor;
use crate::repository::{GlobalReleaseChannel, ReleaseChannel};
use de::de_ignored;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Struct for addons specific settings.
#[derive(Deserialize, Serialize, Clone, Debug, PartialEq, Eq)]
pub struct Addons {
    #[serde(default)]
    pub global_release_channel: GlobalReleaseChannel,

    #[serde(default, deserialize_with = "de_ignored")]
    pub ignored: HashMap<Flavor, Vec<String>>,

    #[serde(default)]
    pub release_channels: HashMap<Flavor, HashMap<String, ReleaseChannel>>,
}

impl Default for Addons {
    fn default() -> Self {
        Addons {
            global_release_channel: GlobalReleaseChannel::Stable,
            ignored: HashMap::new(),
            release_channels: HashMap::new(),
        }
    }
}

mod de {
    use crate::config::Flavor;
    use serde::{
        de::{self, MapAccess, SeqAccess, Visitor},
        Deserialize, Deserializer,
    };
    use std::collections::HashMap;
    use std::fmt;

    pub(crate) fn de_ignored<'de, D>(
        deserializer: D,
    ) -> Result<HashMap<Flavor, Vec<String>>, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct DeIgnored;

        impl<'de> Visitor<'de> for DeIgnored {
            type Value = HashMap<Flavor, Vec<String>>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("Vec<String> or HashMap<Flavor, Vec<String>>")
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let mut map = HashMap::new();
                let mut ignored = vec![];

                while let Ok(Some(value)) = seq.next_element::<String>() {
                    ignored.push(value);
                }

                map.insert(Flavor::Retail, ignored.clone());
                map.insert(Flavor::Classic, ignored);

                Ok(map)
            }

            fn visit_map<A>(self, map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                Deserialize::deserialize(de::value::MapAccessDeserializer::new(map))
            }
        }

        deserializer.deserialize_any(DeIgnored)
    }
}
