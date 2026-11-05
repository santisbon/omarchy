#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
stub_bin="$test_tmp/bin"
calls="$test_tmp/calls.log"
drm="$test_tmp/drm"
icd="$test_tmp/icd.d"
mkdir -p "$stub_bin"

for command in gum omarchy-pkg-drop omarchy-pkg-add hyprctl omarchy-restart-hyprctl omarchy-notification-send systemctl; do
  printf '#!/bin/bash\nexit 0\n' >"$stub_bin/$command"
done
# Voxtype is already installed, so the install asks nothing and only sets it up.
printf '#!/bin/bash\nexit 1\n' >"$stub_bin/omarchy-cmd-missing"
printf '#!/bin/bash\nexit 0\n' >"$stub_bin/omarchy-dictation-use"
cat >"$stub_bin/voxtype" <<'SH'
#!/bin/bash
printf 'voxtype %s\n' "$*" >>"$TEST_LOG"
SH
chmod +x "$stub_bin"/*

# A copy with the GPU's sysfs and Vulkan directories moved to the fixture.
sed -e "s|/sys/class/drm|$drm|g" -e "s|/usr/share/vulkan/icd.d|$icd|g" \
  "$ROOT/bin/omarchy-install-dictation-voxtype" >"$test_tmp/install"

# run_install "<vendor ids of the cards>" "<Vulkan driver files>"
run_install() {
  local vendor index=0 driver

  : >"$calls"
  rm -rf "$test_tmp/home" "$drm" "$icd"
  mkdir -p "$test_tmp/home" "$drm" "$icd"
  for vendor in $1; do
    mkdir -p "$drm/card$index/device"
    printf '%s\n' "$vendor" >"$drm/card$index/device/vendor"
    index=$((index + 1))
  done
  for driver in $2; do : >"$icd/$driver"; done

  HOME="$test_tmp/home" OMARCHY_PATH="$ROOT" TEST_LOG="$calls" PATH="$stub_bin:$ROOT/bin:$PATH" \
    XDG_CONFIG_HOME="$test_tmp/home/.config" bash "$test_tmp/install" >/dev/null ||
    fail "Voxtype install completes (cards: $1; drivers: $2)"

  grep -Fx 'voxtype setup systemd' "$calls" >/dev/null ||
    fail "Voxtype install sets up the user service (cards: $1; drivers: $2)"
  ! grep -q 'setup gpu' "$calls" ||
    fail "Voxtype's own GPU switch stays unused: it replaces a file the package owns"
}

dropin() { echo "$test_tmp/home/.config/systemd/user/voxtype.service.d/omarchy-gpu.conf"; }

run_install "0x10de" "nvidia_icd.json"
grep -qx 'Environment=VOXTYPE_GPU=1' "$(dropin)" && grep -qx 'Environment=VOXTYPE_VULKAN_DEVICE=nvidia' "$(dropin)" ||
  fail "Voxtype enables the GPU backend when Vulkan is present" "$(cat "$(dropin)" 2>&1)"
! grep -q gpu_isolation "$test_tmp/home/.config/voxtype/config.toml" || fail "one GPU needs no isolation"
pass "Voxtype enables the GPU backend when the GPU has a Vulkan driver"

run_install "0x8086 0x10de" "intel_icd.x86_64.json nvidia_icd.json"
grep -qx 'Environment=VOXTYPE_VULKAN_DEVICE=nvidia' "$(dropin)" || fail "the discrete GPU is chosen" "$(cat "$(dropin)")"
grep -qx 'gpu_isolation = true' "$test_tmp/home/.config/voxtype/config.toml" || fail "two GPUs isolate each transcription"
pass "Voxtype takes the discrete GPU of two and isolates it, so it can sleep between dictations"

run_install "0x8086 0x10de" "intel_icd.x86_64.json"
grep -qx 'Environment=VOXTYPE_VULKAN_DEVICE=intel' "$(dropin)" || fail "a GPU with no Vulkan driver is passed over" "$(cat "$(dropin)")"
pass "Voxtype does not pick a GPU whose Vulkan driver is not installed"

run_install "0x10de" ""
[[ ! -e $(dropin) ]] || fail "Voxtype does not enable the GPU backend without a Vulkan driver"
pass "Voxtype does not enable the GPU backend without a Vulkan driver"
