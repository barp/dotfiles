#!/usr/bin/env bash
# Refresh the stow packages in this repo from the live system.
# Run after changing configs by hand, then review `git diff` and commit.
#
# SAFE TO RUN WHILE STOWED. Once packages are stowed, the paths under $HOME are
# symlinks back into this repo. Two rules keep that from eating the repo:
#   1. tar reads with -h, so symlinks are captured as content, never as links.
#   2. Files are replaced by atomic rename from a staging dir on the SAME
#      filesystem, so a stowed symlink never sees its target missing. Without
#      this, Hyprland's config watcher reloads a half-written tree mid-sync
#      and drops every keybinding.
# A guard at the end aborts if any self-referential symlink lands in the repo.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
V=0; [ "${1:-}" = "--verbose" ] && V=1

EXCLUDES=(
  --exclude='*.bak*' --exclude='*.sample' --exclude='.git'
  --exclude='*.omarchy-upgrade-to-*' --exclude='node_modules'
  --exclude='*.log' --exclude='.plugins.lock' --exclude='session.json'
  --exclude='cached_layouts' --exclude='*.lock' --exclude='.DS_Store'
  --exclude='.uuid'
)

# Staging lives inside the repo so `mv` is a real rename, not copy+unlink.
STAGE_ROOT="$(mktemp -d "$REPO/.sync-stage.XXXXXX")"
trap 'rm -rf "$STAGE_ROOT"' EXIT

# swap <stage-dir> <dest-dir> - replace dest's contents with stage's, moving
# each file in by atomic rename so no path is ever momentarily absent.
swap() {
  local src="$1" dest="$2" f
  mkdir -p "$dest"
  ( cd "$src" && find . -type f -o -type l ) | sed 's|^\./||' | sort > "$src.manifest"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    mkdir -p "$dest/$(dirname "$f")"
    mv -f "$src/$f" "$dest/$f"
  done < "$src.manifest"
  ( cd "$dest" && find . -type f -o -type l ) | sed 's|^\./||' | sort | while IFS= read -r f; do
    grep -qxF "$f" "$src.manifest" || rm -f "$dest/$f"
  done
  find "$dest" -type d -empty -delete 2>/dev/null || true
  rm -f "$src.manifest"
}

