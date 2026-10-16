#!/bin/bash

# Omarchy's version of this file tested how omarchy-update-system-pkgs-when-conflicted
# handed a pacman package conflict back to the person at the terminal. The port
# deleted that handler with pacman. The case kept is the one about the upgrade
# itself: an unattended update never waits on an answer.

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

run_update() {
  : >"$test_tmp/calls"
  APT_CALLS="$test_tmp/calls" \
    OMARCHY_UPDATE_UNATTENDED="$1" \
    PATH="$stub_bin:$ROOT/bin:$PATH" \
    bash "$ROOT/bin/omarchy-update-system-pkgs" </dev/null >"$test_tmp/out" 2>"$test_tmp/err"
}

run_update 1 || fail "an unattended update fails" "$(cat "$test_tmp/err")"
upgrade=$(grep 'full-upgrade' "$test_tmp/calls")
[[ " $upgrade " == *" -y "* ]] ||
  fail "an unattended update stops on a prompt nobody answers" "$upgrade"
[[ $upgrade == *"Dpkg::Options::=--force-confdef"* && $upgrade == *"Dpkg::Options::=--force-confold"* ]] ||
  fail "an unattended update leaves dpkg's conffile question open" "$upgrade"
pass "-y is kept: an unattended update never waits on an answer"

run_update "" || fail "an attended update fails" "$(cat "$test_tmp/err")"
upgrade=$(grep 'full-upgrade' "$test_tmp/calls")
[[ $upgrade != *"force-conf"* ]] ||
  fail "an attended update answers dpkg's conffile question for the person" "$upgrade"
pass "an attended update leaves dpkg's conffile question to the person"
