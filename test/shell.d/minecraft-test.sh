#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/home/.minecraft/saves"
for cmd in omarchy-pkg-add omarchy-pkg-drop omarchy-launcher-rescan uwsm-app; do
  printf '#!/bin/bash\necho "%s $*" >>"$TEST_LOG"\n' "$cmd" >"$work/bin/$cmd"
done
printf '#!/bin/bash\necho "sudo $*" >>"$TEST_LOG"\n' >"$work/bin/sudo"
printf '#!/bin/bash\nfor ((i=1;i<=$#;i++)); do [[ ${!i} == -o ]] && { j=$((i+1)); echo deb >"${!j}"; }; done\necho "curl $*" >>"$TEST_LOG"\n' >"$work/bin/curl"
printf '#!/bin/bash\nexit 0\n' >"$work/bin/omarchy-pkg-present"
printf '#!/bin/bash\n"$@"\n' >"$work/bin/setsid"
chmod +x "$work/bin"/*

HOME="$work/home" PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-install-gaming-minecraft" >/dev/null
wait
mapfile -t calls <"$TEST_LOG"
[[ ${calls[0]} == "omarchy-pkg-add omarchy-gdk-pixbuf-compat" ]] || fail "the compatibility package goes in first" "$(cat "$TEST_LOG")"
[[ ${calls[1]} == "curl -fsSL --retry 3 https://launcher.mojang.com/download/Minecraft.deb -o "*"/Minecraft.deb" ]] || fail "Mojang's .deb is downloaded" "${calls[1]}"
[[ ${calls[2]} == "sudo apt-get install -y /"*"/Minecraft.deb" ]] || fail "apt installs the downloaded .deb by path, resolving its dependencies" "${calls[2]}"
grep -qx 'uwsm-app -- gtk-launch minecraft-launcher' "$TEST_LOG" || fail "the installer opens the launcher"

HOME="$work/home" PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-gaming-minecraft" >/dev/null
grep -qx 'omarchy-pkg-drop minecraft-launcher' "$TEST_LOG" || fail "the remover drops the package"
[[ ! -e $work/home/.minecraft ]] || fail "the remover deletes ~/.minecraft, as Omarchy's does"

pass "Minecraft installs Mojang's .deb with the compatibility package, and removes with its data"
