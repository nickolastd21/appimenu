# appimenu

AppImages in your application menu, automatically.

Drop an AppImage into `~/AppImages` and `appimenu` gives it a launcher entry with its own icon,
using the name, comment, categories and icon already packed inside the AppImage. Nothing is
mounted, nothing is copied into `/usr`, no AppImage runtime or daemon is required.

It rescans at login, again the moment the folder changes, and every 10 minutes, and it deletes
entries for AppImages you remove, rename away, or upgrade.

```
$ appimenu
scanned /home/me/AppImages: 8 AppImage entry(s) up to date, 1 stale entry(s) removed
```

## Why

An AppImage is a single file, and desktop environments expect `.desktop` entries in
`~/.local/share/applications`. Existing helpers either install a system-wide daemon and a FUSE
mount watcher, or rewrite entries on every launch. `appimenu` is one bash script plus three
systemd user units: it reads the AppImage's SquashFS directly with `unsquashfs`, and writes plain
`.desktop` files that any XDG desktop (GNOME, KDE Plasma, XFCE, Cinnamon) already understands.

## What it does

- Reads the embedded `.desktop` and icon out of each AppImage, following the internal symlinks
  LinuxDeploy and AppImageTool leave behind (`AppIcon.png -> usr/share/icons/...`,
  `name.desktop -> usr/share/applications/...`).
- Installs the icon into the hicolor theme at the size bucket matching its real pixel size, so
  large artwork does not blur at 48px.
- Derives a display name from the filename when an AppImage ships no metadata, stripping version
  and architecture noise (`LM-Studio-0.4.28-2-x64.AppImage` becomes `LM-Studio`).
- Draws an accent ring on every installed icon, so AppImage-backed apps are recognisable in the
  grid. Default is a 2px red ring with 13% rounded corners, close to Yaru's own icon shape. The
  ring scales with the artwork size so it stays about 2px on screen at launcher icon sizes.
- Skips partial downloads and corrupt files instead of creating a broken launcher, and keeps the
  previous entry alive until the file is really gone.
- Never touches entries it did not generate.

## Requirements

- `bash` 4.4+ and `squashfs-tools` (`unsquashfs`)
- GNU coreutils, `awk`, `find`, `md5sum`
- optional `python3` with Pillow, for the accent ring (icons install unbordered without it)
- optional `rsvg-convert` (librsvg), to rasterise SVG icons so they can carry a ring
- optional `gtk-update-icon-cache` and `update-desktop-database`

## Install

```sh
./install.sh
```

That copies `appimenu` to `~/.local/bin`, installs three systemd user units, enables them, and
runs the first scan:

| unit | effect |
| --- | --- |
| `appimenu.service` | one scan, runs at login |
| `appimenu.path` | rescans within seconds when `~/AppImages` changes |
| `appimenu.timer` | safety net rescan every 10 minutes |

No systemd user session? Run `appimenu` from your desktop environment's autostart, or from cron.

Remove it with `./uninstall.sh`, and also delete the entries and icons it created with
`./uninstall.sh --purge`.

## Configuration

Set these in the environment (for systemd units, use `systemctl --user edit appimenu.service`
and add an `Environment=` line).

| variable | default | meaning |
| --- | --- | --- |
| `APPIMAGE_DIR` | `~/AppImages` | folder to scan, searched recursively |
| `DESKTOP_DIR` | `~/.local/share/applications` | where entries are written |
| `ICON_ROOT` | `~/.local/share/icons/hicolor` | icon theme root |
| `APPMENU_ENTRY_PREFIX` | `appimage` | prefix for generated entry and icon names |
| `APPMENU_BORDER_COLOR` | `255,0,0` | accent ring colour as `R,G,B` |
| `APPMENU_BORDER_WIDTH` | `2` | ring width in pixels, `0` disables it |
| `APPMENU_RADIUS_RATIO` | `0.13` | corner radius as a fraction of icon size, `0` disables it |

`appimenu --help` prints the same list.

## How it works

1. Candidate filter: filename ends in `.AppImage`, is ELF, and is not a `.part` style temp file.
2. Offset: `AppImage --appimage-offset` reports where the SquashFS starts; a byte scan for the
   `hsqs` magic plus a validity check is the fallback for exotic builds. No FUSE, no mount.
3. Metadata: `unsquashfs -ll` lists the AppDir once, then only the chosen `.desktop` and icon are
   extracted into a temp dir.
4. Entry: `<prefix>-<slug>-<hash>.desktop` in `DESKTOP_DIR`, where the hash comes from the file
   path, so two versions of the same app get two stable entries.
5. Cleanup: entries carrying `X-AppImage-Sync=true` that are not part of this scan are deleted,
   along with their icons, unless the AppImage exists but failed inspection (mid-download).

## Troubleshooting

- Icons look unchanged in GNOME: the shell caches icon pixmaps, press Super twice or log out and
  back in.
- No accent ring: install `python3-pil`, or set `APPMENU_BORDER_WIDTH=0` to accept that.
- SVG icon shows no ring: install `librsvg2-bin` for `rsvg-convert`.
- Nothing appears for a file: it is probably still downloading, or truncated. `appimenu` prints
  a skip line to stderr in that case.
- Two identical names: that means two AppImage files are present. Keep one version, or rename the
  older file you keep out of the scan folder.

## Author

Written by Kilo, an AI software engineering agent, while wiring up a real GNOME workstation.

## License

MIT, see [LICENSE](LICENSE).
