#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

require_command xkbcli

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/home"
printf '#!/bin/bash\necho "hyprctl $*" >>"$TEST_LOG"\n' >"$work/bin/hyprctl"
chmod +x "$work/bin/hyprctl"
gui="$work/home/.config/hypr/keyboard-gui.conf"

setup_keyboard() {
  : >"$TEST_LOG"
  HOME="$work/home" PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-setup-keyboard" "$@"
}

setup_keyboard us,es ,deadtilde grp:ctrls_toggle
grep -qx 'XKBLAYOUT="us,es"' "$gui" && grep -qx 'XKBVARIANT=",deadtilde"' "$gui" && grep -qx 'XKBOPTIONS="grp:ctrls_toggle"' "$gui" ||
  fail "the layouts, variants and options go to keyboard-gui.conf" "$(cat "$gui")"
grep -qx 'hyprctl reload' "$TEST_LOG" || fail "Hyprland reloads after the layouts change" "$(cat "$TEST_LOG")"
pass "the layouts, variants and options go to keyboard-gui.conf, and Hyprland reloads"

if setup_keyboard us,nosuchlayout 2>/dev/null; then
  fail "a layout xkbcommon cannot build is refused"
fi
grep -qx 'XKBLAYOUT="us,es"' "$gui" || fail "a refused layout leaves the file as it was" "$(cat "$gui")"
pass "a layout xkbcommon cannot build is refused, and the file stays"

setup_keyboard --reset
[[ ! -e $gui ]] || fail "--reset removes keyboard-gui.conf"
grep -qx 'hyprctl reload' "$TEST_LOG" || fail "Hyprland reloads after --reset" "$(cat "$TEST_LOG")"
pass "--reset goes back to the layout chosen at installation"

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
grep -q '"setup.keyboard":.*omarchy-launch-floating-terminal-with-presentation omarchy-setup-keyboard' "$menu" ||
  fail "Setup > Keyboard opens the layout picker"
grep -q '"setup.displays":.*"label":"Displays","action":"omarchy-launch-monitors"' "$menu" ||
  fail "Setup > Displays starts nwg-displays"
pass "Setup > Keyboard and Setup > Displays"
