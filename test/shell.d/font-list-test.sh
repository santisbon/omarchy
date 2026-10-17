#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf '#!/bin/bash\nprintf "%%s\\n" "JetBrainsMono Nerd Font" "Material Icons" "Noto Color Emoji" "Noto Mono" "Font Awesome 6 Free"\n' >"$work/fc-list"
chmod +x "$work/fc-list"

list=$(PATH="$work:$PATH" bash "$ROOT/bin/omarchy-font-list")
[[ $list == $'JetBrainsMono Nerd Font\nNoto Mono' ]] || fail "icon and emoji fonts are left out of Style > Font" "$list"

pass "the font list leaves out icon fonts such as Material Icons"
