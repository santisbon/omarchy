#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

profile="$ROOT/default/pam-configs/omarchy-fprintd"
mapfile -t auth < <(sed -n '/^Auth:/,$p' "$profile" | tail -n +2)
# auth[0] is the service gate, checked by security-pam-scope-test.sh.
[[ ${auth[1]} == *"[success=1 default=ignore]"*"pam_exec.so quiet /usr/bin/omarchy-hw-laptop-closed" ]] ||
  fail "the lid gate comes right after the service gate and skips exactly one module when the lid is closed"
[[ ${auth[2]} == *"pam_fprintd.so max-tries=1 timeout=10" ]] || fail "the module it skips is pam_fprintd, with Ubuntu's options"
grep -qx 'Conflicts: fprintd' "$profile" || fail "the profile conflicts with Ubuntu's fprintd profile"

stub_dir=$(mktemp -d)
trap 'rm -rf "$stub_dir"' EXIT
export TEST_LOG="$stub_dir/log"
printf '#!/bin/bash\nprintf "sudo %%s\\n" "$*" >>"$TEST_LOG"\n' >"$stub_dir/sudo"
chmod +x "$stub_dir/sudo"
PATH="$stub_dir:$PATH" bash -c 'source <(sed -n "/^setup_pam_config() {/,/^}/p" "$1"); setup_pam_config' bash "$ROOT/bin/omarchy-setup-security-fingerprint" >/dev/null
[[ $(grep pam-auth-update "$TEST_LOG") == $'sudo pam-auth-update --package --disable fprintd\nsudo pam-auth-update --package --enable omarchy-fprintd' ]] ||
  fail "setup swaps Ubuntu's profile for the gated one" "$(cat "$TEST_LOG")"

: >"$TEST_LOG"
PATH="$stub_dir:$PATH" bash "$ROOT/bin/omarchy-remove-security-fingerprint" >/dev/null
grep -qx 'sudo pam-auth-update --package --disable omarchy-fprintd fprintd' "$TEST_LOG" || fail "removal disables both profiles"

pass "fingerprint authentication is skipped while the laptop lid is closed"
