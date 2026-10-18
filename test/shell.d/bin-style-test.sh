#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

raw_command_checks=$(rg -l 'command -v' "$ROOT/bin" \
  | rg -v '/omarchy-(cmd-|pkg-|upgrade-to-quattro)' || true)
[[ -z $raw_command_checks ]] || fail "bin commands use command helpers" "$raw_command_checks"
pass "bin commands use command helpers"

raw_notifications=$(rg -l -P '^[[:space:]]*[^#[:space:]].*\bnotify-send\b' "$ROOT/bin" || true)
[[ -z $raw_notifications ]] || fail "bin commands use the notification helper, never notify-send" "$raw_notifications"
pass "bin commands use the notification helper"

# -g takes the next word as the toast's glyph: with the glyph missing (an editor or a copy that
# drops Nerd Font characters), the headline becomes the glyph and the toast has no title.
glyphless_notifications=$(rg -n -P 'notification-send\b.*\s(-g|--glyph)\s+"[A-Za-z]' "$ROOT/bin" "$ROOT/install" || true)
[[ -z $glyphless_notifications ]] || fail "notification glyphs are present after -g" "$glyphless_notifications"
pass "notification glyphs are present after -g"
