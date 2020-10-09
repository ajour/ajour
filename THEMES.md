# Themes

Ajour supports custom user generated themes.

To add a new theme, save it as a YAML file. E.g. `example.yml`.

And place it in a folder titled `themes`, in this location:

macOS / Linux:
- `$HOME/.config/ajour/themes`

Windows:
- `%APPDATA%\ajour\themes`


Example of `example.yml`

```yaml
name: "Example"
palette:
  base:
    background: '#111111'
    foreground: '#161616'
  normal:
    primary: '#3f2b56'
    secondary: '#4a3c1c'
    surface: '#828282'
    error: '#992B2B'
  bright:
    primary: '#BA84FC'
    secondary: '#ffd03c'
    surface: '#E0E0E0'
    error: '#C13047'
```
