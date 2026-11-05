#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# Owner provisioning's LUKS re-key, killed after every durable step and rerun.
# Each attempt is its own process, like a reboot: omarchy-provision-owner's
# setup attempt from the accepted owner form on, the shared re-key, and a
# cryptsetup that is either a slot-table fake or the real binary on a
# file-backed LUKS2 or LUKS1 volume. The boot-time unlock is the port's: the
# keyfile, /etc/crypttab naming it and cryptsetup-initramfs's conf-hook, with
# update-initramfs stubbed.

tmp=$(mktemp -d)
token_key=""
trap 'rm -rf "$tmp"; [[ -z $token_key ]] || keyctl unlink "$token_key" @s >/dev/null 2>&1 || true' EXIT

runtime=$ROOT

staged_key=staged-install-key
seller_key=previous-owner-key
owner_password=owner-password

sed -n '/^CRYPTTAB=/p; /^PROVISIONING_KEY=/p; /^CONF_HOOK=/p; /^UMASK_CONF=/p; /^KEYBOARD_FILE=/p
  /^restore_unlock_files() {/,/^}/p; /^stage_unlock_files() {/,/^}/p
  /^luks_auto_unlock_present() {/,/^}/p; /^luks_auto_unlock_drop() {/,/^}/p
  /^luks_record_slots() {/,/^}/p' \
  "$ROOT/bin/omarchy-provision-owner" | sed "s|/etc/|$tmp/etc/|g" >"$tmp/unlock.sh"
grep -q '^luks_auto_unlock_drop() {' "$tmp/unlock.sh" && grep -q '^restore_unlock_files() {' "$tmp/unlock.sh" &&
  grep -q '^luks_record_slots() {' "$tmp/unlock.sh" ||
  fail "omarchy-provision-owner defines the auto-unlock callbacks and the slot record"
sed -n '/^rekey_luks() {/,/^}/p; /^run_provisioning() {/,/^}/p; /^cleanup_oem_state() {/,/^}/p
  /^run_setup() {/,/^}/p
  /^rekey_accepts_password() {/,/^}/p' \
  "$ROOT/bin/omarchy-provision-owner" |
  sed "s|/etc/|$tmp/etc/|g" >"$tmp/provision.sh"
grep -q '^run_provisioning() {' "$tmp/provision.sh" && grep -q '^run_setup() {' "$tmp/provision.sh" ||
  fail "omarchy-provision-owner defines its setup and provisioning worker"

cat >"$tmp/attempt.sh" <<'SH'
set -euo pipefail

source "$ROOT/install/provisioning/luks-rekey.sh"
source "$TMP/unlock.sh"
source <(sed -n '/^luks_boot_layout() {/,/^}/p' "$ROOT/bin/omarchy-provision-owner" | sed "s|/etc/|$TMP/etc/|g")
declare -F luks_boot_layout >/dev/null

PROVISIONING_DIR=$TMP/provisioning
REKEY_STATE=$PROVISIONING_DIR/luks-rekey.state
LOG_FILE=$TMP/log
password=$PASSWORD

log_step() { printf '%s\n' "$*" >>"$LOG_FILE"; }
say() { :; }

crash_point() {
  local count
  count=$(( $(cat "$TMP/steps") + 1 ))
  echo "$count" >"$TMP/steps"
  printf '%s %s\n' "$count" "$1" >>"$TMP/trace"
  if (( count == ${CRASH_AT:-0} )); then
    kill -9 $$
    kill -9 "$BASHPID"
  fi
}

eval "$(declare -f rekey_state_put | sed '1s/^rekey_state_put /journal_write /')"
rekey_state_put() {
  journal_write "$@" || return 1
  crash_point "journal $*"
}

eval "$(declare -f restore_unlock_files | sed '1s/^restore_unlock_files /restore_files_real /')"
restore_unlock_files() {
  restore_files_real || return 1
  crash_point "auto-unlock files removed"
}

update-initramfs() {
  echo rebuild >>"$TMP/rebuilds"
  [[ ! -e $TMP/rebuild-fail ]] || return 1
  crash_point "boot rebuilt"
}

shred() {
  command rm -f -- "${@: -1}"
  crash_point "staged key destroyed"
}

