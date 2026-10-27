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
stub python3 'echo 22:22:22:22:22:22 >"${@: -1}"'
# A paired iPhone answers bluetoothctl, in bluetoothctl 5.87's formats, unless NO_PHONE=1.
stub bluetoothctl '[[ $1 == devices && ${NO_PHONE:-0} == 0 ]] && echo "Device 11:11:11:11:11:11 iPhone"; [[ $1 == info ]] && printf "Device $2 (public)\n\tIcon: phone\n"; [[ $1 == show ]] && printf "Controller AA:AA:AA:AA:AA:AA (public)\n\tAlias: laptop\n"; exit 0'

run_installer() {
  : >"$TEST_LOG"
  PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-install-service-iphone" >/dev/null 2>&1 || true
}

run_installer
grep -qx 'omarchy-pkg-add iphonebridge ofono wl-clipboard ibus-data fonts-noto-color-emoji' "$TEST_LOG" ||
  fail "the installer installs iphonebridge and oFono" "$(cat "$TEST_LOG")"
pass "the installer installs iphonebridge and oFono"

# oFono claims the Hands-Free profile only if it starts after WirePlumber, which hfp-enable restarts.
order=$(grep -oE '^(iphonebridge hfp-enable|sudo systemctl restart ofono)' "$TEST_LOG" | tr '\n' ',')
[[ $order == "iphonebridge hfp-enable,sudo systemctl restart ofono," ]] ||
  fail "the installer restarts oFono after hfp-enable" "$(cat "$TEST_LOG")"
pass "the installer restarts oFono after hfp-enable"

[[ $(cat "$HOME/.config/iphonebridge/local.env") == "IPHONEBRIDGE_MAC=11:11:11:11:11:11" &&
  $(stat -c %a "$HOME/.config/iphonebridge/local.env") == 600 ]] ||
  fail "the installer writes the paired iPhone's address to local.env, readable only by the user"
pass "the installer writes the paired iPhone's address to local.env, readable only by the user"

! grep -qE '^(python3|gum)' "$TEST_LOG" ||
  fail "the installer skips pairing when the iPhone's pairing has Low Energy keys" "$(cat "$TEST_LOG")"
pass "the installer skips pairing when the iPhone's pairing has Low Energy keys"

# systemctl restart returns before the daemon has executed, so the label check waits for it.
(( $(grep -c '^sleep 1$' "$TEST_LOG") == 10 )) ||
  fail "the installer waits up to 10 seconds for the daemon's AppArmor label" "$(cat "$TEST_LOG")"
pass "the installer waits up to 10 seconds for the daemon's AppArmor label"

# After ancs-enable, the installer connects the iPhone's Hands-Free and AV Remote Control profiles,
# then restarts the daemon.
order=$(grep -oE '^(iphonebridge ancs-enable|bluetoothctl connect [0-9A-F:]+ [0-9a-f]{8}|systemctl --user restart iphonebridge)' "$TEST_LOG" | tail -4 | sed 's/ [0-9A-F:]\{17\} / /' | tr '\n' ',')
[[ $order == "iphonebridge ancs-enable,bluetoothctl connect 0000111f,bluetoothctl connect 0000110e,systemctl --user restart iphonebridge," ]] ||
  fail "the installer connects calls and media control after ancs-enable, then restarts the daemon" "$(cat "$TEST_LOG")"
pass "the installer connects calls and media control after ancs-enable, then restarts the daemon"

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
  -z $(ls -A "$HOME/.config/wireplumber/wireplumber.conf.d") ]] ||
  fail "the remover deletes the settings, the data and the WirePlumber config"
pass "the remover forgets the iPhone, purges the packages and deletes the settings and the data"

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
  grep -A1 '"install.service.signal":' "$menu" | grep -q '"install.service.iphone":.*"label":"iPhone","when":"! omarchy-pkg-present iphonebridge","action":"omarchy-launch-floating-terminal-with-presentation omarchy-install-service-iphone"' ||
  fail "Install > Service > iPhone follows Signal and runs the installer while iphonebridge is absent"
pass "Install > Service > iPhone follows Signal and runs the installer while iphonebridge is absent"
grep -A1 '"remove.service.signal":' "$menu" | grep -q '"remove.service.iphone":.*"label":"iPhone","when":"omarchy-pkg-present iphonebridge","action":"omarchy-launch-floating-terminal-with-presentation omarchy-remove-service-iphone"' ||
  fail "Remove > Services > iPhone follows Signal and runs the remover while iphonebridge is installed"
pass "Remove > Services > iPhone follows Signal and runs the remover while iphonebridge is installed"
