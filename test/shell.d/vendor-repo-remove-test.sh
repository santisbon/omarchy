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

# Remove > Package would drop these packages but leave each vendor's apt repository.
for case in service-spotify:spotify-client:spotify editor-vscode:code:vscode editor-sublime:sublime-text:sublime-text; do
  IFS=: read -r script package repo <<<"$case"
  : >"$TEST_LOG"
  PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-$script" >/dev/null
  grep -qx "omarchy-pkg-drop $package" "$TEST_LOG" && grep -qx "omarchy-pkg-repo-remove $repo" "$TEST_LOG" ||
    fail "omarchy-remove-$script drops $package and the $repo apt repository" "$(cat "$TEST_LOG")"
  pass "omarchy-remove-$script drops $package and the $repo apt repository"
done

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
for case in service.spotify:spotify-client:service-spotify service.1password:1password:service-1password editor.vscode:code:editor-vscode editor.sublime:sublime-text:editor-sublime; do
  IFS=: read -r key package script <<<"$case"
  grep -q "\"remove.$key\":.*\"when\":\"omarchy-pkg-present $package\".*\"action\":\"omarchy-launch-floating-terminal-with-presentation omarchy-remove-$script\"" "$menu" ||
    fail "Remove > $key runs omarchy-remove-$script while $package is installed"
  pass "Remove > $key runs omarchy-remove-$script while $package is installed"
done

grep -q '"remove.editor": {' "$menu" || fail "Remove has an Editor submenu"
pass "Remove has an Editor submenu"
