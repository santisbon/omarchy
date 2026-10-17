#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin" "$work/home/.docker/desktop"
printf '{"auths":{},"credsStore":"desktop","currentContext":"desktop-linux"}\n' >"$work/home/.docker/config.json"
for cmd in omarchy-pkg-add omarchy-pkg-drop omarchy-pkg-repo-add omarchy-pkg-repo-remove omarchy-launcher-rescan uwsm-app; do
  printf '#!/bin/bash\necho "%s $*" >>"$TEST_LOG"\n' "$cmd" >"$work/bin/$cmd"
done
printf '#!/bin/bash\necho "sudo $*" >>"$TEST_LOG"\n' >"$work/bin/sudo"
printf '#!/bin/bash\nfor ((i=1;i<=$#;i++)); do [[ ${!i} == -o ]] && { j=$((i+1)); echo deb >"${!j}"; }; done\necho "curl $*" >>"$TEST_LOG"\n' >"$work/bin/curl"
printf '#!/bin/bash\necho amd64\n' >"$work/bin/dpkg"
printf '#!/bin/bash\necho users\n' >"$work/bin/id"
# Docker Desktop counts as installed and Docker Engine as not.
printf '#!/bin/bash\n[[ $1 == docker-desktop ]]\n' >"$work/bin/omarchy-pkg-present"
printf '#!/bin/bash\n"$@"\n' >"$work/bin/setsid"
chmod +x "$work/bin"/*

HOME="$work/home" USER=tester PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-install-dev-docker-desktop" >/dev/null
wait
mapfile -t calls <"$TEST_LOG"
[[ ${calls[0]} == "omarchy-pkg-add gnome-terminal" ]] || fail "gnome-terminal goes in first, as Docker's page asks outside GNOME" "$(cat "$TEST_LOG")"
[[ ${calls[1]} == "omarchy-pkg-repo-add docker https://download.docker.com/linux/ubuntu/gpg https://download.docker.com/linux/ubuntu "*" stable amd64" ]] || fail "Docker's apt repository is added" "${calls[1]}"
[[ ${calls[2]} == "curl -fsSL --retry 3 https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb -o "*"/docker-desktop-amd64.deb" ]] || fail "Docker's .deb is downloaded" "${calls[2]}"
[[ ${calls[3]} == "sudo apt-get install -y /"*"/docker-desktop-amd64.deb" ]] || fail "apt installs the downloaded .deb by path, resolving its dependencies" "${calls[3]}"
grep -qx 'sudo usermod -aG kvm tester' "$TEST_LOG" || fail "the user joins the kvm group"
grep -qx 'uwsm-app -- gtk-launch docker-desktop' "$TEST_LOG" || fail "the installer opens Docker Desktop"

HOME="$work/home" PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-dev-docker-desktop" >/dev/null
grep -qx 'omarchy-pkg-drop docker-desktop' "$TEST_LOG" || fail "the remover purges the package"
[[ ! -e $work/home/.docker/desktop ]] || fail "the remover deletes ~/.docker/desktop"
grep -qx 'sudo rm -f /usr/local/bin/com.docker.cli' "$TEST_LOG" || fail "the remover deletes com.docker.cli"
[[ $(jq -c . "$work/home/.docker/config.json") == '{"auths":{}}' ]] || fail "the remover drops credsStore and currentContext only" "$(cat "$work/home/.docker/config.json")"
grep -qx 'omarchy-pkg-repo-remove docker' "$TEST_LOG" || fail "Docker's repository goes when Docker Engine is not installed"

pass "Docker Desktop installs from Docker's .deb and repository, and removes as Docker's page says"
