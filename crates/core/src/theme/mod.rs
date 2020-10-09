use crate::fs;
use de::deserialize_color_hex_string;
use serde::Deserialize;
use std::cmp::Ordering;

pub async fn load_user_themes() -> Vec<Theme> {
    log::debug!("loading user themes");

    fs::load_user_themes().await
}

#[derive(Debug, Clone, Deserialize)]
pub struct Theme {
    pub name: String,
    pub palette: ColorPalette,
}

#[derive(Debug, Clone, Copy, Deserialize)]
pub struct BaseColors {
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub background: iced_native::Color,
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub foreground: iced_native::Color,
}

#[derive(Debug, Clone, Copy, Deserialize)]
pub struct NormalColors {
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub primary: iced_native::Color,
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub secondary: iced_native::Color,
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub surface: iced_native::Color,
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub error: iced_native::Color,
}

#[derive(Debug, Clone, Copy, Deserialize)]
pub struct BrightColors {
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub primary: iced_native::Color,
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub secondary: iced_native::Color,
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub surface: iced_native::Color,
    #[serde(deserialize_with = "deserialize_color_hex_string")]
    pub error: iced_native::Color,
}

#[derive(Debug, Clone, Copy, Deserialize)]
pub struct ColorPalette {
    pub base: BaseColors,
    pub normal: NormalColors,
    pub bright: BrightColors,
}

