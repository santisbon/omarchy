#!/bin/bash
#
# The fingerprint setup installs nothing: fprintd, libpam-fprintd and usbutils
# are in the distro's base install (see the comment in
# bin/omarchy-setup-security-fingerprint). Whatever happens, no package manager
# may run; a missing reader or a missing fprintd-enroll stops before
# enrollment, and a failed enrollment must not change PAM. The package
# managers and the privileged calls are stubbed.

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin"
export CALL_LOG="$scratch/calls"
export PATH="$scratch/bin:$ROOT/bin:$PATH"

cat > "$scratch/bin/omarchy-hw-fingerprint" <<'STUB'
#!/bin/bash
exit "${HARDWARE_STATUS:-0}"
STUB
# FPRINTD_MISSING=1 simulates an image without fprintd-enroll; this
# workstation may have the real one in /usr/bin.
cat > "$scratch/bin/omarchy-cmd-missing" <<STUB
#!/bin/bash
[[ \${FPRINTD_MISSING:-0} == 1 && " \$* " == *" fprintd-enroll "* ]] && exit 0
exec "$ROOT/bin/omarchy-cmd-missing" "\$@"
STUB
# PAM changes are recorded, never applied: pam-auth-update is what setup does
# once enrollment and verification pass, and omarchy-apply-lock (stubbed below)
# writes the lock screen's PAM file.
cat > "$scratch/bin/sudo" <<'STUB'
#!/bin/bash
case "$1" in
  -n) exit "${SUDO_CACHED:-1}" ;;
  -v) echo "sudo authenticated" >> "$CALL_LOG"; exit "${SUDO_V_STATUS:-0}" ;;
  fprintd-enroll) exec "$@" ;;
  pam-auth-update) printf 'pam %s\n' "$*" >> "$CALL_LOG" ;;
  tee) printf 'pam %s\n' "$*" >> "$CALL_LOG"; cat >/dev/null ;;
  *) echo "Unexpected privileged call: $*" >> "$CALL_LOG"; exit 99 ;;
esac
STUB
for manager in apt apt-get dpkg pacman snap flatpak; do
  cat > "$scratch/bin/$manager" <<'STUB'
#!/bin/bash
printf 'package %s %s\n' "$(basename "$0")" "$*" >> "$CALL_LOG"
exit 99
STUB
done
# Both fail unless ENROLL_STATUS or VERIFY_STATUS says otherwise, stopping
# before PAM. ENROLL_OUTPUT is what fprintd-enroll prints first.
cat > "$scratch/bin/fprintd-enroll" <<'STUB'
#!/bin/bash
echo enroll >> "$CALL_LOG"
[[ -z ${ENROLL_OUTPUT:-} ]] || printf '%s\n' "$ENROLL_OUTPUT"
exit "${ENROLL_STATUS:-1}"
STUB
cat > "$scratch/bin/fprintd-verify" <<'STUB'
#!/bin/bash
echo verify >> "$CALL_LOG"
exit "${VERIFY_STATUS:-1}"
STUB
# fprintd on D-Bus: SCAN_TYPE is the default reader's scan type and READER_NAME
# its name; with SCAN_TYPE unset, fprintd doesn't answer. Never the host's own fprintd.
cat > "$scratch/bin/busctl" <<'STUB'
#!/bin/bash
[[ -n ${SCAN_TYPE:-} ]] || exit 1
case "$*" in
  *GetDefaultDevice*) echo 'o "/net/reactivated/Fprint/Device/0"' ;;
  *"/net/reactivated/Fprint/Device/0 net.reactivated.Fprint.Device scan-type"*) echo "s \"$SCAN_TYPE\"" ;;
  *"/net/reactivated/Fprint/Device/0 net.reactivated.Fprint.Device name"*) echo "s \"${READER_NAME:-Some USB reader}\"" ;;
  *) exit 1 ;;
esac
STUB
# The dispatcher as the user: no platform the distro runs on registers an
# enable-fingerprint hook, so it resolves to nothing.
cat > "$scratch/bin/omarchy-lifecycle-dispatch" <<'STUB'
#!/bin/bash
echo "resolve ${*:2}" >> "$CALL_LOG"
STUB
chmod +x "$scratch/bin/"*

cat > "$scratch/bin/omarchy-apply-lock" <<'STUB'
#!/bin/bash
echo apply-lock >> "$CALL_LOG"
if [[ ${LOCK_SETUP_UNKNOWN:-0} != "1" ]]; then
  touch "$TEST_LOCK_PAM"
fi
STUB
chmod +x "$scratch/bin/omarchy-apply-lock"

