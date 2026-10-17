#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
test_home="$test_tmp/home"
mkdir -p "$mock_bin" "$test_home"

cat >"$mock_bin/omarchy-pkg-add" <<'SH'
#!/bin/bash
printf 'pkg:%s\n' "$*" >>"$OMARCHY_TEST_LOG"
exit "${OMARCHY_TEST_PKG_STATUS:-0}"
SH

cat >"$mock_bin/omarchy-font-set" <<'SH'
#!/bin/bash
printf 'font:%s\n' "$*" >>"$OMARCHY_TEST_LOG"
SH

for command in omarchy-pkg-flatpak-add omarchy-theme-set-vscode omarchy-install-32bit-graphics; do
  cat >"$mock_bin/$command" <<'SH'
#!/bin/bash
exit 0
SH
done

# omarchy-install-gaming-steam adds the i386 architecture unless dpkg already has it.
cat >"$mock_bin/dpkg" <<'SH'
#!/bin/bash
[[ $1 == --print-foreign-architectures ]] && echo i386
exit 0
SH

cat >"$mock_bin/setsid" <<'SH'
#!/bin/bash
printf 'launch:%s\n' "$*" >>"$OMARCHY_TEST_LOG"
SH

cat >"$mock_bin/omarchy-launch-floating-terminal-with-presentation" <<'SH'
#!/bin/bash
printf '%s\n' "$1" >"$OMARCHY_TEST_PRESENTATION"
SH

