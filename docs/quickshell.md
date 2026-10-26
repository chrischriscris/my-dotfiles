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

## Validation

Check workspace clicks, tray, calendar, notification actions/dismissal, volume/brightness, dock app launches, and popup dismissal. Confirm Alt+D, window shortcuts, locking, and suspend/resume. At the next login, confirm there is one bar and one notification server. Test additional monitors when connected.

Logs: `~/.local/state/desktop-shell/quickshell.log`.
