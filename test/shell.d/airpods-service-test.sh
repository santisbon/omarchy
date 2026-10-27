#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log" HOME="$work/home"
id=io.github.thisisgm.omapods
dir="$HOME/.config/omarchy/plugins/$id"
mkdir -p "$work/bin" "$HOME"

stub() {
  printf '#!/bin/bash\necho "%s $*" >>"$TEST_LOG"\n%s\n' "$1" "${2:-}" >"$work/bin/$1"
  chmod +x "$work/bin/$1"
}
stub sudo
# The installer's waits log instead of sleeping.
stub sleep
stub gum 'exit 1'
stub systemctl '[[ $* == *MainPID* ]] && echo $$; exit 0'
stub omarchy-plugin-remove "rm -rf \"$dir\""
# The fork's clone carries a setup that logs; a paired AirPods record answers bluetoothctl.
stub omarchy-plugin-add "mkdir -p \"$dir\" && git -C \"$dir\" init -q && git -C \"$dir\" remote add origin https://github.com/santisbon/omarchy-pods && printf '#!/bin/bash\necho setup >>\"\$TEST_LOG\"\n' >\"$dir/setup\" && chmod +x \"$dir/setup\""
stub bluetoothctl '[[ $1 == devices ]] && echo "Device AA:BB:CC:DD:EE:FF AirPods Pro"; [[ $1 == info ]] && echo "	UUID: Audio Sink                (0000110b-0000-1000-8000-00805f9b34fb)"; exit 0'

run_installer() {
  : >"$TEST_LOG"
  PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-install-service-airpods" >/dev/null 2>&1 || true
}

# Upstream's plugin, cloned from thisisgm, is removed before the fork is added.
mkdir -p "$dir" && git -C "$dir" init -q && git -C "$dir" remote add origin https://github.com/thisisgm/omarchy-pods
run_installer
order=$(grep -oE '^(omarchy-plugin-remove|omarchy-plugin-add|setup)' "$TEST_LOG" | tr '\n' ' ')
[[ $order == "omarchy-plugin-remove omarchy-plugin-add setup " ]] ||
  fail "the installer removes upstream's plugin, adds the fork, then runs setup" "$(cat "$TEST_LOG")"
pass "the installer removes upstream's plugin, adds the fork, then runs setup"

grep -qx 'omarchy-plugin-add https://github.com/santisbon/omarchy-pods --enable --yes' "$TEST_LOG" ||
  fail "the installer adds the fork and enables its widget" "$(cat "$TEST_LOG")"
pass "the installer adds the fork and enables its widget"

! grep -q '^gum' "$TEST_LOG" || fail "the installer skips pairing when AirPods are already paired" "$(cat "$TEST_LOG")"
pass "the installer skips pairing when AirPods are already paired"

# Run again over the fork's clone: nothing is removed or re-added, setup runs.
run_installer
order=$(grep -oE '^(omarchy-plugin-remove|omarchy-plugin-add|setup)' "$TEST_LOG" | tr '\n' ' ')
[[ $order == "setup " ]] || fail "the installer reruns setup over the fork's clone" "$(cat "$TEST_LOG")"
pass "the installer reruns setup over the fork's clone"

# With no AirPods paired, the installer offers the classic Bluetooth record, not the Low Energy one,
# in bluetoothctl 5.87's info format, and pairs it.
stub gum '[[ $1 == choose ]] && head -1; exit 0'
stub bluetoothctl '[[ $1 == devices ]] && printf "Device 11:11:11:11:11:11 AirPods Pro 3\nDevice 22:22:22:22:22:22 AirPods Pro 3\n"; [[ $1 == info && $2 == 11:* ]] && printf "Device 11:11:11:11:11:11 (random)\n\tPaired: no\n"; [[ $1 == info && $2 == 22:* ]] && printf "Device 22:22:22:22:22:22 (public)\n\tPaired: no\n"; exit 0'
run_installer
grep -qx 'bluetoothctl pair 22:22:22:22:22:22' "$TEST_LOG" && ! grep -q 'bluetoothctl pair 11:' "$TEST_LOG" ||
  fail "the installer pairs the AirPods' classic Bluetooth address" "$(cat "$TEST_LOG")"
