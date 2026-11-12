#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1794241568.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
home="$test_dir/home"
branding="$home/.config/omarchy/branding"

run_migration() {
  HOME="$home" OMARCHY_PATH="$ROOT" bash -euo pipefail "$migration" >/dev/null
}

# The distro's first placeholders, as the build repository rendered them for the name Oaxaca.
write_old_about() {
  printf '%s\n' \
    ' ┌────────────┐' \
    ' │  Oaxaca  │' \
    ' └────────────┘' >"$branding/about.txt"
}
write_old_screensaver() {
  printf '%s\n' \
    '' \
    '   ┌──────────────────────────┐' \
    '   │                          │' \
    '   │      Oaxaca       │' \
    '   │                          │' \
    '   └──────────────────────────┘' \
    '' >"$branding/screensaver.txt"
}

# The placeholders written above are the shipped bytes the migration knows.
mkdir -p "$branding"
write_old_about
write_old_screensaver
[[ $(sha256sum "$branding/about.txt" | cut -d' ' -f1) == 2b7af0e9757886f4c35134563841ad8b33dceaf9124c487ace0fc27c8b6b05a5 ]] ||
  fail "the test's about.txt placeholder matches the shipped one"
[[ $(sha256sum "$branding/screensaver.txt" | cut -d' ' -f1) == 589a9abe1a08aef1dc47205ccd9ec3c3be2a37d5edb9abd21f5c2338aa1b83d1 ]] ||
  fail "the test's screensaver.txt placeholder matches the shipped one"

# Both placeholders are replaced with the current artwork.
run_migration
cmp -s "$ROOT/icon.txt" "$branding/about.txt" || fail "the old about.txt is replaced with icon.txt"
cmp -s "$ROOT/logo.txt" "$branding/screensaver.txt" || fail "the old screensaver.txt is replaced with logo.txt"
pass "the old placeholders are replaced with the current artwork"

# A logo the user set is kept, and a second run changes nothing.
echo 'mine' >"$branding/about.txt"
write_old_screensaver
run_migration
run_migration
[[ $(cat "$branding/about.txt") == mine ]] || fail "the user's own about.txt is kept"
cmp -s "$ROOT/logo.txt" "$branding/screensaver.txt" || fail "the old screensaver.txt is still replaced"
pass "the user's own logo is kept and the migration can run twice"

# A user without the branding folder gets nothing created.
rm -rf "$home"
mkdir -p "$home"
run_migration
[[ ! -e $home/.config/omarchy/branding ]] || fail "no branding folder is created"
pass "a user without branding files is left alone"
