#!/usr/bin/env bash
# Symlink every package into $HOME.
# Existing real files are adopted, then reset to the repo's version - so a
# machine that already has Omarchy defaults in place converts cleanly.
# Usage: scripts/stow-all.sh [--dry-run] [--with-machine]
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

PACKAGES=(omarchy hypr terminals shell tmux tools mpv desktop input backgrounds)
DRY=0; WITH_MACHINE=0
for a in "$@"; do case "$a" in
  --dry-run) DRY=1 ;;
  --with-machine) WITH_MACHINE=1 ;;
  *) echo "unknown option: $a" >&2; exit 1 ;;
esac; done

if [ "$WITH_MACHINE" -eq 1 ]; then
  mpkg="machine-$(hostname -s)"
  if [ -d "$mpkg" ]; then PACKAGES+=("$mpkg")
  else echo "note: no $mpkg package in this repo; skipping machine-specific config"; fi
fi

if [ "$DRY" -eq 1 ]; then
  stow -n -v --no-folding "${PACKAGES[@]}"
  exit 0
fi

# --adopt pulls conflicting real files into the repo, so the tree must be clean
# for `git checkout` to reliably undo that.
if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty. Commit or stash first - this script uses" >&2
  echo "       'git checkout' to discard files adopted from \$HOME." >&2
  git status --short >&2
  exit 1
fi

# --no-folding keeps every directory real. Without it, stow symlinks whole
# directories that don't yet exist on a fresh machine, and `omarchy theme set`
# would then write its generated theme files back into this repo.
stow --adopt -v --no-folding "${PACKAGES[@]}"
# Anything adopted differs from the committed version; throw the intruder away.
git checkout -- .

echo
echo "Stowed: ${PACKAGES[*]}"
[ "$WITH_MACHINE" -eq 0 ] && echo "Machine-specific config (monitors, displays) NOT applied. Use --with-machine on identical hardware."