impl Theme {
    pub fn dark() -> Theme {
        Theme {
            name: "Dark".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#111111").unwrap(),
                    foreground: hex_to_color("#161616").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#3f2b56").unwrap(),
                    secondary: hex_to_color("#4a3c1c").unwrap(),
                    surface: hex_to_color("#828282").unwrap(),
                    error: hex_to_color("#992B2B").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#BA84FC").unwrap(),
                    secondary: hex_to_color("#ffd03c").unwrap(),
                    surface: hex_to_color("#E0E0E0").unwrap(),
                    error: hex_to_color("#C13047").unwrap(),
                },
            },
        }
    }

    pub fn light() -> Theme {
        Theme {
            name: "Light".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#ffffff").unwrap(),
                    foreground: hex_to_color("#F5F5F5").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#d0caff").unwrap(),
                    secondary: hex_to_color("#F9D659").unwrap(),
                    surface: hex_to_color("#828282").unwrap(),
                    error: hex_to_color("#992B2B").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#9580ff").unwrap(),
                    secondary: hex_to_color("#EAA326").unwrap(),
                    surface: hex_to_color("#000000").unwrap(),
                    error: hex_to_color("#C13047").unwrap(),
                },
            },
        }
    }

    pub fn solarized_dark() -> Theme {
        Theme {
            name: "Solarized Dark".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#012b36").unwrap(),
                    foreground: hex_to_color("#093642").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#1A615B").unwrap(),
                    secondary: hex_to_color("#523F09").unwrap(),
                    surface: hex_to_color("#63797e").unwrap(),
                    error: hex_to_color("#b80f15").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#2aa096").unwrap(),
                    secondary: hex_to_color("#a37f12").unwrap(),
                    surface: hex_to_color("#93a1a1").unwrap(),
                    error: hex_to_color("#EE2F36").unwrap(),
                },
            },
        }
    }

    pub fn solarized_light() -> Theme {
        Theme {
            name: "Solarized Light".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#fdf6e3").unwrap(),
                    foreground: hex_to_color("#eee8d5").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#1A615B").unwrap(),
                    secondary: hex_to_color("#6E540C").unwrap(),
                    surface: hex_to_color("#95a3a2").unwrap(),
                    error: hex_to_color("#b80f15").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#2aa096").unwrap(),
                    secondary: hex_to_color("#a37f12").unwrap(),
                    surface: hex_to_color("#596e75").unwrap(),
                    error: hex_to_color("#EE2F36").unwrap(),
                },
            },
        }
    }

    pub fn outrun() -> Theme {
        Theme {
            name: "Outrun".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#0d0821").unwrap(),
                    foreground: hex_to_color("#110A2B").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#330442").unwrap(),
                    secondary: hex_to_color("#6e3e2e").unwrap(),
                    surface: hex_to_color("#484e81").unwrap(),
                    error: hex_to_color("#671a30").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#ff00ff").unwrap(),
                    secondary: hex_to_color("#ff963a").unwrap(),
                    surface: hex_to_color("#757dc8").unwrap(),
                    error: hex_to_color("#db2c3e").unwrap(),
                },
            },
        }
    }

    pub fn sort() -> Theme {
        Theme {
            name: "Sort".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#1c1c1c").unwrap(),
                    foreground: hex_to_color("#262626").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#2d3d2f").unwrap(),
                    secondary: hex_to_color("#3f4f56").unwrap(),
                    surface: hex_to_color("#8a8a8a").unwrap(),
                    error: hex_to_color("#713e40").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#81ca8c").unwrap(),
                    secondary: hex_to_color("#81abbd").unwrap(),
                    surface: hex_to_color("#bcbcbc").unwrap(),
                    error: hex_to_color("#FF474E").unwrap(),
                },
            },
        }
    }

    pub fn dracula() -> Theme {
        Theme {
            name: "Dracula".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#282a36").unwrap(),
                    foreground: hex_to_color("#353746").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#483e61").unwrap(),
                    secondary: hex_to_color("#386e50").unwrap(),
                    surface: hex_to_color("#a2a4a3").unwrap(),
                    error: hex_to_color("#A13034").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#bd94f9").unwrap(),
                    secondary: hex_to_color("#49eb7a").unwrap(),
                    surface: hex_to_color("#f4f8f3").unwrap(),
                    error: hex_to_color("#ff7ac6").unwrap(),
                },
            },
        }
    }

    pub fn ayu() -> Theme {
        Theme {
            name: "Ayu".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#1f2430").unwrap(),
                    foreground: hex_to_color("#232834").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#987a47").unwrap(),
                    secondary: hex_to_color("#315e6b").unwrap(),
                    surface: hex_to_color("#60697a").unwrap(),
                    error: hex_to_color("#712a34").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#ffcc66").unwrap(),
                    secondary: hex_to_color("#5ccfe6").unwrap(),
                    surface: hex_to_color("#cbccc6").unwrap(),
                    error: hex_to_color("#ff3333").unwrap(),
                },
            },
        }
    }

    pub fn gruvbox() -> Theme {
        Theme {
            name: "Gruvbox".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#282828").unwrap(),
                    foreground: hex_to_color("#3c3836").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#63612f").unwrap(),
                    secondary: hex_to_color("#695133").unwrap(),
                    surface: hex_to_color("#928374").unwrap(),
                    error: hex_to_color("#81302e").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#98971a").unwrap(),
                    secondary: hex_to_color("#d79921").unwrap(),
                    surface: hex_to_color("#ebdbb2").unwrap(),
                    error: hex_to_color("#cc241d").unwrap(),
                },
            },
        }
    }

    pub fn nord() -> Theme {
        Theme {
            name: "Nord".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#2e3440").unwrap(),
                    foreground: hex_to_color("#3b4252").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#485b60").unwrap(),
                    secondary: hex_to_color("#425066").unwrap(),
                    surface: hex_to_color("#9196a1").unwrap(),
                    error: hex_to_color("#894f5a").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#8fbcbb").unwrap(),
                    secondary: hex_to_color("#5e81ac").unwrap(),
                    surface: hex_to_color("#eceff4").unwrap(),
                    error: hex_to_color("#bf616a").unwrap(),
                },
            },
        }
    }

    pub fn horde() -> Theme {
        Theme {
            name: "Horde".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#161313").unwrap(),
                    foreground: hex_to_color("#211C1C").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#331E1F").unwrap(),
                    secondary: hex_to_color("#542A18").unwrap(),
                    surface: hex_to_color("#5E5B5A").unwrap(),
                    error: hex_to_color("#44282a").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#953e43").unwrap(),
                    secondary: hex_to_color("#e27342").unwrap(),
                    surface: hex_to_color("#9B9897").unwrap(),
                    error: hex_to_color("#953e43").unwrap(),
                },
            },
        }
    }

    pub fn alliance() -> Theme {
        Theme {
            name: "Alliance".to_string(),
            palette: ColorPalette {
                base: BaseColors {
                    background: hex_to_color("#03284D").unwrap(),
                    foreground: hex_to_color("#032C54").unwrap(),
                },
                normal: NormalColors {
                    primary: hex_to_color("#57460E").unwrap(),
                    secondary: hex_to_color("#57460E").unwrap(),
                    surface: hex_to_color("#7F8387").unwrap(),
                    error: hex_to_color("#5b3a5e").unwrap(),
                },
                bright: BrightColors {
                    primary: hex_to_color("#ac8a1b").unwrap(),
                    secondary: hex_to_color("#ac8a1b").unwrap(),
                    surface: hex_to_color("#D1D7DE").unwrap(),
                    error: hex_to_color("#953e43").unwrap(),
                },
            },
        }
    }
}

