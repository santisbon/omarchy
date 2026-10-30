#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/home" "$work/root/etc/apparmor.d" "$work/root/usr/sbin"

stub() { printf '#!/bin/bash\n%s\n' "$2" >"$work/bin/$1"; chmod +x "$work/bin/$1"; }
for cmd in omarchy-pkg-repo-add omarchy-pkg-add omarchy-pkg-snap-drop omarchy-theme-set-vscode setsid sudo; do
  stub "$cmd" "echo \"$cmd \$*\" >>\"\$TEST_LOG\""
done

# The installer with the AppArmor paths moved under the work directory.
run_installer() {
  sed "s#/usr/sbin/apparmor_parser#$work/root/usr/sbin/apparmor_parser#g; s#/etc/apparmor.d/code#$work/root/etc/apparmor.d/code#g" \
    "$ROOT/bin/omarchy-install-editor-vscode" | HOME="$work/home" PATH="$work/bin:$PATH" bash >/dev/null
}
migration="$ROOT/migrations/1793375816.sh"

# A first install on a working system: the .deb with OpenSSL 3, the profile loaded, Omarchy's files.
: >"$TEST_LOG"
stub omarchy-pkg-snap-present 'exit 1'
printf '#!/bin/bash\n' >"$work/root/usr/sbin/apparmor_parser"; chmod +x "$work/root/usr/sbin/apparmor_parser"
touch "$work/root/etc/apparmor.d/code"
run_installer
grep -q '^omarchy-pkg-repo-add vscode ' "$TEST_LOG" || fail "Microsoft's apt repository is added" "$(cat "$TEST_LOG")"
grep -qx 'omarchy-pkg-add code libssl3t64' "$TEST_LOG" || fail "VS Code comes with OpenSSL 3 for its signature check" "$(cat "$TEST_LOG")"
grep -qx "sudo apparmor_parser -r $work/root/etc/apparmor.d/code" "$TEST_LOG" || fail "VS Code's AppArmor profile is loaded" "$(cat "$TEST_LOG")"
! grep -q 'reinstall apparmor' "$TEST_LOG" || fail "a working AppArmor is not reinstalled"
! grep -q '^omarchy-pkg-snap-drop' "$TEST_LOG" || fail "no snap, nothing to drop"
grep -qx 'setsid uwsm-app -- gtk-launch code' "$TEST_LOG" || fail "the .deb's desktop entry is launched"
grep -q '"update.mode": "none"' "$work/home/.config/Code/User/settings.json" || fail "a first install turns VS Code's own updates off"
grep -q '"password-store":"gnome-libsecret"' "$work/home/.vscode/argv.json" || fail "a first install uses the keyring"
pass "a first install is the .deb with OpenSSL 3, its AppArmor profile loaded, and Omarchy's defaults"

# A missing parser or profile brings the apparmor package back before the profile is loaded.
for missing in usr/sbin/apparmor_parser etc/apparmor.d/code; do
  : >"$TEST_LOG"
  mv "$work/root/$missing" "$work/moved"
  run_installer
  grep -qx 'sudo apt-get install -y --reinstall apparmor' "$TEST_LOG" || fail "a missing /$missing reinstalls apparmor" "$(cat "$TEST_LOG")"
  [[ $(grep -n 'reinstall apparmor' "$TEST_LOG" | cut -d: -f1) -lt $(grep -n 'apparmor_parser -r' "$TEST_LOG" | cut -d: -f1) ]] ||
    fail "apparmor is reinstalled before the profile is loaded"
  mv "$work/moved" "$work/root/$missing"
done
pass "a missing AppArmor parser or VS Code profile reinstalls apparmor first"

# Switching from the snap: the snap goes, the user's files stay.
: >"$TEST_LOG"
stub omarchy-pkg-snap-present '[[ $1 == code ]]'
echo '{ "editor.fontSize": 15 }' >"$work/home/.config/Code/User/settings.json"
echo '{ "enable-crash-reporter": false }' >"$work/home/.vscode/argv.json"
run_installer
grep -qx 'omarchy-pkg-snap-drop code' "$TEST_LOG" || fail "the snap goes" "$(cat "$TEST_LOG")"
grep -qx '{ "editor.fontSize": 15 }' "$work/home/.config/Code/User/settings.json" || fail "the user's settings stay"
grep -qx '{ "enable-crash-reporter": false }' "$work/home/.vscode/argv.json" || fail "the user's argv.json stays"
pass "switching from the snap removes it and keeps the user's files"

menu="$ROOT/default/omarchy/omarchy-menu.jsonc"
grep -q '"install.editor.vscode":.*"when":"! omarchy-pkg-present code"' "$menu" ||
  fail "Install > Editor > VSCode shows until the .deb is installed"
pass "Install > Editor > VSCode shows until the .deb is installed"

# The migration prints the command for a .deb without OpenSSL 3 and for the snap, and nothing else.
migrate() { PATH="$work/bin:$PATH" bash -euo pipefail "$migration"; }
stub omarchy-pkg-snap-present 'exit 1'
stub omarchy-pkg-present '[[ $1 == code ]]'
stub omarchy-pkg-missing '[[ $1 == libssl3t64 ]]'
grep -q 'omarchy-install-editor-vscode' <<<"$(migrate)" || fail "the migration tells a .deb without OpenSSL 3 what to run"
stub omarchy-pkg-missing 'exit 1'
[[ $(migrate | wc -l) == 1 ]] || fail "the migration prints only its title for a .deb with OpenSSL 3"
stub omarchy-pkg-snap-present '[[ $1 == code ]]'
stub omarchy-pkg-present 'exit 1'
stub omarchy-pkg-missing '[[ $1 == code ]]'
grep -q 'omarchy-install-editor-vscode' <<<"$(migrate)" || fail "the migration tells snap users how to switch back"
stub omarchy-pkg-snap-present 'exit 1'
stub omarchy-pkg-missing 'exit 0'
[[ $(migrate | wc -l) == 1 ]] || fail "the migration prints only its title without VS Code"
pass "the migration tells only users missing the .deb's fixes what to run"
