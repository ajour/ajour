# CLI

It is possible to interact with Ajour through command line arguments.
To get a overview you can use `ajour --help`:

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
    backup     Backup your WTF and/or AddOns folders
    install    Install an addon from the command line
    update     Update all addons from the command line then exit
```

## Options

You can attatch different options together with a [subcommand](#subcommands).  
Currently available options:


```sh
# Enable or disable anti-aliasing.
# Default: true

--aa <true/false>

# Path to a custom data directory for the app.
# Default:
# macOS/Linux: $HOME/.config/ajour
# Windows: %APPDATA%\ajour

--data <data-directory>
```

## Subcommands

### Backup

Backup your WTF and/or AddOns folders.

```text
USAGE:
    ajour backup [OPTIONS] <destination>

OPTIONS:
    -b, --backup-folder <backup-folder>    folder to backup [default: both]  [possible values: both, wtf, addons]
    -f, --flavors <flavors>...             space separated list of flavors to include in backup. If ommited, all flavors
                                           will be included [possible values: retail, ptr, beta, classic, classic_ptr]
ARGS:
    <destination>                          folder to save backups to
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

```text
USAGE:
    ajour install <flavor> <url>

ARGS:
    <flavor>    flavor to install addon under [possible values: retail, ptr, beta, classic, classic_ptr]
    <url>       source url [Github & Gitlab currently supported]
```

#### Example
```sh
# Install Hekili from Github

ajour install retail https://github.com/Hekili/hekili
``` 

### Update

Update all addons from the command line then exit.

```text
USAGE:
    ajour update
```

#### Example

```sh
# Update all addons

ajour update
```
