#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1792164994.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
home="$test_dir/home"

run_migration() {
  HOME="$home" OMARCHY_PATH="$ROOT" bash -euo pipefail "$migration" >/dev/null
}

# A user with none of the three configurations gets Omarchy's, and btop's theme link.
mkdir -p "$home"
run_migration
for rel in btop/btop.conf lazygit/config.yml starship.toml; do
  cmp -s "$ROOT/config/$rel" "$home/.config/$rel" || fail "$rel is seeded"
done
[[ $(readlink "$home/.config/btop/themes/current.theme") == "$home/.local/state/omarchy/current/theme/btop.theme" ]] ||
  fail "btop's current theme links to the rendered theme"
pass "a user without the configurations gets them and btop's theme link"

# A user's own configuration and theme file are left alone, and a second run changes nothing.
rm -rf "$home"
mkdir -p "$home/.config/btop/themes"
echo 'mine' >"$home/.config/starship.toml"
echo 'mine' >"$home/.config/btop/themes/current.theme"
run_migration
run_migration
[[ $(cat "$home/.config/starship.toml") == mine ]] || fail "the user's starship.toml is kept"
[[ ! -L $home/.config/btop/themes/current.theme && $(cat "$home/.config/btop/themes/current.theme") == mine ]] ||
  fail "the user's own btop theme file is kept"
cmp -s "$ROOT/config/btop/btop.conf" "$home/.config/btop/btop.conf" || fail "the missing btop.conf is still seeded"
pass "the user's own files are kept and the migration can run twice"
