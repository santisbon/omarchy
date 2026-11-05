#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

require_command lua

# $1 is /etc/default/keyboard, where Ubuntu keeps the layout (the installer through
# localectl, and the factory reset's first-boot form), and $2 is /etc/vconsole.conf.
resolved_input() {
  OMARCHY_PATH="$ROOT" OMARCHY_DEFAULT_KEYBOARD="${1-}" OMARCHY_VCONSOLE="${2-}" lua - <<'LUA'
package.path = os.getenv("OMARCHY_PATH") .. "/?.lua;" .. package.path

local default_keyboard = os.getenv("OMARCHY_DEFAULT_KEYBOARD")
local vconsole = os.getenv("OMARCHY_VCONSOLE")
local real_open = io.open

io.open = function(path, mode)
  if path:match("/omarchy/keyboard%-layouts$") then
    local selected = os.getenv("TEST_KEYBOARD_SELECTION")
    if not selected then return nil end
    local file = io.tmpfile()
    file:write(selected)
    file:seek("set")
    return file
  end

  if path == "/etc/omarchy/input-method" then
    local preference = os.getenv("TEST_INPUT_PREFERENCE")
    if not preference then return nil end
    local file = io.tmpfile()
    file:write(preference)
    file:seek("set")
    return file
  end

  local content
  if path == "/etc/default/keyboard" then
    content = default_keyboard
  elseif path == "/etc/vconsole.conf" then
    content = vconsole
  else
    return real_open(path, mode)
  end

  -- An unset variable reaches Lua as "", never nil, so the cases that ask for
  -- a missing file need the empty string to fail the open.
  if not content or content == "" then
    return nil
  end

  local file = io.tmpfile()
  file:write(content)
  file:seek("set")
  return file
end

hl = {
  config = function(config)
    local input = config.input
    print(("[%s] [%s] [%s]"):format(input.kb_layout, input.kb_variant, input.kb_options))
  end,
}

o = { window = function() end }

require("default.hypr.input")
LUA
}

