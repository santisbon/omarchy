#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/home"
printf '#!/bin/bash\nexit 1\n' >"$work/bin/omarchy-cmd-missing"
# mise as on a first login without network: the Node.js download fails.
printf '#!/bin/bash\necho "mise $*" >>"$TEST_LOG"\n[[ $1 == use ]] && exit 1\nexit 0\n' >"$work/bin/mise"
chmod +x "$work/bin"/*
export TEST_LOG="$work/log"

# all.sh runs each leaf this way (provision-user's run_logged): errexit on, so a leaf that fails
# stops the user's setup.
HOME="$work/home" PATH="$work/bin:$PATH" bash -eE -c 'source "$1"' bash "$ROOT/install/user/mise-work.sh" 2>"$work/err" ||
  fail "a failed Node.js download does not stop the user's setup" "$(cat "$work/err")"
grep -qx 'mise use -g node@latest' "$TEST_LOG" || fail "mise-work asks mise for Node.js" "$(cat "$TEST_LOG")"
grep -q 'mise use -g node@latest' "$work/err" || fail "mise-work says how to install Node.js later" "$(cat "$work/err")"
[[ -d $work/home/Work/tries ]] || fail "mise-work makes ~/Work/tries"
[[ ! -e $work/home/Work/.mise.toml ]] || fail "mise-work puts no project bin/ directories on PATH (no ~/Work/.mise.toml)"
pass "mise-work finishes when the Node.js download fails"

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