pass "the installer pairs the AirPods' classic Bluetooth address"
# The scan is still running at pairing time.
scan_line=$(grep -n '^bluetoothctl --timeout 300 scan bredr$' "$TEST_LOG" | cut -d: -f1)
pair_line=$(grep -n '^bluetoothctl pair ' "$TEST_LOG" | cut -d: -f1)
[[ -n $scan_line && -n $pair_line ]] && (( scan_line < pair_line )) ||
  fail "the installer scans until it pairs" "$(cat "$TEST_LOG")"
pass "the installer scans until it pairs"

# One AirPods found: paired at once, with no list to pick from, since BlueZ forgets them about
# 30 seconds after finding them.
! grep -q '^gum choose' "$TEST_LOG" || fail "the installer pairs a single AirPods without asking which" "$(cat "$TEST_LOG")"
pass "the installer pairs a single AirPods without asking which"

# Two AirPods found: the user picks one, and the installer pairs that one.
stub bluetoothctl '[[ $1 == devices ]] && printf "Device 33:33:33:33:33:33 AirPods Pro\nDevice 44:44:44:44:44:44 AirPods Max\n"; [[ $1 == info ]] && printf "Device $2 (public)\n\tPaired: no\n"; exit 0'
stub gum '[[ $1 == choose ]] && tail -1; exit 0'
run_installer
grep -q '^gum choose' "$TEST_LOG" && grep -qx 'bluetoothctl pair 44:44:44:44:44:44' "$TEST_LOG" ||
  fail "the installer pairs the AirPods the user picks" "$(cat "$TEST_LOG")"
pass "the installer pairs the AirPods the user picks"

# systemctl restart returns before the daemon has executed, so the label check waits for it.
(( $(grep -c '^sleep 1$' "$TEST_LOG") == 10 )) ||
  fail "the installer waits up to 10 seconds for the daemon's AppArmor label" "$(cat "$TEST_LOG")"
pass "the installer waits up to 10 seconds for the daemon's AppArmor label"

# The remover deletes what setup installed, the settings and the plugin.
mkdir -p "$dir/daemon/build" "$HOME/.local/bin" "$HOME/.config/AirPodsTrayApp" "$HOME/.local/state/librepods"
touch "$HOME/.local/bin/librepods"
echo "$HOME/.local/bin/librepods" >"$dir/daemon/build/install_manifest.txt"
: >"$TEST_LOG"
PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-service-airpods" >/dev/null
[[ ! -e $HOME/.local/bin/librepods && ! -e $HOME/.config/AirPodsTrayApp && ! -e $HOME/.local/state/librepods && ! -e $dir ]] ||
  fail "the remover deletes the daemon, its settings and the plugin" "$(cat "$TEST_LOG")"
grep -qx 'systemctl --user disable --now librepods.service' "$TEST_LOG" ||
  fail "the remover stops and disables the daemon" "$(cat "$TEST_LOG")"
pass "the remover deletes the daemon, its settings and the plugin"

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
grep -q '"install.service.airpods":.*"when":"\[\[ ! -f \\"$HOME/.config/omarchy/plugins/io.github.thisisgm.omapods/daemon/apparmor/librepods\\" \]\]".*"action":"omarchy-launch-floating-terminal-with-presentation omarchy-install-service-airpods"' "$menu" ||
  fail "Install > Service > AirPods runs the installer until the fork is installed"
pass "Install > Service > AirPods runs the installer until the fork is installed"
grep -q '"remove.service.airpods":.*"when":"\[\[ -d \\"$HOME/.config/omarchy/plugins/io.github.thisisgm.omapods\\" \]\]".*"action":"omarchy-launch-floating-terminal-with-presentation omarchy-remove-service-airpods"' "$menu" ||
  fail "Remove > Service > AirPods runs the remover while the plugin is installed"
pass "Remove > Service > AirPods runs the remover while the plugin is installed"
