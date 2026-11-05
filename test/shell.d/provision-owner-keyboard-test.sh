#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# First-boot setup's keyboard step. The owner types the disk password at boot in
# the layout /etc/default/keyboard names, so a layout that did not persist or
# does not read back must be asked for again before the password form.
# keyboard_form and apply_keyboard run as omarchy-provision-owner defines them,
# against a fixture root.

tmp=$(cd -- "$(mktemp -d)" && pwd -P)
trap 'chmod -R u+rwX "$tmp"; rm -rf "$tmp"' EXIT

root=$tmp/root
stub_bin=$tmp/bin
conf=$root/etc/default/keyboard
mkdir -p "$stub_bin"

# Takes its next answer from a queue file, and says "normal" once it is empty.
cat >"$stub_bin/next-mode" <<'SH'
#!/bin/bash
queue=$1
[[ -s $queue ]] || { echo normal; exit 0; }
head -n1 "$queue"
sed -i 1d "$queue"
SH
chmod +x "$stub_bin"/*
export PATH="$stub_bin:$PATH"

{
  sed -n '/^KEYBOARD_FILE=/p; /^keyboard_form() {/,/^}/p; /^apply_keyboard() {/,/^}/p' "$ROOT/bin/omarchy-provision-owner"
  sed -n '/^omarchy_persist_input_selection() {/,/^}/p' "$ROOT/install/provisioning/setup-form.sh"
} | sed "s|/etc/|$root/etc/|g" >"$tmp/keyboard.sh"
grep -q '^keyboard_form() {' "$tmp/keyboard.sh" && grep -q '^apply_keyboard() {' "$tmp/keyboard.sh" ||
  fail "omarchy-provision-owner defines the keyboard step"

# The owner's answers, one "label|layout" per prompt. Running out means the step
# asked once more than the test answered.
cat >"$tmp/form.sh" <<SH
set -euo pipefail
source "$tmp/keyboard.sh"
LOG_FILE=$tmp/log
OMARCHY_FORM_BACK=2
step() { echo "prompt" >>"$tmp/screen"; }
notice() { echo "notice: \$1" >>"$tmp/screen"; }
log_step() { echo "\$1" >>"\$LOG_FILE"; }
confirm_reboot() { exit 5; }
omarchy_prompt_keyboard() {
  local answer
  answer=\$("$stub_bin/next-mode" "$tmp/answers")
  [[ \$answer != normal ]] || { echo "asked again" >>"$tmp/screen"; exit 9; }
  keyboard_label=\${answer%%|*}
  keyboard=\${answer#*|}
}
keyboard_form
echo "password form" >>"$tmp/screen"
SH

# A fresh deferred install: the placeholder US layout from the image build.
fresh_root() {
  chmod -R u+rwX "$root" 2>/dev/null || true
  rm -rf "$root" "$tmp/answers" "$tmp/screen" "$tmp/log"
  mkdir -p "$root/etc/default"
  printf 'XKBMODEL="pc105"\nXKBLAYOUT="us"\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n' >"$conf"
  : >"$tmp/log"
}

answers() {
  printf '%s\n' "$@" >"$tmp/answers"
}

form() {
  local status=0
  bash "$tmp/form.sh" || status=$?
  return "$status"
}

prompts() {
  grep -cx prompt "$tmp/screen" || true
}

assert_layout() {
  grep -qx "XKBLAYOUT=\"$1\"" "$conf" && grep -qx "XKBVARIANT=\"${2:-}\"" "$conf" ||
    fail "/etc/default/keyboard holds $1 ${2:-}" "$(cat "$conf")"
}

# Asked once more after the failure, with the reason on the screen and in the
# log, and only the second answer reaches the password form.
assert_asked_again() {
  local context=$1 log_line=$2
  [[ $(prompts) == 2 ]] || fail "$context: the keyboard is asked for again" "$(cat "$tmp/screen")"
  [[ $(sed -n 2p "$tmp/screen") == "notice: Could not set the Danish keyboard layout. Choose it again." ]] ||
    fail "$context: the owner is told the layout did not take" "$(cat "$tmp/screen")"
  [[ $(tail -n1 "$tmp/screen") == "password form" && $(grep -c 'password form' "$tmp/screen") == 1 ]] ||
    fail "$context: the password form comes only after a layout took" "$(cat "$tmp/screen")"
  grep -q "$log_line" "$tmp/log" || fail "$context: the log records the failure" "$(cat "$tmp/log")"
}

fresh_root
answers 'Danish|dk'
form || fail "a known layout is set" "$(cat "$tmp/screen" "$tmp/log")"
[[ $(prompts) == 1 ]] && ! grep -q '^notice' "$tmp/screen" || fail "a layout that takes is asked for once" "$(cat "$tmp/screen")"
assert_layout dk
grep -qx 'XKBOPTIONS=""' "$conf" && grep -qx 'XKBMODEL="pc105"' "$conf" || fail "the installer's model and options stay" "$(cat "$conf")"
[[ $(<"$root/etc/omarchy/input-method") == $'INPUT_METHOD=none\nXKB_LAYOUT=' ]] ||
  fail "a known layout records no input method" "$(cat "$root/etc/omarchy/input-method" 2>&1)"
pass "a layout that persists and reads back goes straight to the password form"

fresh_root
answers 'English (US, Colemak)|us:colemak'
form || fail "Colemak is set" "$(cat "$tmp/screen" "$tmp/log")"
assert_layout us colemak
answers 'Danish|dk'
form || fail "a layout after a variant is set" "$(cat "$tmp/screen" "$tmp/log")"
assert_layout dk
pass "a layout's variant reaches the file, and the next layout clears it"

# Every layout the form offers has to name an XKB layout, the field apply_keyboard takes.
source "$ROOT/install/provisioning/setup-form.sh"
while IFS='|' read -r label layout _; do
  [[ $layout =~ ^[a-z]+(:[A-Za-z0-9_-]+)?$ ]] || fail "the $label layout ($layout) is an XKB layout with an optional variant"
done <<<"$OMARCHY_KEYBOARD_LAYOUTS"
pass "every layout the form offers has the shape apply_keyboard takes"

# A later line of the file that sed does not rewrite stands for a layout that does not read back.
fresh_root
answers 'Danish|dk'
echo ' XKBLAYOUT=zz' >>"$conf"
answers 'Danish|dk' 'Danish|dk'
cat >"$stub_bin/fix-conf" <<SH
#!/bin/bash
sed -i '/^ XKBLAYOUT=zz/d' "$conf" 2>/dev/null || true
SH
chmod +x "$stub_bin/fix-conf"
sed -i 's|^notice() {.*|notice() { echo "notice: $1" >>"'"$tmp"'/screen"; fix-conf; }|' "$tmp/form.sh"
form || fail "a readback mismatch, then the retry" "$(cat "$tmp/screen" "$tmp/log")"
assert_asked_again "readback mismatch" "does not read back as keyboard layout dk"
assert_layout dk
pass "a file that reads back another layout is asked for again"

# The readback runs in a clean shell: values this process exports never stand
# in for the file.
fresh_root
echo ' XKBLAYOUT=${EXPORTED_LAYOUT:-zz}' >>"$conf"
answers 'Danish|dk' 'Danish|dk'
sed -i "s|^sed -i '/^ XKBLAYOUT=zz/d'|sed -i '/^ XKBLAYOUT=/d'|" "$stub_bin/fix-conf"
EXPORTED_LAYOUT=dk form || fail "an exported layout, then the retry" "$(cat "$tmp/screen" "$tmp/log")"
assert_asked_again "exported layout" "does not read back as keyboard layout dk"
pass "the readback ignores values in the environment"

# A machine that can't set any layout must not keep the owner at the keyboard
# step: after three failures in a row the attempt fails, and setup's own
# retry-or-console screen takes over. A read-only directory stops sed -i.
if (( EUID != 0 )); then
  fresh_root
  answers 'Danish|dk' 'German|de' 'Danish|dk' 'Danish|dk'
  chmod 555 "$root/etc/default"
  status=0
  form || status=$?
  chmod 755 "$root/etc/default"
  (( status == 1 )) || fail "a layout that can never be set fails the attempt" "status $status: $(cat "$tmp/screen")"
  [[ $(prompts) == 3 ]] && [[ $(tail -n1 "$tmp/screen") == "notice: Setup could not set a keyboard layout on this machine." ]] ||
    fail "the keyboard step gives up after three failures, and says so" "$(cat "$tmp/screen")"
  ! grep -q 'password form' "$tmp/screen" || fail "a layout that can never be set never reaches the password form" "$(cat "$tmp/screen")"
  grep -q 'no keyboard layout could be set after 3 attempts' "$tmp/log" || fail "the log records giving up" "$(cat "$tmp/log")"
  grep -qx 'XKBLAYOUT="us"' "$conf" || fail "the install's layout is left alone" "$(cat "$conf")"
fi
sed -n '/^run_setup() {/,/^}/p' "$ROOT/bin/omarchy-provision-owner" | grep -qx '    keyboard_form || return 1' ||
  fail "a failed keyboard step fails the setup attempt, which offers retry or a console"
pass "a machine that can't set any layout fails the attempt after three tries, reaching setup's retry-or-console screen"

# First-boot setup's progress screen, which the ISO install dashboard draws too:
# install/provisioning/progress-icon.sh. It runs in a subshell so its globals and
# stubs stay out of the keyboard tests.
(
  # shellcheck disable=SC1091
  source "$ROOT/install/provisioning/progress-icon.sh"

  # The Linux VT draws a bright background (SGR 100-107) as the normal one
  # (40-47), so a frame must never ask for one: the grey half of a cell under
  # the green tip would vanish. Trace every step at every size the screen draws.
  for scale in 1 2 3; do
    progress_icon_build "$scale"
    for ((pm = 1; pm <= 1000; pm++)); do
      progress_icon_render "$pm"
    done >"$tmp/trace"
    ! grep -qaE $'\033\\[[0-9]+;10[0-7]m' "$tmp/trace" ||
      fail "the icon at scale $scale never asks for a bright background" "$(grep -aoE $'\033\\[[0-9]+;10[0-7]m.' "$tmp/trace" | sort -u | cat -v)"
  done
  pass "the traced icon never asks the VT for a bright background"

  # The icon is sized to the console font's real cell, which first boot can set
  # to sun12x22. Every grid column must still get the same whole number of
  # screen columns, or the icon loses its right edge or draws some strokes half
  # as wide. Its second grid row is two strokes one grid column wide.
  for cell in "8 16" "12 22" "9 19" "16 32"; do
    read -r CELL_WIDTH CELL_HEIGHT <<<"$cell"
    for scale in 1 2 3; do
      progress_icon_build "$scale"
      row=""
      for ((x = 0; x < ICON_WIDTH; x++)); do
        row+=${ICON_FILL[scale * ICON_WIDTH + x]}
      done
      read -ra strokes <<<"${row//0/ }"
      (( ${#strokes[@]} == 2 )) && [[ ${strokes[0]} == "${strokes[1]}" ]] ||
        fail "a ${cell/ /x} font at scale $scale draws both strokes of the icon's second row, equally wide" "$row"
    done
  done
  pass "every console font draws the whole icon with equally wide strokes"

  # Setup draws ten frames a second while it works the disk, so a frame must not
  # start processes: only every fifth reads the console size, and none runs sed.
  stty() { echo stty >>"$tmp/started"; echo "40 120"; }
  sed() { echo sed >>"$tmp/started"; command sed "$@"; }
  progress_icon_cell_size() { echo "8 16"; }
  progress_icon_layout /dev/null 78
  : >"$tmp/started"
  for ((frame = 1; frame <= 10; frame++)); do
    progress_icon_frame "$((frame * 50))" "Setting up your machine" "Tip: one of the tips"
  done >/dev/null
  ! grep -q '^sed$' "$tmp/started" && (( $(grep -c '^stty$' "$tmp/started") <= 2 )) ||
    fail "ten frames read the console size at most twice and run no sed" "$(sort "$tmp/started" | uniq -c)"
  pass "a frame starts no process except the console size check on every fifth"
)
