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

# A stand-in for fzf that answers each list from $work/answers, one line per list: the first
# tab-separated field of the line to choose ("-" for an empty field), or ESC.
cat >"$work/bin/fzf" <<'EOF'
#!/bin/bash
answer=$(head -n 1 "$ANSWERS"); sed -i 1d "$ANSWERS"
[[ $answer == "ESC" || -z $answer ]] && exit 130
[[ $answer == "-" ]] && answer=""
awk -F'\t' -v answer="$answer" '$1 == answer { print; found = 1; exit } END { exit !found }'
EOF
printf '#!/bin/bash\necho "done prompt" >>"$TEST_LOG"\n' >"$work/bin/omarchy-show-done"
chmod +x "$work/bin/fzf" "$work/bin/omarchy-show-done"
export ANSWERS="$work/answers"

# Runs the picker with the answers given, one per list it shows.
pick_keyboard() {
  printf '%s\n' "$@" >"$ANSWERS"
  setup_keyboard >/dev/null
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

setup_keyboard us
pick_keyboard add es deadtilde grp:ctrls_toggle ESC
grep -qx 'XKBLAYOUT="us,es"' "$gui" && grep -qx 'XKBVARIANT=",deadtilde"' "$gui" && grep -qx 'XKBOPTIONS="grp:ctrls_toggle"' "$gui" ||
  fail "adding a layout keeps the layouts already there, first among them" "$(cat "$gui")"
[[ $(grep -c 'done prompt' "$TEST_LOG") == 1 ]] || fail "the picker asks for one key press when done" "$(cat "$TEST_LOG")"
pass "adding a layout keeps the layouts already there, and the picker asks for one key press when done"

pick_keyboard add fr - ESC
grep -qx 'XKBLAYOUT="us,es,fr"' "$gui" && grep -qx 'XKBOPTIONS="grp:ctrls_toggle"' "$gui" ||
  fail "a third layout keeps the switching key, without asking again" "$(cat "$gui")"
pass "a third layout keeps the switching key, without asking again"

pick_keyboard main 2 ESC
grep -qx 'XKBLAYOUT="fr,us,es"' "$gui" && grep -qx 'XKBVARIANT=",,deadtilde"' "$gui" ||
  fail "Change the main layout moves the chosen layout and its variant first" "$(cat "$gui")"
pass "Change the main layout moves the chosen layout and its variant first"

pick_keyboard remove 0 remove 1 ESC
grep -qx 'XKBLAYOUT="us"' "$gui" && grep -qx 'XKBVARIANT=""' "$gui" && grep -qx 'XKBOPTIONS=""' "$gui" ||
  fail "removing down to one layout drops the switching key" "$(cat "$gui")"
pass "removing down to one layout drops the switching key"

pick_keyboard add de ESC ESC
grep -qx 'XKBLAYOUT="us"' "$gui" || fail "Esc at the variant list cancels the add" "$(cat "$gui")"
pass "Esc at the variant list cancels the add"

pick_keyboard add us - ESC
[[ $(grep -c 'XKBLAYOUT=' "$gui") == 1 ]] && grep -qx 'XKBLAYOUT="us"' "$gui" ||
  fail "a layout already in the list is not added twice" "$(cat "$gui")"
! grep -q 'done prompt' "$TEST_LOG" || fail "nothing changed, so no key press is asked for"
pass "a layout already in the list is not added twice, and nothing changed asks for no key press"

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
grep -q '"setup.keyboard":.*"action":"xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-setup-keyboard"' "$menu" ||
  fail "Setup > Keyboard opens the layout picker"
grep -q '"setup.displays":.*"label":"Arrange Monitors","action":"omarchy-launch-monitors"' "$menu" ||
  fail "Setup > Arrange Monitors starts nwg-displays"
pass "Setup > Keyboard and Setup > Arrange Monitors"
