#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

require_command lua

# Setup > Keyboard's file is read from $HOME, so every case runs with a home of its own.
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

resolved_input() {
  HOME="$test_home" OMARCHY_PATH="$ROOT" OMARCHY_VCONSOLE="${1-}" OMARCHY_DEFAULT_KEYBOARD="${2-}" lua <<'LUA'
package.path = os.getenv("OMARCHY_PATH") .. "/?.lua;" .. package.path

local vconsole = os.getenv("OMARCHY_VCONSOLE")
local real_open = io.open

local default_keyboard = os.getenv("OMARCHY_DEFAULT_KEYBOARD")

io.open = function(path, mode)
  local content
  if path == "/etc/vconsole.conf" then
    content = vconsole
  elseif path == "/etc/default/keyboard" then
    content = default_keyboard
  else
    return real_open(path, mode)
  end

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
    actual=$(resolved_input "$3" "$4")
  elif (( $# > 2 )); then
    actual=$(resolved_input "$3")
  else
    actual=$(resolved_input)
  fi

  [[ $actual == "$expected" ]] ||
    fail "$description" "expected: $expected"$'\n'"actual:   $actual"
  pass "$description"
}

base_options=""
toggle_options="grp:alts_toggle"

assert_input "missing vconsole.conf falls back to us" "[us] [] [$base_options]"
# Ubuntu writes the layout to /etc/default/keyboard (the installer through localectl, and the
# factory reset's first-boot form), not to /etc/vconsole.conf.
assert_input "Ubuntu's /etc/default/keyboard is read without an XKB layout in vconsole.conf" "[de] [nodeadkeys] [$base_options]" 'KEYMAP=de
' 'XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT="nodeadkeys"
'
assert_input "vconsole.conf's layout wins over /etc/default/keyboard" "[fr] [] [$base_options]" 'XKBLAYOUT=fr
' 'XKBLAYOUT="de"
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
assert_input "non-latin layout in front gains us even when us trails" "[us,il,us] [,] [$toggle_options]" 'XKBLAYOUT=il,us
'

assert_input "the installer's model and options pass through" "[de] [] [ctrl:nocaps]" 'XKBMODEL=pc105
XKBLAYOUT=de
XKBOPTIONS=ctrl:nocaps
'
assert_input "the installer's switching key replaces Left Alt + Right Alt" "[us,ru] [,] [grp:alt_shift_toggle]" 'XKBLAYOUT=ru
XKBOPTIONS=grp:alt_shift_toggle
'

# Setup > Keyboard (omarchy-setup-keyboard) writes ~/.config/hypr/keyboard-gui.conf.
mkdir -p "$test_home/.config/hypr"
printf 'XKBLAYOUT="us,es"\nXKBVARIANT=",deadtilde"\nXKBOPTIONS="grp:ctrls_toggle"\n' >"$test_home/.config/hypr/keyboard-gui.conf"
assert_input "Setup > Keyboard's layouts replace the system's" "[us,es] [,deadtilde] [grp:ctrls_toggle]" 'XKBMODEL=pc105
XKBLAYOUT=de
XKBOPTIONS=ctrl:nocaps
'
printf 'XKBLAYOUT="ru"\nXKBVARIANT=""\nXKBOPTIONS=""\n' >"$test_home/.config/hypr/keyboard-gui.conf"
assert_input "a non-latin main layout from Setup > Keyboard gains us in front" "[us,ru] [,] [$toggle_options]" 'XKBLAYOUT=de
'
rm "$test_home/.config/hypr/keyboard-gui.conf"
assert_input "without Setup > Keyboard's file the system's layout is back" "[de] [] [$base_options]" 'XKBLAYOUT=de
'