export TEST_LOCK_PAM="$scratch/omarchy-lock-fingerprint"
setup_script="$scratch/omarchy-setup-security-fingerprint"
sed "s|/etc/pam.d/omarchy-lock-fingerprint|$TEST_LOCK_PAM|g" "$ROOT/bin/omarchy-setup-security-fingerprint" > "$setup_script"
chmod +x "$setup_script"

run_setup() {
  : > "$CALL_LOG"
  OMARCHY_PATH="$scratch" "$setup_script" > "$scratch/output" 2>&1
}

# For the cases that read what setup printed where it must stop: enrollment
# fails unless told otherwise, so PAM and the lock screen stay as they are.
run_stopped_setup() {
  if run_setup; then
    fail "setup stops on the simulated enrollment or verify failure"
  fi
  if grep -Eq '^(pam |apply-lock$|Unexpected privileged call)' "$CALL_LOG"; then
    fail "setup does not change PAM or lock recovery after a failed enrollment or verify" "$(cat "$CALL_LOG")"
  fi
}

assert_no_packages() {
  if grep -q '^package ' "$CALL_LOG"; then
    fail "$1: no package manager runs" "$(cat "$CALL_LOG")"
  fi
  if grep -q 'Unexpected privileged call' "$CALL_LOG"; then
    fail "$1: no unexpected privileged call" "$(cat "$CALL_LOG")"
  fi
}

if run_setup; then
  fail "setup stops on the simulated enrollment failure"
fi
assert_no_packages "a failed enrollment"
grep -qx enroll "$CALL_LOG" || fail "setup reaches enrollment without installing anything"
if grep -q '^pam ' "$CALL_LOG"; then
  fail "setup does not change PAM after failed enrollment" "$(cat "$CALL_LOG")"
fi
pass "a failed enrollment installs nothing and leaves PAM alone"

if ENROLL_STATUS=0 run_setup; then
  fail "a failed verification fails setup"
fi
assert_no_packages "a failed verification"
grep -qx verify "$CALL_LOG" || fail "enrollment is followed by verification"
if grep -q '^pam ' "$CALL_LOG"; then
  fail "setup does not change PAM after failed verification" "$(cat "$CALL_LOG")"
fi
pass "a failed verification leaves PAM alone"

ENROLL_STATUS=0 VERIFY_STATUS=0 run_setup || fail "setup succeeds after enrollment and verification" "$(cat "$scratch/output")"
assert_no_packages "a successful setup"
grep -qx 'pam pam-auth-update --package --enable omarchy-fprintd' "$CALL_LOG" ||
  fail "a verified print enables the desktop's lid-gated fprintd PAM profile" "$(cat "$CALL_LOG")"
pass "a verified print enables PAM without installing anything"

if FPRINTD_MISSING=1 run_setup; then
  fail "setup stops when fprintd-enroll is missing"
fi
assert_no_packages "a missing fprintd-enroll"
if grep -qx enroll "$CALL_LOG"; then
  fail "a missing fprintd-enroll stops before enrollment"
fi
pass "a missing fprintd-enroll stops without installing it"

if HARDWARE_STATUS=1 run_setup; then
  fail "setup stops when no reader is detected"
fi
[[ ! -s $CALL_LOG ]] || fail "missing hardware stops before any operation" "$(cat "$CALL_LOG")"
pass "missing hardware performs no operations"

# Successful setup must reuse the same lock/recovery installer as updates.
: > "$CALL_LOG"
OMARCHY_PATH="$scratch" ENROLL_STATUS=0 VERIFY_STATUS=0 \
  "$setup_script" > "$scratch/output" 2>&1 || fail "successful enrollment configures authentication"
[[ $(grep -E '^(enroll|verify|apply-lock)$' "$CALL_LOG") == $'enroll\nverify\napply-lock' ]] ||
  fail "setup configures lock recovery once, after enrollment and verification"
pass "setup reuses apply-lock after enrollment and verification"

rm -f "$TEST_LOCK_PAM"
if OMARCHY_PATH="$scratch" ENROLL_STATUS=0 VERIFY_STATUS=0 LOCK_SETUP_UNKNOWN=1 \
  "$setup_script" > "$scratch/output" 2>&1; then
  fail "an inconclusive lock installer cannot report successful lock setup"
fi
grep -q 'lock-screen configuration could not be confirmed' "$scratch/output" || fail "inconclusive setup explains how to retry"
if grep -q 'Perfect!\|You can use your fingerprint' "$scratch/output"; then
  fail "inconclusive setup does not promise fingerprint unlock"
