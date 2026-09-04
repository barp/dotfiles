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
./install.sh --with-machine   # also apply machine-<hostname>
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
| `machine-<host>` | Per-host hardware config — **not stowed by default** |

`themes/` is at the repo root and is **not** a stow package. `omarchy theme set`
copies a theme directory into `~/.local/state/omarchy/current/theme/` preserving
symlinks, and stow's links are relative: they resolve from `~/.config` but
dangle from `~/.local/state`. The shell then falls back to default colors,
opacity and bar height with no error. `install.sh` deploys themes as real files
(`cp -aL`) and re-applies the active one. Edit a theme in the repo, then re-run
`./install.sh`.

## Per-host config

`monitors.lua`, `displays.json`, and `environment.d/` describe one machine's
hardware, so they live in `machine-<hostname>/` and are skipped unless asked for:

```bash
./install.sh --with-machine
```

On a new machine, configure displays natively and commit the result as a new
`machine-<hostname>/` package.

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
