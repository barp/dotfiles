#!/usr/bin/env bash
# Rebuild ~/.config/omarchy/backgrounds from backgrounds.map.
# Each unique image is stored once - either inside its theme or in the
# backgrounds package - and copied into every place the layout wants it.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP="$REPO/backgrounds.map"
DEST="$HOME/.config/omarchy/backgrounds"
[ -f "$MAP" ] || { echo "no backgrounds.map; nothing to do"; exit 0; }

while IFS=$'\t' read -r rel src; do
  [ -n "$rel" ] || continue
  case "$src" in
    theme:*) from="$REPO/themes/${src#theme:}" ;;
    store:*) from="$REPO/backgrounds/.local/share/backgrounds/${src#store:}" ;;
    *) echo "skip (bad map entry): $rel" >&2; continue ;;
  esac
  [ -f "$from" ] || { echo "skip (missing source): $rel <- $src" >&2; continue; }
  mkdir -p "$DEST/$(dirname "$rel")"
  cp -a "$from" "$DEST/$rel"
  echo "placed  $rel"
done < "$MAP"
