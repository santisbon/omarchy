#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

# omarchy-dev-font replace redraws the glyph a codepoint already maps to, in place: the font keeps
# its glyph count, every other mark is untouched, the old outline is gone, and the codepoint's
# README line names the new source.
tool="$ROOT/bin/omarchy-dev-font"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp "$ROOT/default/fonts/omarchy/omarchy.ttf" "$ROOT/default/fonts/omarchy/README.md" "$work/"
font="$work/omarchy.ttf"

cat >"$work/square.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50"><path d="M0,0h100v50h-100z"/></svg>
SVG

before=$(python3 -I "$tool" list --font "$font")
python3 -I "$tool" replace U+E900 "$work/square.svg" --name square --label "a test square" --font "$font" >/dev/null
after=$(python3 -I "$tool" list --font "$font")

[[ $(wc -l <<<"$before") == $(wc -l <<<"$after") ]] || fail "replace keeps the font's glyph count" "$after"
[[ $(grep -v '^U+E900' <<<"$before") == $(grep -v '^U+E900' <<<"$after") ]] ||
  fail "replace leaves every other mark as it was" "$after"
grep -Eq '^U\+E900 .* square +896 x 448$' <<<"$after" ||
  fail "U+E900 now holds the new outline, scaled into the font's 896 box" "$(grep '^U+E900' <<<"$after")"
grep -qx -- '- `U+E900` — a test square' "$work/README.md" || fail "the README line for U+E900 names the new mark"
(( $(grep -c '^- `U+E900`' "$work/README.md") == 1 )) || fail "the README keeps one line for U+E900"

python3 -I "$tool" replace U+E9FF "$work/square.svg" --font "$font" >/dev/null 2>&1 &&
  fail "replace refuses a codepoint the font does not have"
python3 -I "$tool" add again "$work/square.svg" --codepoint U+E900 --font "$font" >/dev/null 2>&1 &&
  fail "add still refuses a codepoint in use"

pass "omarchy-dev-font replace redraws a mark in place"
