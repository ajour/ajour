# Install

## Third Party Repositories

### Cargo

```sh
cargo install ajour
```

### [Homebrew](https://brew.sh/)

```sh
brew cask install ajour
```

### [Chocolatey](https://chocolatey.org/)

#### Standard

```cmd
choco install ajour
```

#### OpenGL

```cmd
choco install ajour-opengl
```

## Manual Installation

1. [Prerequisites](#prerequisites)
    1. [Source Code](#clone-the-source-code)
    2. [Rust Compiler](#install-the-rust-compiler-with-rustup)
    3. [Dependencies](#dependencies)
        1. [Debian/Ubuntu](#debianubuntu)
        2. [Other](#other)
2. [Building](#building)
    1. [Linux/Windows](#linux--windows)
    2. [macOS](#macos)
    3. [Compatibility build](#compatibility-build)

### Prerequisites

#### Clone the source code

Before compiling Ajour, you need the source code

```sh
git clone https://github.com/casperstorm/ajour.git
cd ajour
```

#### Install the Rust compiler with `rustup`

Ensure you have installed the Rust compiler [`rustup.rs`](https://rustup.rs/).

#### Dependencies

Depending on what system you are building the source code on, additional dependencies
might be required.

##### Debian/Ubuntu

```sh
sudo apt install build-essential cmake libxft-dev libssl-dev libx11-dev
```

##### Other

If your system has extra dependencies, and they are not listed here please create
a [pull-request](https://github.com/casperstorm/ajour/pulls) or open a [issue](https://github.com/casperstorm/ajour/issues).

### Building

#### Linux / Windows

```sh
cargo build --release
```

The application executable will be built to

```sh
target/release/ajour
```

#### macOS

```sh
make app
cp -r target/release/osx/Ajour.app /Applications/
```

#### Compatibility build

Ajour is built using `wgpu` which has [requirements](https://github.com/gfx-rs/wgpu#supported-platforms)
which might not be achievable by all.
It is therefore possible to build a compatability build using `opengl`
as renderer instead. Performance should be close to 1:1.

To build a compatability build add the flag `--no-default-features --features opengl`

```sh
cargo build --release --no-default-features --features opengl
```
