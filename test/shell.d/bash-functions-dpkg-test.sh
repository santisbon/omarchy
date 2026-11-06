#!/bin/bash

source "$(dirname "$0")/base-test.sh"

# dpkg keeps <name>.dpkg-new and <name>.dpkg-tmp in the same folder as each file it replaces. A
# terminal opened during an upgrade must not source them: a partly written file prints errors.
fake=$(mktemp -d)
trap 'rm -rf "$fake"' EXIT
mkdir -p "$fake/default/bash/fns"
cp "$ROOT/default/bash/functions" "$fake/default/bash/functions"
echo 'real_loaded=yes' >"$fake/default/bash/fns/real"
echo 'new_loaded=yes' >"$fake/default/bash/fns/real.dpkg-new"
echo 'tmp_loaded=yes' >"$fake/default/bash/fns/real.dpkg-tmp"

result=$(OMARCHY_PATH="$fake" bash --norc --noprofile -c 'source "$OMARCHY_PATH/default/bash/functions"; echo "${real_loaded:-no} ${new_loaded:-no} ${tmp_loaded:-no}"')
[[ $result == "yes no no" ]] || fail "bash functions skip dpkg's temporary files" "$result"
pass "bash functions skip dpkg's temporary files"