fake_cryptsetup() {
  local op=$1 key_file="" token_type="" target="" extra="" requested="" material slot next
  shift
  while (( $# )); do
    case $1 in
      --key-file) key_file=$2; shift 2 ;;
      --key-slot) requested=$2; shift 2 ;;
      --token-type) token_type=$2; shift 2 ;;
      -*) shift ;;
      *)
        if [[ -z $target ]]; then target=$1; else extra=$1; fi
        shift
        ;;
    esac
  done
  [[ $target == "$DEVICE" ]] || return 4

  if [[ $op == "luksDump" ]]; then
    echo "Keyslots:"
    awk '{ printf "  %s: luks2\n", $1 }' "$TMP/slots"
    if [[ -s $TMP/token-slot ]]; then
      printf 'Tokens:\n  0: luks2-keyring\n\tKeyslot:    %s\n' "$(cat "$TMP/token-slot")"
    fi
    printf 'Digests:\n  0: pbkdf2\n'
    return 0
  fi
  if [[ $op == "luksKillSlot" ]]; then
    [[ ! -e $TMP/kill-noop ]] || return 0
    awk -v s="$extra" '$1 != s' "$TMP/slots" >"$TMP/slots.next"
    command mv -f "$TMP/slots.next" "$TMP/slots"
    return 0
  fi

  # An enrolled token unlocks its slot whatever key is given, unless the
  # allowed token types exclude it, as with cryptsetup.
  if [[ $op == "open" && -z $token_type && -s $TMP/token-slot ]]; then
    echo "Key slot $(cat "$TMP/token-slot") unlocked."
    return 0
  fi

  material=$(cat "$key_file")
  slot=$(awk -v m="$material" '$2 == m { print $1; exit }' "$TMP/slots")
  if [[ -z $slot ]]; then
    echo "No key available with this passphrase."
    return 2
  fi
  case $op in
    open) echo "Key slot $slot unlocked." ;;
    luksAddKey)
      next=$requested
      if [[ -z $next ]]; then
        for (( next = 0; next < 32; next++ )); do
          awk '{ print $1 }' "$TMP/slots" | grep -qx "$next" || break
        done
      fi
      ! awk '{ print $1 }' "$TMP/slots" | grep -qx "$next" || return 1
      printf '%s %s\n' "$next" "$(cat "$extra")" >>"$TMP/slots"
      ;;
    *) return 1 ;;
  esac
}

cryptsetup() {
  local status=0
  if [[ $BACKEND == "fake" ]]; then
    fake_cryptsetup "$@" || status=$?
  elif [[ $1 == "luksAddKey" ]]; then
    command cryptsetup luksAddKey --pbkdf pbkdf2 --pbkdf-force-iterations 1000 "${@:2}" || status=$?
  else
    command cryptsetup "$@" || status=$?
  fi
  (( status == 0 )) || return "$status"
  case $1 in
    luksAddKey)
      echo owner >>"$TMP/adds"
      crash_point "owner key added"
      ;;
    luksKillSlot) crash_point "slot ${*: -1} killed" ;;
  esac
}

# omarchy-provision-owner's setup functions, with account and boot setup and
# the screen stubbed.
setup_functions() {
  source "$TMP/provision.sh"
  STATE_FILE=$TMP/state
  FINALIZE_WARNING_FLAG=$TMP/finalize-warning
  username=owner hostname="" timezone=""
  create_user() { :; }
  install_authorized_keys() { :; }
  configure_login() { :; }
  configure_hostname() { :; }
  configure_timezone() { :; }
  finalize_user() { :; }
  luks_device() { echo "$DEVICE"; }
  systemctl() { :; }
  clear_logo() { :; }
  sleep() { :; }
  say() { printf '%s\n' "$*" >>"$TMP/screen"; }
}

# The first-boot worker around the re-key.
provision() {
  setup_functions
  run_provisioning
}

# A whole setup attempt once the owner form is filled in: the password check,
# then the worker.
attempt() {
  setup_functions
  keyboard_form() { :; }
  user_form() { :; }
  confirm_form() { :; }
  notice() {
    printf 'refused: %s\n' "$1" >>"$TMP/screen"
    exit 3
  }
  set_now() { NOW=0; }
  render_setup_static() { :; }
  render_setup_dynamic() { :; }
  render_setup_finish() { :; }
  SHOW_CURSOR=""
  run_setup
}

# First-boot setup up to the owner form, with the screen captured.
setup() {
  source "$TMP/provision.sh"
  clear_logo() { :; }
  sleep() { :; }
  say() { printf '%s\n' "$*" >>"$TMP/screen"; }
  keyboard_form() {
    echo "owner form" >>"$TMP/screen"
    exit 0
  }
  run_setup
}

