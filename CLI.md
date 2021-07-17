<!-- markdownlint-disable MD024 -->

# CLI

Ajour accepts arguments and can even run certain operations on the command line
without launching the GUI, such as updating all addons. This makes it possible to
manage your addon collection through scripts and scheduling.

You can pass `--help` to see a full list of supported flags, options and commands.

```text
USAGE:
    ajour [OPTIONS] [SUBCOMMAND]

FLAGS:
    -h, --help       Prints help information
    -V, --version    Prints version information

OPTIONS:
        --aa <antialiasing>        Enable / Disable Anti-aliasing (true / false)
        --data <data-directory>    Path to a custom data directory for the app

SUBCOMMANDS:
    backup     Backup your WTF, AddOns, and/or Ajour config folders
    install    Install an addon from the command line
    update              Update all addons, WeakAura and Plater auras
    update-addons       Update all addons
    update-auras        Update all WeakAura and Plater auras
    path-add            Add a World of Warcraft path to known directories
```

## Options

You can attach different options together with a [subcommand](#subcommands).
Currently available options:

```sh
# Enable or disable anti-aliasing.
# [default: true]

--aa <true/false>

# Path to a custom data directory for the app.
# [default]:
# macOS/Linux: $HOME/.config/ajour
# Windows: %APPDATA%\ajour

--data <data-directory>
```

## Subcommands

### Backup

Backup your WTF, AddOns, and/or Ajour config folders.

```sh
USAGE:
    ajour backup [OPTIONS] <destination>

OPTIONS:
    # Folder to backup
    # [default: all]
    # [possible values: all, wtf, addons, config, screenshots, fonts]

    -b, --backup-folder <backup-folder>

    # Space separated list of flavors to include in backup.
    # If ommited, all flavors will be included
    # [possible values: retail, ptr, beta, classic, classic_ptr]

    -f, --flavors <flavors>

    # Compression format to use
    # [default: zip]
    # [possible values: zip, zstd]

    -c, --compression-format <compression-format>

    # Compression level to use, when using zstd format
    # [default: 0]

    -l, --level <level>


ARGS:
    # folder to save backups to

    <destination>
```

#### Example

```sh
# Backup both WTF and AddOns folder for all flavors

ajour backup -b both

# Backup the WTF folder for Retail

ajour backup -b wtf -f retail /tmp
```

### Install

Install an addon from the command line.

```sh
USAGE:
    ajour install <flavor> <url>

ARGS:
    # Flavor to install addon under
    # [possible values: retail, ptr, beta, classic, classic_ptr]

    <flavor>

    # Source url
    # [Github & Gitlab currently supported]

    <url>
```

#### Example

```sh
# Install Hekili from Github

ajour install retail https://github.com/Hekili/hekili
```

### Update

Update all addons and/or WeakAuras from the command line then exit.

```sh
USAGE:
    ajour update
    ajour update-addons
    ajour update-auras
```

#### Example

```sh
# Update all addons and WeakAuras

ajour update

# Update all addons

ajour update-addons

# Update all WeakAura and Plater auras

ajour update-auras
```

### Path Add

Add World of Warcraft path to known directories.

```sh
USAGE:
    ajour path-add <path> [flavor]

ARGS:
    # Path to the World of Warcraft directory

    <path>

    # Flavor to use from the path. If none, we use all we find
    # [possible values: retail, ptr, beta, classic, classic_ptr]

    [flavor]
```

#### Example

```sh
# Add retail from ./World of Warcraft

ajour path-add ./World of Warcraft retail

# Add all known flavors from ./World of Warcraft

ajour path-add ./World of Warcraft
```
