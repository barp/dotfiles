#!/usr/bin/env bash
# Post-sync / post-stow health check. Catches the failure modes that broke this
# system during the Omarchy 4 consolidation.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fail=$((fail+1)); }

echo "Repo integrity"
n=$(find "$REPO" -path "$REPO/.git" -prune -o -type l -print 2>/dev/null \
    | while IFS= read -r l; do case "$(readlink "$l")" in *.dotfiles/*|"$REPO"/*) echo x;; esac; done | wc -l)
[ "$n" -eq 0 ] && ok "no self-referential symlinks" || bad "$n self-referential symlinks - run: git checkout-index -f -a"
n=$(git -C "$REPO" ls-files | while IFS= read -r f; do [ -e "$REPO/$f" ] || echo x; done | wc -l)
[ "$n" -eq 0 ] && ok "no tracked files missing from working tree" || bad "$n tracked files missing - run: git checkout-index -f -a"

echo "Stowed links"
n=$(find "$HOME/.config" "$HOME/.local/share" -maxdepth 4 -type l ! -exec test -e {} \; -print 2>/dev/null \
    | grep -c "dotfiles" || true)
[ "$n" -eq 0 ] && ok "every link into the repo resolves" || bad "$n dangling links into the repo"

echo "Hyprland"
if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
  b=$(hyprctl binds 2>/dev/null | grep -c '^bind')
  [ "$b" -gt 100 ] && ok "$b keybindings registered" || bad "only $b keybindings - run: hyprctl reload"
  e=$(hyprctl configerrors 2>&1 | grep -c .)
  [ "$e" -eq 0 ] && ok "no config errors" || bad "$e config errors"
else
  echo "  skip  hyprland not running"
fi

echo "Omarchy shell"
if command -v omarchy >/dev/null; then
  python3 -c "import json;json.load(open('$HOME/.config/omarchy/shell.json'))" 2>/dev/null \
    && ok "shell.json is valid JSON" || bad "shell.json is not valid JSON"
  # Every widget the bar layout references must actually be enabled. A shell
  # restarted mid-sync silently marks missing plugins disabled and keeps that
  # state - the bar then renders without them.
  ids=$(python3 - <<'PY'
import json,os
d=json.load(open(os.path.expanduser('~/.config/omarchy/shell.json')))
out=set()
for sec in d.get('bar',{}).get('layout',{}).values():
    for w in sec:
        i=w.get('id','')
        if i and not i.startswith('omarchy.'): out.add(i)
print('\n'.join(sorted(out)))
PY
)
  state=$(omarchy plugin list 2>/dev/null)
  for id in $ids; do
    if echo "$state" | grep -qE "^$id +enabled"; then ok "widget $id enabled"
    else bad "widget $id NOT enabled - run: omarchy theme set \$(cat ~/.local/state/omarchy/current/theme.name) && omarchy restart shell"; fi
  done
  t=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)
  [ -n "$t" ] && ok "theme applied: $t" || bad "no theme recorded"

  # A theme directory must contain real files. `omarchy theme set` copies it
  # into the state dir preserving symlinks, and a relative link that resolved
  # from ~/.config dangles from ~/.local/state - the shell then silently falls
  # back to default colors, opacity and bar height.
  n=$(find "$HOME/.config/omarchy/themes" -type l 2>/dev/null | wc -l)
  [ "$n" -eq 0 ] && ok "theme dirs contain no symlinks" \
    || bad "$n symlinks under ~/.config/omarchy/themes - run: ./scripts/install-theme.sh"
  n=$(find "$HOME/.local/state/omarchy/current/theme" -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
  [ "$n" -eq 0 ] && ok "active theme state fully resolves" \
    || bad "$n dangling files in the active theme state - run: ./scripts/install-theme.sh"
fi

echo
[ "$fail" -eq 0 ] && echo "All checks passed." || echo "$fail check(s) failed."
exit "$fail"