case $MODE in
  provision) provision ;;
  attempt) attempt ;;
  setup) setup ;;
  rekey) luks_rekey "$DEVICE" ;;
  accepts) luks_rekey_accepts_password "$DEVICE" ;;
  remains) luks_staged_unlock_remains ;;
esac
SH

run() {
  local mode=$1 password=$2 crash_at=${3:-0}
  echo "$crash_at" >"$tmp/crash-at"
  {
    ROOT=$ROOT TMP=$tmp BACKEND=$backend DEVICE=$device MODE=$mode PASSWORD=$password CRASH_AT=$crash_at \
      OMARCHY_PATH=$runtime bash "$tmp/attempt.sh"
  } >>"$tmp/output" 2>&1
}

# The slot the key opens on the volume, or nothing. Tokens never answer.
opens() {
  if [[ $backend == "fake" ]]; then
    awk -v m="$1" '$2 == m { print $1; exit }' "$tmp/slots"
  else
    LC_ALL=C cryptsetup open --test-passphrase --verbose --token-type passphrase-only --key-file <(printf '%s' "$1") "$device" 2>&1 |
      grep -o 'Key slot [0-9]* unlocked' | grep -o '[0-9]*' || true
  fi
}

slot_count() {
  if [[ $backend == "fake" ]]; then
    wc -l <"$tmp/slots"
  else
    cryptsetup luksDump "$device" 2>/dev/null | grep -cE '^ +[0-9]+: luks2$|^Key Slot [0-9]+: ENABLED'
  fi
}

fixture() {
  local format=${1:-luks2}
  rm -rf "$tmp/provisioning" "$tmp/etc" "$tmp/log" "$tmp/output" "$tmp/trace" "$tmp/rebuilds" "$tmp/adds" "$tmp/rebuild-fail" "$tmp/kill-noop" \
    "$tmp/screen" "$tmp/token-slot"
  mkdir -p "$tmp/provisioning"
  chmod 755 "$tmp/provisioning"
  touch "$tmp/provisioning/pending"
  printf '%s' "$staged_key" >"$tmp/provisioning/luks-key"
  # What the factory reset stages: the keyfile, /etc/crypttab and the conf-hook
  # naming it, and the originals kept for the re-key to restore.
  mkdir -p "$tmp/etc/omarchy" "$tmp/etc/cryptsetup-initramfs" "$tmp/etc/initramfs-tools/conf.d"
  printf '%s' "$staged_key" >"$tmp/etc/omarchy/provisioning.key"
  echo 'root UUID=root-uuid /etc/omarchy/provisioning.key luks' >"$tmp/etc/crypttab"
  echo 'KEYFILE_PATTERN=/etc/omarchy/provisioning.key' >"$tmp/etc/cryptsetup-initramfs/conf-hook"
  echo 'UMASK=0077' >"$tmp/etc/initramfs-tools/conf.d/omarchy-provisioning"
  echo 'root UUID=root-uuid none luks' >"$tmp/provisioning/crypttab.orig"
  echo '#KEYFILE_PATTERN=' >"$tmp/provisioning/conf-hook.orig"
  echo 0 >"$tmp/steps"
  : >"$tmp/log"

  # A reset leaves the previous owner's slot next to the staged key.
  if [[ $backend == "fake" ]]; then
    device=$tmp/volume
    : >"$device"
    printf '0 %s\n1 %s\n' "$staged_key" "$seller_key" >"$tmp/slots"
  else
    device=$tmp/volume.img
    rm -f "$device"
    truncate -s 32M "$device"
    local pbkdf=(--pbkdf pbkdf2 --pbkdf-force-iterations 1000)
    [[ $format == "luks1" ]] && pbkdf=(--pbkdf-force-iterations 1000)
    cryptsetup luksFormat -q --type "$format" "${pbkdf[@]}" "$device" <(printf '%s' "$staged_key")
    cryptsetup luksAddKey "${pbkdf[@]}" --key-file <(printf '%s' "$staged_key") "$device" <(printf '%s' "$seller_key")
  fi
}

