#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# On Arch the setup commands create /etc/pam.d/polkit-1, and a hand-rolled stack
# there would silently drop pam_faillock. Ubuntu's polkitd (127-3ubuntu1) ships
# /usr/lib/pam.d/polkit-1, which includes common-auth, so pam-auth-update's profiles
# reach polkit with no stack of Omarchy's; the setup commands must not write one.
for setup in omarchy-setup-security-fingerprint omarchy-setup-security-fido2; do
  script="$ROOT/bin/$setup"
  grep -q 'pam-auth-update' "$script" || fail "$setup configures PAM through pam-auth-update"
  ! grep -q '/etc/pam.d/polkit-1' "$script" || fail "$setup writes no polkit-1 stack of its own"
  pass "$setup leaves polkit's PAM stack to Ubuntu"
done
