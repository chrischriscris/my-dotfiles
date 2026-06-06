# Dotfiles

Dotfiles for Linux and macOS, managed with GNU Stow.

## Install

```sh
git clone --recurse-submodules git@github.com:chrischriscris/my-dotfiles.git ~/.dotfiles
~/.dotfiles/install
```

The installer detects the operating system and installs two stable Stow
packages:

- `common`: configuration shared by Linux and macOS
- `linux` or `macos`: platform-specific configuration

Adding a dotfile does not require changing the installer. Put it at the path it
should have below `common/`, `linux/`, or `macos/`, then run `./install` again.

The installer uses `--no-folding`, so applications can create caches and state
beside managed files without writing them into this repository.

For example, `common/.config/nvim/init.lua` is linked to
`~/.config/nvim/init.lua`.

Existing regular files at target paths can cause Stow conflicts. Back them up
or move them into the appropriate package before the first installation.