# What a previous owner can leave on the real volume: a systemd-tpm2 token and
# a luks2-keyring token on slot $1, the second answered from the session keyring
# with $2. Fails when the kernel keyring is out of reach (no keyctl, or a
# container's seccomp profile), so that a bare cryptsetup open does not take the
# token in place of any key.
enroll_tokens() {
  local slot=$1 key=$2 description=omarchy-test-token-$$
  command -v keyctl >/dev/null || return 1
  token_key=$(printf '%s' "$key" | keyctl padd user "$description" @s 2>/dev/null) || return 1
  keyctl timeout "$token_key" 600 >/dev/null 2>&1 || true
  printf '{"type":"systemd-tpm2","keyslots":["%s"],"tpm2-blob":"AA==","tpm2-pcrs":[7],"tpm2-pcr-bank":"sha256","tpm2-primary-alg":"ecc","tpm2-policy-hash":"00","tpm2-pin":false}' "$slot" |
    cryptsetup token import --disable-external-tokens "$device" || return 1
  cryptsetup token add --key-description "$description" --key-slot "$slot" "$device" >/dev/null || return 1
  local unlocked
  unlocked=$(LC_ALL=C cryptsetup open --test-passphrase --verbose --key-file <(printf 'not-a-key') "$device" 2>&1) || return 1
  grep -qx "Key slot $slot unlocked." <<<"$unlocked"
}

unlock_files_present() {
  [[ -e $tmp/etc/omarchy/provisioning.key || -e $tmp/etc/initramfs-tools/conf.d/omarchy-provisioning ]] ||
    grep -qsF /etc/omarchy/provisioning.key "$tmp/etc/crypttab" "$tmp/etc/cryptsetup-initramfs/conf-hook"
}

no_secrets_in() {
  local file
  local -a keys=(-e "$staged_key" -e "$seller_key" -e "$owner_password" -e "other-password")
  for file in "$@"; do
    [[ -e $file ]] || continue
    ! grep -Fq "${keys[@]}" "$file" ||
      fail "$backend: $(basename "$file") holds no key material" "$(cat "$file")"
  done
}

# Between attempts the disk must still open at the next boot: unattended while
# the auto-unlock remains, otherwise with a password the owner typed.
assert_recoverable() {
  local context=$1 password=$2
  if unlock_files_present; then
    [[ -n $(opens "$staged_key") ]] || fail "$backend: $context: the auto-unlock key still opens the disk"
  else
    [[ -n $(opens "$password") ]] || fail "$backend: $context: the owner's password opens the disk once auto-unlock is gone"
  fi
  if [[ -n $(opens "$staged_key") && ! -f $tmp/provisioning/luks-key ]]; then
    fail "$backend: $context: the staged key file is kept while it still unlocks the volume"
  fi
  if [[ -f $tmp/provisioning/luks-rekey.state ]]; then
    [[ $(stat -c %a "$tmp/provisioning/luks-rekey.state") == "600" ]] || fail "$backend: $context: the journal is private"
  fi
  [[ $(stat -c %a "$tmp/provisioning") == "755" ]] || fail "$backend: $context: the provisioning directory stays readable for the new user"
  no_secrets_in "$tmp/provisioning/luks-rekey.state" "$tmp/log"
}

# The re-key finished: the owner's slot is all the volume holds.
assert_finished() {
  local context=$1 password=$2 max_adds=${3:-1} adds=0 owner
  owner=$(opens "$password")
  [[ $(slot_count) == "1" && -n $owner ]] || fail "$backend: $context: only the owner's slot remains" "$(cat "$tmp/log")"
  [[ -z $(opens "$staged_key") ]] || fail "$backend: $context: the staged install key no longer unlocks the volume"
  [[ -z $(opens "$seller_key") ]] || fail "$backend: $context: the previous owner's key no longer unlocks the volume"
  [[ ! -e $tmp/provisioning/luks-key ]] || fail "$backend: $context: the staged key file is destroyed"
  ! unlock_files_present || fail "$backend: $context: no boot-time auto-unlock remains"
  [[ -f $tmp/adds ]] && adds=$(grep -c '^owner' "$tmp/adds" || true)
  (( adds <= max_adds )) || fail "$backend: $context: the owner's key is added at most $max_adds time(s)"
  ! run remains "$password" || fail "$backend: $context: nothing of the staged unlock remains"
  no_secrets_in "$tmp/provisioning/luks-rekey.state" "$tmp/log" "$tmp/output"
}

# Setup completed: the disk opens with the password the account got, and the
# provisioning state is gone.
assert_provisioned() {
  assert_finished "$@"
  [[ ! -e $tmp/provisioning/pending && ! -e $tmp/provisioning/luks-rekey.state ]] ||
    fail "$backend: $1: setup drops pending and the journal together"
}

backends=(fake)
if command -v cryptsetup >/dev/null; then
  backends+=(luks2 luks1)
else
  skip "cryptsetup is not installed; skipping the file-backed volume runs"
fi

