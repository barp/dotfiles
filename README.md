# dotfiles

Personal configuration for an [Omarchy](https://omarchy.org/) (Arch + Hyprland)
machine, deployed with GNU Stow. Every package symlinks into `$HOME`, so editing
a file in this repo edits the live config.

## Install on a new machine

```bash
git clone https://github.com/barp/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` is the only install script. It installs packages, oh-my-zsh and its
plugins, tpm, and Neovim; links every stow package; deploys themes; re-adds the
Omarchy shell plugins; places wallpapers; re-applies the theme and restarts the
shell; then verifies the result.

```bash
./install.sh                  # full install
./install.sh --dry-run        # show what would happen, change nothing
./install.sh --verify         # health check only
./install.sh --stow-only      # re-link packages only
./install.sh --skip-packages  # skip the pacman/AUR step
```

It is idempotent - re-run it any time.

Stow uses `--adopt`, so a machine that already has Omarchy's default configs in
place converts cleanly: the defaults are pulled in, then immediately reset to
this repo's versions. The working tree must be clean for that reset to be safe,
and the script refuses to run otherwise.

## Packages

| Package | Contents |
|---|---|
| `omarchy` | Shell/bar config, menus, hooks, and the locally-cloned `bar.*` widgets |
| `hypr` | Hyprland `.lua` and `.conf` overrides |
| `terminals` | alacritty, kitty, ghostty, foot |
| `shell` | `.zshrc`, `.zprofile`, `.zshenv`, `.bashrc`, `.bash_profile` |
| `tmux` | `.tmux.conf` and the sessionizer scripts |
| `tools` | btop, git, herdr, opencode, fastfetch, mise, starship, lazygit, lazydocker, eza, imv, kanshi, xournalpp, yapf |
| `mpv` | mpv config, scripts, script-opts |
| `desktop` | GTK, fontconfig, mimeapps, autostart, fonts, Omarchy web apps |
| `input` | fcitx5 (Japanese input) |
| `backgrounds` | Wallpapers not owned by a theme |
| `lcd` | Case LCD panel daemon, its config and user service |

`system/` holds files that belong outside `$HOME` (a udev rule); it is **not**
a stow package - `install.sh` places its contents.

`themes/` is at the repo root and is **not** a stow package. `omarchy theme set`
copies a theme directory into `~/.local/state/omarchy/current/theme/` preserving
symlinks, and stow's links are relative: they resolve from `~/.config` but
dangle from `~/.local/state`. The shell then falls back to default colors,
opacity and bar height with no error. `install.sh` deploys themes as real files
(`cp -aL`) and re-applies the active one. Edit a theme in the repo, then re-run
`./install.sh`.

## Case LCD panels

`lcd` shows the current theme's backgrounds on the case's LCD panels - a
different picture on each panel. Two panels are supported, each speaking its
own protocol:

| Panel | USB ID | Transport |
|---|---|---|
| Thermaltake 6" LCD Panel Kit | `264a:2347` | hidraw, "BY" protocol, 1110x540 JPEG |
| Thermalright / ChiZhu `USBDISPLAY` | `87ad:70db` | vendor bulk, "USBLCDNew", geometry probed |

`avoid_desktop_background` (default **false**) additionally keeps the panels
off whatever image the desktop is currently using as its wallpaper, tracked
live through `~/.local/state/omarchy/current/background`. It is a global
setting, not per panel: with it on, a panel showing the desktop's picture
moves to another one as soon as the wallpaper changes.

`install.sh` acts only when one of the panels is actually present: it installs
`system/udev/70-case-lcd.rules` and enables `omarchy-lcd-bg.service`.

**The rule must keep its `70-` prefix.** `TAG+="uaccess"` is what grants the
logged-in user access to the devices, and it is consumed by
`/usr/lib/udev/rules.d/73-seat-late.rules`. A file sorting after that one tags
the device too late: `udevadm info` shows the tag, `getfacl` shows no ACL, and
the daemon fails with a permission error nothing else reports.

The daemon runs on `/usr/bin/python3`, not `python3` - the latter is a mise
shim that cannot see `python-pillow` and `python-pyusb` from pacman.

Panel geometry is read from the device at startup, but **how a panel is
physically mounted is not discoverable**. That, and anything else specific to
one machine, goes in `~/.config/omarchy/lcd-bg.local.json`, which is merged
over the versioned config and is never committed:

```json
{ "thermalright": { "rotate": 180 } }
```

With `"stats": true` a panel also carries a CPU/GPU readout along the bottom -
temperature, load bar and percentage - redrawn every keepalive tick. CPU
temperature comes from `k10temp`'s Tctl (looked up by driver name, since hwmon
numbering is not stable across boots) and load from `/proc/stat` deltas; the
GPU figures come from `nvidia-smi`, not hwmon, because the `amdgpu` hwmon on
this board is the CPU's integrated graphics rather than the card driving the
display. A sensor that cannot be read draws a dash instead of failing.

