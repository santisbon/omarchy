#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
export HOME="$test_tmp/home" XDG_CONFIG_HOME="$test_tmp/config" OMARCHY_PATH="$ROOT"
export DICTATION_LOG="$test_tmp/calls" DICTATION_INSTALLED="superwhisper"
mkdir -p "$test_tmp/bin" "$XDG_CONFIG_HOME/omarchy/defaults"
export PATH="$test_tmp/bin:$ROOT/bin:$PATH"
config="$XDG_CONFIG_HOME/omarchy/defaults/dictation"

cat > "$test_tmp/bin/omarchy-cmd-present" <<'SH'
#!/bin/bash
case "$1" in
  omarchy-dictation-*|omarchy-install-dictation-*) command -v "$1" >/dev/null ;;
  *) [[ " $DICTATION_INSTALLED " == *" $1 "* ]] ;;
esac
SH
cat > "$test_tmp/bin/omarchy-cmd-missing" <<'SH'
#!/bin/bash
! omarchy-cmd-present "$1"
SH
cat > "$test_tmp/bin/omarchy-launch-floating-terminal-with-presentation" <<'SH'
#!/bin/bash
printf '%s\n' "$*" > "$DICTATION_INSTALL_LOG"
SH
export DICTATION_INSTALL_LOG="$test_tmp/install"
for backend in superwhisper; do
  cat > "$test_tmp/bin/$backend" <<'SH'
