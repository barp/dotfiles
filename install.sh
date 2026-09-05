#!/usr/bin/env bash
#
# Bring an Omarchy (Arch + Hyprland) machine to the state this repo describes.
# Safe to re-run: every step is idempotent.
#
#   ./install.sh                  full install
#   ./install.sh --stow-only      re-link packages only
#   ./install.sh --verify         health check only, change nothing
#   ./install.sh --dry-run        show what would happen
#   ./install.sh --with-machine   also apply machine-<hostname> (identical hardware only)
#   ./install.sh --skip-packages  skip the pacman/AUR step
#
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

PACKAGES=(omarchy hypr terminals shell tmux tools mpv desktop input backgrounds)
NVIM_REMOTE="git@github.com:barp/lazyvim-config.git"

# Large files rewritten in place - Steam game data, the Monero blockchain -
# fragment badly under btrfs copy-on-write, so they live in NoCOW directories.
# ~/.bitmonero is additionally its own subvolume, which keeps snapper/limine
# from snapshotting a multi-gigabyte blockchain along with $HOME.
NOCOW_DIRS=(
  ".local/share/Steam/steamapps/common"
  ".local/share/Steam/steamapps/shadercache"
)
NOCOW_SUBVOLS=(
  ".bitmonero"
)

STOW_ONLY=0; VERIFY_ONLY=0; DRY=0; WITH_MACHINE=0; SKIP_PACKAGES=0
for a in "$@"; do case "$a" in
  --stow-only)     STOW_ONLY=1 ;;
  --verify)        VERIFY_ONLY=1 ;;
  --dry-run)       DRY=1 ;;
  --with-machine)  WITH_MACHINE=1 ;;
  --skip-packages) SKIP_PACKAGES=1 ;;
  -h|--help)       sed -n '3,12p' "$0"; exit 0 ;;
  *) echo "unknown option: $a" >&2; exit 1 ;;
esac; done

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
run()  { if [ "$DRY" -eq 1 ]; then echo "  would run: $*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- verify ----
fail=0
ok()  { printf '  \033[32mok\033[0m    %s\n' "$1"; }
bad() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fail=$((fail+1)); }

