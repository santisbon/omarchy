#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin"
for cmd in omarchy-pkg-drop omarchy-pkg-repo-remove; do
  printf '#!/bin/bash\necho "%s $*" >>"$TEST_LOG"\n' "$cmd" >"$work/bin/$cmd"
done
chmod +x "$work/bin"/*

: >"$TEST_LOG"
PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-service-signal" >/dev/null
grep -qx 'omarchy-pkg-drop signal-desktop' "$TEST_LOG" && grep -qx 'omarchy-pkg-repo-remove signal' "$TEST_LOG" ||
  fail "the remover drops Signal and Signal's apt repository" "$(cat "$TEST_LOG")"
pass "the remover drops Signal and Signal's apt repository"

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
grep -q '"remove.service.signal":.*"when":"omarchy-pkg-present signal-desktop".*"action":"omarchy-launch-floating-terminal-with-presentation omarchy-remove-service-signal"' "$menu" ||
  fail "Remove > Service > Signal runs the remover while Signal is installed"
pass "Remove > Service > Signal runs the remover while Signal is installed"