#!/bin/bash
printf '%s %s\n' "${0##*/}" "$*" >> "$DICTATION_LOG"
if [[ -n ${FAIL_SETUP_STEP:-} && $* == "$FAIL_SETUP_STEP" ]]; then exit 7; fi
if [[ ${0##*/} == "superwhisper" && $1 == "shortcuts" && ${DICTATION_EXIT:-0} == 0 ]]; then
  if [[ $2 == "show" ]]; then
    cat "$SHORTCUT_STATE"
  elif [[ $2 == "set" ]]; then
    chord=$4
    [[ $chord != "none" ]] || chord=""
    updated=$(jq --arg action "$3" --arg chord "$chord" '.shortcuts[$action] = $chord' "$SHORTCUT_STATE")
    jq -e '.shortcuts | .hold != "RightAlt" and (.hold != "" or .toggle != "")' <<< "$updated" >/dev/null || exit 1
    printf '%s\n' "$updated" > "$SHORTCUT_STATE"
  fi
fi
exit "${DICTATION_EXIT:-0}"
SH
done
for command in omarchy-pkg-add omarchy-notification-send hyprctl omarchy-restart-hyprctl omarchy-restart-shell; do
  cat > "$test_tmp/bin/$command" <<'SH'
#!/bin/bash
printf '%s %s\n' "${0##*/}" "$*" >> "$DICTATION_LOG"
exit "${SETUP_EXIT:-0}"
SH
done
cat > "$test_tmp/bin/systemctl" <<'SH'
#!/bin/bash
if [[ $* == "--user is-active --quiet superwhisper.service" ]]; then
  [[ ${DICTATION_SERVICE_ACTIVE:-1} == 1 ]]
else
  printf '%s %s\n' "${0##*/}" "$*" >> "$DICTATION_LOG"
  exit "${SERVICE_EXIT:-0}"
fi
SH
cat > "$test_tmp/bin/omarchy-hw-vulkan" <<'SH'
#!/bin/bash
exit 1
SH
cat > "$test_tmp/bin/gum" <<'SH'
#!/bin/bash
exit "${CONFIRM_EXIT:-0}"
SH
cat > "$test_tmp/bin/bash" <<'SH'
#!/bin/bash
if [[ $1 == "/usr/share/superwhisper/setup-user" ]]; then
  printf '%s\n' setup-user >> "$DICTATION_LOG"
  exit "${SETUP_EXIT:-0}"
else
  exec /bin/bash "$@"
fi
SH
chmod +x "$test_tmp/bin/"*

if omarchy-dictation start 2> "$test_tmp/error"; then
  fail "unset backend must fail even when providers are installed"
fi
[[ ! -e $DICTATION_LOG ]] || fail "recording never configures or installs a backend"
pass "dictation requires explicit configuration"
omarchy-default-dictation superwhisper
[[ $(cat "$DICTATION_INSTALL_LOG") == "omarchy-install-dictation-superwhisper" ]] || fail "Defaults launches backend installer"
[[ ! -e $config ]] || fail "Defaults does not select before setup succeeds"
if omarchy-default-dictation unknown > "$test_tmp/output" 2>&1; then fail "missing installer must fail"; fi
if omarchy-default-dictation '../invalid' > "$test_tmp/output" 2>&1; then fail "invalid backend must fail"; fi
pass "Defaults delegates setup without prematurely selecting a backend"


printf '%s\n' superwhisper > "$config"
[[ $(omarchy-default-dictation) == "superwhisper" ]] || fail "configured backend is readable"
: > "$DICTATION_LOG"
for action in start stop toggle; do omarchy dictation "$action"; done
[[ $(cat "$DICTATION_LOG") == $'superwhisper start\nsuperwhisper stop\nsuperwhisper record' ]] || fail "adapter dispatches recording for superwhisper"
pass "built-in adapters implement start stop and toggle"

cat > "$test_tmp/bin/omarchy-dictation-future-backend" <<'SH'
#!/bin/bash
[[ ! -e /proc/$$/fd/9 ]] || exit 90
printf '%s\n' "$1" >> "$DICTATION_LOG"
exit "${DICTATION_EXIT:-0}"
SH
chmod +x "$test_tmp/bin/omarchy-dictation-future-backend"
cat > "$test_tmp/bin/omarchy-install-dictation-future-backend" <<'SH'
#!/bin/bash
exit 0
SH
chmod +x "$test_tmp/bin/omarchy-install-dictation-future-backend"
omarchy-default-dictation future-backend
[[ $(cat "$DICTATION_INSTALL_LOG") == "omarchy-install-dictation-future-backend" ]] || fail "third backend installer requires no selector changes"
printf '%s\n' future-backend > "$config"
: > "$DICTATION_LOG"
for action in start stop toggle; do omarchy-dictation "$action"; done
[[ $(cat "$DICTATION_LOG") == $'start\nstop\ntoggle' ]] || fail "third backend requires no dispatcher changes"
result=0
DICTATION_EXIT=7 omarchy-dictation start || result=$?
(( result == 7 )) || fail "backend failures propagate"
rm "$test_tmp/bin/omarchy-dictation-future-backend"
if omarchy-dictation start 2> "$test_tmp/error"; then fail "missing adapter must fail"; fi
printf '%s\n' '../invalid' > "$config"
if omarchy-dictation start 2> "$test_tmp/error"; then fail "invalid backend must fail"; fi
pass "external adapters follow the same protocol and errors propagate"

cat > "$test_tmp/bin/omarchy-dictation-other" <<'SH'
#!/bin/bash
printf 'other %s\n' "$*" >> "$DICTATION_LOG"
exit "${DICTATION_EXIT:-0}"
SH
chmod +x "$test_tmp/bin/omarchy-dictation-other"
printf '%s\n' other > "$config"
export SHORTCUT_STATE="$test_tmp/shortcuts.json"
printf '%s\n' '{"shortcuts":{"hold":"RightAlt","toggle":"","cancel":"Escape"}}' > "$SHORTCUT_STATE"
if SETUP_EXIT=1 omarchy-install-dictation-superwhisper > "$test_tmp/output" 2>&1; then fail "failed installation must fail"; fi
[[ $(cat "$config") == "other" ]] || fail "failed setup must preserve selection"
if DICTATION_EXIT=7 omarchy-install-dictation-superwhisper > "$test_tmp/output" 2>&1; then fail "failed shortcut setup must fail"; fi
[[ $(cat "$config") == "other" ]] || fail "failed shortcuts must preserve selection"
omarchy-install-dictation-superwhisper
[[ $(omarchy-default-dictation) == "superwhisper" ]] || fail "installer selects Superwhisper"
jq -e '.shortcuts | .hold == "" and .toggle == "Ctrl+Alt+Space"' "$SHORTCUT_STATE" >/dev/null || fail "installer repairs conflicting hold-only profiles"
printf '%s\n' '{"shortcuts":{"hold":"RightAlt","toggle":"RightSuper","cancel":"Escape"}}' > "$SHORTCUT_STATE"
omarchy-install-dictation-superwhisper
jq -e '.shortcuts | .hold == "" and .toggle == "Ctrl+Alt+Space"' "$SHORTCUT_STATE" >/dev/null || fail "installer repairs conflicting profiles with an existing toggle"
omarchy-install-dictation-superwhisper
pass "Superwhisper installer owns setup and saves selection only after success"

printf '%s\n' other > "$config"
CONFIRM_EXIT=1 omarchy-install-dictation-superwhisper
[[ $(cat "$config") == "other" ]] || fail "cancelled installation preserves selection"
pass "Superwhisper installer asks before downloading"

: > "$DICTATION_LOG"
if DICTATION_EXIT=7 omarchy-dictation-use superwhisper > "$test_tmp/output" 2>&1; then fail "failed stop must prevent switching"; fi
[[ $(cat "$config") == "other" ]] || fail "failed stop preserves selection"
omarchy-dictation-use superwhisper
[[ $(cat "$DICTATION_LOG") == $'other stop\nother stop' ]] || fail "switch stops the previous backend"
[[ $(cat "$config") == "superwhisper" ]] || fail "successful stop permits switching"
: > "$DICTATION_LOG"
omarchy-dictation-use superwhisper
[[ ! -s $DICTATION_LOG ]] || fail "reselecting does not interrupt recording"
DICTATION_SERVICE_ACTIVE=0 omarchy-dictation-use other
[[ $(cat "$config") == "other" ]] || fail "a stopped Superwhisper service permits switching"
printf '%s\n' removed-backend > "$config"
omarchy-dictation-use superwhisper
[[ $(cat "$config") == "superwhisper" ]] || fail "a removed adapter permits recovery"
pass "switching stops recordings, preserves failed stops, and recovers unavailable providers"

# Readers may run throughout a switch, but must never observe a truncated file.
(
  for ((i = 0; i < 200; i++)); do
    selection=$(cat "$config")
    [[ $selection == "other" || $selection == "superwhisper" ]] || exit 1
  done
) &
reader=$!
for ((i = 0; i < 20; i++)); do
  omarchy-dictation-use other
  omarchy-dictation-use superwhisper
done
wait "$reader" || fail "concurrent readers always see a complete selection"
printf '%s\n' other > "$config"
pass "selection updates are atomic for concurrent readers"

lua - <<'LUA' || fail "dictation shortcuts require a selection without limiting backend names"
local root = os.getenv("ROOT")
local selected, installed, bindings = nil, true, {}
io.popen = function(command)
  assert(command == "omarchy-default-dictation 2>/dev/null")
  return { read = function() return selected end, close = function() end }
end
o = {
  cmd_missing = function(command)
    assert(command == selected)
    return not installed
  end,
  bind = function(...) table.insert(bindings, {...}) end,
  bind_hold = function(keys, _, press, _, release)
    table.insert(bindings, { keys, false, press })
    table.insert(bindings, { keys, false, release })
  end,
}
dofile(root .. "/default/hypr/bindings/dictation.lua")
assert(#bindings == 0, "unconfigured dictation leaves application keys available")
selected = "some-backend"
dofile(root .. "/default/hypr/bindings/dictation.lua")
local function binds(keys, command)
  for _, binding in ipairs(bindings) do
    if binding[1] == keys and binding[3] == command then return true end
  end
end
assert(#bindings == 1, "any installed backend receives Alt + Space, and nothing else")
assert(binds("ALT + SPACE", "omarchy-dictation toggle"), "Alt + Space toggles dictation")
assert(o.dictation_installed(), "personal dictation keys see the installed backend")
bindings, installed = {}, false
dofile(root .. "/default/hypr/bindings/dictation.lua")
assert(#bindings == 0, "a selected backend that is not installed leaves application keys available")
assert(not o.dictation_installed(), "personal dictation keys release their keys once the backend is gone")
LUA
pass "Alt + Space toggles dictation once a backend is installed"

# Fresh users have no backend until they install Superwhisper from the menu.
[[ ! -e $ROOT/config/omarchy/defaults/dictation ]] || fail "fresh users start with no backend"
pass "fresh users start with no dictation backend"

lua - <<'LUA' || fail "desktop integration follows the selected backend without personal Hyprland config"
local root = os.getenv("ROOT")
package.path = root .. "/?.lua;" .. package.path
package.loaded["default.hypr.paths"] = { config_home = "/config" }
local selected, available, loaded = "superwhisper", true, {}
local missing = false
o = { cmd_missing = function() return missing end }
local real_open, real_popen, real_dofile = io.open, io.popen, dofile
io.popen = function(command)
  assert(command == "omarchy-default-dictation 2>/dev/null")
  return { read = function() return selected end, close = function() end }
end
io.open = function(path)
  assert(path == "/config/" .. selected .. "/shortcuts.lua")
  if available then return { close = function() end } end
end
dofile = function(path) table.insert(loaded, path) end
local function load_backend()
  package.loaded["default.hypr.dictation-backend"] = nil
  require("default.hypr.dictation-backend")
end
load_backend()
assert(loaded[1] == "/config/superwhisper/shortcuts.lua")
selected, available = "other", false
load_backend()
assert(#loaded == 1, "a backend with no integration should need no config")
selected, available = "future-backend", true
load_backend()
assert(loaded[2] == "/config/future-backend/shortcuts.lua", "integration must not be limited to named providers")
missing = true
load_backend()
assert(#loaded == 2, "an uninstalled backend must not load a stale bridge")
missing = false
dofile = function() error("broken generated bridge") end
load_backend()
assert(#loaded == 2, "a broken bridge must not abort the desktop configuration")
dofile = function(path) table.insert(loaded, path) end
selected = "../../outside"
load_backend()
assert(#loaded == 2, "a backend must not escape the config directory")
selected = nil
load_backend()
assert(#loaded == 2, "no installed backend must leave configuration usable")
io.open, io.popen, dofile = real_open, real_popen, real_dofile
LUA
pass "desktop integration follows the selected backend without personal Hyprland config"

cat > "$test_tmp/bin/systemctl" <<'SH'
#!/bin/bash
exit 0
SH
cat > "$test_tmp/bin/omarchy-pkg-drop" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >> "$DICTATION_LOG"
exit "${REMOVE_EXIT:-0}"
SH
chmod +x "$test_tmp/bin/systemctl" "$test_tmp/bin/omarchy-pkg-drop"
cat > "$test_tmp/bin/omarchy-shell" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >> "$DICTATION_LOG"
SH
chmod +x "$test_tmp/bin/omarchy-shell"
export XDG_DATA_HOME="$test_tmp/data"
mkdir -p "$HOME/.local/bin" "$XDG_DATA_HOME/superwhisper/app" "$XDG_DATA_HOME/superwhisper/models" "$XDG_CONFIG_HOME/omarchy/plugins" "$HOME/.agents/skills" "$HOME/.claude/skills"
ln -s /usr/bin/superwhisper "$HOME/.local/bin/superwhisper"
ln -s /opt/superwhisper "$XDG_DATA_HOME/superwhisper/app/current"
ln -s /opt/superwhisper/assets/omarchy-plugin/superwhisper-panel "$XDG_CONFIG_HOME/omarchy/plugins/superwhisper-panel"
ln -s /opt/superwhisper/assets/agent-skill/superwhisper "$HOME/.agents/skills/superwhisper"
ln -s /custom/skill "$HOME/.claude/skills/superwhisper"
printf '%s\n' retained > "$XDG_DATA_HOME/superwhisper/models/model"
printf '%s\n' superwhisper > "$config"
if REMOVE_EXIT=1 omarchy-remove-dictation-superwhisper > "$test_tmp/output" 2>&1; then
  fail "failed package removal must fail"
fi
[[ -L $HOME/.local/bin/superwhisper && $(cat "$config") == "superwhisper" ]] || fail "failed removal preserves selection and links"
omarchy-remove-dictation-superwhisper
[[ ! -e $config ]] || fail "Superwhisper removal clears its selection"
for link in "$HOME/.local/bin/superwhisper" "$XDG_DATA_HOME/superwhisper/app/current" "$XDG_CONFIG_HOME/omarchy/plugins/superwhisper-panel" "$HOME/.agents/skills/superwhisper"; do
  [[ ! -L $link ]] || fail "Superwhisper removal unlinks packaged integration"
done
[[ $(readlink "$HOME/.claude/skills/superwhisper") == "/custom/skill" ]] || fail "custom skills are preserved"
[[ -f $XDG_DATA_HOME/superwhisper/models/model ]] || fail "downloaded models are retained"
printf '%s\n' other > "$config"
omarchy-remove-dictation-superwhisper
[[ $(cat "$config") == "other" ]] || fail "removing Superwhisper preserves another selected backend"
pass "Superwhisper removal clears its selection and owned links while preserving user data and other backends"
