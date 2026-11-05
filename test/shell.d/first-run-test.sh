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

pass "completed first-run exits at its lifecycle gate"

# systemctl enables none of a list when one unit in it is unknown, so a unit
# missing from a build must cost first-run only that unit.
cat >"$mock_bin/systemctl" <<'SH'
#!/bin/bash
[[ $* != *"$OMARCHY_TEST_MISSING_UNIT"* ]] || exit 1
printf '%s\n' "$*" >>"$OMARCHY_TEST_CALLS"
SH
cat >"$mock_bin/omarchy-hook-install" <<'SH'
#!/bin/bash
echo "hook $*" >>"$OMARCHY_TEST_CALLS"
SH
chmod +x "$mock_bin/systemctl" "$mock_bin/omarchy-hook-install"

enable_user_units() {
  rm -f "$test_tmp/calls"
  PATH="$mock_bin:$PATH" OMARCHY_TEST_CALLS="$test_tmp/calls" OMARCHY_TEST_MISSING_UNIT="$1" \
    bash "$ROOT/install/user/first-run/enable-user-units.sh"
}

enable_user_units no-such-unit || fail "first-run enables its user units"
clean_run=$(<"$test_tmp/calls")
grep -Fq 'hook theme-set' <<<"$clean_run" || fail "first-run installs the theme hook"
mapfile -t units < <(sed -n 's/^--user enable --now //p' <<<"$clean_run")

for unit in "${units[@]}"; do
  [[ $unit != *" "* ]] || fail "first-run enables each unit on its own" "$unit"
  if enable_user_units "$unit"; then
    fail "first-run reports a unit it could not enable" "$unit"
  fi
  [[ $(<"$test_tmp/calls") == "$(grep -Fvx -- "--user enable --now $unit" <<<"$clean_run")" ]] ||
    fail "a unit missing from the build costs first-run only that unit" "$unit"
done
(( ${#units[@]} > 1 )) || fail "first-run enables each unit on its own"
pass "a unit missing from the build costs first-run only that unit"

# First run offers an update only when there is one. A fresh install from
# current media is already current, and a critical toast that leads to
# "nothing to do" teaches people to dismiss the next one.
cat >"$mock_bin/nm-online" <<'SH'
#!/bin/bash
exit 0
SH
cat >"$mock_bin/omarchy-update-available" <<'SH'
#!/bin/bash
exit "$OMARCHY_TEST_OMARCHY_UPDATE"
SH
cat >"$mock_bin/omarchy-notification-send" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$OMARCHY_TEST_CALLS"
SH
cat >"$mock_bin/omarchy-i18n" <<'SH'
#!/bin/bash
echo "$1"
SH
chmod +x "$mock_bin/nm-online" "$mock_bin/omarchy-update-available" \
  "$mock_bin/omarchy-notification-send" "$mock_bin/omarchy-i18n"

# Argument: omarchy-update-available's exit status. It reads apt's lists and,
# in a development checkout, the checkout's upstream; the first-run step only
# acts on the answer.
offers_update() {
  : >"$test_tmp/calls"
  OMARCHY_PATH="$checkout" PATH="$mock_bin:$PATH" OMARCHY_TEST_CALLS="$test_tmp/calls" \
    OMARCHY_TEST_OMARCHY_UPDATE="$1" \
    bash -c 'source "$1"; wait' _ "$ROOT/install/user/first-run/wifi.sh"
  grep -Fq -- '--exec omarchy-launch-floating-terminal-with-presentation omarchy-update' "$test_tmp/calls"
}

checkout="$test_tmp/omarchy-checkout"
mkdir -p "$checkout"
ln -s "$ROOT/install" "$checkout/install"

if offers_update 1; then
  fail "first run offers no update when nothing is pending"
fi
offers_update 0 || fail "first run offers an update when packages are pending"
pass "first run offers an update only when there is one"

# Choosing an agent installs it, so the invitation waits for a connection, not
# for the first update.
cat >"$mock_bin/omarchy-default-agent" <<'SH'
#!/bin/bash
SH
cat >"$mock_bin/omarchy-done" <<'SH'
#!/bin/bash
[[ $1 == "ensure" ]]
SH
chmod +x "$mock_bin/omarchy-default-agent" "$mock_bin/omarchy-done"
offers_update 1 || true
grep -Fq -- '--exec omarchy menu summon setup.default.agent' "$test_tmp/calls" ||
  fail "first run invites a default agent once there is a connection"
pass "first run invites a default agent once there is a connection"

# Arguments: the git name and email already configured, empty for unset.
offers_git_setup() {
  : >"$test_tmp/calls"
  local home="$test_tmp/git-home"
  rm -rf "$home" && mkdir -p "$home"
  [[ -z $1 ]] || HOME="$home" git config --global user.name "$1"
  [[ -z $2 ]] || HOME="$home" git config --global user.email "$2"
  HOME="$home" PATH="$mock_bin:$PATH" OMARCHY_TEST_CALLS="$test_tmp/calls" \
    bash "$ROOT/install/user/first-run/git.sh"
  grep -Fq 'omarchy-setup-git' "$test_tmp/calls"
}

offers_git_setup "" "" || fail "first run offers git setup on a fresh account"
offers_git_setup "Jane" "" || fail "first run offers git setup when the email is missing"
if offers_git_setup "Jane" "jane@example.com"; then
  fail "first run offers no git setup when the install already set an identity"
fi
pass "first run offers git setup only when the identity is missing"

# A new user's first login, against a stand-in tree: the shipped migrations are marked done
# before anything else, so the user is not offered them, and every step runs. In the live
# session (boot=casper on the kernel command line) the keybinding lesson is skipped and the
# update prompt is held back.
fake="$test_tmp/omarchy"
mkdir -p "$fake/migrations" "$fake/install/user/first-run"
touch "$fake/migrations/1700000001.sh" "$fake/migrations/1700000002.sh"
for step in enable-user-units gnome-theme gtk-primary-paste audio-tuning welcome git wifi; do
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
printf '#!/bin/bash\nexit 0\n' >"$mock_bin/omarchy-lifecycle-dispatch"
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