# The crash matrix runs whole setup attempts on every backend.
for backend in "${backends[@]}"; do
  format=$backend
  [[ $backend == "fake" ]] && format=luks2

  fixture "$format"
  run attempt "$owner_password" || fail "$backend: uninterrupted setup completes" "$(cat "$tmp/log" "$tmp/output")"
  assert_provisioned "uninterrupted" "$owner_password"
  total_steps=$(cat "$tmp/steps")
  (( total_steps >= 7 )) || fail "$backend: every durable step is a crash point" "$(cat "$tmp/trace")"
  pass "$backend: uninterrupted setup leaves only the owner's slot and destroys the staged key"

  # After each kill the owner reboots and answers the form again, with the same
  # password or a new one. The account takes whatever the form accepts, so the
  # disk must open with that password when setup finishes.
  for (( step = 1; step <= total_steps; step++ )); do
    for retry_password in "$owner_password" other-password; do
      fixture "$format"
      if run attempt "$owner_password" "$step"; then
        fail "$backend: setup is killed at step $step"
      fi
      point=$(sed -n "${step}p" "$tmp/trace")
      assert_recoverable "killed after '$point'" "$owner_password"
      [[ -e $tmp/provisioning/pending ]] || fail "$backend: killed after '$point', setup runs again"
      staged_alive=$([[ -n $(opens "$staged_key") ]] && echo 1 || echo 0)

      if run accepts "$retry_password"; then
        [[ $retry_password == "$owner_password" ]] || (( staged_alive )) ||
          fail "$backend: after '$point' a new password is refused once the staged key is retired"
        run attempt "$retry_password" || fail "$backend: after '$point' setup completes" "$(cat "$tmp/log")"
        if [[ $retry_password == "$owner_password" ]]; then
          assert_provisioned "rerun after '$point'" "$retry_password"
          if head -n "$step" "$tmp/trace" | grep -q 'journal phase boot'; then
            [[ $(wc -l <"$tmp/rebuilds") == "1" ]] || fail "$backend: rerun after '$point' does not rebuild boot again"
          fi
        else
          assert_provisioned "new password after '$point'" "$retry_password" 2
          [[ -z $(opens "$owner_password") ]] || fail "$backend: after '$point' the abandoned password is retired"
        fi
      else
        [[ $retry_password != "$owner_password" ]] || fail "$backend: after '$point' the original password is always accepted"
        (( ! staged_alive )) || fail "$backend: after '$point' a new password is accepted while the staged key works"
        if run attempt "$retry_password"; then fail "$backend: after '$point' setup refuses a new password"; fi
        assert_recoverable "refused new password after '$point'" "$owner_password"
        [[ -e $tmp/provisioning/pending ]] || fail "$backend: after '$point' a refused password keeps setup pending"
        run attempt "$owner_password" || fail "$backend: after '$point' the original password completes" "$(cat "$tmp/log")"
        assert_provisioned "original password after '$point'" "$owner_password"
      fi
    done
  done
  pass "$backend: killed after each of $total_steps steps, setup resumes to a disk that opens with the account's password"
done

backend=fake

fixture
touch "$tmp/rebuild-fail"
if run rekey "$owner_password"; then fail "a failed boot rebuild fails the attempt"; fi
unlock_files_present || fail "a failed boot rebuild restores the auto-unlock"
[[ $(cat "$tmp/etc/omarchy/provisioning.key") == "$staged_key" ]] || fail "the restored keyfile is the staged key"
grep -qF /etc/omarchy/provisioning.key "$tmp/etc/crypttab" || fail "a failed boot rebuild puts the staged crypttab back"
[[ -n $(opens "$staged_key") && -n $(opens "$seller_key") ]] || fail "a failed boot rebuild retires no slot"
rm "$tmp/rebuild-fail"
run rekey "$owner_password" || fail "the retry after a failed rebuild completes" "$(cat "$tmp/log")"
assert_finished "retry after a failed rebuild" "$owner_password"
pass "a failed boot rebuild keeps the unattended unlock and every slot for the retry"

fixture
printf '2 %s\n' tpm-sealed-key >>"$tmp/slots"
echo 2 >"$tmp/token-slot"
run provision "$owner_password" || fail "setup completes beside an enrolled token" "$(cat "$tmp/log")"
assert_provisioned "beside the previous owner's token" "$owner_password"
pass "a token the previous owner enrolled never answers for a key and is retired with its slot"

