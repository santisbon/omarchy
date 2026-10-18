#!/bin/bash

# The factory reset's Ubuntu parts (the distro's docs/6): the functions of
# omarchy-system-factory-reset, -finish and omarchy-provision-owner that the port rewrote,
# each loaded on its own from its script and run on files under a temporary directory with
# stand-ins for the commands that would change the machine. The whole reset, with its
# reboots, runs in the distro's VM test (make factory-reset-test).

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# One function's definition, from its first line to the closing brace at column 0.
load() {
  local script="$1" fn
  shift
  for fn in "$@"; do
    source <(sed -n "/^$fn() {/,/^}/p" "$ROOT/bin/$script")
    declare -F "$fn" >/dev/null || fail "$script defines $fn"
  done
}

log() { :; }
log_step() { :; }
LOG_FILE=/dev/null
mkdir -p "$tmp/bin"
export PATH="$tmp/bin:$PATH"

# --- the reset stages the boot-time unlock in /etc/crypttab and the conf-hook
load omarchy-system-factory-reset stage_luks_rekey generate_passphrase
next="$tmp/next"
mkdir -p "$next/etc/cryptsetup-initramfs"
uuid=0d6a1f2e-1111-2222-3333-444455556666
printf '# <target name> <source device> <key file> <options>\nluks-%s UUID=%s none luks,discard\nother UUID=aaaa none luks\n' "$uuid" "$uuid" >"$next/etc/crypttab"
printf '#KEYFILE_PATTERN=\n' >"$next/etc/cryptsetup-initramfs/conf-hook"
cp "$next/etc/crypttab" "$tmp/crypttab.before"
cp "$next/etc/cryptsetup-initramfs/conf-hook" "$tmp/conf-hook.before"
cat >"$tmp/bin/cryptsetup" <<'SH'
#!/bin/bash
case $1 in
  luksUUID) echo 0d6a1f2e-1111-2222-3333-444455556666 ;;
  open | luksAddKey) echo "$*" >>"$CRYPTSETUP_CALLS" ;;
