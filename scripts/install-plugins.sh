#!/usr/bin/env bash
# Re-add the git-managed Omarchy shell plugins listed in plugins.txt.
# Locally-cloned plugins (bar.*) ship in the omarchy stow package instead.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$REPO/plugins.txt" ] || { echo "no plugins.txt; nothing to do"; exit 0; }
command -v omarchy >/dev/null || { echo "omarchy not on PATH; skipping plugins"; exit 0; }

while IFS= read -r url; do
  [ -n "$url" ] || continue
  id="$(basename "$url" .git)"
  if compgen -G "$HOME/.config/omarchy/plugins/*${id#omarchy-}*" >/dev/null; then
    echo "present  $id"; continue
  fi
  echo "adding   $url"
  omarchy plugin add "$url" --yes || echo "  failed: $url"
done < "$REPO/plugins.txt"
