#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/root"

stub() { printf '#!/bin/bash\n%s\n' "$2" >"$work/bin/$1"; chmod +x "$work/bin/$1"; }
stub omarchy-pkg-add 'echo "pkg-add $*" >>"$TEST_LOG"'

# Run a hardware script with /etc/ moved under the work directory.
run() { sed "s#/etc/#$work/root/etc/#g" "$ROOT/install/hardware/$1" | PATH="$work/bin:$PATH" bash; }

stub omarchy-hw-asus-expertbook-b9406 'exit 0'
stub omarchy-hw-asus-zenbook-ux5406aa 'exit 1'
run asus/fix-asus-ptl-display-backlight.sh
run asus/fix-asus-ptl-b9406-display.sh
grep -qx 'options xe enable_dpcd_backlight=1' "$work/root/etc/modprobe.d/omarchy-asus-ptl-display-backlight.conf" || fail "B9406 gets DPCD backlight"
grep -qx 'options xe enable_panel_replay=0' "$work/root/etc/modprobe.d/omarchy-asus-expertbook-b9406-display.conf" || fail "B9406 gets Panel Replay off"

rm -rf "$work/root/etc"
stub omarchy-hw-asus-expertbook-b9406 'exit 1'
run asus/fix-asus-ptl-display-backlight.sh
run asus/fix-asus-ptl-b9406-display.sh
[[ ! -e $work/root/etc/modprobe.d ]] || fail "other machines get no xe options"

stub lspci 'echo "00:02.0 VGA compatible controller: Intel Corporation Arrow Lake-S [Intel Graphics] (rev 06) Iris Xe"'
run intel/video-acceleration.sh
grep -qx 'pkg-add intel-media-va-driver-non-free libvpl2 libmfx-gen1.2' "$TEST_LOG" || fail "current Intel GPUs get the Quick Sync runtime" "$(cat "$TEST_LOG")"
: >"$TEST_LOG"
stub lspci 'echo "00:02.0 VGA compatible controller: Intel Corporation Mobile GM965/GL960 Integrated Graphics Controller (primary) (rev 0c) GMA X3100"'
run intel/video-acceleration.sh
grep -qx 'pkg-add i965-va-driver' "$TEST_LOG" || fail "GMA-era Intel GPUs get the i965 driver"

: >"$TEST_LOG"
stub lspci 'echo "02:00.0 Network controller [0280]: Broadcom Inc. and subsidiaries BCM4331 802.11a/b/g/n [14e4:4331] (rev 02)"'
run fix-bcm43xx.sh >/dev/null
grep -qx 'pkg-add firmware-b43-installer' "$TEST_LOG" || fail "BCM4331 gets b43's firmware"
: >"$TEST_LOG"
stub lspci 'echo "02:00.0 Network controller [0280]: Broadcom Inc. and subsidiaries BCM4360 802.11ac [14e4:43a0] (rev 03)"'
run fix-bcm43xx.sh >/dev/null
[[ ! -s $TEST_LOG ]] || fail "BCM4360 gets nothing: its only driver is DKMS"

rm -rf "$work/root/etc"
stub lspci 'case "$*" in *-nn*) echo "00:14.3 Network controller [0280]: Intel Corporation Wi-Fi 7(802.11be) AX1775*/AX1790*/BE20*/BE401/BE1750* 2x2 [8086:272b] (rev 1a)" ;; *) echo "00:02.0 VGA compatible controller: Intel Corporation Raptor Lake-S UHD Graphics (rev 04)" ;; esac'
stub omarchy-hw-match '[[ $1 == XPS ]] && exit 1; exit 1'
stub omarchy-hw-intel-ptl 'exit 1'
run intel/fix-wifi7-eht.sh
[[ ! -e $work/root/etc/modprobe.d/iwlwifi-disable-eht.conf ]] || fail "a BE200 outside a Dell XPS on Panther Lake keeps Wi-Fi 7"
stub omarchy-hw-match '[[ $1 == XPS ]]'
stub omarchy-hw-intel-ptl 'exit 0'
run intel/fix-wifi7-eht.sh
grep -qx 'options iwlwifi disable_11be=Y' "$work/root/etc/modprobe.d/iwlwifi-disable-eht.conf" || fail "a Dell XPS on Panther Lake gets Wi-Fi 7 off"

