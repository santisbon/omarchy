#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/home/Games/Heroic/game"
for cmd in omarchy-pkg-add omarchy-pkg-flatpak-add omarchy-pkg-flatpak-drop uwsm-app; do
  printf '#!/bin/bash\necho "%s $*" >>"$TEST_LOG"\n' "$cmd" >"$work/bin/$cmd"
done
printf '#!/bin/bash\n"$@"\n' >"$work/bin/setsid"
chmod +x "$work/bin"/*

HOME="$work/home" PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-install-gaming-heroic" >/dev/null
wait
grep -qx 'omarchy-pkg-flatpak-add com.heroicgameslauncher.hgl' "$TEST_LOG" || fail "Heroic comes from Flathub" "$(cat "$TEST_LOG")"
grep -qx 'uwsm-app -- flatpak run com.heroicgameslauncher.hgl' "$TEST_LOG" || fail "the installer opens Heroic"

HOME="$work/home" PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-gaming-heroic" >/dev/null
grep -qx 'omarchy-pkg-flatpak-drop com.heroicgameslauncher.hgl' "$TEST_LOG" || fail "the remover drops the Flatpak and its data"
[[ ! -e $work/home/Games/Heroic ]] || fail "the remover deletes ~/Games/Heroic, as Omarchy's does"

pass "Heroic installs from Flathub and removes with its data"
