#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
test_home="$test_tmp/home"
mkdir -p "$stub_bin" "$test_home"

write_stub() {
  local name="$1"
  local body="$2"

  cat >"$stub_bin/$name" <<SH
#!/bin/bash
$body
SH
  chmod +x "$stub_bin/$name"
}

run_orphan_checker() {
  HOME="$test_home" PATH="$stub_bin:$PATH" "$ROOT/bin/omarchy-update-orphan-pkgs"
}

# The port lists apt's orphans from a simulated autoremove, whose "Remv name
# [version]" lines name each package apt would remove; the other lines are noise.
write_stub apt-get '
if [[ $1 == "-s" && $2 == "autoremove" ]]; then
  printf "NOTE: This is only a simulation!\n"
  printf "Reading package lists...\n"
  printf "The following packages will be REMOVED:\n  old-lib unused-tool\n"
  printf "Remv old-lib [1.0-1]\nRemv unused-tool [2.3-0ubuntu1]\n"
  exit 0
fi
echo "apt-get should only be simulated" >&2
exit 99'
write_stub sudo 'echo "sudo should not be called" >&2; exit 99'
write_stub gum 'echo "gum should not be called" >&2; exit 99'

run_orphan_checker >"$test_tmp/noninteractive.out" 2>"$test_tmp/noninteractive.err"
grep -q '^  old-lib$' "$test_tmp/noninteractive.out" || fail "orphan checker lists orphan packages"
grep -q '^  unused-tool$' "$test_tmp/noninteractive.out" || fail "orphan checker lists every orphan package"
! grep -q 'REMOVED\|simulation\|1.0-1' "$test_tmp/noninteractive.out" ||
  fail "orphan checker lists only package names from the Remv lines" "$(cat "$test_tmp/noninteractive.out")"
grep -q '^2 orphaned package(s) found. Re-run omarchy-update-orphan-pkgs in a terminal' "$test_tmp/noninteractive.out" ||
  fail "orphan checker does not remove packages non-interactively"
pass "orphan checker only reports orphans non-interactively"

write_stub apt-get '
if [[ $1 == "-s" && $2 == "autoremove" ]]; then
  printf "Reading package lists...\n0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.\n"
  exit 0
fi
exit 99'
run_orphan_checker >"$test_tmp/none.out" 2>"$test_tmp/none.err"
[[ ! -s $test_tmp/none.out ]] || fail "orphan checker stays quiet when no orphans exist"
pass "orphan checker stays quiet without orphans"
