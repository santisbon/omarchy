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
# PAM changes are recorded, never applied: pam-auth-update and the tee into
# /etc/pam.d are what setup does once enrollment and verification pass.
cat > "$scratch/bin/sudo" <<'STUB'
#!/bin/bash
case "$1" in
  fprintd-enroll) exec "$@" ;;
  pam-auth-update) printf 'pam %s\n' "$*" >> "$CALL_LOG" ;;
  tee) cat > /dev/null; printf 'pam %s\n' "$*" >> "$CALL_LOG" ;;
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
cat > "$scratch/bin/fprintd-enroll" <<'STUB'
#!/bin/bash
echo enroll >> "$CALL_LOG"
exit "${ENROLL_STATUS:-1}"
STUB
cat > "$scratch/bin/fprintd-verify" <<'STUB'
#!/bin/bash
echo verify >> "$CALL_LOG"
exit "${VERIFY_STATUS:-1}"
STUB
chmod +x "$scratch/bin/"*

run_setup() {
  : > "$CALL_LOG"
  "$ROOT/bin/omarchy-setup-security-fingerprint" > "$scratch/output" 2>&1
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

ENROLL_STATUS=0 run_setup || fail "setup succeeds when verification fails after enrollment"
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
grep -qx 'pam tee /etc/pam.d/omarchy-lock-fingerprint' "$CALL_LOG" ||
  fail "a verified print writes the lock screen's PAM file" "$(cat "$CALL_LOG")"
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