# Run a generated initramfs hook with a force_load that prints the module.
run_hook() { sed "s#/usr/share/initramfs-tools/hook-functions#$work/hook-functions#" "$1" | sh; }
echo 'force_load() { echo "force_load $1"; }' >"$work/hook-functions"

rm -rf "$work/root/etc"; mkdir -p "$work/root/etc"
ln -s /usr/share/zoneinfo/America/Mexico_City "$work/root/etc/localtime"
run set-wireless-regdom.sh
grep -qx 'options cfg80211 ieee80211_regdom=MX' "$work/root/etc/modprobe.d/omarchy-wireless-regdom.conf" || fail "the timezone's country becomes cfg80211's regulatory domain"

stub omarchy-hw-surface 'exit 0'
stub lsmod 'printf "Module Size Used by\npinctrl_tigerlake 32768 1\n"'
run fix-surface-keyboard.sh >/dev/null
hook="$work/root/etc/initramfs-tools/hooks/omarchy-surface-keyboard"
[[ -x $hook ]] || fail "a Surface gets an executable initramfs hook"
loads=$(run_hook "$hook" | paste -sd' ')
[[ $loads == "force_load pinctrl_tigerlake force_load surface_aggregator force_load surface_aggregator_registry force_load surface_aggregator_hub force_load surface_hid_core force_load surface_hid force_load surface_kbd force_load intel_lpss_pci force_load 8250_dw" ]] ||
  fail "the Surface hook force-loads the pinctrl and keyboard modules" "$loads"

mkdir -p "$work/dmi"; echo "MacBook8,1" >"$work/dmi/product_name"
run_dmi() { sed "s#/sys/class/dmi/id/#$work/dmi/#g; s#/etc/#$work/root/etc/#g" "$ROOT/install/hardware/$1" | PATH="$work/bin:$PATH" bash; }
run_dmi apple/fix-spi-keyboard.sh >/dev/null
loads=$(run_hook "$work/root/etc/initramfs-tools/hooks/omarchy-macbook-spi-keyboard" | paste -sd' ')
[[ $loads == "force_load applespi force_load spi_pxa2xx_platform force_load spi_pxa2xx_pci" ]] || fail "a MacBook8,1 force-loads its SPI keyboard modules" "$loads"
! grep -q dkms "$TEST_LOG" || fail "the SPI keyboard needs no DKMS package"

: >"$TEST_LOG"
mkdir -p "$work/acpi/INT3472:00"; echo OVTI08F4 >"$work/acpi/INT3472:00/hid"
sed "s#/sys/bus/acpi/devices/#$work/acpi/#" "$ROOT/install/hardware/intel/ipu7-camera.sh" | PATH="$work/bin:$PATH" bash
grep -qx 'pkg-add libcamera0.7 libcamera-ipa gstreamer1.0-libcamera libspa-0.2-libcamera' "$TEST_LOG" || fail "an OV08X40 camera gets libcamera"

: >"$TEST_LOG"
stub omarchy-hw-dell-xps-haptic-touchpad 'exit 0'
run dell-xps-touchpad-haptics.sh
grep -qx 'pkg-add dell-xps-touchpad-haptics' "$TEST_LOG" || fail "an XPS with the haptic touchpad gets its package"
: >"$TEST_LOG"
stub omarchy-hw-dell-xps-haptic-touchpad 'exit 1'
run dell-xps-touchpad-haptics.sh
[[ ! -s $TEST_LOG ]] || fail "other machines do not get the haptics package"

grep -qx 'fs.inotify.max_user_watches=524288' "$ROOT/etc/sysctl.d/90-omarchy-file-watchers.conf" || fail "the inotify limit ships"

pass "hardware fixes apply on their own machines only"
