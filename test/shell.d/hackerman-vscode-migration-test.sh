#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
migration="$ROOT/migrations/1793386202.sh"
current="$work/home/.local/state/omarchy/current"
mkdir -p "$current/theme" "$work/pkg/themes/hackerman" "$work/bin"
cp "$ROOT/themes/hackerman/vscode.json" "$work/pkg/themes/hackerman/vscode.json"
printf '{\n  "name": "Hackerman",\n  "extension": "Bjarne.hackerman-distro"\n}\n' >"$current/theme/vscode.json"
printf '#!/bin/bash\necho themed >>"$THEME_LOG"\n' >"$work/bin/omarchy-theme-set-vscode"
chmod +x "$work/bin/omarchy-theme-set-vscode"
export THEME_LOG="$work/log"
migrate() { HOME="$work/home" OMARCHY_PATH="$work/pkg" PATH="$work/bin:$PATH" bash -euo pipefail "$migration" >/dev/null; }

# On Hackerman, the current theme's copy gets the packaged ID and VS Code is re-themed, once.
echo hackerman >"$current/theme.name"
migrate
migrate
cmp -s "$work/pkg/themes/hackerman/vscode.json" "$current/theme/vscode.json" ||
  fail "the current Hackerman theme gets the packaged vscode.json" "$(cat "$current/theme/vscode.json")"
[[ $(wc -l <"$THEME_LOG") == 1 ]] || fail "VS Code is re-themed once" "$(cat "$THEME_LOG")"
pass "the current Hackerman theme gets its VS Code extension's real ID, once"

# Another current theme is left alone.
rm -f "$THEME_LOG"
echo tokyo-night >"$current/theme.name"
printf '{\n  "name": "Hackerman",\n  "extension": "Bjarne.hackerman-distro"\n}\n' >"$current/theme/vscode.json"
migrate
[[ ! -e $THEME_LOG ]] && grep -q 'hackerman-distro' "$current/theme/vscode.json" || fail "another current theme is left alone"
pass "another current theme is left alone"
