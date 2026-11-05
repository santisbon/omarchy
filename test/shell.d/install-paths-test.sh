#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# A script the install steps source or run must exist: the port deletes Arch-only files, and a call
# left behind stops the installer on a real machine, which the unit tests of other scripts do not reach.
cd "$ROOT"
missing=$(grep -rhoE '(source|run_logged|bash) "\$OMARCHY_(INSTALL|PATH)/[A-Za-z0-9_./-]+"' bin install |
  sed -E 's/^[a-z_]+ "//; s/"$//; s#^\$OMARCHY_INSTALL/#install/#; s#^\$OMARCHY_PATH/##' | sort -u |
  while read -r path; do [[ -e $path ]] || echo "$path"; done)
[[ -z $missing ]] || fail "every script the install steps source or run exists" "$missing"
pass "every script the install steps source or run exists"
