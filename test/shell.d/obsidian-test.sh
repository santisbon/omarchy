#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin"
for cmd in omarchy-pkg-snap-add setsid omarchy-launch-or-focus omarchy-launch-floating-terminal-with-presentation; do
  printf '#!/bin/bash\necho "%s $*" >>"$TEST_LOG"\n' "$cmd" >"$work/bin/$cmd"
done
printf '#!/bin/bash\n[[ $1 == "obsidian" && ${TEST_SNAP:-0} == 1 ]]\n' >"$work/bin/omarchy-pkg-snap-present"
chmod +x "$work/bin"/*

: >"$TEST_LOG"
PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-install-productivity-obsidian" >/dev/null
grep -qx 'omarchy-pkg-snap-add obsidian --classic' "$TEST_LOG" ||
  fail "the installer adds Obsidian's snap with classic confinement" "$(cat "$TEST_LOG")"
pass "the installer adds Obsidian's snap with classic confinement"

: >"$TEST_LOG"
PATH="$work/bin:$PATH" TEST_SNAP=1 bash "$ROOT/bin/omarchy-launch-obsidian"
grep -qx 'omarchy-launch-or-focus ^obsidian$ uwsm-app -- /snap/bin/obsidian' "$TEST_LOG" ||
  fail "the launcher focuses or starts the installed snap" "$(cat "$TEST_LOG")"
pass "the launcher focuses or starts the installed snap"

: >"$TEST_LOG"
PATH="$work/bin:$PATH" TEST_SNAP=0 bash "$ROOT/bin/omarchy-launch-obsidian"
grep -qx 'omarchy-launch-floating-terminal-with-presentation omarchy-install-productivity-obsidian' "$TEST_LOG" ||
  fail "the launcher opens the installer while the snap is missing" "$(cat "$TEST_LOG")"
pass "the launcher opens the installer while the snap is missing"

grep -Fq 'o.bind("SUPER + SHIFT + O", "Obsidian", { omarchy = "obsidian" })' "$ROOT/default/hypr/bindings/applications.lua" ||
  fail "Super+Shift+O runs the Obsidian launcher"
pass "Super+Shift+O runs the Obsidian launcher"

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
grep -q '"install.productivity.obsidian":.*"when":"! omarchy-pkg-snap-present obsidian".*omarchy-install-productivity-obsidian' "$menu" ||
  fail "Install > Productivity > Obsidian shows while the snap is missing"
grep -q "\"remove.productivity.obsidian\":.*\"when\":\"omarchy-pkg-snap-present obsidian\".*'omarchy-pkg-snap-drop obsidian'" "$menu" ||
  fail "Remove > Productivity > Obsidian drops the snap"
pass "Install and Remove > Productivity > Obsidian"

grep -qx '  omarchy-theme-set-obsidian' "$ROOT/bin/omarchy-theme-set" ||
  fail "a theme change runs the Obsidian theme sync"
pass "a theme change runs the Obsidian theme sync"

# The sync copies the current theme's obsidian.css into each vault obsidian.json lists.
home="$work/home"
mkdir -p "$home/.local/state/omarchy/current/theme" "$home/.config/obsidian" "$home/Vault/.obsidian" "$home/Gone"
echo '/* theme */' >"$home/.local/state/omarchy/current/theme/obsidian.css"
printf '{"vaults":{"a":{"path":"%s"},"b":{"path":"%s"}}}\n' "$home/Vault" "$home/Gone" >"$home/.config/obsidian/obsidian.json"
HOME="$home" bash "$ROOT/bin/omarchy-theme-set-obsidian"
cmp -s "$home/.local/state/omarchy/current/theme/obsidian.css" "$home/Vault/.obsidian/themes/Omarchy/theme.css" ||
  fail "the sync copies the theme into a vault"
[[ $(jq -r .name "$home/Vault/.obsidian/themes/Omarchy/manifest.json") == "Omarchy" ]] ||
  fail "the sync writes the theme's manifest"
[[ ! -e $home/Gone/.obsidian ]] || fail "the sync skips a listed folder that is not a vault"
pass "the sync themes each vault Obsidian lists"
