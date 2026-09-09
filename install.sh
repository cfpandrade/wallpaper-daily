#!/usr/bin/env bash
# Installs wallpaper-daily into the current user account.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
UNIT_DIR="${HOME}/.config/systemd/user"
CONFIG="${HOME}/.config/wallpaper-daily.json"

mkdir -p "$BIN_DIR" "$UNIT_DIR"

install -m 755 "$SRC/wallpaper-daily" "$BIN_DIR/wallpaper-daily"
install -m 644 "$SRC/systemd/wallpaper-daily.service" "$UNIT_DIR/wallpaper-daily.service"
install -m 644 "$SRC/systemd/wallpaper-daily.timer" "$UNIT_DIR/wallpaper-daily.timer"

if [ ! -f "$CONFIG" ]; then
    install -m 644 "$SRC/wallpaper-daily.example.json" "$CONFIG"
    echo "Wrote a starter config to $CONFIG - edit the connectors before first run."
else
    echo "Kept the existing config at $CONFIG."
fi

systemctl --user daemon-reload
systemctl --user enable --now wallpaper-daily.timer

echo
echo "Installed. Useful next steps:"
echo "  wallpaper-daily --list-groups     # check the detected monitors"
echo "  wallpaper-daily --dry-run         # preview without touching the desktop"
echo "  systemctl --user list-timers wallpaper-daily.timer"
