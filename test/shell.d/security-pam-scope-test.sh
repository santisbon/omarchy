#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

# Both profiles go into common-auth, which SDDM's login screen includes as well
# as sudo and polkit. Each must start with a gate that jumps over the rest of
# the profile for every service outside Omarchy's scope, so the login screen
# keeps asking for the password, the password that unlocks the login keyring.
gate=$'pam_succeed_if.so quiet service notin sudo:sudo-i:polkit-1'

check_profile() {
  local name=$1 skip=$2 last=$3
  local profile="$ROOT/default/pam-configs/$name"
  local -a auth

  mapfile -t auth < <(sed -n '/^Auth:/,$p' "$profile" | tail -n +2)
  [[ ${auth[0]} == $'\t'"[success=$skip default=ignore]"$'\t'"$gate" ]] ||
    fail "$name starts with the service gate, skipping $skip lines" "got: ${auth[0]}"
  (( ${#auth[@]} == skip + 1 )) ||
    fail "$name's gate skips every line after it" "the profile has ${#auth[@]} lines"
  [[ ${auth[skip]} == *"[success=end default=ignore]"*"$last"* ]] ||
    fail "$name's gate lands past $last, the profile's last line" "got: ${auth[skip]}"
}

check_profile omarchy-u2f 1 pam_u2f.so
check_profile omarchy-fprintd 2 pam_fprintd.so

pass "the FIDO2 key and the fingerprint reader serve only sudo, sudo -i and polkit"
