#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/home"

stub() { printf '#!/bin/bash\n%s\n' "$2" >"$work/bin/$1"; chmod +x "$work/bin/$1"; }
for cmd in omarchy-pkg-snap-add omarchy-pkg-drop omarchy-pkg-repo-remove omarchy-theme-set-vscode setsid; do
  stub "$cmd" "echo \"$cmd \$*\" >>\"\$TEST_LOG\""
done
installer="$ROOT/bin/omarchy-install-editor-vscode"
migration="$ROOT/migrations/1793326339.sh"

# A first install: the snap, classic, and Omarchy's two files.
: >"$TEST_LOG"
stub omarchy-pkg-present 'exit 1'
HOME="$work/home" PATH="$work/bin:$PATH" bash "$installer" >/dev/null
grep -qx 'omarchy-pkg-snap-add code --classic' "$TEST_LOG" || fail "VS Code is Microsoft's classic snap" "$(cat "$TEST_LOG")"
! grep -q '^omarchy-pkg-drop' "$TEST_LOG" || fail "a first install drops no .deb"
grep -qx 'setsid uwsm-app -- gtk-launch code_code' "$TEST_LOG" || fail "the snap's desktop entry, code_code, is launched" "$(cat "$TEST_LOG")"
grep -q '"update.mode": "none"' "$work/home/.config/Code/User/settings.json" || fail "a first install turns VS Code's own updates off"
grep -q '"password-store":"gnome-libsecret"' "$work/home/.vscode/argv.json" || fail "a first install uses the keyring"
pass "a first install is Microsoft's classic snap with Omarchy's defaults"

# Switching from the .deb: the package and its apt repository go, the user's files stay.
: >"$TEST_LOG"
stub omarchy-pkg-present '[[ $1 == code ]]'
echo '{ "editor.fontSize": 15 }' >"$work/home/.config/Code/User/settings.json"
echo '{ "enable-crash-reporter": false }' >"$work/home/.vscode/argv.json"
HOME="$work/home" PATH="$work/bin:$PATH" bash "$installer" >/dev/null
grep -qx 'omarchy-pkg-drop code' "$TEST_LOG" || fail "the .deb goes" "$(cat "$TEST_LOG")"
grep -qx 'omarchy-pkg-repo-remove vscode' "$TEST_LOG" || fail "Microsoft's apt repository goes"
grep -qx '{ "editor.fontSize": 15 }' "$work/home/.config/Code/User/settings.json" || fail "the user's settings stay"
grep -qx '{ "enable-crash-reporter": false }' "$work/home/.vscode/argv.json" || fail "the user's argv.json stays"
pass "switching from the .deb removes it and its repository and keeps the user's files"

grep -q '"install.editor.vscode":.*"when":"! omarchy-pkg-snap-present code"' "$ROOT/default/omarchy/omarchy-menu.jsonc" ||
  fail "Install > Editor > VSCode shows until the snap is installed"
pass "Install > Editor > VSCode shows until the snap is installed"

# The migration prints the command only while the .deb is installed and the snap is not.
stub omarchy-pkg-present '[[ $1 == code ]]'
stub omarchy-pkg-snap-present 'exit 1'
out=$(PATH="$work/bin:$PATH" bash -euo pipefail "$migration")
grep -q 'omarchy-install-editor-vscode' <<<"$out" || fail "the migration tells .deb users how to switch" "$out"
stub omarchy-pkg-snap-present 'exit 0'
out=$(PATH="$work/bin:$PATH" bash -euo pipefail "$migration")
[[ $(wc -l <<<"$out") == 1 ]] || fail "the migration prints only its title once the snap is installed" "$out"
stub omarchy-pkg-present 'exit 1'
stub omarchy-pkg-snap-present 'exit 1'
out=$(PATH="$work/bin:$PATH" bash -euo pipefail "$migration")
[[ $(wc -l <<<"$out") == 1 ]] || fail "the migration prints only its title without the .deb" "$out"
pass "the migration tells only .deb users how to switch"
