#!/usr/bin/env bash
set -euo pipefail

BIN="${BINDIR:-$HOME/.local/bin}"
UNITS="$HOME/.config/systemd/user"
DESKTOP_DIR="${DESKTOP_DIR:-$HOME/.local/share/applications}"
ICON_ROOT="${ICON_ROOT:-$HOME/.local/share/icons/hicolor}"

purge=0
tools=()
for arg in "$@"; do
  if [ "$arg" = "--purge" ]; then purge=1; else tools+=("$arg"); fi
done
[ ${#tools[@]} -eq 0 ] && tools=(appimenu appfolder-sync)

for tool in "${tools[@]}"; do
  systemctl --user disable --now "$tool.service" "$tool.path" "$tool.timer" 2>/dev/null || true
  rm -f "$UNITS/$tool.service" "$UNITS/$tool.path" "$UNITS/$tool.timer"
  rm -f "$BIN/$tool"
done
systemctl --user daemon-reload
printf 'removed %s units and binaries\n' "${tools[*]}"

if [ "$purge" -eq 1 ]; then
  removed=0
  for entry in "$DESKTOP_DIR"/appimage-*.desktop "$DESKTOP_DIR"/appfolder-*.desktop; do
    [ -e "$entry" ] || continue
    grep -Eq '^X-(AppImage|AppFolder)-Sync=true$' "$entry" || continue
    icon=$(awk -F= '$1=="Icon"{print $2; exit}' "$entry")
    case "$icon" in "$ICON_ROOT"/*) rm -f "$icon" ;; esac
    rm -f "$entry"
    removed=$((removed + 1))
  done
  gtk-update-icon-cache -q -t -f "$ICON_ROOT" 2>/dev/null || true
  printf 'purged %s generated entry(s)\n' "$removed"
fi