fi
pass "an inconclusive lock installer cannot report successful lock setup"

# A press sensor takes a touch per sample, so setup
# says to lift and touch again; a swipe sensor keeps the moving-finger
# instruction, and one fprintd can't name is told neither.
press_text=$'Touch the sensor, lift your finger and touch it again.\nKeep going until it says Enrolled. A step can take a few touches.'
swipe_text="Keep moving the finger around on sensor until it says Enrolled."
unnamed_text=$'Touch or swipe the sensor, and keep going until it says Enrolled.\nA step can take a few tries.'
check_instruction() {
  SCAN_TYPE=$1 run_stopped_setup
  local text output
  output=$(<"$scratch/output")
  for text in "$press_text" "$swipe_text" "$unnamed_text"; do
    if [[ $text == "$2" ]]; then
      [[ $output == *"$text"* ]] || fail "$3" "$output"
    else
      [[ $output != *"$text"* ]] || fail "$3" "$output"
    fi
  done
}
check_instruction press "$press_text" "a press sensor is told to lift and touch again"
check_instruction swipe "$swipe_text" "a swipe sensor keeps the moving-finger instruction"
check_instruction "" "$unnamed_text" "a sensor fprintd can't name is told to touch or swipe"
pass "each scan type gets its own instruction, and an unnamed one is told to touch or swipe"

# The verify prompt names the reader's scan type, and neither when fprintd
# can't say which, so a press reader is never told to swipe.
check_verify_prompt() {
  : > "$CALL_LOG"
  SCAN_TYPE=$1 ENROLL_STATUS=0 VERIFY_STATUS=1 \
    OMARCHY_PATH="$scratch" "$setup_script" > "$scratch/output" 2>&1 || true
  grep -qF "Now let's verify that it's working correctly. $2" "$scratch/output" ||
    fail "a ${1:-unnamed} sensor is asked to verify with: $2" "$(cat "$scratch/output")"
}
check_verify_prompt press "Touch the sensor."
check_verify_prompt swipe "Swipe your finger across the sensor."
check_verify_prompt "" "Touch or swipe the sensor."
pass "the verify prompt names the scan type only when fprintd gives one"

# fprintd-enroll's raw results become instructions. Later stages count as steps,
# never touches, since one stage can take several.
enroll_lines=$'Using device /net/reactivated/Fprint/Device/0\nEnrolling right-index-finger finger.'
for result in stage-passed stage-passed retry-scan stage-passed unknown-error; do
  enroll_lines+=$'\nEnroll result: enroll-'$result
done
SCAN_TYPE=press ENROLL_OUTPUT=$enroll_lines run_stopped_setup
expected=$'  ✓ Step 1 done. Keep lifting your finger and touching the sensor.
  ✓ Step 2 done. Keep lifting your finger and touching the sensor.
  That one didn\'t read. Keep lifting your finger and touching the sensor.
  ✓ Step 3 done. Keep lifting your finger and touching the sensor.
  ✗ Enrollment stopped. If you stopped before it said Enrolled, run this again and keep going.'
[[ $(grep -E '^  ' "$scratch/output") == "$expected" ]] ||
  fail "enrollment results read as instructions, counting steps" "$(cat "$scratch/output")"
! grep -q 'Enroll result:' "$scratch/output" || fail "no raw fprintd result reaches the owner" "$(cat "$scratch/output")"
grep -q 'Enrollment failed' "$scratch/output" || fail "a failed enrollment still fails setup" "$(cat "$scratch/output")"
pass "enrollment results read as instructions, and a failed enrollment still fails setup"

# A failed verify fails setup and leaves PAM and the lock screen alone; the
# success path's order is checked above.
: > "$CALL_LOG"
if SCAN_TYPE=press ENROLL_STATUS=0 VERIFY_STATUS=1 \
  OMARCHY_PATH="$scratch" "$setup_script" > "$scratch/output" 2>&1; then
  fail "a failed verify fails setup" "$(cat "$scratch/output")"
fi
grep -qx verify "$CALL_LOG" && ! grep -Eq '^(pam |apply-lock$|Unexpected privileged call)' "$CALL_LOG" ||
  fail "a failed verify leaves PAM and the lock screen alone" "$(cat "$CALL_LOG")"
pass "a failed verify fails setup, leaving PAM and the lock screen alone"

# The verify step's results, in fprintd-verify's own format (each with " (done)"
# or " (not done)"), through the functions setup uses.
source <(sed -n '/^fprintd_chatter()/,/^}/p;/^enroll_progress()/,/^}/p;/^verify_progress()/,/^}/p' \
  "$ROOT/bin/omarchy-setup-security-fingerprint")
