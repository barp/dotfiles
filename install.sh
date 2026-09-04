#!/usr/bin/env bash
# Set up this machine from the repo. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v pacman >/dev/null; then
  echo "This repo targets Arch/Omarchy only." >&2
  exit 1
fi

./scripts/0-packages.arch.sh
./scripts/install-zsh.sh
./scripts/install-tpm.sh
./scripts/install-nvim.sh
./scripts/stow-all.sh
./scripts/install-theme.sh
./scripts/install-plugins.sh
./scripts/install-backgrounds.sh

if command -v omarchy >/dev/null; then
  omarchy restart shell || true
  hyprctl reload || true
fi

./scripts/verify.sh || echo "  (see failures above)"

echo
echo "Done. Remaining manual steps:"
echo "  - monitors/displays:  ./scripts/stow-all.sh --with-machine   (identical hardware only)"
echo "  - check Hyprland:     hyprctl configerrors"