verify() {
  fail=0
  step "Verifying"

  local n
  n=$(find "$REPO" -path "$REPO/.git" -prune -o -type l -print 2>/dev/null \
      | while IFS= read -r l; do case "$(readlink "$l")" in *.dotfiles/*|"$REPO"/*) echo x;; esac; done | wc -l)
  [ "$n" -eq 0 ] && ok "no self-referential symlinks in repo" \
    || bad "$n self-referential symlinks - run: git checkout-index -f -a"

  n=$(git ls-files | while IFS= read -r f; do [ -e "$REPO/$f" ] || echo x; done | wc -l)
  [ "$n" -eq 0 ] && ok "no tracked files missing from working tree" \
    || bad "$n tracked files missing - run: git checkout-index -f -a"

  n=$(find "$HOME/.config" "$HOME/.local/share" -maxdepth 4 -type l ! -exec test -e {} \; -print 2>/dev/null \
      | grep -c "dotfiles" || true)
  [ "$n" -eq 0 ] && ok "every link into the repo resolves" || bad "$n dangling links into the repo"

  if [ "$(stat -f -c %T "$HOME" 2>/dev/null)" = "btrfs" ]; then
    local d
    for d in "${NOCOW_DIRS[@]}" "${NOCOW_SUBVOLS[@]}"; do
      if [ ! -d "$HOME/$d" ]; then bad "$d missing"
      elif lsattr -d "$HOME/$d" 2>/dev/null | awk '{print $1}' | grep -q C; then ok "NoCOW set on $d"
      else bad "$d is NOT NoCOW - run: ./install.sh"; fi
    done
    for d in "${NOCOW_SUBVOLS[@]}"; do
      [ "$(stat -c %i "$HOME/$d" 2>/dev/null)" = "256" ] && ok "$d is its own subvolume" \
        || bad "$d is not a subvolume - excluded from snapshots requires one"
    done
  fi

  # Every input method named in the fcitx5 profile must actually be available.
  # fcitx5 silently drops one whose engine is missing, then writes the pruned
  # profile back through the stow symlink into this repo - which is how
  # Japanese and Hebrew disappear without an error anywhere.
  local prof="$HOME/.config/fcitx5/profile" im layout
  if [ -r "$prof" ]; then
    for im in $(sed -n '/^\[Groups\/0\/Items\//,/^$/s/^Name=//p' "$prof"); do
      case "$im" in
        keyboard-*)
          layout="${im#keyboard-}"
          grep -q "<name>$layout</name>" /usr/share/X11/xkb/rules/evdev.xml 2>/dev/null \
            && ok "input method $im available" \
            || bad "xkb layout $layout missing - needs xkeyboard-config" ;;
        *)
          [ -f "/usr/share/fcitx5/inputmethod/$im.conf" ] \
            && ok "input method $im available" \
            || bad "fcitx5 engine $im NOT installed - fcitx5 will drop it from the profile" ;;
      esac
    done
  fi

  if have hyprctl && hyprctl version >/dev/null 2>&1; then
    local b e
    b=$(hyprctl binds 2>/dev/null | grep -c '^bind')
    [ "$b" -gt 100 ] && ok "$b keybindings registered" || bad "only $b keybindings - run: hyprctl reload"
    e=$(hyprctl configerrors 2>&1 | grep -c .)
    [ "$e" -eq 0 ] && ok "no Hyprland config errors" || bad "$e Hyprland config errors"
  else
    echo "  skip  Hyprland not running"
  fi

  if have omarchy; then
    python3 -c "import json;json.load(open('$HOME/.config/omarchy/shell.json'))" 2>/dev/null \
      && ok "shell.json is valid JSON" || bad "shell.json is not valid JSON"

    # Every widget the bar layout references must actually be enabled. A shell
    # restarted while the plugin dir is mid-write silently marks plugins
    # disabled and keeps that state - the bar then renders without them.
    local ids state id
    ids=$(python3 - <<'PY'
import json,os
d=json.load(open(os.path.expanduser('~/.config/omarchy/shell.json')))
out={w.get('id','') for sec in d.get('bar',{}).get('layout',{}).values() for w in sec}
print('\n'.join(sorted(i for i in out if i and not i.startswith('omarchy.'))))
PY
)
    state=$(omarchy plugin list 2>/dev/null)
    for id in $ids; do
      echo "$state" | grep -qE "^$id +enabled" && ok "widget $id enabled" \
        || bad "widget $id NOT enabled - run: ./install.sh (re-applies theme and restarts shell)"
    done

    local t
    t=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)
    [ -n "$t" ] && ok "theme applied: $t" || bad "no theme recorded"

    # A theme directory must hold real files. `omarchy theme set` copies it into
    # the state dir preserving symlinks, and a relative link that resolved from
    # ~/.config dangles from ~/.local/state - the shell then silently falls back
    # to default bar colors, opacity and height.
    n=$(find "$HOME/.config/omarchy/themes" -type l 2>/dev/null | wc -l)
    [ "$n" -eq 0 ] && ok "theme dirs contain no symlinks" \
      || bad "$n symlinks under ~/.config/omarchy/themes - run: ./install.sh"
    n=$(find "$HOME/.local/state/omarchy/current/theme" -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
    [ "$n" -eq 0 ] && ok "active theme state fully resolves" \
      || bad "$n dangling files in active theme state - run: ./install.sh"
  fi

  echo
  [ "$fail" -eq 0 ] && echo "All checks passed." || echo "$fail check(s) failed."
  return "$fail"
}

if [ "$VERIFY_ONLY" -eq 1 ]; then verify; exit $?; fi

# -------------------------------------------------------------- preflight ----
step "Preflight"
have pacman || { echo "This repo targets Arch/Omarchy only." >&2; exit 1; }
have git    || { echo "git is required." >&2; exit 1; }
if ! have stow; then
  echo "  installing GNU Stow"
  run sudo pacman -S --noconfirm --needed stow || exit 1
fi
echo "  ok"

# ------------------------------------------------------------------ stow ----
stow_packages() {
  step "Linking packages into \$HOME"
  local pkgs=("${PACKAGES[@]}")
  if [ "$WITH_MACHINE" -eq 1 ]; then
    local mpkg="machine-$(hostname -s)"
    if [ -d "$mpkg" ]; then pkgs+=("$mpkg")
    else echo "  note: no $mpkg package in this repo; skipping machine-specific config"; fi
  fi

  if [ "$DRY" -eq 1 ]; then
    # Mirror the real invocation exactly (-n simulates, so nothing is adopted).
    # Without --adopt here, the simulation reports conflicts on every existing
    # file that the real run would quietly adopt.
    stow -n -v --adopt --no-folding "${pkgs[@]}" 2>&1 | sed 's/^/  /'
    return 0
  fi

  # --adopt pulls conflicting real files into the repo, so the tree must be
  # clean for `git checkout` to reliably discard them afterwards.
  # fcitx5 rewrites ~/.config/fcitx5/profile from memory when it exits, and
  # that path is a stow symlink into this repo - so a running instance
  # overwrites the profile moments after stow links it, silently dropping any
  # input method whose engine was missing when fcitx5 started. Stop it first
  # and let that final write land before the dirty check reads the tree.
  fcitx_was_running=0
  if systemctl --user is-active --quiet omarchy-fcitx5.service 2>/dev/null; then
    fcitx_was_running=1
    systemctl --user stop omarchy-fcitx5.service
    echo "  stopped fcitx5 (it rewrites its profile on exit)"
  fi

  if [ -n "$(git status --porcelain)" ]; then
    echo "  error: working tree is dirty. Commit or stash first - stowing uses" >&2
    echo "         'git checkout' to discard files adopted from \$HOME." >&2
    git status --short | sed 's/^/         /' >&2
    return 1
  fi

  # --no-folding keeps every directory real. Without it stow symlinks whole
  # directories that don't yet exist on a fresh machine, and tools like
  # `omarchy theme set` would then write generated files into this repo.
  stow --adopt -v --no-folding "${pkgs[@]}" 2>&1 | sed 's/^/  /'
  git checkout -- .   # throw away anything adopted from $HOME
  [ "$fcitx_was_running" -eq 1 ] \
    && systemctl --user start omarchy-fcitx5.service \
    && echo "  restarted fcitx5 against the linked profile"
  echo "  stowed: ${pkgs[*]}"
  [ "$WITH_MACHINE" -eq 0 ] && echo "  machine-specific config (monitors, displays) NOT applied; use --with-machine"
  return 0
}

if [ "$STOW_ONLY" -eq 1 ]; then stow_packages; exit $?; fi

# -------------------------------------------------------------- packages ----
if [ "$SKIP_PACKAGES" -eq 0 ]; then
  step "Installing packages"
  helper=""
  have yay && helper=yay
  [ -z "$helper" ] && have paru && helper=paru
  # Split the list by source instead of handing all of it to the AUR helper.
  # yay and paru abort the whole run when a single AUR package fails to
  # build, which silently leaves every repo package uninstalled too.
  # sort -u here so the comm stays correct even if a list is edited out of
  # order - comm reads unsorted input as garbage without failing.
  repo_pkgs=$(comm -23 <(sort -u packages.arch.txt) <(sort -u packages.aur.txt))
  aur_pkgs=$(comm -12 <(sort -u packages.arch.txt) <(sort -u packages.aur.txt))

  # One name that no longer exists aborts the entire pacman transaction,
  # so drop unknown names with a warning rather than lose the batch.
  valid="" unknown=""
  for p in $repo_pkgs; do
    if pacman -Si "$p" >/dev/null 2>&1; then valid="$valid $p"; else unknown="$unknown $p"; fi
  done
  [ -n "$unknown" ] && echo "  not in any configured repo, skipped:$unknown"
  # shellcheck disable=SC2086
  [ -n "$valid" ] && run sudo pacman -S --noconfirm --needed $valid

  if [ -n "$helper" ]; then
    # One at a time: a package that fails to build must not stop the rest.
    aur_failed=""
    for p in $aur_pkgs; do
      pacman -Qq "$p" >/dev/null 2>&1 && continue
      run "$helper" -S --noconfirm --needed "$p" || aur_failed="$aur_failed $p"
    done
    [ -n "$aur_failed" ] && echo "  AUR builds failed:$aur_failed" || echo "  all AUR packages present"
  else
    echo "  no AUR helper (yay/paru); skipped $(echo $aur_pkgs | wc -w) AUR packages"
  fi
else
  step "Installing packages"; echo "  skipped (--skip-packages)"
fi

# ----------------------------------------------------------- btrfs / cow ----
# chattr +C only affects files created AFTER it is set, so these directories
# must be prepared while empty - ideally before Steam or monerod ever runs.
# Existing files keep copy-on-write forever and need an explicit rewrite.
cow_stale() {   # any file under $1 missing the NoCOW flag?
  find "$1" -type f 2>/dev/null | head -200 | while IFS= read -r f; do
    lsattr "$f" 2>/dev/null | awk '{print $1}' | grep -q C || { echo x; break; }
  done | grep -qc x
}

nocow_dir() {   # nocow_dir <path-relative-to-$HOME>
  local rel="$1" abs="$HOME/$1"
  if [ "$DRY" -eq 1 ]; then
    [ -d "$abs" ] && echo "  would set NoCOW on existing $rel" || echo "  would create $rel with NoCOW"
    return 0
  fi
  mkdir -p "$abs" || { echo "  could not create $rel"; return 1; }
  if ! chattr +C "$abs" 2>/dev/null; then
    echo "  could not set NoCOW on $rel"; return 1
  fi
  if cow_stale "$abs"; then
    echo "  set NoCOW on $rel - WARNING: existing files predate it and stay CoW"
    echo "      to rewrite them:  mv '$abs'{,.cow} && mkdir '$abs' && chattr +C '$abs' \\"
    echo "                        && cp -a --reflink=never '$abs.cow/.' '$abs/' && rm -rf '$abs.cow'"
  else
    echo "  NoCOW  $rel"
  fi
}

nocow_subvol() {   # nocow_subvol <path-relative-to-$HOME>
  local rel="$1" abs="$HOME/$1"
  if [ "$DRY" -eq 1 ]; then
    [ -e "$abs" ] && echo "  would ensure NoCOW on existing $rel" || echo "  would create subvolume $rel with NoCOW"
    return 0
  fi
  if [ ! -e "$abs" ]; then
    btrfs subvolume create "$abs" >/dev/null 2>&1 || { echo "  could not create subvolume $rel"; return 1; }
    chattr +C "$abs" 2>/dev/null
    echo "  subvolume + NoCOW  $rel"
    return 0
  fi
  if [ "$(stat -c %i "$abs" 2>/dev/null)" = "256" ]; then
    chattr +C "$abs" 2>/dev/null
    cow_stale "$abs" \
      && echo "  subvolume $rel - WARNING: existing files predate NoCOW and stay CoW" \
      || echo "  subvolume + NoCOW  $rel"
  else
    echo "  $rel exists as a plain directory, not a subvolume."
    echo "      to convert (monerod must be stopped, needs root to delete the old dir):"
    echo "        mv '$abs' '$abs.old' && btrfs subvolume create '$abs' && chattr +C '$abs' \\"
    echo "          && cp -a --reflink=never '$abs.old/.' '$abs/' && sudo rm -rf '$abs.old'"
  fi
}

step "btrfs storage layout"
if [ "$(stat -f -c %T "$HOME" 2>/dev/null)" != "btrfs" ]; then
  echo "  \$HOME is not btrfs; nothing to do"
elif ! have chattr; then
  echo "  chattr not available (e2fsprogs); skipping"
else
  for d in "${NOCOW_DIRS[@]}";    do nocow_dir "$d";    done
  for d in "${NOCOW_SUBVOLS[@]}"; do nocow_subvol "$d"; done
fi

# ------------------------------------------------------------------- zsh ----
step "Setting up zsh"
# The plugin clones below create ~/.oh-my-zsh/custom, so the directory
# existing is not proof the core is there - test for the core file itself.
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  echo "  oh-my-zsh already installed"
elif [ -d "$HOME/.oh-my-zsh" ]; then
  # Directory present but no core: an earlier run aborted, almost always
  # because zsh was not installed yet. The upstream installer refuses to
  # write into an existing directory, so fetch the core in place. Nothing
  # under custom/ is tracked by that repo, so the cloned plugins and
  # themes survive the reset.
  echo "  repairing partial oh-my-zsh install"
  run git -C "$HOME/.oh-my-zsh" init -q
  git -C "$HOME/.oh-my-zsh" remote get-url origin >/dev/null 2>&1 \
    || run git -C "$HOME/.oh-my-zsh" remote add origin https://github.com/ohmyzsh/ohmyzsh.git
  run git -C "$HOME/.oh-my-zsh" fetch -q --depth=1 origin master
  run git -C "$HOME/.oh-my-zsh" reset -q --hard FETCH_HEAD
else
  # --unattended: don't chsh and don't drop into a zsh shell mid-install.
  run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
ZCUSTOM="$HOME/.oh-my-zsh/custom"
clone_once() {  # clone_once <url> <dest>
  [ -d "$2" ] && { echo "  present  $(basename "$2")"; return 0; }
  run git clone -q "$1" "$2" && echo "  cloned   $(basename "$2")"
}
clone_once https://github.com/zsh-users/zsh-autosuggestions        "$ZCUSTOM/plugins/zsh-autosuggestions"
clone_once https://github.com/zsh-users/zsh-completions            "$ZCUSTOM/plugins/zsh-completions"
clone_once https://github.com/zsh-users/zsh-syntax-highlighting    "$ZCUSTOM/plugins/zsh-syntax-highlighting"
clone_once https://github.com/MichaelAquilina/zsh-you-should-use   "$ZCUSTOM/plugins/you-should-use"
clone_once https://github.com/romkatv/powerlevel10k                "$ZCUSTOM/themes/powerlevel10k"
# oh-my-zsh writes its own .zshrc; ours comes from the shell package.
if [ "$DRY" -eq 0 ] && [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.pre-dotfiles.$(date +%s)"
  echo "  moved oh-my-zsh's .zshrc aside"
fi

# ------------------------------------------------------------------ tmux ----
step "Setting up tmux"
clone_once https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# ----------------------------------------------------------------- neovim ----
step "Setting up Neovim"
# Neovim is versioned in its own repo, not as a stow package here.
if [ -d "$HOME/.config/nvim/.git" ]; then
  echo "  present  ~/.config/nvim"
elif [ "$DRY" -eq 1 ]; then
  echo "  would clone: $NVIM_REMOTE -> ~/.config/nvim"
else
  [ -e "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.pre-install.$(date +%s)"
  git clone -q "$NVIM_REMOTE" "$HOME/.config/nvim" && echo "  cloned   ~/.config/nvim" \
    || echo "  could not clone $NVIM_REMOTE (needs an SSH key); skipping"
fi

# ------------------------------------------------------------------ stow ----
stow_packages || exit 1

# ---------------------------------------------------------------- themes ----
step "Installing themes"
# Themes are deliberately NOT a stow package. `omarchy theme set` copies a theme
# directory into ~/.local/state/omarchy/current/theme/ preserving symlinks, and
# stow's links are relative: they resolve from ~/.config but dangle from
# ~/.local/state, leaving the shell on default colors, opacity and bar height.
if [ -d themes ]; then
  for t in themes/*/; do
    [ -d "$t" ] || continue
    name="$(basename "$t")"
    if [ "$DRY" -eq 1 ]; then echo "  would install theme: $name"; continue; fi
    mkdir -p "$HOME/.config/omarchy/themes/$name"
    cp -aL "$t." "$HOME/.config/omarchy/themes/$name/"   # -L: never leave a symlink in a theme
    echo "  installed  $name"
  done
else
  echo "  no themes/ in repo"
fi

# --------------------------------------------------------------- plugins ----
step "Adding shell plugins"
# Locally-cloned bar.* widgets ship in the omarchy package; these are the
# git-managed third-party ones.
if [ -s plugins.txt ] && have omarchy; then
  while IFS= read -r url; do
    [ -n "$url" ] || continue
    id="$(basename "$url" .git)"
    if compgen -G "$HOME/.config/omarchy/plugins/*${id#omarchy-}*" >/dev/null; then
      echo "  present  $id"
    elif [ "$DRY" -eq 1 ]; then
      echo "  would add: $url"
    else
      echo "  adding   $url"
      omarchy plugin add "$url" --yes >/dev/null 2>&1 || echo "    failed: $url"
    fi
  done < plugins.txt
else
  echo "  nothing to add"
fi

# ------------------------------------------------------------ backgrounds ----
step "Placing wallpapers"
# Each unique image is stored once - inside its theme, or in the backgrounds
# package - and backgrounds.map replays the layout.
if [ -f backgrounds.map ]; then
  while IFS=$'\t' read -r rel src; do
    [ -n "$rel" ] || continue
    case "$src" in
      theme:*) from="$REPO/themes/${src#theme:}" ;;
      store:*) from="$REPO/backgrounds/.local/share/backgrounds/${src#store:}" ;;
      *) echo "  skip (bad map entry): $rel"; continue ;;
    esac
    [ -f "$from" ] || { echo "  skip (missing source): $rel"; continue; }
    if [ "$DRY" -eq 1 ]; then echo "  would place: $rel"; continue; fi
    mkdir -p "$HOME/.config/omarchy/backgrounds/$(dirname "$rel")"
    cp -aL "$from" "$HOME/.config/omarchy/backgrounds/$rel"
    echo "  placed   $rel"
  done < backgrounds.map
else
  echo "  no backgrounds.map"
fi

# ----------------------------------------------------------------- apply ----
step "Applying"
if [ "$DRY" -eq 1 ]; then
  echo "  would re-apply theme, restart shell, reload Hyprland"
elif have omarchy; then
  theme="$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || echo noctchill)"
  omarchy theme set "$theme" >/dev/null 2>&1 && echo "  theme set: $theme"
  omarchy restart shell >/dev/null 2>&1 && echo "  shell restarted"
  have hyprctl && hyprctl reload >/dev/null 2>&1 && echo "  Hyprland reloaded"
  sleep 2
fi

# ---------------------------------------------------------------- finish ----
if [ "$DRY" -eq 1 ]; then
  echo; echo "Dry run complete - nothing was changed."
  exit 0
fi

verify
rc=$?

echo
echo "Remaining manual steps:"
[ "$WITH_MACHINE" -eq 0 ] && echo "  - displays/monitors:  ./install.sh --with-machine   (identical hardware only)"
echo "  - default shell:      chsh -s /usr/bin/zsh"
echo "  - tmux plugins:       open tmux, press prefix + I"
exit "$rc"