[[ $(printf '%s\n' 'Using device /net/reactivated/Fprint/Device/0' 'Listing enrolled fingers:' ' - #0: right-index-finger' \
  'Verify started!' 'Verifying: right-index-finger' 'Verify result: verify-retry-scan (not done)' \
  'Verify result: verify-finger-not-centered (not done)' 'Verify result: verify-match (done)' |
  verify_progress "Touch again.") == $'  That one didn\'t read. Touch again.\n  Not centered: use the middle of the sensor. Touch again.\n  ✓ Matched.' ]] ||
  fail "verify results, retries included, read as instructions"
[[ $(printf '%s\n' 'Verify result: verify-no-match (done)' | verify_progress "Touch again.") == $'  ✗ No match.' ]] ||
  fail "a failed verify says so"
pass "verify results read as instructions"

# sudo's own prompt comes first and is named as such; with sudo already
# authenticated there is no prompt to explain.
SCAN_TYPE=press run_stopped_setup
grep -qF "First, confirm it's you." "$scratch/output" && grep -qx 'sudo authenticated' "$CALL_LOG" ||
  fail "setup names sudo's prompt and authenticates before enrolling" "$(cat "$scratch/output")"
(( $(grep -n "First, confirm it's you." "$scratch/output" | cut -d: -f1) < $(grep -n "Let's set up" "$scratch/output" | cut -d: -f1) )) ||
  fail "sudo's prompt comes before the enrollment instructions" "$(cat "$scratch/output")"
SCAN_TYPE=press SUDO_CACHED=0 run_stopped_setup
! grep -qF "First, confirm it's you." "$scratch/output" && ! grep -qx 'sudo authenticated' "$CALL_LOG" ||
  fail "an authenticated sudo is not asked again" "$(cat "$scratch/output")"
pass "sudo is authenticated, and named, before the enrollment instructions"

# What fprintd prints when it can't go on (a claimed device, no fingers) is
# shown; its routine lines are not.
[[ $(printf '%s\n' 'Using device /net/reactivated/Fprint/Device/0' \
  'failed to claim device: GDBus.Error:net.reactivated.Fprint.Error.AlreadyInUse: Device was already claimed' |
  enroll_progress "Touch again.") == '  failed to claim device: GDBus.Error:net.reactivated.Fprint.Error.AlreadyInUse: Device was already claimed' ]] ||
  fail "why enrollment could not start is shown"
[[ $(printf '%s\n' 'Using device /net/reactivated/Fprint/Device/0' 'No fingers enrolled for this device.' |
  verify_progress "Touch again.") == '  No fingers enrolled for this device.' ]] || fail "why verify could not start is shown"
pass "fprintd's reasons for stopping reach the owner, its routine lines do not"

# A sudo that won't authenticate stops setup with a reason, before enrolling.
SCAN_TYPE=press SUDO_V_STATUS=1 run_stopped_setup
grep -qF "Setup needs administrator rights to enroll a fingerprint." "$scratch/output" && ! grep -qx enroll "$CALL_LOG" ||
  fail "a failed sudo stops setup with a reason" "$(cat "$scratch/output")"
pass "a failed sudo stops setup with a reason, before enrolling"

# Every retry fprintd 1.94.5 can send keeps enrollment going; only a failure
# says it stopped, and a result fprintd adds later is shown, not called a stop.
[[ $(printf '%s\n' 'Enrolling right-index-finger finger.' 'Enroll result: enroll-stage-passed' 'Enroll result: enroll-too-fast' \
  'Enroll result: enroll-swipe-too-short' 'Enroll result: enroll-stage-passed' 'Enroll result: enroll-some-new-result' \
  'Enroll result: enroll-completed' | enroll_progress "Swipe it again.") == $'  ✓ Step 1 done. Swipe it again.\n  Too fast. Swipe it again.\n  Too short. Swipe it again.\n  ✓ Step 2 done. Swipe it again.\n  enroll-some-new-result\n  ✓ Enrolled.' ]] ||
  fail "enrollment retries keep going, and an unknown result is shown"
[[ $(printf '%s\n' 'Verify result: verify-too-fast (not done)' 'Verify result: verify-some-new-retry (not done)' \
  'Verify result: verify-unknown-error (done)' | verify_progress "Swipe it again.") == $'  Too fast. Swipe it again.\n  That one didn\'t read. Swipe it again.\n  ✗ The check stopped (verify-unknown-error).' ]] ||
  fail "any verify result that isn't done is a retry"
pass "every retry keeps the step going, and only a finished failure says it stopped"
