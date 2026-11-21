#!/usr/bin/env bash
set -euo pipefail

BIN="${BINDIR:-$HOME/.local/bin}"
UNITS="$HOME/.config/systemd/user"
DESKTOP_DIR="${DESKTOP_DIR:-$HOME/.local/share/applications}"
ICON_ROOT="${ICON_ROOT:-$HOME/.local/share/icons/hicolor}"

systemctl --user disable --now appimenu.service appimenu.path appimenu.timer 2>/dev/null || true
rm -f "$UNITS/appimenu.service" "$UNITS/appimenu.path" "$UNITS/appimenu.timer"
rm -f "$BIN/appimenu"
systemctl --user daemon-reload

printf 'removed appimenu units and %s/appimenu\n' "$BIN"

if [ "${1:-}" = "--purge" ]; then
  removed=0
  for entry in "$DESKTOP_DIR"/appimage-*.desktop; do
    [ -e "$entry" ] || continue
    grep -q '^X-AppImage-Sync=true$' "$entry" || continue
    icon=$(awk -F= '$1=="Icon"{print $2; exit}' "$entry")
    case "$icon" in "$ICON_ROOT"/*) rm -f "$icon" ;; esac
    rm -f "$entry"
    removed=$((removed + 1))
  done
  gtk-update-icon-cache -q -t -f "$ICON_ROOT" 2>/dev/null || true
  printf 'purged %s generated entry(s)\n' "$removed"
fi