Typeface and text size are set by `"stats_font"`:

```json
"stats_font": {
  "family": "Adwaita Sans",
  "weight": "Black",
  "label": 0.105, "value": 0.135, "percent": 0.060
}
```

`family` is a fontconfig pattern (`"Noto Sans"`, `"Adwaita Sans:style=Bold"`)
or an absolute path to a `.ttf`/`.otf`. `weight` picks a named instance of a
variable font - Adwaita Sans carries Thin through Black - and is ignored by
fonts that have none. fc-match answers every pattern with *something*, so a
misspelt family would otherwise render silently in a substitute; the daemon
logs the substitution instead.

The three sizes are fractions of the panel's height, so one setting holds
across panels of different resolutions: `label` is the `CPU`/`GPU` heading,
`value` the temperature, `percent` the load figure. The backdrop's height is derived from these rather than fixed, so
raising a size grows the gradient with it instead of pushing the readout off
the bottom of the panel. Any key may be omitted to keep its default.

Text colour is chosen per half from the brightness of the shaded background
behind it: light text with a dark outline over a dark picture, dark text with
a pale halo over a bright one, and the heading's accent colour darkened to
match. A fixed light-on-dark scheme washes out on a pale wallpaper, which the
gradient alone cannot fix without blacking out the picture.

Numbers are drawn with tabular figures where PIL has raqm, so a value ticking
from 9 to 10 does not shove the degree sign sideways twice a second.

The overlay is drawn before the panel rotation is applied, so it stays upright
on an upside-down panel. Re-compositing costs about 9 ms per tick: the fitted
background is cached decoded, and only the overlay and JPEG encode repeat.

### Video

A panel can play a video, or a playlist, instead of wallpapers:

```bash
omarchy-lcd-bg --panel thermaltake --video a.mp4 b.mp4
omarchy-lcd-bg --panel thermaltake --video ~/Videos/lcd    # a whole folder
```

or permanently, in that panel's config - the other panel keeps cycling
backgrounds, since a video panel runs in its own thread at frame rate rather
than on the 2 s keepalive tick:

```json
"video": ["~/Videos/a.webm", "~/Videos/b.webm"],
"video_fps": 30, "video_quality": 6,
"video_loop": true, "video_shuffle": false
```

`video` takes one path, a list, or a directory - a directory is expanded to the
video files inside it, so a playlist can be a folder to drop files into rather
than a list to keep editing. Clips play in order (or shuffled) and the list
repeats. A file that will not play is skipped rather than ending the playlist.

`video_sets` replaces `video` with several playlists that a keybinding cycles
between:

```json
"video_sets": ["~/Videos/lcd/a", "~/Videos/lcd/b"],
"video_fps": 60, "video_quality": 4
```

**SUPER + SHIFT + V** (`omarchy-lcd-video-next`) switches to the next set and
notifies which one took over. It sends `SIGUSR2`; the handler only flips a flag
and signals ffmpeg, so the change lands within a frame - measured at 68 ms end
to end - rather than waiting for the next keepalive tick.

Each set is resolved **when it starts playing**, not at startup, so a file
dropped into a folder joins that set without restarting the daemon. An empty
set is not an error: the panel holds, the daemon says so, and it re-checks
every 15 s, which is how a folder filled later starts playing on its own. Only
when *every* set is empty does the panel fall back to backgrounds.

The live set's name is written to `~/.local/state/omarchy/lcd-video-set`, which
is what lets the keybinding name it in the notification rather than guessing.

ffmpeg does the decode, scale, crop, rotate and JPEG encode, so the daemon only
splits the MJPEG stream and writes frames - the panel wants JPEG, which is what
MJPEG already is. `video_quality` is ffmpeg's `-q:v`, 2 (best) to 31.

Measured on the Thermaltake's HID endpoint, 1110x540:

| JPEG quality | Frame | Ceiling |
|---|---|---|
| q90 | 232 KB | 28 fps |
| q75 | 144 KB | 45 fps |
| q60 | 111 KB | 59 fps |

about 6.5 MB/s either way, so frame size sets the ceiling. 30 fps is
comfortable. Pacing comes from ffmpeg's `-re`: without it the decode runs flat
out and, since the panel is not the bottleneck at these sizes, the video plays
several times too fast.

`-re` alone is still not enough: ffmpeg hands over a burst of buffered frames
when it starts, so each clip would open with a brief fast-forward. A wall-clock
pacer waits when it is ahead and drops frames when it is more than half a
second behind. It is timed from the *first frame*, not from the spawn - count
ffmpeg's startup latency as lag and the guard drops every frame in the file.

