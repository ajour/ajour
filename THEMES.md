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
    background: '#6d6875'
    foreground: '#777180'
  normal:
    primary: '#664A50'
    secondary: '#855859'
    surface: '#C9A28D'
    error: '#661A1F'
  bright:
    primary: '#b4838d'
    secondary: '#e5989b'
    surface: '#fecdb2'
    error: '#e63a46'
```
