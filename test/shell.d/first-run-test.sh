#!/bin/bash

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin" "$test_tmp/home"

cat >"$mock_bin/omarchy-done" <<'SH'
#!/bin/bash
[[ $1 == "check" && $2 == "first-run-user" ]]
SH
cat >"$mock_bin/omarchy-provision-user" <<'SH'
#!/bin/bash
touch "$OMARCHY_TEST_FINALIZE_CALLED"
SH
chmod +x "$mock_bin/omarchy-done" "$mock_bin/omarchy-provision-user"

finalize_called="$test_tmp/finalize-called"
HOME="$test_tmp/home" PATH="$mock_bin:$PATH" OMARCHY_TEST_FINALIZE_CALLED="$finalize_called" \
  bash "$ROOT/bin/omarchy-provision-first-run" >"$test_tmp/output"

[[ ! -e $finalize_called ]] || fail "completed first-run exits before any setup step"
grep -F 'First-run already complete' "$test_tmp/output" >/dev/null || fail "completed first-run reports its lifecycle gate"

if grep -F 'user-migration-notify-watch-enabled' "$ROOT/bin/omarchy-provision-first-run" >/dev/null; then
  fail "first-run does not track the migration watcher separately"
fi
if grep -F 'skip-first-run-update-notification' "$ROOT/install/user/first-run/wifi.sh" >/dev/null; then
  fail "first-run does not track update notifications separately"
fi

pass "first-run uses one lifecycle completion marker"

# A new user's first login, against a stand-in tree: the shipped migrations are marked done
# before anything else, so the user is not offered them, and every step runs. In the live
# session (boot=casper on the kernel command line) the keybinding lesson is skipped and the
# update prompt is held back.
fake="$test_tmp/omarchy"
mkdir -p "$fake/migrations" "$fake/install/user/first-run"
touch "$fake/migrations/1700000001.sh" "$fake/migrations/1700000002.sh"
for step in enable-user-units gnome-theme gtk-primary-paste audio-tuning welcome wifi; do
  printf '#!/bin/bash\necho "%s live=${OMARCHY_LIVE_SESSION:-unset}" >>"$OMARCHY_TEST_STEPS"\n' "$step" \
    >"$fake/install/user/first-run/$step.sh"
done
cat >"$mock_bin/omarchy-done" <<'SH'
#!/bin/bash
[[ $1 == "check" ]] && exit 1
exit 0
SH
printf '#!/bin/bash\nexit 0\n' >"$mock_bin/omarchy-hook-install"
printf '#!/bin/bash\nexit 0\n' >"$mock_bin/omarchy-notification-wait"
chmod +x "$mock_bin"/*

run_first_run() {
  HOME="$test_tmp/$1" PATH="$mock_bin:$PATH" OMARCHY_PATH="$fake" \
    OMARCHY_TEST_FINALIZE_CALLED="$finalize_called" OMARCHY_TEST_STEPS="$test_tmp/$1.steps" \
    OMARCHY_KERNEL_CMDLINE="$test_tmp/cmdline" bash "$ROOT/bin/omarchy-provision-first-run" >/dev/null
}

echo "BOOT_IMAGE=/vmlinuz root=UUID=x ro quiet splash" >"$test_tmp/cmdline"
run_first_run installed
for m in 1700000001.sh 1700000002.sh; do
  [[ -f $test_tmp/installed/.local/state/omarchy/migrations/$m ]] || fail "a new user's first-run marks migration $m done"
done
grep -qx 'welcome live=0' "$test_tmp/installed.steps" || fail "an installed system shows the welcome" "$(cat "$test_tmp/installed.steps")"
pass "a new user's first-run marks the shipped migrations done"

echo "BOOT_IMAGE=/casper/vmlinuz boot=casper quiet splash" >"$test_tmp/cmdline"
run_first_run live
! grep -q '^welcome' "$test_tmp/live.steps" || fail "the live session skips the welcome" "$(cat "$test_tmp/live.steps")"
grep -qx 'wifi live=1' "$test_tmp/live.steps" || fail "the Wi-Fi step learns it runs in the live session" "$(cat "$test_tmp/live.steps")"
pass "the live session skips the keybinding lesson and tells the Wi-Fi step"

# The user's setup fails (on 2026-10-20 the first login came before Wi-Fi, and Node's download
# stopped it): the failure is logged, the other steps still run, and first-run is not marked
# done, so the next login retries the setup.
cat >"$mock_bin/omarchy-provision-user" <<'SH'
#!/bin/bash
exit 3
SH
printf '#!/bin/bash\n[[ $1 == "check" ]] && exit 1\necho "$*" >>"$OMARCHY_TEST_DONE_LOG"\n' >"$mock_bin/omarchy-done"
chmod +x "$mock_bin"/*
echo "BOOT_IMAGE=/vmlinuz root=UUID=x ro quiet splash" >"$test_tmp/cmdline"
OMARCHY_TEST_DONE_LOG="$test_tmp/done.log" run_first_run offline
log="$test_tmp/offline/.local/state/omarchy/first-run.log"
grep -q "Failed: finish the user's setup (exit code: 3)" "$log" || fail "a failed user setup is logged" "$(cat "$log")"
grep -qx 'wifi live=0' "$test_tmp/offline.steps" || fail "the other first-run steps still run" "$(cat "$test_tmp/offline.steps")"
! grep -qx 'mark first-run-user' "$test_tmp/done.log" 2>/dev/null || fail "first-run is left for the next login to retry"
pass "a failed user setup is logged and retried at the next login"
