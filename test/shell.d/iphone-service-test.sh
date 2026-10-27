#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log" HOME="$work/home"
mkdir -p "$work/bin" "$HOME"

stub() {
  printf '#!/bin/bash\necho "%s $*" >>"$TEST_LOG"\n%s\n' "$1" "${2:-}" >"$work/bin/$1"
  chmod +x "$work/bin/$1"
}
# sudo grep is the installer's look at the bond's Low Energy keys: LE_KEYS=0 makes it find none.
stub sudo '[[ $1 == grep ]] && exit $(( 1 - ${LE_KEYS:-1} )); exit 0'
# The installer's waits log instead of sleeping.
stub sleep
stub gum 'exit 1'
stub systemctl '[[ $* == *MainPID* ]] && echo $$; exit 0'
stub omarchy-pkg-add
stub omarchy-pkg-drop
stub iphonebridge
stub journalctl
# The pairing agent pairs 22:22:22:22:22:22 and writes its address to the file named last.
# python3 -c '<code>' <file> is the pairing agent: it pairs 22:22:22:22:22:22 and writes the address
# to <file>. python3 -c '<code>' alone parses GetStatus: it prints the working features, STATUS.
stub python3 '[[ $1 == -c && $# == 3 ]] && echo 22:22:22:22:22:22 >"$3"; [[ $1 == -c && $# == 2 ]] && echo "${STATUS-map pbap ancs hfp avrcp}"; exit 0'
stub busctl
# The daemon's AppArmor label, read from /proc/<pid>/attr/current: confined only with LABEL_OK=1.
# The bluetooth drop-in reads as missing with NO_DROPIN=1, so the installer restarts Bluetooth.
stub cat '[[ $1 == /proc/*/attr/current ]] && { [[ ${LABEL_OK:-0} == 1 ]] && echo "iphonebridge (enforce)"; exit 0; }; [[ $1 == */bluetooth.service.d/iphonebridge.conf && ${NO_DROPIN:-0} == 1 ]] && exit 1; exec /usr/bin/cat "$@"'
# A paired iPhone answers bluetoothctl, in bluetoothctl 5.87's formats, unless NO_PHONE=1. With
# KEYBOARD=1, a connected keyboard 33:33:33:33:33:33 is also listed.
stub bluetoothctl '[[ $1 == devices && ${NO_PHONE:-0} == 0 ]] && echo "Device 11:11:11:11:11:11 iPhone"; [[ $1 == devices && ${KEYBOARD:-0} == 1 ]] && echo "Device 33:33:33:33:33:33 Keyboard"; [[ $1 == info && $2 == 33:* ]] && { printf "Device $2 (public)\n\tIcon: input-keyboard\n"; exit 0; }; [[ $1 == info ]] && printf "Device $2 (public)\n\tIcon: phone\n"; [[ $1 == show ]] && printf "Controller AA:AA:AA:AA:AA:AA (public)\n\tAlias: laptop\n"; exit 0'

export OMARCHY_PATH=$ROOT
icon=$HOME/.local/share/icons/hicolor/scalable/apps/me.santisbon.iphonebridge.UI.svg

run_installer() {
  : >"$TEST_LOG"
  PATH="$work/bin:$PATH" timeout 10 bash "$ROOT/bin/omarchy-install-service-iphone" >"$work/out" 2>&1 || true
}

run_installer
grep -qx 'omarchy-pkg-add iphonebridge ofono wl-clipboard ibus-data fonts-noto-color-emoji' "$TEST_LOG" ||
  fail "the installer installs iphonebridge and oFono" "$(cat "$TEST_LOG")"
pass "the installer installs iphonebridge and oFono"

cmp -s "$icon" "$ROOT/default/iphone/iphone.svg" ||
  fail "the installer gives the iPhone app the menu's phone glyph as its icon"
pass "the installer gives the iPhone app the menu's phone glyph as its icon"

# oFono claims the Hands-Free profile only if it starts after WirePlumber, which hfp-enable restarts.
order=$(grep -oE '^(iphonebridge hfp-enable|sudo systemctl restart ofono)' "$TEST_LOG" | tr '\n' ',')
[[ $order == "iphonebridge hfp-enable,sudo systemctl restart ofono," ]] ||
  fail "the installer restarts oFono after hfp-enable" "$(cat "$TEST_LOG")"
pass "the installer restarts oFono after hfp-enable"

[[ $(cat "$HOME/.config/iphonebridge/local.env") == "IPHONEBRIDGE_MAC=11:11:11:11:11:11" &&
  $(stat -c %a "$HOME/.config/iphonebridge/local.env") == 600 ]] ||
  fail "the installer writes the paired iPhone's address to local.env, readable only by the user"
pass "the installer writes the paired iPhone's address to local.env, readable only by the user"

! grep -qE '^(python3 -c|gum)' "$TEST_LOG" ||
  fail "the installer skips pairing when the iPhone's pairing has Low Energy keys" "$(cat "$TEST_LOG")"
pass "the installer skips pairing when the iPhone's pairing has Low Energy keys"

# systemctl restart returns before the daemon has executed, so the label check waits for it.
(( $(grep -c '^sleep 1$' "$TEST_LOG") == 10 )) ||
  fail "the installer waits up to 10 seconds for the daemon's AppArmor label" "$(cat "$TEST_LOG")"
pass "the installer waits up to 10 seconds for the daemon's AppArmor label"