if [[ " ${backends[*]} " == *" luks2 "* ]]; then
  backend=luks2
  fixture luks2
  if enroll_tokens 1 "$seller_key"; then
    run provision "$owner_password" || fail "luks2: setup completes beside live tokens" "$(cat "$tmp/log" "$tmp/output")"
    assert_provisioned "beside the previous owner's live tokens" "$owner_password"
    pass "luks2: with a live keyring token and a TPM2 token on the previous owner's slot, only real keys count"
  else
    skip "the kernel keyring is out of reach; skipping the live token run"
  fi
  backend=fake
fi

fixture
touch "$tmp/kill-noop"
if run rekey "$owner_password"; then fail "a slot kill that changes nothing fails the re-key"; fi
[[ -f $tmp/provisioning/luks-key && -f $tmp/provisioning/luks-rekey.state ]] || fail "an unverified retirement keeps the staged key and journal"
rm "$tmp/kill-noop"
run rekey "$owner_password" || fail "the retry after an ineffective slot kill completes" "$(cat "$tmp/log")"
assert_finished "retry after an ineffective slot kill" "$owner_password"
pass "the staged key is destroyed only after the volume proves it no longer opens"

fixture
printf '0 %s\n1 %s\n2 %s\n' "$staged_key" "$seller_key" "$owner_password" >"$tmp/slots"
printf 'staged_slot=0\nowner_slot=2\nphase=boot\n' >"$tmp/provisioning/luks-rekey.state"
run rekey "$owner_password" || fail "a leftover auto-unlock after the boot step is removed" "$(cat "$tmp/log")"
assert_finished "leftover auto-unlock after the boot step" "$owner_password"
[[ $(wc -l <"$tmp/rebuilds") == "1" ]] || fail "the leftover auto-unlock triggers a boot rebuild"
pass "an auto-unlock that outlives the boot step is rebuilt away rather than blocking forever"

# The boot files ask for the disk password in the layout /etc/default/keyboard held
# when they were built. A retry after the owner picked another layout rebuilds
# them once, at the boot step and after done; the same layout rebuilds nothing,
# and a journal from before the fingerprint rebuilds once.
choose_layout() {
  mkdir -p "$tmp/etc/default"
  printf 'XKBMODEL="pc105"\nXKBLAYOUT="%s"\nXKBVARIANT=""\nXKBOPTIONS=""\n' "$1" >"$tmp/etc/default/keyboard"
}

rebuild_count() {
  wc -l <"$tmp/rebuilds" 2>/dev/null || echo 0
}

assert_fingerprint() {
  local context=$1 journal=$tmp/provisioning/luks-rekey.state
  grep -Eqx 'boot_layout=[0-9a-f]{64}' "$journal" || fail "$context: the journal records the layout as a hash" "$(cat "$journal")"
  ! grep -Eqw 'dk|us' "$journal" "$tmp/log" "$tmp/trace" || fail "$context: the journal and log never name the layout"
}

