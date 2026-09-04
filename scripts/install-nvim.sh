#!/usr/bin/env bash
# Neovim is versioned in its own repo, not as a stow package here.
set -euo pipefail
DEST="$HOME/.config/nvim"
REMOTE="git@github.com:barp/lazyvim-config.git"
if [ -d "$DEST/.git" ]; then
  echo "nvim config already present at $DEST"
else
  [ -e "$DEST" ] && mv "$DEST" "$DEST.pre-install.$(date +%s)"
  git clone "$REMOTE" "$DEST"
fi