# After ancs-enable, the installer connects the iPhone over classic Bluetooth (the Python step),
# then restarts the daemon.
order=$(grep -oE '^(iphonebridge ancs-enable|python3 - [0-9A-F:]+|systemctl --user restart iphonebridge)' "$TEST_LOG" | tail -3 | sed 's/ [0-9A-F:]\{17\}$//' | tr '\n' ',')
[[ $order == "iphonebridge ancs-enable,python3 -,systemctl --user restart iphonebridge," ]] ||
  fail "the installer connects the iPhone over classic Bluetooth after ancs-enable, then restarts the daemon" "$(cat "$TEST_LOG")"
pass "the installer connects the iPhone over classic Bluetooth after ancs-enable, then restarts the daemon"

# A confined daemon with every feature working: the installer reports each one and finishes.
LABEL_OK=1 run_installer
grep -q '^Everything works' "$work/out" && (( $(grep -c '^  Working: ' "$work/out") == 5 )) ||
  fail "the installer finishes once all five features work, reporting each" "$(cat "$work/out")"
pass "the installer finishes once all five features work, reporting each"

# Calls missing: the installer keeps waiting instead of finishing.
LABEL_OK=1 STATUS="map pbap ancs avrcp" run_installer
! grep -q '^Everything works' "$work/out" && grep -q '^  Working: Media controls' "$work/out" ||
  fail "the installer does not finish while calls do not work" "$(cat "$work/out")"
pass "the installer does not finish while calls do not work"

# A Bluetooth keyboard connected before the restart: the installer asks, in yellow, for a key
# press on it, which is what reconnects it, and waits for it.
NO_DROPIN=1 KEYBOARD=1 run_installer
grep -q $'^\e\[33mPress a key on Keyboard so it reconnects.' "$work/out" &&
  (( $(grep -c '^bluetoothctl devices Connected$' "$TEST_LOG") == 2 )) ||
  fail "the installer asks for a key press on a Bluetooth keyboard after restarting Bluetooth, and waits for it" "$(cat "$work/out")"
pass "the installer asks for a key press on a Bluetooth keyboard after restarting Bluetooth, and waits for it"

# A pairing without Low Energy keys: the installer offers to pair again.
LE_KEYS=0 run_installer
grep -q '^gum confirm Pair the iPhone again?' "$TEST_LOG" ||
  fail "the installer offers to pair again when the pairing has no Low Energy keys" "$(cat "$TEST_LOG")"
pass "the installer offers to pair again when the pairing has no Low Energy keys"

# No iPhone paired: the agent pairs one, and the installer uses its address.
NO_PHONE=1 run_installer
grep -q '^python3 -c' "$TEST_LOG" && [[ $(cat "$HOME/.config/iphonebridge/local.env") == "IPHONEBRIDGE_MAC=22:22:22:22:22:22" ]] ||
  fail "the installer runs the pairing agent and uses the iPhone it paired" "$(cat "$TEST_LOG")"
pass "the installer runs the pairing agent and uses the iPhone it paired"

# The remover forgets the iPhone, purges the packages and deletes the settings and the data.
mkdir -p "$HOME/.local/state/iphonebridge" "$HOME/.config/wireplumber/wireplumber.conf.d"
touch "$HOME/.config/wireplumber/wireplumber.conf.d/51-bluez-hfp-hf.conf" \
  "$HOME/.config/wireplumber/wireplumber.conf.d/51-bluez-hfp-hf.conf.bak.1"
: >"$TEST_LOG"
PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-service-iphone" >/dev/null
grep -qx 'bluetoothctl remove 22:22:22:22:22:22' "$TEST_LOG" && grep -qx 'omarchy-pkg-drop iphonebridge ofono' "$TEST_LOG" ||
  fail "the remover forgets the iPhone and purges iphonebridge and oFono" "$(cat "$TEST_LOG")"
[[ ! -e $HOME/.config/iphonebridge && ! -e $HOME/.local/state/iphonebridge &&
  -z $(ls -A "$HOME/.config/wireplumber/wireplumber.conf.d") && ! -e $icon ]] ||
  fail "the remover deletes the settings, the data, the WirePlumber config and the icon"
pass "the remover forgets the iPhone, purges the packages and deletes the settings and the data"

# An install whose pairing failed left no local.env: the remover still purges the packages.
: >"$TEST_LOG"
PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-service-iphone" >/dev/null 2>&1 || true
grep -qx 'omarchy-pkg-drop iphonebridge ofono' "$TEST_LOG" && ! grep -q '^bluetoothctl remove' "$TEST_LOG" ||
  fail "the remover purges the packages when no iPhone was paired" "$(cat "$TEST_LOG")"
pass "the remover purges the packages when no iPhone was paired"

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
  grep -A1 '"install.service.signal":' "$menu" | grep -q '"install.service.iphone":.*"label":"iPhone","when":"! omarchy-pkg-present iphonebridge","action":"omarchy-launch-floating-terminal-with-presentation omarchy-install-service-iphone"' ||
  fail "Install > Service > iPhone follows Signal and runs the installer while iphonebridge is absent"
pass "Install > Service > iPhone follows Signal and runs the installer while iphonebridge is absent"
grep -A1 '"remove.service.signal":' "$menu" | grep -q '"remove.service.iphone":.*"label":"iPhone","when":"omarchy-pkg-present iphonebridge","action":"omarchy-launch-floating-terminal-with-presentation omarchy-remove-service-iphone"' ||
  fail "Remove > Services > iPhone follows Signal and runs the remover while iphonebridge is installed"
pass "Remove > Services > iPhone follows Signal and runs the remover while iphonebridge is installed"
