# Linux machine setup (for an agent)

Bring an Arch Linux machine to the state these dotfiles assume. A person may follow it too, but it is written for an agent with a shell on the machine.

## How to work

- **Inspect, then act.** For every section, first check whether it applies (the **Applies** line) and whether it is already done (the **Check** commands). Skip what is done; say what you skipped and why.
- **Adapt to the hardware.** The files under `system/linux/` come from one Lenovo IdeaPad. Device IDs, sysfs paths and the username (`chus`) may differ; find the real values on this machine and edit a copy, never the repo file, unless the change belongs in the repo for every machine.
- **Ask before root.** Anything that writes outside `$HOME` (copies into `/etc` or `/usr/local`, enabling system units, PAM) runs as root: show the user the exact files and their diff against what is installed, and wait for an OK. Batch these asks per section rather than per file.
- **PAM can lock the user out.** Before touching `/etc/pam.d`, make sure a root shell stays open, and test login in a second session before closing it.
- **Verify, then report.** Run each section's **Check** after acting. Finish with a short report: done, skipped (and why), and anything that needs the user (logins, pairing, a reboot).

Repo paths below are relative to the repo root (usually `~/.dotfiles`). `system/linux/<path>` installs to `/<path>`: for example, `system/linux/etc/keyd/default.conf` goes to `/etc/keyd/default.conf`. Install with `install -Dm644` (or `-Dm755` for files under `usr/local/bin` and `usr/local/lib`).

## 1. Dotfiles

**Applies:** always.

1. Clone with submodules: `git clone --recurse-submodules git@github.com:chrischriscris/my-dotfiles.git ~/.dotfiles`. On an existing clone, `git pull --rebase` and `git submodule update --init`.
2. Install GNU Stow and run `~/.dotfiles/install`. It links `common/` and `linux/` into `$HOME` file by file.
3. If stow aborts on a conflict (a regular file where a link should go), compare that file with the repo copy. If they're identical, or the repo copy is newer, remove the local file (back it up first) and rerun. If the local copy has changes the repo lacks, show the user the diff and ask which one wins; `stow --adopt` pulls the local version into the repo.

**Check:** `./install` exits 0; `readlink ~/.config/hypr/hyprland.lua` points into the repo.

## 2. Packages

**Applies:** always.

Install what the configs call. The quickest way to find gaps: every command in the `hl.on("hyprland.start", …)` block and the `hl.dsp.exec_cmd(…)` binds of `linux/.config/hypr/hyprland.lua`, plus the scripts in `common/bin` (`jq`, `sqlite3`, `pactl`, `notify-send`, `brightnessctl`, `rfkill`). Core set: `hyprland` (0.57 or newer: the config is Lua), `hypridle`, `swaylock`, `quickshell`, `kitty`, `vicinae`, `hokum`, `wlsunset`, `ibus`, `polkit-gnome`, `keyd`, `stow`, `github-cli`. Use `paru` for AUR packages.

**Check:** `command -v` succeeds for each autostart command; `Hyprland --verify-config` prints `config ok`.

## 3. Desktop defaults

**Applies:** a machine with a desktop session.

