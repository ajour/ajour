<div align="center">
  
<h1>Ajour</h1>

![Continuous integration](https://github.com/casperstorm/ajour/workflows/Continuous-integration/badge.svg)
![Security audit](https://github.com/casperstorm/ajour/workflows/Security%20audit/badge.svg)
[![Discord Server](https://img.shields.io/discord/757155234500968459?color=blue&label=Discord%20Chat&logo=discord&logoColor=white&style=flat-square)](https://discord.gg/4838t9R)

![](./resources/screenshots/ajour-banner.jpg)

</div>

### Table of Contents
- [Introduction](#introduction)
- [Screenshots](#screenshots)
- [Features](#features)
- [Install](#install)
- [Themes](#themes)
- [Contribute](#contribute)
- [FAQ](#faq)
- [Acknowledgement](#acknowledgement)

## Introduction
Ajour is a World of Warcraft addon manager written in Rust with a strong focus on performance and simplicity. The project is completely advertisement free, privacy respecting and open source. Ajour currently supports Windows, macOS and Linux.

<div align="center">

[![Download Button](./resources/download-button.png)](https://github.com/casperstorm/ajour/releases)

</div>

## Screenshots

<p align="center">
  <img width="410"
       alt="Ajour with default Dark theme"
       src="./resources/screenshots/ajour-0.3.0a.png">
    <img width="410"
       alt="Ajour with Solarized Light theme"
       src="./resources/screenshots/ajour-0.3.0b.png">
</p>

## Features

- Addons will be parsed automatically and resolved from multiple repositories:
  - [tukui.org](https://www.tukui.org/)
  - [curse](https://www.curseforge.com/wow/addons)
- Support for release channels, so it's possible to select either `alpha`, `beta` or `stable` for each addon
- Bulk addon update without any limitations
- Remove addons and their dependencies
- Ignore addons you don't want to update
- Supports both Retail and Classic version of World of Warcraft
- [Create your own custom themes](./THEMES.md)
- Ability to backup your whole UI, including all settings from WTF

## Install 

Prebuilt binaries for macOS and Windows can be downloaded from the [GitHub releases](https://github.com/casperstorm/ajour/releases) page.

For everyone else, a detailed instruction can be found [here](https://github.com/casperstorm/ajour/blob/master/INSTALL.md).

## Themes

<p align="left">
  <img width="200"
       alt="Ajour with Ayu Dark theme"
       src="./resources/themes/ayu-dark.png">
    <img width="200"
       alt="Ajour with Gruvbox Dark theme"
       src="./resources/themes/gruvbox-dark.png">
      <img width="200"
       alt="Ajour with Nord theme"
       src="./resources/themes/nord.png">
    <img width="200"
       alt="Ajour with Outrun theme"
       src="./resources/themes/outrun.png">
</p>

Ajour supports Dark (default) and Light themes out of the box. Custom themes can also be added and selected inside the application.  
Find instructions and a variety of custom themes [here](./THEMES.md).

## Contribute
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

Ajour wouldn't be here without your help.  
I welcome contributions of any kind, because together we can make Ajour even better.

+ [Let me know](https://github.com/casperstorm/ajour/issues/new?assignees=&labels=type%3A+feature&template=feature_request.md&title=) if you are missing a vital feature.
+ I love [pull requests](https://github.com/casperstorm/ajour/pulls) and [bug reports](https://github.com/casperstorm/ajour/issues/new?assignees=&labels=type%3A+bug&template=bug_report.md&title=).
+ Don't hesitate to [tell me my Rust programming is bad](https://github.com/casperstorm/ajour/issues/new), but please tell me
  why.
+ Join our [our Discord server](https://discord.gg/4838t9R) and say hey.

## FAQ

**_When will you release Ajour / be feature complete?_**

The plan is to have a stable, polished release in time for the Shadowlands launch. 10.27.20.

**_What features are planned?_**

We have a roadmap [here](https://github.com/casperstorm/ajour/projects/2).

**_What should I do if some addon isn't showing or updating correctly?_**

We encourage you to raise an issue and tell us all about it! We want Ajour to support as many addons as possible. This means a lot of edge cases. A list of addons with known issues can be found in the [wiki](https://github.com/casperstorm/ajour/wiki/Addons-with-known-issues).

**_macOS won't let me open the app, what should I do?_**

Instead of double clicking it, right click and choose "Open". That should successfully open Ajour.

**_Where does Ajour store its configuration?_**

Ajour will generate a folder in the following directory:

macOS / Linux:
- `$HOME/.config/ajour`

Windows:

- `%APPDATA%\ajour`

Inside this folder Ajour will keep a configuration file for storing different user settings, a log file with events from the last session, a fingerprint file with hashed fingerprints for each addon and a theme folder with custom themes.

**_Why Rust?_**

We wanted to create an application which natively compiles to both Windows, Linux and macOS while at the same time is as performant and reliable as possible.

## Other addon managers

If Ajour isn't your cup of tea, then [Ogri'la](https://github.com/ogri-la) has done a great job of creating a curated [list of other addon managers](https://ogri-la.github.io/wow-addon-managers/).

## Acknowledgement

- [tarkah](https://github.com/tarkah) for the many great contributions. 
- [Rasmus Nielsen](https://rasmusnielsen.dk/) for the Ajour icon.
- [Rune Seir](https://instagram.com/rseir/) for the Ajour banner.
- [mlablah](https://github.com/mlablah) for the architectural discussions.

## License

Ajour is released under the [MIT License.](https://github.com/casperstorm/ajour/blob/master/LICENSE)
