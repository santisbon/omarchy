#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"
source "$SHELL_TEST_DIR/fixtures/sudo-boundary-test.sh"
copy_boundary_file bin/omarchy-update
test_tmp="$boundary_tmp"
stub_bin="$SUDO_TEST_ROOT/bin"

# Every step omarchy-update runs, recorded in order with the unattended flag it
# was handed. One of them can be told to fail. omarchy-update-available is here
# so a recheck after the update would show up as an unexpected step.
steps=(
  omarchy-update-lock
  omarchy-update-requires-free-space
  omarchy-update-confirm
  omarchy-snapshot
  omarchy-update-stay-awake
  omarchy-update-dev
  omarchy-update-system-pkgs
  omarchy-migrate
  omarchy-restart-shell
  omarchy-hook
  omarchy-update-mise
  omarchy-update-orphan-pkgs
  omarchy-update-pkg-prune
  omarchy-update-analyze-logs
  omarchy-shell
  omarchy-update-available
  omarchy-update-restart
)

for step in "${steps[@]}"; do
  rm -f "$stub_bin/$step"
  cat >"$stub_bin/$step" <<'STUB'
#!/bin/bash
step=${0##*/}
# The pending check is a step of its own, so the order around the restart shows.
if [[ $step == "omarchy-migrate" && ${1:-} == "--pending" ]]; then
  step+=":--pending"
fi
printf '%s unattended=%s\n' "$step" "${OMARCHY_UPDATE_UNATTENDED:-}" >>"$STEP_LOG"
[[ $step != "omarchy-migrate:--pending" || ${NO_PENDING:-} != 1 ]] || exit 1
if [[ ${0##*/} == "omarchy-update-orphan-pkgs" ]]; then
  printf '%s\n' "$@" >"$STEP_LOG.orphan-args"
fi
if [[ ${0##*/} == "omarchy-shell" ]]; then
  printf '%s\n' "$*" >"$STEP_LOG.shell-args"
fi
[[ ${FAILING_STEP:-} != "${0##*/}" ]] || exit "${FAILING_STATUS:-1}"
STUB
  chmod +x "$stub_bin/$step"
done

# OMARCHY_UPDATE_LOGGED stands in for the script(1) wrapper the update re-execs
# itself under; the stubbed lock reports itself already held.
run_update() {
  : >"$test_tmp/steps"
  STEP_LOG="$test_tmp/steps" \
    FAILING_STEP="${FAILING_STEP:-}" \
    FAILING_STATUS="${FAILING_STATUS:-1}" \
    OMARCHY_UPDATE_LOGGED=1 \
    PATH="$stub_bin:$PATH" \
    "$SUDO_TEST_ROOT/bin/omarchy-update" "$@" >"$test_tmp/out" 2>"$test_tmp/err"
}

steps_run() {
  cut -d' ' -f1 "$test_tmp/steps"
}

# Every step of a whole update, in order. $1 asks for the one a person confirms;
# an empty $2 leaves out the shell restart, for an update with nothing to migrate.
# Stay Awake bookends the work, so it is here twice. The port has no keyring or
# AUR step (apt has neither), and prunes the package cache after the upgrade
# rather than before the snapshot (bin/omarchy-update says why).
expected_steps() {
  printf '%s\n' \
    omarchy-update-lock \
    omarchy-update-requires-free-space \
    ${1:+omarchy-update-confirm} \
    omarchy-snapshot \
    omarchy-update-stay-awake \
    omarchy-update-dev \
    omarchy-update-system-pkgs \
    omarchy-migrate:--pending \
    ${2-omarchy-restart-shell} \
    omarchy-migrate \
    omarchy-update-orphan-pkgs \
    omarchy-update-analyze-logs \
    omarchy-shell \
    omarchy-update-restart \
    omarchy-hook \
    omarchy-update-mise \
    omarchy-update-pkg-prune \
    omarchy-update-stay-awake \
    omarchy-update-restart
}

run_update -y || fail "an update where everything works reports a failure"
diff <(expected_steps) <(steps_run) >"$test_tmp/order" ||
  fail "an update where everything works does not run every step in order" "$(cat "$test_tmp/order")"
pass "an update where every step works runs all of them, in order"
[[ $(cat "$test_tmp/steps.orphan-args") == "-y" ]] || fail "an unattended update approves orphan removal"
pass "an unattended update approves orphan removal"
[[ $(cat "$test_tmp/steps.shell-args") == "-q omarchy.system-update clear" ]] ||
  fail "a finished update clears the shell update indicator" "$(cat "$test_tmp/steps.shell-args")"
pass "a finished update clears the shell update indicator without rechecking"

grep -q '^omarchy-update-system-pkgs unattended=1$' "$test_tmp/steps" ||
  fail "-y does not mark the update unattended"
run_update </dev/null || fail "a confirmed update reports a failure"
diff <(expected_steps confirmed) <(steps_run) >"$test_tmp/order" ||
  fail "a confirmed update runs a different set of steps" "$(cat "$test_tmp/order")"
grep -q '^omarchy-update-system-pkgs unattended=$' "$test_tmp/steps" ||
  fail "an update a person confirmed is treated as unattended"
pass "-y is what marks an update unattended, not the update itself"
[[ $(cat "$test_tmp/steps.orphan-args") == "-y" ]] || fail "a confirmed update approves orphan removal"
pass "a confirmed update approves orphan removal"

NO_PENDING=1 run_update -y || fail "an update with nothing to migrate reports a failure"
diff <(expected_steps "" "") <(steps_run) >"$test_tmp/order" ||
  fail "an update with nothing to migrate restarts the shell anyway" "$(cat "$test_tmp/order")"
pass "an update restarts the shell before migrating only when migrations are pending"

# Migrations ship with the packages the upgrade installs and are written against
# them. Running them against what is still on disk is the failure this ordering
# exists to prevent, so the update stops where the packages did.
if FAILING_STEP=omarchy-update-system-pkgs run_update -y; then
  fail "an update whose packages did not upgrade passes for a whole one"
fi
for step in omarchy-migrate omarchy-restart-shell omarchy-hook omarchy-update-mise omarchy-update-restart; do
  if grep -q "^$step " "$test_tmp/steps"; then
    fail "a blocked package upgrade still runs $step"
  fi
done
pass "a blocked package upgrade stops the update before it migrates"

# omarchy-snapshot exits 127 where snapshots are deliberately absent (no btrfs
# root or no Timeshift); that is not worth a word. Any other failure is not
# worth blocking the update over, but must not pass for a snapshot either.
FAILING_STEP=omarchy-snapshot FAILING_STATUS=127 run_update -y ||
  fail "an update without snapshot support reports a failure"
diff <(expected_steps) <(steps_run) >"$test_tmp/order" ||
  fail "an update without snapshot support skips steps" "$(cat "$test_tmp/order")"
! grep -q 'without a snapshot' "$test_tmp/err" ||
  fail "an update without snapshot support warns about the missing snapshot"
pass "an update without snapshot support continues quietly"

FAILING_STEP=omarchy-snapshot FAILING_STATUS=1 run_update -y ||
  fail "a failed snapshot fails the update"
diff <(expected_steps) <(steps_run) >"$test_tmp/order" ||
  fail "a failed snapshot skips update steps" "$(cat "$test_tmp/order")"
grep -q 'Continuing the update without a snapshot' "$test_tmp/err" ||
  fail "a failed snapshot passes silently" "$(cat "$test_tmp/err")"
pass "a failed snapshot warns and the update continues"

# Optional tools may fail after system packages have already changed. Verify
# boot files and release Stay Awake before offering a reboot.
FAILING_STEP=omarchy-update-mise run_update -y || fail "a failed mise update prevents system update completion"
diff <(expected_steps) <(steps_run) >"$test_tmp/order" ||
  fail "a failed mise update skips later update steps" "$(cat "$test_tmp/order")"
grep -q "omarchy update mise" "$test_tmp/err" || fail "the tool update failure has no retry guidance"
pass "a mise failure still finishes the update, offers a reboot and explains how to retry"
