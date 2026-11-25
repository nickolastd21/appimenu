#!/usr/bin/env bash
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${BINDIR:-$HOME/.local/bin}"
UNITS="$HOME/.config/systemd/user"

tools=("$@")
[ ${#tools[@]} -eq 0 ] && tools=(appimenu appfolder-sync)

for tool in "${tools[@]}"; do
  [ -f "$src/$tool" ] || { printf 'unknown tool: %s\n' "$tool" >&2; exit 1; }
  mkdir -p "$BIN" "$UNITS"
  install -m 755 "$src/$tool" "$BIN/$tool"
  for unit in service path timer; do
    install -m 644 "$src/units/$tool.$unit" "$UNITS/$tool.$unit"
  done
done

systemctl --user daemon-reload
for tool in "${tools[@]}"; do
  systemctl --user enable "$tool.service" "$tool.path" "$tool.timer"
  systemctl --user start "$tool.path" "$tool.timer"
  "$BIN/$tool"
done

printf 'installed %s into %s\n' "${tools[*]}" "$BIN"
printf 'each tool watches its own folder and updates the menu by itself\n'
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) printf 'note: %s is not in PATH, run tools as %s/<tool>\n' "$BIN" "$BIN" ;;
esac
