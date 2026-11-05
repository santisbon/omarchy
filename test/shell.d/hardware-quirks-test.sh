#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'chmod -R u+rwX "$test_tmp"; rm -rf "$test_tmp"' EXIT

# --- Every setup step is reached ---

# Run the real dispatchers with run_logged recording what they would run. A
# hardware leaf neither dispatches is still reached when another hardware
# script names it.
dispatched=$(
  run_logged() { printf '%s\n' "${1#"$ROOT/install/"}"; }
  OMARCHY_INSTALL="$ROOT/install"
  source "$ROOT/install/config/all.sh"
  source "$ROOT/install/hardware/all.sh"
  source "$ROOT/install/user/all.sh"
)
while read -r script; do
  [[ -f $ROOT/install/$script ]] || fail "install/$script, run during setup, exists"
done <<<"$dispatched"
while read -r leaf; do
  leaf=${leaf#"$ROOT/install/"}
  grep -Fxq "$leaf" <<<"$dispatched" && continue
  # A comment or a message naming the leaf runs nothing, so it does not count.
  grep -rF --exclude=all.sh "$leaf" "$ROOT/install/hardware" "$ROOT/install/user/hardware" |
    grep -vF "/install/$leaf:" | grep -vqE '^[^:]+:[[:space:]]*(#|echo )' ||
    fail "install/$leaf runs during setup" "neither install/hardware/all.sh nor install/user/all.sh runs it, and no other hardware script names it"
done < <(find "$ROOT/install/hardware" "$ROOT/install/user/hardware" -name '*.sh' ! -name all.sh | sort)
while read -r leaf; do
  leaf=${leaf#"$ROOT/install/"}
  grep -Fxq "$leaf" <<<"$dispatched" || fail "install/$leaf runs during setup" "its all.sh does not run it"
done < <(find "$ROOT/install/config" "$ROOT/install/user" -maxdepth 1 -name '*.sh' ! -name all.sh | sort)
pass "every setup script is reached from setup"

# --- Each quirk is a no-op on other hardware and applies on its own ---

# The fake machine: DMI attributes as files, which cat and omarchy-hw-match
# read in place of /sys/class/dmi/id; the platform, loaded modules, input
# devices and lspci listing come from FAKE_* variables. Writes the leaves make
# through sudo land under a scratch root, and every other effect is logged.
hw="$test_tmp/hw"
root="$test_tmp/root"
stub_bin="$test_tmp/bin"
calls="$test_tmp/calls"
mkdir -p "$stub_bin"

sed 's|/sys/class/dmi/id|$FAKE_HW/dmi|g' "$ROOT/bin/omarchy-hw-match" >"$stub_bin/omarchy-hw-match"

cat >"$stub_bin/cat" <<'SH'
#!/bin/bash
args=()
for arg in "$@"; do
  [[ $arg == /sys/class/dmi/id/* ]] && arg="$FAKE_HW/dmi/${arg#/sys/class/dmi/id/}"
  args+=("$arg")
done
exec /usr/bin/cat "${args[@]}"
SH

cat >"$stub_bin/omarchy-hw-x86" <<'SH'
#!/bin/bash
[[ $FAKE_PLATFORM == "x86" ]]
SH

cat >"$stub_bin/lspci" <<'SH'
#!/bin/bash
printf '%b\n' "$FAKE_LSPCI"
SH

cat >"$stub_bin/lsmod" <<'SH'
#!/bin/bash
printf 'Module                  Size  Used by\n%b\n' "$FAKE_LSMOD"
SH

# -qn resolves a module without loading it: FAKE_MODPROBE_RESOLVES=1 is a
# chroot whose running kernel's modules are not on disk.
cat >"$stub_bin/modprobe" <<'SH'
#!/bin/bash
[[ $1 == "-qn" ]] && exit "$FAKE_MODPROBE_RESOLVES"
printf 'modprobe %s\n' "$*" >>"$CALLS"
exit "$FAKE_MODPROBE_STATUS"
SH

cat >"$stub_bin/omarchy-pkg-add" <<'SH'
#!/bin/bash
printf 'pkg-add %s\n' "$*" >>"$CALLS"
exit "$FAKE_PKG_ADD_STATUS"
SH

cat >"$stub_bin/omarchy-pkg-drop" <<'SH'
#!/bin/bash
printf 'pkg-drop %s\n' "$*" >>"$CALLS"
SH

# File writes run for real under the scratch root; anything else is logged and
# only runs when it is one of the stubs above.
cat >"$stub_bin/sudo" <<'SH'
#!/bin/bash
args=()
for arg in "$@"; do
  [[ $arg == /etc/* ]] && arg="$FAKE_ROOT$arg"
  args+=("$arg")
done
case $1 in
  mkdir | tee | install) exec "${args[@]}" ;;
esac
printf 'sudo %s\n' "$*" >>"$CALLS"
[[ -x $STUB_BIN/$1 ]] && exec "$STUB_BIN/$1" "${@:2}"
exit 0
SH

chmod +x "$stub_bin"/*

# machine <name>[+unreadable]: build the fake machine. +unreadable keeps its
# DMI attributes but makes them unreadable, as a locked-down sysfs does.
machine() {
  local name=${1%+unreadable}
  rm -rf "$hw" "$root"
  mkdir -p "$hw/dmi" "$root/etc" "$root/home/.config/hypr"
  printf '%s\n' '-- User look and feel' >"$root/home/.config/hypr/looknfeel.lua"
  : >"$hw/input-devices"
  FAKE_PLATFORM=x86 FAKE_LSMOD="" FAKE_LSPCI="00:02.0 VGA compatible controller: Intel Corporation Alder Lake\n\tKernel driver in use: i915"
  FAKE_MODPROBE_RESOLVES=0 FAKE_MODPROBE_STATUS=0 FAKE_PKG_ADD_STATUS=0

  dmi() { printf '%s\n' "$2" >"$hw/dmi/$1"; }
  xps13() { dmi sys_vendor "Dell Inc."; dmi product_name "XPS 13 ${1:-DX13260}"; dmi product_sku "${2:-0E53}"; }
  synaptics() { printf '%s\n' 'N: Name="SynPS/2 Synaptics TouchPad"' >"$hw/input-devices"; }
  surface() { dmi sys_vendor "Microsoft Corporation"; dmi product_name "$1"; }

  case $name in
    plain) dmi sys_vendor LENOVO; dmi product_name 21HM0000US; dmi product_family "ThinkPad X1 Carbon Gen 11" ;;
    no-dmi) rm -rf "$hw/dmi" ;;
    macbookpro13) dmi product_name "MacBookPro13,2" ;;
    macbook8) dmi product_name "MacBook8,1" ;;
    macbookpro15) dmi product_name "MacBookPro15,1" ;;
    synaptics) synaptics ;;
    synaptics-chroot) synaptics; FAKE_MODPROBE_RESOLVES=1 ;;
    synaptics-psmouse-loaded) synaptics; FAKE_LSMOD="psmouse 217088 0" ;;
    synaptics-modprobe-fails) synaptics; FAKE_MODPROBE_STATUS=1 ;;
    surface-intel) surface "Surface Laptop 3"; FAKE_LSMOD="pinctrl_tigerlake 32768 0" ;;
    xps13-wcl) xps13; FAKE_LSPCI="00:02.0 VGA compatible controller: Intel Corporation Wildcat Lake [Intel Graphics]" ;;
    nouveau) FAKE_LSPCI="01:00.0 VGA compatible controller: NVIDIA Corporation GK208B\n\tKernel driver in use: nouveau" ;;
    nouveau-proprietary) FAKE_LSPCI="01:00.0 VGA compatible controller: NVIDIA Corporation GK208B\n\tKernel driver in use: nouveau"; : >"$hw/nvidia.conf" ;;
    *) fail "hardware-quirks-test knows the machine '$name'" ;;
  esac

  if [[ $1 == *+unreadable ]]; then
    chmod 000 "$hw/dmi"/*
  fi
  export FAKE_PLATFORM FAKE_LSMOD FAKE_LSPCI FAKE_MODPROBE_RESOLVES FAKE_MODPROBE_STATUS FAKE_PKG_ADD_STATUS
}

snapshot() {
  (cd "$root" && find . -type f -exec md5sum {} + | LC_ALL=C sort)
}

# run_leaf <install-relative script>: source it the way run_logged does, under
# errexit, and print its exit status and what it did: logged calls, then every
# file it created or changed under the scratch root.
run_leaf() {
  local before status=0
  : >"$calls"
  before=$(snapshot)
  HOME="$root/home" OMARCHY_PATH="$ROOT" PATH="$stub_bin:$ROOT/bin:$PATH" STUB_BIN="$stub_bin" CALLS="$calls" \
    FAKE_HW="$hw" FAKE_ROOT="$root" \
    OMARCHY_DMI_PRODUCT_SKU="$hw/dmi/product_sku" \
    OMARCHY_SYNAPTIC_INPUT_DEVICES="$hw/input-devices" \
    OMARCHY_NVIDIA_MODPROBE_CONFIG="$hw/nvidia.conf" \
    bash -eE -c 'source <(sed "s|/etc/initramfs-tools|\$FAKE_ROOT&|g" "$1")' bash "$ROOT/install/$1" </dev/null >/dev/null 2>&1 || status=$?
  {
    printf '%s\n' "$status"
    cat "$calls"
    LC_ALL=C comm -13 <(printf '%s\n' "$before") <(snapshot) | sed 's|^[^ ]*  \./|wrote |'
  } | paste -sd '|'
}

leaves=(
  hardware/apple/fix-spi-keyboard.sh
  hardware/fix-synaptic-touchpad.sh
  hardware/fix-surface-keyboard.sh
  user/hardware/fix-nouveau-cursor.sh
)

for leaf in "${leaves[@]}"; do
  for name in plain no-dmi; do
    machine "$name"
    got=$(run_leaf "$leaf")
    [[ $got == "0" ]] || fail "install/$leaf does nothing on a $name machine" "got: $got"
  done
done
pass "hardware quirks do nothing on unrelated machines or machines without DMI"

# leaf|machine|exit status, then what it did, |-separated
while IFS='|' read -r leaf name want; do
  [[ -n $leaf && $leaf != \#* ]] || continue
  if [[ $name == *+unreadable ]] && (( EUID == 0 )); then
    continue
  fi
  machine "$name"
  got=$(run_leaf "$leaf")
  [[ $got == "$want" ]] || fail "install/$leaf on $name: $want" "got: $got"
done <<'ROWS'
# Ubuntu's initramfs already carries the other models' SPI modules.
hardware/apple/fix-spi-keyboard.sh|macbook8|0|wrote etc/initramfs-tools/hooks/omarchy-macbook-spi-keyboard
hardware/apple/fix-spi-keyboard.sh|macbook8+unreadable|0
hardware/apple/fix-spi-keyboard.sh|macbookpro13|0
hardware/apple/fix-spi-keyboard.sh|macbookpro15|0
hardware/fix-synaptic-touchpad.sh|synaptics|0|modprobe psmouse synaptics_intertouch=1
# In a chroot the live kernel's modules are not the ones on disk.
hardware/fix-synaptic-touchpad.sh|synaptics-chroot|0
hardware/fix-synaptic-touchpad.sh|synaptics-psmouse-loaded|0
# An optional touchpad improvement never gets to halt an install.
hardware/fix-synaptic-touchpad.sh|synaptics-modprobe-fails|0|modprobe psmouse synaptics_intertouch=1
hardware/fix-surface-keyboard.sh|surface-intel|0|wrote etc/initramfs-tools/hooks/omarchy-surface-keyboard
hardware/fix-surface-keyboard.sh|surface-intel+unreadable|0
# Wildcat Lake's GPU is named only "[Intel Graphics]".
hardware/intel/video-acceleration.sh|xps13-wcl|0|pkg-add intel-media-va-driver-non-free libvpl2 libmfx-gen1.2
hardware/intel/video-acceleration.sh|nouveau|0
user/hardware/fix-nouveau-cursor.sh|nouveau|0|wrote home/.config/hypr/looknfeel.lua
# Supported GPUs still use nouveau during installation before switching drivers on reboot.
user/hardware/fix-nouveau-cursor.sh|nouveau-proprietary|0
ROWS
pass "hardware quirks apply on their own hardware and nowhere else"

# --- What the applied quirks leave behind ---

machine surface-intel
run_leaf hardware/fix-surface-keyboard.sh >/dev/null
hook="$root/etc/initramfs-tools/hooks/omarchy-surface-keyboard"
grep -Fxq 'force_load surface_aggregator_hub' "$hook" || fail "Surface keyboard setup loads the one module Ubuntu's initramfs lacks"
[[ -x $hook ]] || fail "Surface keyboard hook is executable, or initramfs-tools skips it"
pass "Surface keyboard setup adds the module Ubuntu's initramfs lacks"

machine nouveau
run_leaf user/hardware/fix-nouveau-cursor.sh >/dev/null
run_leaf user/hardware/fix-nouveau-cursor.sh >/dev/null
(( $(grep -c 'no_hardware_cursors = true' "$root/home/.config/hypr/looknfeel.lua") == 1 )) ||
  fail "nouveau cursor setup enables software cursors once however often it runs"
pass "nouveau cursor setup is idempotent"
