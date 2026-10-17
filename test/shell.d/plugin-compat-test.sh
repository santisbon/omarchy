#!/bin/bash

# Compatibility with plugins and themes written for Omarchy (the distro's docs/6, choice 86):
# the add-time scan for Arch's package tools and its warning, the stand-ins for those tools,
# the Arch-to-Ubuntu package names in omarchy-pkg-add, and, on a renamed copy of the tree,
# the names the rename keeps, the per-user links and the migration for existing users.

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stubs="$work/stubs"
mkdir -p "$stubs"
stub() { printf '#!/bin/bash\n%s\n' "$2" >"$stubs/$1"; chmod +x "$stubs/$1"; }

# --- the scan ----------------------------------------------------------------
mkdir -p "$work/scan/uses/bin" "$work/scan/clean/bin" "$work/scan/docs-only"
printf '#!/bin/bash\ninstall_cmd="yay -S xray"\n' >"$work/scan/uses/bin/install"
printf '#!/bin/bash\nomarchy-notification-send "hi"\n' >"$work/scan/clean/bin/run"
printf 'Install it with pacman -S foo.\n' >"$work/scan/docs-only/README.md"
found=$(bash "$ROOT/bin/omarchy-arch-tools-scan" "$work/scan/uses") ||
  fail "the scan finds yay in a plugin's script"
grep -qF 'bin/install:2: install_cmd="yay -S xray"' <<<"$found" ||
  fail "the scan names the file, line and text" "$found"
! bash "$ROOT/bin/omarchy-arch-tools-scan" "$work/scan/clean" >/dev/null ||
  fail "the scan passes a plugin that uses no Arch tools"
! bash "$ROOT/bin/omarchy-arch-tools-scan" "$work/scan/docs-only" >/dev/null ||
  fail "the scan skips Markdown documentation"
pass "the add-time scan finds Arch's package tools in code and skips clean plugins and docs"

# --- the warning in omarchy-plugin-add ------------------------------------------
plugin="$work/arch-plugin"
mkdir -p "$plugin"
cat >"$plugin/manifest.json" <<'JSON'
{"schemaVersion": 1, "id": "acme.arch", "name": "Arch", "version": "1.0.0", "kinds": ["bar-widget"],
 "entryPoints": {"barWidget": "Widget.qml"}, "barWidget": {"displayName": "Arch", "category": "Test", "allowMultiple": false}}
JSON
printf 'import QtQuick\nItem { property string cmd: "pacman -S foo" }\n' >"$plugin/Widget.qml"
git -C "$plugin" init -q && git -C "$plugin" add . &&
  git -C "$plugin" -c user.name=Test -c user.email=test@example.com commit -qm init
stub omarchy-shell 'exit 0'
home="$work/home-plugin"
output=$(HOME="$home" OMARCHY_PATH="$ROOT" PATH="$stubs:$ROOT/bin:$PATH" \
  omarchy-plugin-add "$plugin" --yes </dev/null 2>&1) || fail "plugin add with --yes keeps a plugin it warns about" "$output"
grep -qF "refers to Arch Linux's package tools" <<<"$output" || fail "plugin add warns about Arch tools" "$output"
grep -qF 'Widget.qml:2:' <<<"$output" || fail "the warning shows what was found" "$output"
[[ -d $home/.config/omarchy/plugins/acme.arch ]] || fail "plugin add with --yes installs the plugin"
pass "plugin add warns about Arch's package tools and keeps the plugin when told --yes"

# --- the stand-ins ---------------------------------------------------------------
log="$work/notify.log"
stub omarchy-notification-send "echo \"\$*\" >>'$log'"
ln -s "$ROOT/bin/omarchy-arch-standin" "$work/pacman"
ln -s "$ROOT/bin/omarchy-arch-standin" "$work/yay"
out=$(PATH="$stubs:$ROOT/bin:$PATH" "$work/pacman" -Qq zip 2>&1) && fail "a pacman query answers not installed"
[[ -z $out && ! -e $log ]] || fail "a pacman query is quiet" "$out"
out=$(PATH="$stubs:$ROOT/bin:$PATH" "$work/yay" -S xray 2>&1) && fail "yay -S fails"
grep -qF 'The command that ran: yay -S xray' <<<"$out" || fail "the stand-in says what ran" "$out"
grep -qF 'yay is not available' "$log" || fail "the stand-in sends a notification" "$(cat "$log" 2>/dev/null)"
out=$(PATH="$stubs:$ROOT/bin:$PATH" omarchy-pkg-aur-add xray 2>&1) && fail "the AUR stand-in fails"
grep -qF "installs from the AUR" <<<"$out" || fail "the AUR stand-in explains the AUR" "$out"
! bash "$ROOT/bin/omarchy-pkg-aur-accessible" || fail "the AUR is never accessible"
pass "pacman, yay and the AUR commands explain apt and change nothing; queries answer quietly"