chmod +x "$mock_bin"/*

export HOME="$test_home"
export OMARCHY_TEST_LOG="$test_tmp/launch.log"
export OMARCHY_TEST_PRESENTATION="$test_tmp/presentation"
export PATH="$mock_bin:$PATH"

wait_for_launch() {
  local expected="$1"

  for ((attempt = 0; attempt < 100; attempt++)); do
    grep -Fxq "$expected" "$OMARCHY_TEST_LOG" && return 0
    sleep 0.01
  done

  return 1
}

# The port's installers start the app through one of three scoped launches:
# "uwsm-app -- gtk-launch <id>" as upstream, omarchy-launch-desktop (which runs
# that same gtk-launch and adds discrete-GPU offload, commit dfe338ce), or, for
# a Flatpak, "uwsm-app -- flatpak run <app id>".
assert_detached_installer_launch() {
  local script="$1"
  local launch="$2"

  : >"$OMARCHY_TEST_LOG"
  bash "$ROOT/bin/$script"

  wait_for_launch "launch:$launch" ||
    fail "$script launches its app in a UWSM scope" "$(<"$OMARCHY_TEST_LOG")"
  grep -Fqx "setsid $launch >/dev/null 2>&1 &" "$ROOT/bin/$script" ||
    fail "$script detaches its scoped launch"
  pass "$script detaches its scoped launch"
}

# Ubuntu's emacs package has no Omarchy daemon unit, so the installer opens
# Emacs itself rather than emacsclient.
assert_detached_installer_launch omarchy-install-editor-emacs "uwsm-app -- gtk-launch emacs"
assert_detached_installer_launch omarchy-install-editor-vscodium "uwsm-app -- flatpak run com.vscodium.codium"
assert_detached_installer_launch omarchy-install-gaming-steam "omarchy-launch-desktop steam"

bash "$ROOT/bin/omarchy-install-and-launch" "Example App" "alpha beta" "Disk Usage"
presentation_command=$(<"$OMARCHY_TEST_PRESENTATION")

[[ $presentation_command == *'echo Installing\ Example\ App...;'* ]] ||
  fail "generic installer shell-quotes the display name" "$presentation_command"
[[ $presentation_command == *'omarchy-pkg-add alpha beta && (setsid omarchy-launch-desktop Disk\ Usage >/dev/null 2>&1 &)'* ]] ||
  fail "generic installer waits for packages and detaches only the scoped launch" "$presentation_command"
pass "generic installer waits for packages and detaches only the scoped launch"

: >"$OMARCHY_TEST_LOG"
bash -c "$presentation_command"
grep -Fxq 'pkg:alpha beta' "$OMARCHY_TEST_LOG" ||
  fail "generic installer passes every package to the package helper"
wait_for_launch 'launch:omarchy-launch-desktop Disk Usage' ||
  fail "generic installer preserves a desktop ID containing spaces"
pass "generic installer preserves a desktop ID containing spaces"

: >"$OMARCHY_TEST_LOG"
if OMARCHY_TEST_PKG_STATUS=1 bash -c "$presentation_command"; then
  fail "generic installer propagates package installation failure"
fi
if grep -q '^launch:' "$OMARCHY_TEST_LOG"; then
  fail "generic installer does not launch after package installation failure"
fi
pass "generic installer does not launch after package installation failure"

run_presentation() {
  bash -c "sleep() { :; }; $(<"$OMARCHY_TEST_PRESENTATION")"
}

bash "$ROOT/bin/omarchy-install-app" "LM Studio" "lmstudio-bin"
presentation_command=$(<"$OMARCHY_TEST_PRESENTATION")
[[ $presentation_command == *'echo Installing\ LM\ Studio...;'* ]] ||
  fail "install-app shell-quotes the display name" "$presentation_command"
[[ $presentation_command == *'omarchy-pkg-add lmstudio-bin'* ]] ||
  fail "install-app still passes the package list through" "$presentation_command"
pass "install-app shell-quotes the display name"

bash "$ROOT/bin/omarchy-install-app" "Example App" "alpha beta"
presentation_command=$(<"$OMARCHY_TEST_PRESENTATION")
[[ $presentation_command == 'echo Installing\ Example\ App...; omarchy-pkg-add alpha beta' ]] ||
  fail "install-app builds the presentation command with no stray argument" "$presentation_command"
: >"$OMARCHY_TEST_LOG"
run_presentation
grep -Fxq 'pkg:alpha beta' "$OMARCHY_TEST_LOG" ||
  fail "install-app passes every package to the package helper"
pass "install-app passes every package to the package helper"

bash "$ROOT/bin/omarchy-install-app" "Foo's App" "alpha"
presentation_command=$(<"$OMARCHY_TEST_PRESENTATION")
quoted_app_message="echo $(printf '%q' "Installing Foo's App...");"
[[ $presentation_command == "$quoted_app_message"* ]] ||
  fail "install-app shell-quotes an apostrophe in the display name" "$presentation_command"
: >"$OMARCHY_TEST_LOG"
run_presentation >"$test_tmp/app-apostrophe.out"
grep -Fxq 'pkg:alpha' "$OMARCHY_TEST_LOG" ||
  fail "install-app still installs when the display name has an apostrophe"
pass "install-app still installs when the display name has an apostrophe"

bash "$ROOT/bin/omarchy-install-app" "a'; echo PWNED; echo '" "alpha"
: >"$OMARCHY_TEST_LOG"
run_presentation >"$test_tmp/app-inject.out"
if grep -Fxq 'PWNED' "$test_tmp/app-inject.out"; then
  fail "install-app does not run extra commands from a quote in the display name" "$(<"$test_tmp/app-inject.out")"
fi
grep -Fxq 'pkg:alpha' "$OMARCHY_TEST_LOG" ||
  fail "install-app still installs after quoting a hostile display name"
pass "install-app does not run extra commands from a quote in the display name"

bash "$ROOT/bin/omarchy-install-app" "Example App" "alpha; echo PWNED"
: >"$OMARCHY_TEST_LOG"
run_presentation >"$test_tmp/app-pkg-inject.out"
if grep -Fxq 'PWNED' "$test_tmp/app-pkg-inject.out"; then
  fail "install-app does not run extra commands from a package list" "$(<"$test_tmp/app-pkg-inject.out")"
fi
grep -Fxq 'pkg:alpha; echo PWNED' "$OMARCHY_TEST_LOG" ||
  fail "install-app hands a hostile package list to the package helper as arguments" "$(<"$OMARCHY_TEST_LOG")"
pass "install-app does not run extra commands from a package list"

bash "$ROOT/bin/omarchy-install-app" "Example App" "$(printf 'alpha\nbeta')"
: >"$OMARCHY_TEST_LOG"
run_presentation
grep -Fxq 'pkg:alpha beta' "$OMARCHY_TEST_LOG" ||
  fail "install-app keeps every package when the list is newline-separated" "$(<"$OMARCHY_TEST_LOG")"
pass "install-app keeps every package when the list is newline-separated"

env SHELLOPTS=errexit bash "$ROOT/bin/omarchy-install-app" "Example App" "alpha beta" ||
  fail "install-app builds its command under an inherited errexit"
[[ $(<"$OMARCHY_TEST_PRESENTATION") == 'echo Installing\ Example\ App...; omarchy-pkg-add alpha beta' ]] ||
  fail "install-app builds the same command under an inherited errexit" "$(<"$OMARCHY_TEST_PRESENTATION")"
env SHELLOPTS=errexit bash "$ROOT/bin/omarchy-install-and-launch" "Example App" "alpha beta" "Disk Usage" ||
  fail "install-and-launch builds its command under an inherited errexit"
grep -Fq 'omarchy-pkg-add alpha beta' "$OMARCHY_TEST_PRESENTATION" ||
  fail "install-and-launch keeps its package list under an inherited errexit" "$(<"$OMARCHY_TEST_PRESENTATION")"
pass "the installers build their command under an inherited errexit"

bash "$ROOT/bin/omarchy-install-and-launch" "Example App" "alpha; echo PWNED" "Disk Usage"
: >"$OMARCHY_TEST_LOG"
run_presentation >"$test_tmp/launch-pkg-inject.out"
if grep -Fxq 'PWNED' "$test_tmp/launch-pkg-inject.out"; then
  fail "install-and-launch does not run extra commands from a package list" "$(<"$test_tmp/launch-pkg-inject.out")"
fi
grep -Fxq 'pkg:alpha; echo PWNED' "$OMARCHY_TEST_LOG" ||
  fail "install-and-launch hands a hostile package list to the package helper as arguments" "$(<"$OMARCHY_TEST_LOG")"
pass "install-and-launch does not run extra commands from a package list"