# copy <package> <path-relative-to-$HOME>...
copy() {
  local pkg="$1"; shift
  cd "$HOME"
  local existing=() p
  for p in "$@"; do [ -e "$p" ] && existing+=("$p"); done
  [ ${#existing[@]} -eq 0 ] && return 0

  local tmp; tmp="$(mktemp -d "$STAGE_ROOT/XXXXXX")"
  # -h dereferences symlinks, so configs already stowed back into this repo are
  # captured as content, never as links pointing at themselves.
  # tar exits non-zero when -h meets a dangling symlink (e.g. eza/theme.yml
  # points at theme state omarchy regenerates). --ignore-failed-read already
  # skips it; swallow the status so pipefail doesn't abort the whole sync.
  { tar -chf - --ignore-failed-read "${EXCLUDES[@]}" "${existing[@]}" 2>/dev/null || true; } \
    | tar -xf - -C "$tmp"

  local dest="$REPO/$pkg" f
  # Record what upstream has, then move each file into place atomically.
  ( cd "$tmp" && find . -type f -o -type l ) | sed 's|^\./||' | sort > "$tmp.manifest"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    mkdir -p "$dest/$(dirname "$f")"
    mv -f "$tmp/$f" "$dest/$f"
  done < "$tmp.manifest"

  # Prune repo files that no longer exist upstream, but only under the paths
  # this call owns - never touch another package's tree.
  for p in "${existing[@]}"; do
    [ -e "$dest/$p" ] || continue
    ( cd "$dest" && find "$p" -type f -o -type l ) | sort | while IFS= read -r f; do
      grep -qxF "$f" "$tmp.manifest" || rm -f "$dest/$f"
    done
  done
  find "$dest" -type d -empty -delete 2>/dev/null || true

  rm -rf "$tmp" "$tmp.manifest"
  [ "$V" -eq 1 ] && printf '  %-16s %s\n' "$pkg" "${existing[*]}"
  return 0
}

echo "Syncing live config into $REPO"

# --- Omarchy desktop shell, theme, menus, hooks ---
# Theme-owned backgrounds stay inside the theme: an Omarchy theme must be
# self-contained for `omarchy theme set` to install its wallpaper.
copy omarchy \
  .config/omarchy/shell.json .config/omarchy/shell.toml \
  .config/omarchy/branding .config/omarchy/extensions \
  .config/omarchy/hooks .config/omarchy/themed

# --- Custom themes: repo-root themes/, NOT a stow package. `omarchy theme set`
#     copies a theme dir preserving symlinks, and stow's relative links dangle
#     from ~/.local/state/omarchy/current/theme/ - the shell then falls back to
#     default colors, opacity and bar height. Deployed by install-theme.sh. ---
for t in "$HOME"/.config/omarchy/themes/*/; do
  [ -d "$t" ] || continue
  name="$(basename "$t")"
  ttmp="$(mktemp -d "$STAGE_ROOT/XXXXXX")"
  cp -aL "$t." "$ttmp/" 2>/dev/null || true
  find "$ttmp" -name '*.bak*' -delete 2>/dev/null || true
  swap "$ttmp" "$REPO/themes/$name"
  rm -rf "$ttmp"
done

# Shell plugins: only the local (non-git) clones travel in the repo. Git-managed
# ones are recorded as URLs and re-added by scripts/install-plugins.sh.
PLUGDEST="$REPO/omarchy/.config/omarchy/plugins"
ptmp="$(mktemp -d "$STAGE_ROOT/XXXXXX")"
: > "$REPO/plugins.txt"
for d in "$HOME"/.config/omarchy/plugins/*/; do
  [ -d "$d" ] || continue
  if url="$(git -C "$d" remote get-url origin 2>/dev/null)"; then
    echo "$url" >> "$REPO/plugins.txt"
  else
    cp -aL "$d" "$ptmp/"
  fi
done
swap "$ptmp" "$PLUGDEST"
rm -rf "$ptmp"

# --- Hyprland (monitors.lua is machine-specific, see machine-* package) ---
copy hypr .config/hypr
rm -f "$REPO/hypr/.config/hypr/monitors.lua"

# --- Terminals ---
copy terminals .config/alacritty .config/kitty .config/ghostty .config/foot

# --- Shell (.zshrc is edited in-repo and symlinked out; never pulled back) ---
copy shell .zprofile .zshenv .bashrc .bash_profile

# --- CLI tools ---
copy tools \
  .config/btop .config/git .config/fastfetch .config/mise .config/lazygit \
  .config/lazydocker .config/eza .config/imv .config/kanshi .config/ccmanager \
  .config/dgop .config/xournalpp .config/yapf .config/starship.toml
# herdr and opencode need field-stripping: config only, no logs/state/deps.
mkdir -p "$REPO/tools/.config/herdr" "$REPO/tools/.config/opencode"
cp -aL "$HOME/.config/herdr/config.toml" "$REPO/tools/.config/herdr/" 2>/dev/null || true
for f in opencode.json tui.jsonc package.json herdr-tui-session.js; do
  cp -aL "$HOME/.config/opencode/$f" "$REPO/tools/.config/opencode/" 2>/dev/null || true
done
cp -aL "$HOME/.config/opencode/plugins" "$REPO/tools/.config/opencode/" 2>/dev/null || true

# --- Media ---
copy mpv .config/mpv

# --- Desktop integration ---
copy desktop \
  .config/gtk-3.0 .config/gtk-4.0 .config/fontconfig .config/mimeapps.list \
  .config/autostart .config/brave-flags.conf .config/chromium-flags.conf \
  .local/share/fonts
# Only the Omarchy web apps from ~/.local/share/applications - the rest of that
# directory is written by package installers and Steam.
APPDEST="$REPO/desktop/.local/share/applications"
atmp="$(mktemp -d "$STAGE_ROOT/XXXXXX")"; mkdir -p "$atmp/icons"
for f in "$HOME"/.local/share/applications/*.desktop; do
  [ -f "$f" ] || continue
  grep -q 'omarchy-launch-webapp' "$f" || continue
  cp -aL "$f" "$atmp/"
  icon="$(sed -n 's|^Icon=.*/applications/icons/||p' "$f")"
  [ -n "$icon" ] && cp -aL "$HOME/.local/share/applications/icons/$icon" \
    "$atmp/icons/" 2>/dev/null || true
done
swap "$atmp" "$APPDEST"
rm -rf "$atmp"

# --- Input method (fcitx5 config only; ~/.config/mozc holds an encryption key
#     and learned-history DBs and is deliberately never committed) ---
copy input .config/fcitx5

# --- Wallpapers: every unique image stored exactly once ---
# Images shipped inside a theme are canonical there; the backgrounds package
# holds only what no theme provides. The store is ADDITIVE on purpose - a
# machine that no longer has a given wallpaper must not silently delete it from
# the repo. Retire one with `git rm`.
STORE="$REPO/backgrounds/.local/share/backgrounds"
mkdir -p "$STORE"
: > "$REPO/backgrounds.map"
declare -A owner=()
while IFS= read -r img; do
  [ -n "$img" ] || continue
  owner["$(md5sum "$img" | cut -d' ' -f1)"]="theme:${img#$REPO/themes/}"
done < <(find "$REPO/themes" -type f \( -name '*.png' -o -name '*.jpg' \) 2>/dev/null | sort)
# Images already in the store keep their identity across runs.
while IFS= read -r img; do
  [ -n "$img" ] || continue
  sum="$(md5sum "$img" | cut -d' ' -f1)"
  [ -z "${owner[$sum]:-}" ] && owner[$sum]="store:$(basename "$img")"
done < <(find "$STORE" -type f 2>/dev/null | sort)
BGROOT="$HOME/.config/omarchy/backgrounds"
while IFS= read -r img; do
  [ -n "$img" ] || continue
  sum="$(md5sum "$img" | cut -d' ' -f1)"
  if [ -z "${owner[$sum]:-}" ]; then
    cp -aL "$img" "$STORE/$(basename "$img")"
    owner[$sum]="store:$(basename "$img")"
  fi
  printf '%s\t%s\n' "${img#$BGROOT/}" "${owner[$sum]}" >> "$REPO/backgrounds.map"
done < <(find "$BGROOT" -type f \( -name '*.png' -o -name '*.jpg' \) 2>/dev/null | sort)

# --- Machine-specific: hardware layout for THIS host only ---
copy "machine-$(hostname -s)" \
  .config/hypr/monitors.lua .config/omarchy/displays.json .config/environment.d

# --- Drop per-machine theme artifacts. `omarchy theme set` regenerates these,
#     and they point at theme state outside the repo. They arrive either as
#     absolute symlinks (which make GNU Stow refuse the whole operation) or,
#     because tar runs with -h, as dereferenced copies of the current theme. ---
rm -f "$REPO/tools/.config/btop/themes/current.theme" \
      "$REPO/tools/.config/eza/theme.yml"
find "$REPO" -type d -empty -delete 2>/dev/null || true
find "$REPO" -path "$REPO/.git" -prune -o -type l -print 2>/dev/null | while IFS= read -r l; do
  case "$(readlink "$l")" in /*) rm -f "$l" ;; esac
done

# --- Guard: nothing in the repo may be a link back into the repo ---
bad="$(find "$REPO" -path "$REPO/.git" -prune -o -type l -print 2>/dev/null \
       | while IFS= read -r l; do case "$(readlink "$l")" in *.dotfiles/*|"$REPO"/*) echo "$l";; esac; done)"
if [ -n "$bad" ]; then
  echo "ERROR: self-referential symlinks in repo - restore with:" >&2
  echo "  git checkout-index -f -a" >&2
  echo "$bad" >&2
  exit 1
fi

# --- Package manifests ---
if command -v pacman >/dev/null; then
  pacman -Qqe > "$REPO/packages.arch.txt"
  pacman -Qqm > "$REPO/packages.aur.txt"
fi

echo "Done. Review with: git -C $REPO status && git -C $REPO diff"