- **XDG folders** (`~/.config/user-dirs.dirs`) are per machine and not in the repo. If there is a separate data drive (this machine uses `/mnt/hdd`), point Downloads, Documents, Music, Pictures and Videos there, and add `XDG_PROJECTS_DIR="$HOME/Projects"`. Then write `enabled=False` to `~/.config/user-dirs.conf`. Otherwise `xdg-user-dirs-update` runs at login, and if the drive hasn't mounted yet (it's `nofail` in fstab), it resets every folder to `$HOME/`.
- **Default browser:** `xdg-settings set default-web-browser zen.desktop`.
- **Notifications:** hokum is the notification server; `systemctl --user enable hokum.service`. Its theme is `theme "pill"` in `~/.config/hokum/config.kdl` (hokum's settings window owns that file, so it is not stowed).
- **AI usage widget:** install the CodexBar CLI as described in `docs/quickshell.md`.

**Check:** `xdg-user-dir DOWNLOAD` shows the intended folder; `xdg-settings get default-web-browser` prints `zen.desktop`.

## 4. Laptop hardware

**Applies:** the IdeaPad-specific parts only on a Lenovo IdeaPad (`/sys/bus/platform/drivers/ideapad_acpi` exists); keyd on any machine.

| File | What it does | Adapt |
|---|---|---|
| `etc/keyd/default.conf` | Caps Lock is Esc on tap and Ctrl on hold; Esc becomes Caps Lock. It leaves the IdeaPad hotkey devices (`0000:0000`, `0000:0006`) alone, because keyd drops key codes above 255. | Check `keyd monitor` for the hotkey device IDs. |
| `etc/udev/rules.d/90-backlight-access.rules` | `wheel` can write the backlight directly, which keeps `laptop-hotkey`'s brightness glide smooth. | None; the user must be in `wheel`. |
| `etc/udev/rules.d/90-webcam-toggle.rules` | `wheel` can (de)authorize the built-in camera for the Fn+F8 toggle. | The USB ID (`5986:2130`) is this camera's; find the real one with `lsusb`. |
| `etc/udev/rules.d/90-ideapad-fnlock.rules` | F1–F12 send hotkeys first; hold Fn for plain F-keys. | IdeaPad only. |
| `etc/udev/rules.d/70-libfprint-elanmoc2-0c57.rules` | Lets the local user use the ELAN `04f3:0c57` fingerprint reader. | Only if `lsusb` shows that reader. |

Install, then run `sudo systemctl enable --now keyd`, `sudo keyd reload`, `sudo udevadm control --reload` and `sudo udevadm trigger`.

**Fingerprint login with an encrypted home** (`etc/pam.d/gdm-fingerprint` and `usr/local/bin/fp-home-unlocked`). This applies only with GDM, fprintd and an fscrypt-encrypted home. Fingerprint login can't unlock fscrypt, so the PAM file refuses it while the home is locked, and GDM falls back to the password. Follow the PAM rule in "How to work". Enroll a finger with `fprintd-enroll`.

**Check:**
- `stat -c %G /sys/class/backlight/*/brightness` prints `wheel`.
- `~/bin/laptop-hotkey brightness up` changes the brightness.
- `~/bin/laptop-hotkey camera` toggles the camera instead of saying "unavailable".
- Caps Lock behaves as Esc and Ctrl.

## 5. Server mode

**Applies:** the machine stays on as a server (lid closed, reached remotely).

- **`usr/local/bin/outage-guard`** with **`etc/systemd/system/outage-guard.service`**: on battery with the lid closed, it stays up while the battery and the internet hold. Otherwise it suspends, wakes on an RTC alarm to check for AC, and shuts down cleanly when the battery is critical. It also caps charging at 80% through the IdeaPad conservation mode. The sysfs paths at the top of the script (`ADP0`, `BAT0`, `LID0`, `VPC2004:00`) are this laptop's; check them under `/sys/class/power_supply` and `/proc/acpi/button/lid`. Enable it with `sudo systemctl enable --now outage-guard.service`.
- **`etc/systemd/system/pacman-update.{service,timer}`**: runs `pacman -Syu` on Saturdays at 10:00. Enable it with `sudo systemctl enable --now pacman-update.timer`.
- **Logins without a desktop:** run `loginctl enable-linger "$USER"`, so the user services in sections 6 and 7 run at boot.

**Check:** `systemctl is-active outage-guard.service` and `systemctl is-enabled pacman-update.timer`; `loginctl show-user "$USER" -p Linger` prints `Linger=yes`.

## 6. T3 Code server

**Applies:** the user wants T3 Code on this machine. It runs headless; the desktop app is not autostarted.

1. Install `t3code-nightly-bin` from the AUR. It provides the `t3` CLI.
2. The user runs `t3 up` in a terminal and picks remote access (T3 Connect is the usual choice). It installs and starts `t3code.service`, a user service. It restarts any running T3 server, so don't run it from inside a T3 Code session.
3. **Auto-updater:** `docs/t3code.md` explains how it works.
   - Install these four files:
     - `etc/sysusers.d/t3code-build.conf`, then run `systemd-sysusers`.
     - `usr/local/lib/t3code-update/install-latest` (mode 755).
     - `etc/systemd/system/t3code-update.service`.
     - `etc/polkit-1/rules.d/50-t3code-update.rules`. Change `subject.user == "chus"` if the username differs.
   - Run `sudo systemctl daemon-reload`.
   - Run `systemctl --user enable --now t3code-autoupdate.timer`. The unit is already stowed.
4. **VPN bypass** (`usr/local/bin/t3connect-bypass` with `etc/systemd/system/t3connect-vpn-bypass.{service,timer}`): this applies only when a VPN (WireGuard, NetworkManager) may come up on this machine. It keeps the Cloudflare tunnel edge that T3 Connect uses outside the VPN. Enable it with `sudo systemctl enable --now t3connect-vpn-bypass.timer`.

**Check:**
- `t3 status` shows the service installed.
- `systemctl --user is-active t3code.service` and `systemctl --user is-enabled t3code-autoupdate.timer`.
- `t3code-update --when-idle` finishes with either "deferred" or an up-to-date message.

## 7. User services

**Applies:** always. The units are stowed into `~/.config/systemd/user`; enable the ones that fit.

- **`bgchange.timer`**: rotates the wallpaper every 15 minutes. Run `systemctl --user enable --now bgchange.timer`.
- **`ready-ops.timer`**: opens the Ensolvers Ops page on weekdays at 14:00. It's for work machines only. Run `systemctl --user enable --now ready-ops.timer`.

**Check:** `systemctl --user list-timers` lists each enabled timer with a next run.

## 8. Hermes Agent (WhatsApp bot)

**Applies:** only if this machine should run the bot. **Only one machine may run the gateway at a time.** Two gateways sharing a WhatsApp session keep logging each other out: the bridge log, `~/.hermes/whatsapp/bridge.log`, fills with `Connection closed (reason: 440)`.

1. Install Hermes Agent with its installer, restore `~/.hermes` (config, `.env`, WhatsApp session) from the old machine, or pair again.
2. Model IDs must be ones the provider lists. For OpenCode Go, list them with `curl -s https://opencode.ai/zen/go/v1/models | jq -r '.data[].id'`. Unlisted aliases can stop working; `deepseek-flash` started failing with "Model is unavailable" on 2026-10-27.
3. Run `hermes gateway install`, then `hermes gateway start`. Then stop and disable the gateway everywhere else. On macOS that's `hermes gateway stop`, then `launchctl disable gui/$(id -u)/ai.hermes.gateway`.

**Check:** `hermes gateway status` is running; after a minute, the bridge log has no new `reason: 440` lines.

## 9. Final report

List each section with its result: done, already done, skipped (and why), or needs the user. Include anything left for a human: `t3 up`, Hermes pairing, enrolling a fingerprint, rebooting to test `outage-guard`.
