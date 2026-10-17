#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/home"
stub() { printf '#!/bin/bash\n%s\n' "$2" >"$work/bin/$1"; chmod +x "$work/bin/$1"; }
stub omarchy-pkg-repo-add 'echo "repo-add $*" >>"$TEST_LOG"'
stub omarchy-pkg-add 'echo "pkg-add $*" >>"$TEST_LOG"'
stub curl 'echo "curl $*" >>"$TEST_LOG"'
# A PATH without any mise on it.
clean_path="$work/bin:/usr/bin:/bin"

HOME="$work/home" PATH="$clean_path" bash "$ROOT/bin/omarchy-mise-ensure" >/dev/null
grep -qx 'repo-add mise https://mise.jdx.dev/gpg-key.pub https://mise.jdx.dev/deb stable main amd64' "$TEST_LOG" ||
  fail "a missing mise comes from mise's apt repository" "$(cat "$TEST_LOG")"
grep -qx 'pkg-add mise' "$TEST_LOG" || fail "the package mise is installed"
! grep -q '^curl' "$TEST_LOG" || fail "the vendor's install script is not run"

: >"$TEST_LOG"
mkdir -p "$work/home/.local/bin"; printf '#!/bin/bash\necho "mise $*" >>"$TEST_LOG"\n' >"$work/home/.local/bin/mise"; chmod +x "$work/home/.local/bin/mise"
HOME="$work/home" PATH="$clean_path" bash "$ROOT/bin/omarchy-mise-ensure" >/dev/null
[[ ! -s $TEST_LOG ]] || fail "a mise in ~/.local/bin counts as installed"

# The update: the script's copy in ~/.local/bin updates itself, then the tools.
stub omarchy-cmd-present 'command -v "$1" >/dev/null'
HOME="$work/home" PATH="$work/home/.local/bin:$clean_path" bash "$ROOT/bin/omarchy-update-mise" >/dev/null
[[ $(cat "$TEST_LOG") == $'mise self-update --yes\nmise up' ]] || fail "the update runs mise self-update for a mise in ~/.local/bin, then mise up" "$(cat "$TEST_LOG")"

# A system mise (apt's) is left to apt.
: >"$TEST_LOG"; rm "$work/home/.local/bin/mise"
printf '#!/bin/bash\necho "mise $*" >>"$TEST_LOG"\n' >"$work/bin/mise"; chmod +x "$work/bin/mise"
HOME="$work/home" PATH="$clean_path" bash "$ROOT/bin/omarchy-update-mise" >/dev/null
[[ $(cat "$TEST_LOG") == "mise up" ]] || fail "apt's mise is not self-updated" "$(cat "$TEST_LOG")"

pass "mise comes from its apt repository, and a script-installed mise keeps itself current"
