# Third Party Repositories

## Cargo
```sh
cargo install ajour --git https://github.com/casperstorm/ajour.git
```

## [Homebrew](https://brew.sh/)
```sh
brew cask install ajour
```

# Manual Installation

1. [Prerequisites](#prerequisites)
    1. [Source Code](#clone-the-source-code)
    2. [Rust Compiler](#install-the-rust-compiler-with-rustup)
    3. [Dependencies](#dependencies)
        1. [Debian/Ubuntu](#debianubuntu)
        2. [Other](#other)
2. [Building](#building)
    1. [Linux/Windows](#linux--windows)
    2. [macOS](#macos)
        
        
## Prerequisites

### Clone the source code

Before compiling Ajour, you need the source code

```sh
git clone https://github.com/casperstorm/ajour.git
cd ajour
```

### Install the Rust compiler with `rustup`

Ensure you have installed the Rust compiler [`rustup.rs`](https://rustup.rs/).

### Dependencies

Depending on what system you are building the source code on, additional dependencies might be required.

#### Debian/Ubuntu

```sh
sudo apt install build-essential cmake libxft-dev libssl-dev libx11-dev
```

#### Other

If your system has extra dependencies, and they are not listed here please create a [pull-request](https://github.com/casperstorm/ajour/pulls) or open a [issue](https://github.com/casperstorm/ajour/issues).

## Building

### Linux / Windows

```sh
cargo build --release
```

### macOS

```sh
make app
cp -r target/release/osx/Ajour.app /Applications/
```
