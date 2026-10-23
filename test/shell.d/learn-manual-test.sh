#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
grep -qE '"learn\.omarchy": \{"icon":"[^"]*","label":"Omarchy","action":"omarchy-launch-webapp .https://omarchy\.org/manual/."\}' "$menu" ||
  fail "Learn > Omarchy opens Omarchy's manual address, as on Omarchy"
pass "Learn > Omarchy is in the menu"

# rename.sh runs on a copy of the tree, as the packaging does. The menu's entry keys keep
# Omarchy's spelling (learn.omarchy); the label and the address are the distro's.
renamed_tree() {
  local tree=$1
  shift
  mkdir -p "$tree"
  cp -a "$ROOT"/{default,shell,port} "$tree/"
  env "$@" DISTRO_ID=distro DISTRO_NAME=Distro bash "$tree/port/rename.sh" --tree "$tree" >/dev/null ||
    fail "the rename passes its own leftover check"
}

renamed_tree "$work/with" DISTRO_MANUAL_URL=https://distro.example/manual/ DISTRO_HOME_URL=https://example.org/distro
grep -qE '"learn\.omarchy": \{"icon":"[^"]*","label":"Distro","action":"distro-launch-webapp .https://distro\.example/manual/."\}' \
  "$work/with/default/distro/distro-menu.jsonc" ||
  fail "with DISTRO_MANUAL_URL, Learn > Distro opens the distro's manual" "$(grep -F learn.omarchy "$work/with/default/distro/distro-menu.jsonc")"
pass "with DISTRO_MANUAL_URL, the rename points Learn at the distro's manual"

renamed_tree "$work/without"
grep -qF "distro-launch-webapp 'https://omarchy.org/manual/'" "$work/without/default/distro/distro-menu.jsonc" ||
  fail "without DISTRO_MANUAL_URL, Learn keeps Omarchy's manual"
pass "without DISTRO_MANUAL_URL, the rename leaves Omarchy's manual address"
