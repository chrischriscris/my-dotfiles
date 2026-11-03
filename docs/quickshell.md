# Quickshell desktop adaptation

The installed configuration lives in `~/.dotfiles/linux/.config/quickshell`, linked from `~/.config/quickshell`. Original desktop files and Git state are preserved in the sibling `desktop-backup-2026-09-30` directory. Its `dotfiles` directory is a complete snapshot, including the existing staged Vicinae changes.

## Install packages and activate

Run these from your Hyprland desktop terminal:

```sh
sudo pacman -S --needed quickshell papirus-icon-theme
bash '/mnt/hdd/Downloads/Telegram Desktop/desktop-adaptation/finish.sh'
```

The finish script validates Hyprland syntax, stops Waybar/SwayNC, and previews Quickshell. It changes the startup configuration only after Quickshell responds to IPC. If startup fails, it restores the old panels and prints the log. Quickshell's runtime supervisor also restores the panels after a crash.

Alt+D keeps Vicinae. Alt+Shift+N toggles notifications. Alt+Shift+R reloads Hyprland; Quickshell hot-reloads its QML files. Hover at the right screen edge for the dock. Alt+Shift+B still selects a random wallpaper; login uses the supplied gold-watch wallpaper. swaylock and laptop settings stay unchanged.

## Restore the previous desktop

```sh
bash '/mnt/hdd/Downloads/Telegram Desktop/desktop-backup-2026-09-30/restore.sh'
```

Restore overwrites only the Hyprland configuration and wallpaper script changed by this adaptation, stops this Quickshell configuration, reloads Hyprland, and restarts Waybar/SwayNC. It leaves Quickshell files and packages available. Keep the backup directory for future restoration; config snapshots include symlinks to their original repository paths, while the `dotfiles` snapshot contains the actual saved files.

## AI usage widget

The bar shows Claude, Codex and OpenCode Go quota from the [CodexBar](https://github.com/steipete/CodexBar) CLI (`AiUsage.qml`, `AiUsagePopup.qml`). Like CodexBar's macOS menu bar, it shows one provider: the selected popup tab, or the first provider on Overview. The selection persists in the ignored `ai-usage-state.json`. The number is the quota left in that provider's tightest window. Click it for a popup laid out like CodexBar's macOS menu: per-window bars with pace, local spend, and dashboard/status links. Middle-click refreshes; it also polls every five minutes.

Install the CLI where the widget expects it, outside `PATH` so it never collides with another `codexbar`. Rerun to upgrade:

```sh
(
set -eu
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
gh release download --repo steipete/CodexBar --pattern "CodexBarCLI-*-linux-$(uname -m).tar.gz*"
sha256sum -c CodexBarCLI-*.sha256
mkdir -p ~/.local/lib/codexbar-cli
tar -xzf CodexBarCLI-*.tar.gz -C ~/.local/lib/codexbar-cli
~/.local/lib/codexbar-cli/codexbar --version
)
```

The CLI reuses the Claude Code, Codex and OpenCode logins. OpenCode Go needs CLI 0.82 or newer to read the real quota from the OpenCode login; older versions only estimate it from local logs. Spend is estimated from this machine's local logs only. Without the CLI the bar shows a red `AI !`. To track other providers, add any `codexbar --provider` id to `providerIds` in `AiUsagePopup.qml`.

## Validation

Check workspace clicks, tray, calendar, notification actions/dismissal, volume/brightness, dock app launches, and popup dismissal. Confirm Alt+D, window shortcuts, locking, and suspend/resume. At the next login, confirm there is one bar and one notification server. Test additional monitors when connected.

Logs: `~/.local/state/desktop-shell/quickshell.log`.