fn hex_to_color(hex: &str) -> Option<iced_native::Color> {
    let hash = &hex[0..1];
    let r = u8::from_str_radix(&hex[1..3], 16);
    let g = u8::from_str_radix(&hex[3..5], 16);
    let b = u8::from_str_radix(&hex[5..7], 16);

    if hash == "#" && r.is_ok() && g.is_ok() && b.is_ok() {
        return Some(iced_native::Color {
            r: r.unwrap() as f32 / 255.0,
            g: g.unwrap() as f32 / 255.0,
            b: b.unwrap() as f32 / 255.0,
            a: 1.0,
        });
    }

    None
}

impl PartialEq for Theme {
    fn eq(&self, other: &Self) -> bool {
        self.name == other.name
    }
}

impl PartialOrd for Theme {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.name.cmp(&other.name))
    }
}

impl Eq for Theme {}

impl Ord for Theme {
    fn cmp(&self, other: &Self) -> Ordering {
        self.name.cmp(&other.name)
    }
}

// Newtype on iced::Color so we can impl Deserialzer for it
struct Color(iced_native::Color);

mod de {
    use super::{hex_to_color, Color};
    use serde::de::{self, Error, Unexpected, Visitor};
    use std::fmt;

    pub fn deserialize_color_hex_string<'de, D>(
        deserializer: D,
    ) -> Result<iced_native::Color, D::Error>
    where
        D: de::Deserializer<'de>,
    {
        struct ColorVisitor;

        impl<'de> Visitor<'de> for ColorVisitor {
            type Value = Color;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a hex string in the format of '#09ACDF'")
            }

            #[allow(clippy::unnecessary_unwrap)]
            fn visit_str<E>(self, s: &str) -> Result<Self::Value, E>
            where
                E: Error,
            {
                if let Some(color) = hex_to_color(s) {
                    return Ok(Color(color));
                }

                Err(de::Error::invalid_value(Unexpected::Str(s), &self))
            }
        }

        deserializer.deserialize_any(ColorVisitor).map(|c| c.0)
    }
}

#[cfg(test)]
mod tests {
    use super::{de::deserialize_color_hex_string, Theme};
    use serde::de::value::{Error, StrDeserializer};
    use serde::de::IntoDeserializer;

    #[test]
    fn test_hex_color_deser() {
        let colors = [
            "AABBCC", "AABBCG", "#AABBCG", "#AABB091", "#AABBCC", "#AABB09",
        ];

        for (idx, color_str) in colors.iter().enumerate() {
            let deserializer: StrDeserializer<Error> = color_str.into_deserializer();

            let color = deserialize_color_hex_string(deserializer);

            if idx < 4 {
                assert!(color.is_err());
            } else {
                assert!(color.is_ok());
            }
        }
    }

    #[test]
    fn test_theme_yml_deser() {
        let theme_str = "---
        name: Test
        palette:
            primary: '#ABCDEF'
            secondary: '#000000'
            surface: '#FFFFFF'
            on_surface: '#012345'
            background: '#543210'
            error: '#FEDCBA'
        ";

        serde_yaml::from_str::<Theme>(theme_str).unwrap();
    }
}
