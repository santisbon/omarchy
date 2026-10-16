#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

stub_dir=$(mktemp -d)
trap 'rm -rf "$stub_dir"' EXIT
export TEST_LOG="$stub_dir/log"

for cmd in sudo omarchy-pkg-repo-add omarchy-pkg-add omarchy-pkg-drop omarchy-pkg-repo-remove uwsm-app; do
  printf '#!/bin/bash\nprintf "%s %%s\\n" "$*" >>"$TEST_LOG"\n' "$cmd" >"$stub_dir/$cmd"
done
printf '#!/bin/bash\nexit 1\n' >"$stub_dir/omarchy-cmd-missing"
chmod +x "$stub_dir"/*

file=/usr/share/chromium/extensions/aeblfdkhhhdcdjpifhhbdiojplfjncoa.json
PATH="$stub_dir:$PATH" bash "$ROOT/bin/omarchy-install-service-1password" >/dev/null
grep -qx "sudo tee $file" "$TEST_LOG" || fail "the install writes Chromium's external-extension file for 1Password" "$(cat "$TEST_LOG")"

: >"$TEST_LOG"
PATH="$stub_dir:$PATH" bash "$ROOT/bin/omarchy-remove-service-1password" >/dev/null
grep -qx "sudo rm -f $file" "$TEST_LOG" || fail "the removal deletes the extension file"

pass "1Password's install and removal add and remove its Chromium extension"
