#!/usr/bin/env bash
# Deploy custom themes as REAL FILES into ~/.config/omarchy/themes/.
#
# Themes are deliberately not a stow package. `omarchy theme set` copies the
# theme directory into ~/.local/state/omarchy/current/theme/ preserving
# symlinks, and stow's links are relative - they resolve from the config dir
# but dangle from the state dir, so the shell silently falls back to default
# colors, opacity and bar height.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.config/omarchy/themes"
[ -d "$REPO/themes" ] || { echo "no themes/ in repo; nothing to do"; exit 0; }

for t in "$REPO"/themes/*/; do
  [ -d "$t" ] || continue
  name="$(basename "$t")"
  mkdir -p "$DEST/$name"
  # -L dereferences, so nothing symlinked ever lands in a theme directory.
  cp -aL "$t." "$DEST/$name/"
  echo "installed theme  $name"
done

# Re-apply the active theme so the state copy is regenerated from these files.
active="$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)"
if [ -n "$active" ] && command -v omarchy >/dev/null; then
  omarchy theme set "$active" >/dev/null 2>&1 || true
  echo "re-applied theme $active"
fi
