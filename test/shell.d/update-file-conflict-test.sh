#!/bin/bash

# Omarchy's version of this file tested omarchy-update-system-pkgs-when-conflicted,
# which moved files out of pacman's way and retried the upgrade. The port deleted
# that handler with pacman: omarchy-update-system-pkgs now runs apt-get, which has
# no retry. The case kept is the one about the upgrade itself: a clean upgrade
# pays for nothing extra.

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

cat >"$stub_bin/sudo" <<'STUB'
#!/bin/bash
exec "$@"
STUB

# Records each call's arguments, one line per call.
cat >"$stub_bin/apt-get" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >>"$APT_CALLS"
STUB

chmod +x "$stub_bin/sudo" "$stub_bin/apt-get"

: >"$test_tmp/calls"
APT_CALLS="$test_tmp/calls" \
  OMARCHY_UPDATE_UNATTENDED= \
  PATH="$stub_bin:$ROOT/bin:$PATH" \
  bash "$ROOT/bin/omarchy-update-system-pkgs" >"$test_tmp/out" 2>"$test_tmp/err" ||
  fail "a clean upgrade fails" "$(cat "$test_tmp/err")"
[[ $(grep -c 'full-upgrade' "$test_tmp/calls") == 1 ]] ||
  fail "a clean upgrade runs more than one apt-get full-upgrade" "$(cat "$test_tmp/calls")"
[[ $(sed -n 1p "$test_tmp/calls") == "update" ]] ||
  fail "a clean upgrade refreshes the package lists first" "$(cat "$test_tmp/calls")"
(( $(wc -l <"$test_tmp/calls") == 2 )) ||
  fail "a clean upgrade runs only apt-get update and one full-upgrade" "$(cat "$test_tmp/calls")"
pass "a clean upgrade runs a single apt-get full-upgrade"
