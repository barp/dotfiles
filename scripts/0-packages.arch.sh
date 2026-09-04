#!/usr/bin/env bash
# Install the package set from the source machine. Needs an AUR helper for
# packages.aur.txt; plain pacman is enough for the rest.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v yay >/dev/null; then HELPER=yay
elif command -v paru >/dev/null; then HELPER=paru
else
  echo "No AUR helper found. Installing repo packages only; $REPO/packages.aur.txt"
  echo "will need yay or paru."
  HELPER=""
fi

if [ -n "$HELPER" ]; then
  # shellcheck disable=SC2046
  "$HELPER" -S --noconfirm --needed $(cat "$REPO/packages.arch.txt")
else
  # shellcheck disable=SC2046
  sudo pacman -S --noconfirm --needed $(comm -23 \
    <(sort "$REPO/packages.arch.txt") <(sort "$REPO/packages.aur.txt")) || true
fi