boot_layout_runs() {
  local name=$1 stop step refresh before

  fixture
  choose_layout us
  run rekey "$owner_password" || fail "$name: the re-key completes with a layout" "$(cat "$tmp/log")"
  assert_fingerprint "$name: uninterrupted"
  cp "$tmp/trace" "$tmp/layout-trace"

  for stop in boot done; do
    step=$(grep -m1 "^[0-9]* journal phase $stop" "$tmp/layout-trace" | cut -d' ' -f1)
    [[ -n $step ]] || fail "$name: the trace names the $stop journal write" "$(cat "$tmp/layout-trace")"

    fixture
    choose_layout us
    if run rekey "$owner_password" "$step"; then fail "$name: the re-key is killed after the $stop journal write"; fi
    [[ $(rebuild_count) == 1 ]] || fail "$name: killed at $stop after one rebuild"
    run rekey "$owner_password" || fail "$name: the same layout completes after $stop" "$(cat "$tmp/log")"
    [[ $(rebuild_count) == 1 ]] || fail "$name: an unchanged layout after $stop rebuilds nothing"
    assert_finished "$name: unchanged layout after $stop" "$owner_password"

    # The owner picks another layout on the retry right after the interruption.
    fixture
    choose_layout us
    if run rekey "$owner_password" "$step"; then fail "$name: the re-key is killed after the $stop journal write"; fi
    before=$(grep -m1 '^boot_layout=' "$tmp/provisioning/luks-rekey.state")
    choose_layout dk
    run rekey "$owner_password" || fail "$name: a changed layout after $stop completes" "$(cat "$tmp/log")"
    [[ $(rebuild_count) == 2 ]] || fail "$name: a changed layout after $stop rebuilds the boot files"
    [[ $(grep -m1 '^boot_layout=' "$tmp/provisioning/luks-rekey.state") != "$before" ]] ||
      fail "$name: the journal takes the new layout's fingerprint after $stop"
    [[ $(grep -c '^[0-9]* journal boot_layout ' "$tmp/trace") == 1 && $(grep -c "^[0-9]* journal phase $stop" "$tmp/trace") == 1 ]] ||
      fail "$name: the rebuild after $stop records only the fingerprint, keeping the phase" "$(cat "$tmp/trace")"
    refresh=$(awk -v s="$step" '$1 > s && / boot rebuilt$/ { print $1; exit }' "$tmp/trace")
    run rekey "$owner_password" || fail "$name: a rerun after the rebuild completes" "$(cat "$tmp/log")"
    [[ $(rebuild_count) == 2 ]] || fail "$name: the changed layout after $stop rebuilds only once"
    assert_finished "$name: changed layout after $stop" "$owner_password"
    assert_fingerprint "$name: changed layout after $stop"

    # Killed between that rebuild and its fingerprint: the retry rebuilds again.
    fixture
    choose_layout us
    if run rekey "$owner_password" "$step"; then fail "$name: the re-key is killed after the $stop journal write"; fi
    choose_layout dk
    if run rekey "$owner_password" "$refresh"; then fail "$name: the re-key is killed after the layout rebuild at $stop"; fi
    [[ $(grep -m1 '^boot_layout=' "$tmp/provisioning/luks-rekey.state") == "$before" ]] ||
      fail "$name: a layout rebuild killed before its journal write keeps the old fingerprint"
    run rekey "$owner_password" || fail "$name: the retry after a killed layout rebuild at $stop completes" "$(cat "$tmp/log")"
    [[ $(rebuild_count) == 3 ]] || fail "$name: a layout rebuild killed at $stop runs again"
    assert_finished "$name: killed layout rebuild at $stop" "$owner_password"
    assert_fingerprint "$name: killed layout rebuild at $stop"
  done

  # Interrupted at the boot step, the owner picks another layout and a new
  # password while the staged key still opens the disk.
  step=$(grep -m1 "^[0-9]* journal phase boot" "$tmp/layout-trace" | cut -d' ' -f1)
  fixture
  choose_layout us
  if run rekey "$owner_password" "$step"; then fail "$name: the re-key is killed after the boot journal write"; fi
  choose_layout dk
  run rekey other-password || fail "$name: a new layout and password after the boot step complete" "$(cat "$tmp/log")"
  [[ $(rebuild_count) == 2 ]] || fail "$name: a new layout and password after the boot step rebuild once"
  assert_finished "$name: new layout and password after the boot step" other-password 2
  assert_fingerprint "$name: new layout and password after the boot step"

  # A journal from before the fingerprint, at the boot step with the auto-unlock
  # already gone and after done: rebuilt once, then recorded.
  for stop in boot done; do
    fixture
    choose_layout dk
    run rekey "$owner_password" || fail "$name: the re-key completes" "$(cat "$tmp/log")"
    step=$(grep -m1 -n "^[0-9]* journal phase $stop" "$tmp/trace" | cut -d: -f1)

    fixture
    choose_layout dk
    if run rekey "$owner_password" "$step"; then fail "$name: the re-key is killed after the $stop journal write"; fi
    sed -i '/^boot_layout=/d' "$tmp/provisioning/luks-rekey.state"
    rm -f "$tmp/rebuilds"
    run rekey "$owner_password" || fail "$name: an older journal at $stop completes" "$(cat "$tmp/log")"
    [[ $(rebuild_count) == 1 ]] || fail "$name: an older journal at $stop rebuilds the boot files once"
    run rekey "$owner_password" || fail "$name: a rerun of an older journal at $stop completes" "$(cat "$tmp/log")"
    [[ $(rebuild_count) == 1 ]] || fail "$name: an older journal at $stop rebuilds only once"
    assert_finished "$name: older journal at $stop" "$owner_password"
    assert_fingerprint "$name: older journal at $stop"
  done

  # After done a failed rebuild keeps the old fingerprint, so the retry rebuilds.
  fixture
  choose_layout us
  run rekey "$owner_password" || fail "$name: the re-key completes" "$(cat "$tmp/log")"
  before=$(grep -m1 '^boot_layout=' "$tmp/provisioning/luks-rekey.state")
  choose_layout dk
  touch "$tmp/rebuild-fail"
  if run rekey "$owner_password"; then fail "$name: a failed layout rebuild after done fails the attempt"; fi
  [[ $(grep -m1 '^boot_layout=' "$tmp/provisioning/luks-rekey.state") == "$before" ]] ||
    fail "$name: a failed layout rebuild keeps the old fingerprint"
  rm "$tmp/rebuild-fail"
  run rekey "$owner_password" || fail "$name: the retry after a failed layout rebuild completes" "$(cat "$tmp/log")"
  assert_finished "$name: retry after a failed layout rebuild" "$owner_password"
  assert_fingerprint "$name: retry after a failed layout rebuild"
}

