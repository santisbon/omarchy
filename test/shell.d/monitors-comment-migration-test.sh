#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1792630210.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/.config/hypr"
lua="$work/.config/hypr/monitors.lua"

# The comment as the first port seeded it, with a user's rule above it.
cat >"$lua" <<'LUA'
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = 1.6 })

-- Layout saved by nwg-displays (Setup > Monitors in the menu): it writes
-- ~/.config/hypr/monitors-gui.lua, loaded here when it exists. Lines above it win.
require("default.hypr.require_optional").module("hypr.monitors-gui")
LUA
HOME="$work" bash "$migration" >/dev/null
diff <(tail -n 4 "$lua") <(tail -n 4 "$ROOT/config/hypr/monitors.lua") >/dev/null ||
  fail "the comment matches the one in config/hypr/monitors.lua" "$(cat "$lua")"
grep -qx 'hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = 1.6 })' "$lua" ||
  fail "the user's rule stays" "$(cat "$lua")"
pass "the first port's comment about nwg-displays is corrected"

# The comment as the release with nwg-displays on Setup > Monitors seeded it.
cat >"$lua" <<'LUA'
-- Layout saved by nwg-displays (Setup > Monitors in the menu): it writes
-- ~/.config/hypr/monitors-gui.lua, loaded here when it exists. Loaded last, its rule for a
-- monitor replaces a rule above for the same monitor: Hyprland keeps the last rule per name.
require("default.hypr.require_optional").module("hypr.monitors-gui")
LUA
HOME="$work" bash "$migration" >/dev/null
diff "$lua" <(tail -n 4 "$ROOT/config/hypr/monitors.lua") >/dev/null ||
  fail "the menu name in the comment is corrected" "$(cat "$lua")"
pass "the comment naming Setup > Monitors is corrected"

before=$(cat "$lua")
HOME="$work" bash "$migration" >/dev/null
[[ $(cat "$lua") == "$before" ]] || fail "a second run changes nothing" "$(cat "$lua")"
pass "a corrected file stays as it is"

rm -f "$lua"
HOME="$work" bash "$migration" >/dev/null
[[ ! -e $lua ]] || fail "no monitors.lua is created" ""
pass "a missing monitors.lua stays missing"
