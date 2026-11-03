#!/bin/bash
# One-time root setup for t3code-update:
#   sudo ~/.local/share/t3code-update/install-system.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
here=$(dirname "$(readlink -f "$0")")/system

install -Dm644 "$here/t3code-build.conf" /etc/sysusers.d/t3code-build.conf
systemd-sysusers /etc/sysusers.d/t3code-build.conf
install -Dm755 "$here/install-latest" /usr/local/lib/t3code-update/install-latest
install -Dm644 "$here/t3code-update.service" /etc/systemd/system/t3code-update.service
install -Dm644 "$here/50-t3code-update.rules" /etc/polkit-1/rules.d/50-t3code-update.rules
systemctl daemon-reload
systemctl --user -M "${SUDO_USER:?run via sudo}@" enable --now t3code-autoupdate.timer
echo "Installed. Try: t3code-update"