There is no audio: the panel has no speaker, and `-an` keeps the stream to
video only.

| Command | |
|---|---|
| `omarchy-lcd-video-next` | switch to the next video set (SUPER+SHIFT+V) |
| `omarchy-lcd-bg --probe` | identify the panels and their geometry |
| `omarchy-lcd-bg --test` | corner-marked pattern, to check size and rotation |
| `systemctl --user reload omarchy-lcd-bg` | jump to the next pictures |

Both panels fall back to their own screen when frames stop arriving, so the
daemon re-sends the current picture every couple of seconds. That is inherent
to the hardware, not a design choice.

## btrfs: copy-on-write

Steam game data and the Monero blockchain are large files rewritten in place,
which fragments badly under btrfs copy-on-write. `install.sh` sets them up:

| Path | Treatment |
|---|---|
| `~/.local/share/Steam/steamapps/common` | NoCOW directory |
| `~/.local/share/Steam/steamapps/shadercache` | NoCOW directory |
| `~/.bitmonero` | Own subvolume, NoCOW |

`~/.bitmonero` is a subvolume so snapper/limine never snapshots a
multi-gigabyte blockchain along with `$HOME`.

**`chattr +C` only affects files created after it is set.** These directories
must be prepared while empty — run `./install.sh` before starting Steam or
monerod for the first time. If data is already there, the script says so and
prints the exact rewrite command; it never moves your data on its own.

Adjust the paths in the `NOCOW_DIRS` / `NOCOW_SUBVOLS` arrays at the top of
`install.sh`. On a non-btrfs machine the whole step is skipped.

## Per-host config

This repo holds **no per-machine config.** `monitors.lua`, `displays.json` and
`environment.d/` describe one machine's hardware, so each host keeps its own
real files in `~/.config/` and nothing here touches them:

- `install.sh` never links them, and has no `--with-machine` flag.
- `scripts/sync-from-system.sh` never pulls them back in, and explicitly drops
  `monitors.lua` from the `hypr` package after copying `.config/hypr`.

Configure displays natively on each machine. A rebuild therefore starts from
Omarchy's defaults and you set the monitors up once by hand - deliberate, since
display layout is the one thing that should not follow the dotfiles onto
different hardware.

## Scripts

There are two, by design:

| Script | Direction |
|---|---|
| `install.sh` | repo → machine (plus `--verify`) |
| `scripts/sync-from-system.sh` | machine → repo |

## Keeping the repo current

Configs change in place — some through `omarchy` commands rather than editing.
Pull those changes back in:

```bash
./scripts/sync-from-system.sh
git diff            # review
git commit -am "sync"
```

The sync script also regenerates `packages.arch.txt`, `packages.aur.txt`,
`plugins.txt`, and `backgrounds.map`.

Always follow a sync with:

```bash
./install.sh --verify
```

It checks for self-referential symlinks, dangling links into the repo, Hyprland
keybinding count and config errors, and — importantly — that every widget the
bar layout references is actually **enabled**. A Quickshell restarted while the
plugin directory is mid-write silently marks those plugins disabled and keeps
that state, so the bar renders without them even though every file on disk is
correct. Recovery is `omarchy theme set <name> && omarchy restart shell`.

## Deliberate exclusions

- **Credentials.** `sync-from-system.sh` works from an allowlist. Nothing in
  `~/.config/{gh,gcloud,aws,docker,azure,Bitwarden}`, `~/.ssh`, or browser
  profiles is ever collected.
- **`~/.config/mozc`.** Holds `.encrypt_key.db` and learned-input history —
  a secret plus personal data. fcitx5's own config is in the `input` package.
- **Generated state.** `node_modules`, `*.log`, `*.bak*`, `session.json`,
  `.plugins.lock`, and `*.sample` are filtered out.
- **Neovim.** Lives at [barp/lazyvim-config](https://github.com/barp/lazyvim-config)
  and is cloned by `install.sh`.
- **`~/.local/share/applications`.** Only the Omarchy web apps
  (`Exec=omarchy-launch-webapp`) are kept; the rest is written by package
  installers and Steam. Their `Icon=` lines hardcode `/home/bar/`, so a
  different username needs a rewrite.

## Wallpapers

Images are stored exactly once. An image shipped inside a theme stays there —
Omarchy themes must be self-contained — and the `backgrounds` package holds only
what no theme provides. `backgrounds.map` records the layout and
`install.sh` replays it into
`~/.config/omarchy/backgrounds/`.

## History

Pre-Quattro packages (waybar, wofi, the old Hyprland `.conf` set), the NvChad
Neovim config, `gita`, `alacritty-mac`, and the Debian/macOS install paths were
retired when this repo moved to Omarchy 4. They remain in git history:

```bash
git log --diff-filter=D --name-only -- waybar wofi hyprland nvim gita
```
