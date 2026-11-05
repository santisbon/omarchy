#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/home"
printf '#!/bin/bash\nexit 1\n' >"$work/bin/omarchy-cmd-missing"
# Node.js comes lazily through mise, so setup needs no network and calls no mise.
printf '#!/bin/bash\necho "mise $*" >>"$TEST_LOG"\nexit 1\n' >"$work/bin/mise"
chmod +x "$work/bin"/*
export TEST_LOG="$work/log"

# all.sh runs each leaf this way (provision-user's run_logged): errexit on, so a leaf that fails
# stops the user's setup.
HOME="$work/home" PATH="$work/bin:$PATH" bash -eE -c 'source "$1"' bash "$ROOT/install/user/mise-work.sh" 2>"$work/err" ||
  fail "mise-work does not stop the user's setup" "$(cat "$work/err")"
[[ ! -e $TEST_LOG ]] || fail "mise-work leaves Node.js to mise's lazy install" "$(cat "$TEST_LOG")"
[[ -d $work/home/Work/tries ]] || fail "mise-work makes ~/Work/tries"
[[ ! -e $work/home/Work/.mise.toml ]] || fail "mise-work puts no project bin/ directories on PATH (no ~/Work/.mise.toml)"
pass "mise-work makes the Work directories and needs no network"

# The port preinstalls mise, but it can be removed: the PATH migration must still finish (later
# migrations wait on it) and delete the stock ~/Work/.mise.toml, with no mise to revoke trust in.
nomise="$work/nomise"
mkdir -p "$nomise/bin" "$nomise/home/Work"
for tool in bash cat cp cut mkdir mktemp readlink rm rmdir sed sha256sum; do
  ln -s "$(command -v "$tool")" "$nomise/bin/$tool"
done
printf '[env]\n_.path = "{{ cwd }}/bin"\n' >"$nomise/home/Work/.mise.toml"
env -i HOME="$nomise/home" PATH="$nomise/bin" bash -euo pipefail "$ROOT/migrations/1789095456.sh" >"$nomise/out" 2>&1 ||
  fail "the PATH migration finishes without mise" "$(cat "$nomise/out")"
[[ ! -e $nomise/home/Work/.mise.toml ]] || fail "the PATH migration deletes the stock ~/Work/.mise.toml without mise"
pass "the PATH migration finishes without mise and deletes the stock ~/Work/.mise.toml"