# --- Arch names in omarchy-pkg-add ------------------------------------------------
installed="$work/installed"
stub apt-cache "case \$4 in bluez-obexd|python3-requests|zip) exit 0 ;; *) exit 100 ;; esac"
stub sudo "\"\$@\""
stub apt-get "shift 3; printf '%s\n' \"\$@\" >>'$installed'"
stub dpkg-query "grep -qx \"\${@: -1}\" '$installed' 2>/dev/null && printf installed"
out=$(OMARCHY_PATH="$ROOT" PATH="$stubs:$ROOT/bin:$PATH" omarchy-pkg-add bluez-obex python-requests zip 2>&1) ||
  fail "pkg add installs translated names" "$out"
[[ $(sort "$installed" | paste -sd' ') == "bluez-obexd python3-requests zip" ]] ||
  fail "pkg add installs Ubuntu's names for Arch's and passes known names through" "$(cat "$installed")"
grep -qF "Using Ubuntu's bluez-obexd for Arch's bluez-obex." <<<"$out" || fail "pkg add says what it translated" "$out"
OMARCHY_PATH="$ROOT" PATH="$stubs:$ROOT/bin:$PATH" omarchy-pkg-present bluez-obex ||
  fail "pkg present checks an Arch name under its Ubuntu name"
! OMARCHY_PATH="$ROOT" PATH="$stubs:$ROOT/bin:$PATH" omarchy-pkg-missing bluez-obex ||
  fail "pkg missing checks an Arch name under its Ubuntu name"
pass "pkg add, present and missing use Ubuntu's packages for Arch names, from the table and python-*"

# --- the renamed tree: kept names, links, migration ------------------------------------
tree="$work/tree"
mkdir -p "$tree"
cp -a "$ROOT"/{bin,config,default,shell,install,migrations,port} "$tree/"
DISTRO_ID=distro DISTRO_NAME=Distro bash "$tree/port/rename.sh" --tree "$tree" >/dev/null ||
  fail "the rename passes its own leftover check"
grep -qF '"omarchy.clock"' "$tree/config/distro/shell.json" || fail "the rename keeps built-in plugin IDs"
grep -qF 'OMARCHY_PATH' "$tree/default/bash/env-bootstrap" || fail "the rename keeps OMARCHY_* variables"
grep -qF '/usr/share/distro' "$tree/default/bash/env-bootstrap" || fail "the rename still renames paths"
grep -qF 'manifest.omarchy' "$tree/shell/services/PluginRegistry.qml" || fail "the rename keeps the manifest's omarchy section"
grep -qF 'org.omarchy.terminal' "$tree/bin/distro-launch-floating-terminal-with-presentation" || fail "the rename keeps app IDs"
[[ -x $tree/bin/distro-plugin-add && ! -e $tree/bin/omarchy-plugin-add ]] || fail "the rename still renames commands"

user="$work/user"
mkdir -p "$user/.config/distro" "$user/.config/hypr"
printf '{"bar":{"left":["distro.clock","acme.mine"]}}\n' >"$user/.config/distro/shell.json"
printf 'o.window("org.distro.terminal")\nlocal p = os.getenv("DISTRO_PATH")\n' >"$user/.config/hypr/rules.lua"
mkdir -p "$user/.config/chromium/NativeMessagingHosts"
printf '{}\n' >"$user/.config/chromium/NativeMessagingHosts/com.distro.copy_url.json"
stub distro-install-chromium-copy-url "touch '$user/.config/chromium/NativeMessagingHosts/com.omarchy.copy_url.json'"
stub distro-install-chromium-ytdlp 'exit 0'
HOME="$user" OMARCHY_PATH="$tree" PATH="$stubs:$tree/bin:$PATH" bash -euo pipefail "$tree/migrations/1792256553.sh" >/dev/null ||
  fail "the migration runs"
[[ $(readlink "$user/.config/omarchy") == distro ]] || fail "~/.config/omarchy links to the distro's folder"
[[ $(readlink "$user/.local/share/omarchy") == "$tree" ]] || fail "~/.local/share/omarchy links to OMARCHY_PATH"
grep -qF '"omarchy.clock","acme.mine"' "$user/.config/distro/shell.json" ||
  fail "the migration puts Omarchy's plugin IDs back and leaves others" "$(cat "$user/.config/distro/shell.json")"
grep -qF 'o.window("org.omarchy.terminal")' "$user/.config/hypr/rules.lua" || fail "the migration puts app IDs back"
grep -qF 'os.getenv("OMARCHY_PATH")' "$user/.config/hypr/rules.lua" || fail "the migration puts OMARCHY_* back"
[[ ! -e $user/.config/chromium/NativeMessagingHosts/com.distro.copy_url.json &&
  -e $user/.config/chromium/NativeMessagingHosts/com.omarchy.copy_url.json ]] ||
  fail "the migration replaces the native-messaging hosts"
pass "a renamed tree keeps the names plugins use, and the migration fixes an existing user's files"