esac
SH
cat >"$tmp/bin/gum" <<'SH'
#!/bin/bash
[[ $1 == input ]] && echo "old passphrase"
exit 0
SH
chmod +x "$tmp/bin"/*
export CRYPTSETUP_CALLS="$tmp/cryptsetup.calls"
PROVISIONING_DIR=/var/lib/omarchy/provisioning
PROVISIONING_KEY=/etc/omarchy/provisioning.key
CONF_HOOK=/etc/cryptsetup-initramfs/conf-hook
UMASK_CONF=/etc/initramfs-tools/conf.d/omarchy-provisioning
luks_device() { echo /dev/null; }
stage_luks_rekey "$next" >/dev/null

root_line=$(grep "^luks-$uuid" "$next/etc/crypttab")
[[ $root_line == "luks-$uuid"$'\t'"UUID=$uuid"$'\t'"/etc/omarchy/provisioning.key"$'\t'"luks,discard" ]] ||
  fail "the root's crypttab line names the provisioning keyfile" "$root_line"
grep -qx 'other UUID=aaaa none luks' "$next/etc/crypttab" || fail "other crypttab lines are left as they were"
grep -qx '# <target name> <source device> <key file> <options>' "$next/etc/crypttab" || fail "crypttab comments stay"
tail -n1 "$next/etc/cryptsetup-initramfs/conf-hook" | grep -qx 'KEYFILE_PATTERN="/etc/omarchy/provisioning.key"' ||
  fail "the conf-hook copies the keyfile into the initramfs"
grep -qx 'UMASK=0077' "$next/etc/initramfs-tools/conf.d/omarchy-provisioning" || fail "the initramfs is made root-only"
cmp -s "$tmp/crypttab.before" "$next$PROVISIONING_DIR/crypttab.orig" || fail "the original crypttab is kept"
cmp -s "$tmp/conf-hook.before" "$next$PROVISIONING_DIR/conf-hook.orig" || fail "the original conf-hook is kept"
[[ $(stat -c %a "$next$PROVISIONING_KEY") == 600 && $(stat -c %a "$next$PROVISIONING_DIR/luks-key") == 600 ]] ||
  fail "both copies of the throwaway key are root-only"
cmp -s "$next$PROVISIONING_KEY" "$next$PROVISIONING_DIR/luks-key" || fail "the keyfile is the staged key"
pass "the reset stages the boot-time unlock in crypttab and the conf-hook, keeping the originals"

# --- the owner setup puts the originals back byte for byte, and can stage them again
load omarchy-provision-owner restore_unlock_files stage_unlock_files
PROVISIONING_DIR="$next/var/lib/omarchy/provisioning"
PROVISIONING_KEY="$next/etc/omarchy/provisioning.key"
CONF_HOOK="$next/etc/cryptsetup-initramfs/conf-hook"
UMASK_CONF="$next/etc/initramfs-tools/conf.d/omarchy-provisioning"
CRYPTTAB="$next/etc/crypttab"
crypttab_staged=$(cat "$CRYPTTAB")
restore_unlock_files
cmp -s "$tmp/crypttab.before" "$next/etc/crypttab" || fail "first-boot setup restores crypttab byte for byte"
cmp -s "$tmp/conf-hook.before" "$CONF_HOOK" || fail "first-boot setup restores the conf-hook byte for byte"
[[ ! -e $PROVISIONING_KEY && ! -e $UMASK_CONF ]] || fail "the keyfile and the umask drop-in are removed"
stage_unlock_files
[[ $(cat "$next/etc/crypttab") == "$crypttab_staged" ]] || fail "a failed rebuild stages the unlock again"
[[ -f $PROVISIONING_KEY ]] || fail "a failed rebuild puts the keyfile back"
pass "first-boot setup restores the originals, and stages the unlock again when the rebuild fails"

# --- the reset removes accounts and identity from a root
load omarchy-system-factory-reset scrub_accounts_and_identity
fake="$tmp/fake"
mkdir -p "$fake"/{etc/ssh,etc/NetworkManager/system-connections,var/lib/NetworkManager,var/lib/fprint/ana,home/ana,var/lib/sddm,etc/sddm.conf.d}
printf 'root:x:0:0::/root:/bin/bash\nsddm:x:120:120::/var/lib/sddm:/bin/false\nana:x:1000:1000::/home/ana:/bin/bash\nnobody:x:65534:65534::/:/bin/false\n' >"$fake/etc/passwd"
touch "$fake/etc/ssh/ssh_host_ed25519_key" "$fake/etc/ssh/sshd_config" "$fake/etc/NetworkManager/system-connections/home.nmconnection" \
  "$fake/var/lib/sddm/state.conf" "$fake/etc/sddm.conf.d/autologin.conf" "$fake/home/ana/notes"
cat >"$tmp/bin/userdel" <<'SH'
#!/bin/bash
[[ $1 == --root ]] && sed -i "/^$3:/d" "$2/etc/passwd"
SH
printf '#!/bin/bash\nexit 0\n' >"$tmp/bin/passwd"
chmod +x "$tmp/bin"/*
scrub_accounts_and_identity "$fake" "the test root"
! grep -q '^ana:' "$fake/etc/passwd" || fail "the user is removed"
grep -q '^sddm:' "$fake/etc/passwd" && grep -q '^nobody:' "$fake/etc/passwd" || fail "system accounts stay"
[[ ! -e $fake/home/ana && ! -e $fake/var/lib/fprint/ana ]] || fail "the user's home and fingerprints go"
[[ ! -e $fake/etc/ssh/ssh_host_ed25519_key && -e $fake/etc/ssh/sshd_config ]] || fail "host keys go, sshd's config stays"
[[ -z $(ls "$fake/etc/NetworkManager/system-connections") ]] || fail "network connections go"
[[ ! -e $fake/var/lib/sddm/state.conf && ! -e $fake/etc/sddm.conf.d/autologin.conf ]] || fail "the login manager forgets the user"
pass "the reset removes users, homes, fingerprints, host keys, connections and the last login"

# --- the new owner's groups: sudo, plus the old user's, without docker or a stale input
load omarchy-provision-owner user_groups
PROVISIONING_DIR="$tmp/prov"
mkdir -p "$PROVISIONING_DIR"
printf 'adm\nsudo\ndocker\ninput\nlpadmin\nno-such-group\n' >"$PROVISIONING_DIR/groups"
getent() { [[ $1 == group && $2 != no-such-group ]]; }
omarchy-pkg-present() { return 1; }
[[ $(user_groups) == "sudo,adm,lpadmin" ]] || fail "groups without ydotool" "$(user_groups)"
omarchy-pkg-present() { [[ $1 == ydotool ]]; }
[[ $(user_groups) == "sudo,adm,input,lpadmin" ]] || fail "input stays with ydotool" "$(user_groups)"
rm "$PROVISIONING_DIR/groups"
[[ $(user_groups) == "sudo" ]] || fail "sudo alone without a record" "$(user_groups)"
unset -f getent omarchy-pkg-present
pass "the new owner gets sudo and the old user's groups, never docker, input only with ydotool"

# --- the keyboard goes to localectl's X11 keymap
load omarchy-provision-owner apply_keyboard
KEYBOARD_FILE="$tmp/keyboard"
printf 'XKBMODEL="pc105"\nXKBLAYOUT="us"\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n' >"$KEYBOARD_FILE"
apply_keyboard us:dvorak
grep -qx 'XKBLAYOUT="us"' "$KEYBOARD_FILE" && grep -qx 'XKBVARIANT="dvorak"' "$KEYBOARD_FILE" ||
  fail "a layout and variant reach /etc/default/keyboard" "$(cat "$KEYBOARD_FILE")"
apply_keyboard gb
grep -qx 'XKBLAYOUT="gb"' "$KEYBOARD_FILE" && grep -qx 'XKBVARIANT=""' "$KEYBOARD_FILE" ||
  fail "a layout without a variant clears the variant" "$(cat "$KEYBOARD_FILE")"
grep -qx 'XKBOPTIONS=""' "$KEYBOARD_FILE" && grep -qx 'XKBMODEL="pc105"' "$KEYBOARD_FILE" || fail "the file's other keys stay"
rm "$KEYBOARD_FILE"
apply_keyboard fr
grep -qx 'XKBLAYOUT="fr"' "$KEYBOARD_FILE" || fail "a missing file is created" "$(cat "$KEYBOARD_FILE")"
# Every layout the form offers is one XKB knows.
source "$ROOT/install/provisioning/setup-form.sh"
if [[ -f /usr/share/X11/xkb/rules/evdev.lst ]]; then
  while IFS='|' read -r label value; do
    layout=${value%%:*}
    awk '/^! layout/{f=1;next} /^!/{f=0} f{print $1}' /usr/share/X11/xkb/rules/evdev.lst | grep -x "$layout" >/dev/null ||
      fail "the form's layout for $label is an XKB layout" "$layout"
    if [[ $value == *:* ]]; then
      awk '/^! variant/{f=1;next} /^!/{f=0} f{print $1, $2}' /usr/share/X11/xkb/rules/evdev.lst |
        grep -x "${value#*:} $layout:" >/dev/null || fail "the form's variant for $label is an XKB variant" "$value"
    fi
  done <<<"$OMARCHY_KEYBOARD_LAYOUTS"
fi
pass "the keyboard reaches /etc/default/keyboard as an XKB layout and variant"

# --- the finish step recreates the swap file at the old size
load omarchy-system-factory-reset-finish recreate_subvolume delete_subvolume recreate_swap
TOP_MNT="$tmp/top"
mkdir -p "$TOP_MNT/@swap"
truncate -s 4096 "$TOP_MNT/@swap/swapfile"
cat >"$tmp/bin/btrfs" <<'SH'
#!/bin/bash
echo "$*" >>"$BTRFS_CALLS"
case "$1 $2" in
  "subvolume delete") rm -rf "${@: -1}" ;;
  "subvolume create") mkdir -p "$3" ;;
esac
SH
chmod +x "$tmp/bin/btrfs"
export BTRFS_CALLS="$tmp/btrfs.calls"
recreate_swap
grep -qx "filesystem mkswapfile --size 4096 $TOP_MNT/@swap/swapfile" "$BTRFS_CALLS" ||
  fail "the swap file comes back at its old size" "$(cat "$BTRFS_CALLS")"
pass "the finish step recreates @swap and a swap file of the old size"
