#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/run" "$work/home"

stub() { printf '#!/bin/bash\n%s\n' "$2" >"$work/bin/$1"; chmod +x "$work/bin/$1"; }
stub gum 'echo "gum $*" >>"$TEST_LOG"; exit 1'
stub uname 'echo 7.3.0-9-generic'
stub pgrep 'exit 1'
stub omarchy-restart-shell 'exit 0'

# Run the restart step with /run/ moved under the work directory; no newer kernel on disk.
run() { sed "s#/run/reboot-required#$work/run/reboot-required#g; s#/boot/vmlinuz-#$work/boot/vmlinuz-#g" "$ROOT/bin/omarchy-update-restart" |
  HOME="$work/home" PATH="$work/bin:$PATH" bash >/dev/null 2>&1 || true; }

run
! grep -q 'Reboot\|reboot' "$TEST_LOG" 2>/dev/null || fail "no marker, no reboot question"

touch "$work/run/reboot-required"
run
grep -q '^gum confirm Updates require reboot. Ready?$' "$TEST_LOG" || fail "a package's /run/reboot-required brings the reboot question" "$(cat "$TEST_LOG")"

pass "the update offers a reboot when a package asked for one in /run/reboot-required"

# A session that began before the update that introduced OMARCHY_PATH: the restart step puts
# the variable into the user manager, so the shell and units started afterwards have it.
stub systemctl 'echo "systemctl $*" >>"$TEST_LOG"; [[ $2 == show-environment ]] && printf "%s\n" ${TEST_SESSION_ENV:-}; exit 0'
: >"$TEST_LOG"
rm -f "$work/run/reboot-required"
(unset OMARCHY_PATH; run)
grep -qx 'systemctl --user set-environment OMARCHY_PATH=/usr/share/omarchy' "$TEST_LOG" ||
  fail "the restart step gives a session without OMARCHY_PATH the packaged tree" "$(cat "$TEST_LOG")"
: >"$TEST_LOG"
TEST_SESSION_ENV=OMARCHY_PATH=/home/me/omarchy run
! grep -q 'set-environment' "$TEST_LOG" || fail "the restart step leaves a session's OMARCHY_PATH alone" "$(cat "$TEST_LOG")"
pass "the update gives a session that predates OMARCHY_PATH the variable"
