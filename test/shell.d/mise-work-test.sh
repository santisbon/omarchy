#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/home"
printf '#!/bin/bash\nexit 1\n' >"$work/bin/omarchy-cmd-missing"
# mise as on a first login without network: trust works, the Node.js download fails.
printf '#!/bin/bash\necho "mise $*" >>"$TEST_LOG"\n[[ $1 == use ]] && exit 1\nexit 0\n' >"$work/bin/mise"
chmod +x "$work/bin"/*
export TEST_LOG="$work/log"

# all.sh runs each leaf this way (provision-user's run_logged): errexit on, so a leaf that fails
# stops the user's setup.
HOME="$work/home" PATH="$work/bin:$PATH" bash -eE -c 'source "$1"' bash "$ROOT/install/user/mise-work.sh" 2>"$work/err" ||
  fail "a failed Node.js download does not stop the user's setup" "$(cat "$work/err")"
grep -qx 'mise use -g node@latest' "$TEST_LOG" || fail "mise-work asks mise for Node.js" "$(cat "$TEST_LOG")"
grep -q 'mise use -g node@latest' "$work/err" || fail "mise-work says how to install Node.js later" "$(cat "$work/err")"
[[ -f $work/home/Work/.mise.toml ]] || fail "mise-work writes ~/Work/.mise.toml"
pass "mise-work finishes when the Node.js download fails"
