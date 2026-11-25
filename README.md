# appimenu

Launcher entries for portable apps, automatically.

Two small syncers, one shared idea: read metadata and icons straight out of a portable app, write
plain `.desktop` files plus a theme icon, and keep them in step with the folder. Nothing is
mounted, nothing is copied into `/usr`, no daemon or FUSE required.

| tool | watches | apps it handles | accent ring |
| --- | --- | --- | --- |
| `appimenu` | `~/AppImages` | single-file AppImages | red |
| `appfolder-sync` | `~/AppFolders` | extracted tarball/tar.gz folders | blue |

The ring tells the two kinds apart at a glance in the app grid, and is configurable or disabled.

```
$ appimenu
scanned /home/me/AppImages: 8 AppImage entry(s) up to date, 1 stale entry(s) removed

$ appfolder-sync
scanned /home/me/AppFolders: 1 folder entry(s) up to date, 0 stale entry(s) removed
```

## Why

AppImages and extracted tarballs are single files or loose directories, while desktop environments
expect `.desktop` entries in `~/.local/share/applications`. Existing helpers install a system-wide
watcher or rewrite entries on every launch. These two tools are bash scripts plus systemd user
units, writing entries that any XDG desktop (GNOME, KDE Plasma, XFCE, Cinnamon) already reads.

## What they do

- Read the `.desktop` that the app itself ships, and use its name, comment, categories, keywords,
  MIME types, `Terminal`, `StartupNotify` and `StartupWMClass`.
- Resolve relative launch commands against the app location, keeping arguments such as `%f` and
  `%U`. `appfolder-sync` also sets `Path=` to the program folder, so apps start in their own
  directory.
- Extract the app's own icon, following the symlinks LinuxDeploy and AppImageTool leave behind
  (`AppIcon.png -> usr/share/icons/...`), and install it into the hicolor theme at the size bucket
  matching its real pixel size.
- Fall back to a name derived from the filename or folder when no metadata ships, stripping version
  and architecture noise (`LM-Studio-0.4.28-2-x64` becomes `LM-Studio`), or to the main executable
  in the folder when no `.desktop` ships.
- Draw an accent ring so portable apps are recognisable: rounded corners at 13% of the icon size,
  close to Yaru's own icon shape, scaled so it reads as about 2px at launcher icon sizes.
- Ignore partial downloads, corrupt files and unreadable images instead of creating a broken
  launcher, and keep the previous entry alive until the app is really gone.
- Delete entries and icons for apps you remove or move away, and never touch entries they did not
  create.

## Requirements

- `bash` 4.4+ and GNU coreutils (`find`, `awk`, `od`, `md5sum`, `realpath`)
- `squashfs-tools` (`unsquashfs`) for `appimenu` only
- optional `python3` with Pillow, for the accent ring (icons install unbordered without it)
- optional `rsvg-convert` (librsvg), to rasterise SVG icons so they can carry a ring
- optional `gtk-update-icon-cache` and `update-desktop-database`

## Install

```sh
./install.sh                      # both tools
./install.sh appfolder-sync       # one tool only
```

Copies the scripts to `~/.local/bin`, installs three systemd user units per tool, enables them, and
runs the first scan:

| unit | effect |
| --- | --- |
| `<tool>.service` | one scan, runs at login |
| `<tool>.path` | rescans within seconds when the watched folder changes |
| `<tool>.timer` | safety net rescan every 10 minutes |

No systemd user session? Run the tools from your desktop environment's autostart, or from cron.

Remove with `./uninstall.sh`, and also delete the entries and icons they created with
`./uninstall.sh --purge`.

## Configuration

Set these in the environment. For systemd, use `systemctl --user edit appimenu.service` (or the
`appfolder-sync` one) and add `Environment=` lines.

| variable | default | meaning |
| --- | --- | --- |
| `APPIMAGE_DIR` | `~/AppImages` | AppImage folder scanned by `appimenu` |
| `APPFOLDER_DIR` | `~/AppFolders` | extracted folder root scanned by `appfolder-sync` |
| `DESKTOP_DIR` | `~/.local/share/applications` | where entries are written |
| `ICON_ROOT` | `~/.local/share/icons/hicolor` | icon theme root |
| `APPMENU_ENTRY_PREFIX` | `appimage` | entry and icon name prefix for AppImages |
| `APPFOLDER_ENTRY_PREFIX` | `appfolder` | entry and icon name prefix for extracted folders |
| `APPMENU_BORDER_COLOR` | `255,0,0` | AppImage ring colour as `R,G,B` |
| `APPFOLDER_BORDER_COLOR` | `0,110,255` | folder ring colour as `R,G,B` |
| `APPMENU_BORDER_WIDTH` / `APPFOLDER_BORDER_WIDTH` | `2` | ring width in pixels, `0` disables |
| `APPMENU_RADIUS_RATIO` / `APPFOLDER_RADIUS_RATIO` | `0.13` | corner radius as a fraction of icon size, `0` disables |

`--help` prints the same list for each tool.

## How they work

`appimenu`

1. Candidate filter: filename ends in `.AppImage`, is ELF, and is not a `.part` style temp file.
2. Offset: `AppImage --appimage-offset` reports where the SquashFS starts, with a byte scan for the
   `hsqs` magic plus a validity check as fallback. No FUSE, no mount.
3. Metadata: `unsquashfs -ll` lists the AppDir once, then only the chosen `.desktop` and icon are
   extracted into a temp dir.

`appfolder-sync`

1. Each subdirectory of the root is a candidate app, descending one level when the parent holds no
   launcher of its own.
2. A bundled `.desktop` wins; otherwise the executable whose name matches the folder is used, with
   helper binaries (`*-launcher`, `*-thumbnailer`, crash handlers, uninstallers) ignored.
3. Icons are collected to a bounded depth, skipping `lib`, `data`, `docs`, `node_modules` and
   similar, and anything that is not a real PNG, SVG, ICO or XPM is rejected.

Both write `<prefix>-<name>-<hash>.desktop`, where the hash comes from the app path, so two
versions of the same app produce two stable entries. Entries carry `X-AppImage-Sync=true` or
`X-AppFolder-Sync=true` so cleanup can tell generated files from yours.

## Troubleshooting

- Icons look unchanged in GNOME: the shell caches icon pixmaps, press Super twice or log out and
  back in.
- No accent ring: install `python3-pil`, or set the border width to `0` to accept that.
- SVG icon shows no ring: install `librsvg2-bin` for `rsvg-convert`.
- Nothing appears for an AppImage: it is probably still downloading or truncated, which the tools
  report on stderr.
- Nothing appears for a folder: no executable was found in it. If a launcher script lives deeper
  than two levels, or the binary is not marked executable, fix that rather than the entry.
- Two identical names: two versions of the app are present. Keep one in the watched folder.

## Author

Written by Kilo, an AI software engineering agent, while wiring up a real GNOME workstation.

## License

MIT, see [LICENSE](LICENSE).
