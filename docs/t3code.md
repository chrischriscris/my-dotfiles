# T3 Code server and auto-update (Linux)

T3 Code runs headless as the `t3code.service` user service, reached remotely through T3 Connect (or the LAN). Set it up with `t3 up`; the Hyprland config does not start the desktop app.

`t3code-update` (in `linux/.local/bin`) keeps it current, and `t3code-autoupdate.timer` runs it every 30 minutes with `--when-idle`:

1. It installs the latest `t3code-nightly-bin` from the AUR through the root `t3code-update.service`. That package provides the `t3` CLI.
2. It runs `t3 update --yes`, which updates the server's own copy under `~/.t3/runtime` and restarts it, but only while no agent run or T3 terminal command is in progress. Otherwise it waits for the next tick.

`t3code-update restart` restarts the server without updating; `--no-restart` updates only the package.

## New machine

Section 6 of [`setup/linux.md`](../setup/linux.md) covers it: the root half (the `t3code-build` user, `t3code-update.service`, the polkit rule) lives in `system/linux/`, and `t3 up` installs the server.

The root service builds the package as the unprivileged `t3code-build` user, so nothing your account (or an agent running as you) can write reaches `pacman -U`. The polkit rule only lets `chus` start that one service.