assert_input() {
  local description="$1"
  local expected="$2"
  local actual

  if (( $# > 3 )); then
    actual=$(resolved_input "$3" "$4") || fail "$description" "$actual"
  elif (( $# > 2 )); then
    actual=$(resolved_input "$3") || fail "$description" "$actual"
  else
    actual=$(resolved_input) || fail "$description" "$actual"
  fi

  [[ $actual == "$expected" ]] ||
    fail "$description" "expected: $expected"$'\n'"actual:   $actual"
  pass "$description"
}

# No Shift + Caps Lock compose: the options are only what the installer wrote.
base_options=""
toggle_options="grp:alts_toggle"

assert_input "missing /etc/default/keyboard falls back to us" "[us] [] [$base_options]"
assert_input "Ubuntu's quoted /etc/default/keyboard values are read" "[de] [nodeadkeys] [$base_options]" 'XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT="nodeadkeys"
'
assert_input "/etc/default/keyboard is read without an XKB layout in vconsole.conf" "[de] [] [$base_options]" 'XKBLAYOUT="de"
' 'KEYMAP=de
'
assert_input "vconsole.conf's layout wins over /etc/default/keyboard" "[fr] [] [$base_options]" 'XKBLAYOUT="de"
' 'XKBLAYOUT=fr
'

assert_input "us layout passes through" "[us] [intl] [$base_options]" 'XKBLAYOUT=us
XKBVARIANT=intl
'

assert_input "latin layouts are left alone" "[de] [nodeadkeys] [$base_options]" 'XKBLAYOUT=de
XKBVARIANT=nodeadkeys
'

assert_input "non-latin layout gains us in front" "[us,ara] [,] [$toggle_options]" 'XKBLAYOUT=ara
'

assert_input "prepended us keeps variants aligned" "[us,ru] [,phonetic] [$toggle_options]" 'XKBLAYOUT=ru
XKBVARIANT=phonetic
'
assert_input "non-latin layout in front moves a trailing us to the front" "[us,il] [,] [$toggle_options]" 'XKBLAYOUT=il,us
'
assert_input "a trailing us is not duplicated, so the toggle has one stop per layout" "[us,ru] [,] [$toggle_options]" 'XKBLAYOUT=ru,us
'
assert_input "moving us keeps every layout paired with its variant" "[us,ru] [intl,phonetic] [$toggle_options]" 'XKBLAYOUT=ru,us
XKBVARIANT=phonetic,intl
'
assert_input "a third layout keeps its place and variant" "[us,ua,de] [,,nodeadkeys] [$toggle_options]" 'XKBLAYOUT=ua,us,de
XKBVARIANT=,,nodeadkeys
'
assert_input "a us variant that can't type latin still gets a plain us in front" "[us,ru,us] [,,rus] [$toggle_options]" 'XKBLAYOUT=ru,us
XKBVARIANT=,rus
'

assert_input "the installer's model and options pass through" "[de] [] [ctrl:nocaps]" 'XKBMODEL=pc105
XKBLAYOUT=de
XKBOPTIONS=ctrl:nocaps
'
assert_input "the installer's switching key replaces Left Alt + Right Alt" "[us,ru] [,] [grp:alt_shift_toggle]" 'XKBLAYOUT=ru
XKBOPTIONS=grp:alt_shift_toggle
'

TEST_INPUT_PREFERENCE=$'INPUT_METHOD=hangul\n XKB_LAYOUT="kr" # desktop only\n' assert_input "Korean selection overrides its installer US layout" "[kr] [] [$base_options]" $'XKBLAYOUT=us\n'
TEST_INPUT_PREFERENCE=$'INPUT_METHOD=hangul\nXKB_LAYOUT=kr:kr104\n' assert_input "Korean Right Alt selection maps 한/영 and 한자 to Right Alt and Right Ctrl" "[kr] [kr104] [$base_options]" $'XKBLAYOUT=us\n'
TEST_INPUT_PREFERENCE=$'INPUT_METHOD=none\nXKB_LAYOUT=la\n' assert_input "Lao selection gets Lao behind US on the desktop" "[us,la] [,] [$toggle_options]" $'XKBLAYOUT=us\n'
TEST_INPUT_PREFERENCE=$'INPUT_METHOD=none\nXKB_LAYOUT=xx\n' assert_input "an unknown desktop override is ignored" "[us] [] [$base_options]" $'XKBLAYOUT=us\n'
TEST_INPUT_PREFERENCE=$'INPUT_METHOD=hangul\nXKB_LAYOUT=kr\n' assert_input "a later US variant overrides the Korean preference" "[us] [intl] [$base_options]" $'XKBLAYOUT=us\nXKBVARIANT=intl\n'
TEST_INPUT_PREFERENCE=$'INPUT_METHOD=hangul\nXKB_LAYOUT=kr\n' assert_input "a later layout overrides the Korean preference" "[de] [nodeadkeys] [$base_options]" $'XKBLAYOUT=de\nXKBVARIANT=nodeadkeys\n'

TEST_KEYBOARD_SELECTION=$'XKBLAYOUT=us,fr\nXKBVARIANT=intl,\n' assert_input "menu selections replace installer desktop defaults" "[us,fr] [intl,] [$base_options]" $'XKBLAYOUT=jp\n'
TEST_KEYBOARD_SELECTION=$'XKBLAYOUT=us,fr\nXKBVARIANT=intl,\n' assert_input "menu selections keep the installer's options" "[us,fr] [intl,] [ctrl:nocaps]" $'XKBLAYOUT=jp\nXKBOPTIONS=ctrl:nocaps\n'

TEST_KEYBOARD_SELECTION=$'XKBLAYOUT=us,ru\nXKBVARIANT=,phonetic\n' assert_input "saved non-Latin selections retain the layout shortcut" "[us,ru] [,phonetic] [$toggle_options]" $'XKBLAYOUT=us\n'