boot_layout_runs layout
pass "a changed keyboard layout rebuilds the boot files once, an unchanged one never, and an older journal once"

fixture
printf 'wrong-key' >"$tmp/provisioning/luks-key"
if run rekey "$owner_password"; then fail "a staged key that opens nothing fails the re-key"; fi
[[ ! -e $tmp/provisioning/luks-rekey.state && $(slot_count) == "2" ]] || fail "a dead staged key changes nothing"
pass "a fresh re-key refuses a staged key that no longer unlocks the volume"

fixture
rm "$tmp/provisioning/luks-key"
run remains "$owner_password" || fail "a leftover auto-unlock counts as the staged unlock remaining"
if run rekey "$owner_password"; then fail "a leftover auto-unlock without its staged key fails closed"; fi
unlock_files_present || fail "the leftover auto-unlock is not silently accepted"
pass "a boot-time auto-unlock without its staged key keeps provisioning from finishing"

fixture
if run rekey "$staged_key"; then fail "the staged key is refused as the owner's password"; fi
[[ $(slot_count) == "2" ]] && unlock_files_present || fail "refusing the staged key as a password changes nothing"
run rekey "$owner_password" || fail "a retry with a real password completes" "$(cat "$tmp/log")"
assert_finished "retry after refusing the staged key" "$owner_password"
pass "the owner's password must differ from the staged install key"

fixture
printf 'phase=owner\nstaged_slot=0\nowner_slot=2\nrecovery_slot=5\n' >"$tmp/provisioning/luks-rekey.state"
chmod 600 "$tmp/provisioning/luks-rekey.state"
(
  source "$ROOT/install/provisioning/luks-rekey.sh"
  REKEY_STATE=$tmp/provisioning/luks-rekey.state
  rekey_state_put phase boot
)
[[ $(grep -c . "$tmp/provisioning/luks-rekey.state") == "4" ]] && grep -qx 'phase=boot' "$tmp/provisioning/luks-rekey.state" &&
  grep -qx 'recovery_slot=5' "$tmp/provisioning/luks-rekey.state" || fail "a journal write keeps every other recorded key" "$(cat "$tmp/provisioning/luks-rekey.state")"
pass "journal writes replace only their own keys"

fixture
rm "$tmp/provisioning/luks-key"
if run provision "$owner_password"; then fail "provisioning with a leftover auto-unlock and no staged key fails"; fi
[[ -e $tmp/provisioning/pending ]] && unlock_files_present || fail "provisioning keeps its state while the auto-unlock remains"
pass "first-boot provisioning never finishes with the boot-time auto-unlock still configured"

fixture
rm -rf "$tmp/provisioning/luks-key" "$tmp/etc"
run provision "$owner_password" || fail "unencrypted provisioning finishes" "$(cat "$tmp/log" "$tmp/output")"
[[ ! -e $tmp/provisioning/pending && ! -e $tmp/provisioning/luks-rekey.state && $(slot_count) == "2" ]] ||
  fail "unencrypted provisioning skips the re-key"
pass "provisioning without a staged key or auto-unlock skips the re-key"

# Any slot but the owner's is retired, a recovery key an earlier setup added
# and recorded in the journal included.
backend=fake
fixture
printf '2 recovery-key\n' >>"$tmp/slots"
printf 'recovery_slot=2\nrecovery_shown=1\n' >"$tmp/provisioning/luks-rekey.state"
chmod 600 "$tmp/provisioning/luks-rekey.state"
run rekey "$owner_password" || fail "the re-key beside an earlier recovery slot completes" "$(cat "$tmp/log")"
[[ -z $(opens "$staged_key") && -z $(opens "$seller_key") && -z $(opens recovery-key) && -n $(opens "$owner_password") && $(slot_count) == 1 ]] ||
  fail "every slot but the owner's is retired" "$(cat "$tmp/slots")"
pass "the re-key retires every slot but the owner's, an earlier recovery slot included"
