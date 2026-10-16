#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

write_stub() {
  local name="$1"
  local body="$2"

  cat >"$stub_bin/$name" <<SH
#!/bin/bash
$body
SH
  chmod +x "$stub_bin/$name"
}

run_pkg_prune() {
  PATH="$stub_bin:$PATH" "$ROOT/bin/omarchy-update-pkg-prune"
}

# The port prunes with apt's autoclean, which drops only the .deb files no
# configured source still offers, so the installed version's file stays.
write_stub sudo 'printf "%s\n" "$*" >"$SUDO_LOG"; exit 0'

SUDO_LOG="$test_tmp/args" run_pkg_prune >"$test_tmp/prune.out" 2>&1
grep -qx 'apt-get autoclean' "$test_tmp/args" ||
  fail "cache prune runs apt-get autoclean" "$(cat "$test_tmp/args")"
pass "cache prune keeps every version the archive still offers"

# Housekeeping failure must not abort the update.
write_stub sudo 'exit 1'
run_pkg_prune >"$test_tmp/fail.out" 2>&1 ||
  fail "cache prune survives apt-get autoclean failure"
grep -q 'Could not prune the package cache' "$test_tmp/fail.out" ||
  fail "cache prune warns when it fails" "$(cat "$test_tmp/fail.out")"
pass "cache prune warns but does not abort the update"

# The port runs the prune after the packages update (bin/omarchy-update says
# why): autoclean only drops files the archive no longer offers, and the
# upgrade is what makes the old ones obsolete.
line_of() {
  grep -n "^[[:space:]]*$1\b" "$ROOT/bin/omarchy-update" | head -1 | cut -d: -f1
}

prune_line=$(line_of omarchy-update-pkg-prune)
pkgs_line=$(line_of omarchy-update-system-pkgs)
[[ -n $prune_line && -n $pkgs_line ]] ||
  fail "omarchy-update runs the cache prune and the packages update"

(( prune_line > pkgs_line )) ||
  fail "cache prune runs after the packages update" "prune: $prune_line, packages: $pkgs_line"
pass "cache prune runs after the packages update"
