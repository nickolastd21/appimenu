#!/usr/bin/env bash
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${BINDIR:-$HOME/.local/bin}"
UNITS="$HOME/.config/systemd/user"

mkdir -p "$BIN" "$UNITS"
install -m 755 "$src/appimenu" "$BIN/appimenu"
for unit in service path timer; do
  install -m 644 "$src/units/appimenu.$unit" "$UNITS/appimenu.$unit"
done

systemctl --user daemon-reload
systemctl --user enable appimenu.service appimenu.path appimenu.timer
systemctl --user start appimenu.path appimenu.timer
"$BIN/appimenu"

printf 'installed %s/appimenu and enabled appimenu.{service,path,timer}\n' "$BIN"
printf 'drop AppImages into %s and the menu updates by itself\n' "${APPIMAGE_DIR:-$HOME/AppImages}"
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) printf 'note: %s is not in PATH, run it as %s/appimenu\n' "$BIN" "$BIN" ;;
esac
