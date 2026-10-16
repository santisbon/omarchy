#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# The port's omarchy-snapshot drives Timeshift instead of Snapper: it snapshots a btrfs root
# with an on-demand (tag O) snapshot described "omarchy-update <version>", and keeps only the
# newest OMARCHY_SNAPSHOT_KEEP of those, never touching a snapshot it did not take.

snapshot="$ROOT/bin/omarchy-snapshot"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

fake_bin="$test_tmp/bin"
calls="$test_tmp/calls.log"
listing="$test_tmp/listing"
mkdir -p "$fake_bin"

cat >"$fake_bin/sudo" <<'STUB'
#!/bin/bash
exec "$@"
STUB

cat >"$fake_bin/omarchy-cmd-missing" <<'STUB'
#!/bin/bash
[[ $1 == "timeshift" ]] && (( ${TEST_TIMESHIFT_MISSING:-0} == 1 ))
STUB

cat >"$fake_bin/findmnt" <<'STUB'
#!/bin/bash
[[ $* == "-no FSTYPE /" ]] || exit 2
echo "${TEST_FSTYPE:-btrfs}"
STUB

cat >"$fake_bin/omarchy-version" <<'STUB'
#!/bin/bash
echo 4.0.4
STUB

# Logs each call tab-separated, so a description with a space stays one argument, and answers
# --list with the fixture listing in Timeshift's own layout.
cat >"$fake_bin/timeshift" <<'STUB'
#!/bin/bash
printf 'timeshift' >>"$TEST_LOG"
printf '\t%s' "$@" >>"$TEST_LOG"
printf '\n' >>"$TEST_LOG"
if [[ $1 == "--list" ]]; then
  cat "$TEST_LISTING"
fi
STUB

chmod +x "$fake_bin"/*

# Timeshift's --list layout, oldest first: a header block, then one row per snapshot of
# "<num> > <name> <tags> <description>" (linuxmint/timeshift src/AppConsole.vala,
# list_snapshots; several tags are joined by spaces).
write_listing() {
  {
    echo "Device : /dev/mapper/root"
    echo "Mode   : BTRFS"
    echo "Status : OK"
    echo
    echo "Num     Name                 Tags  Description"
    echo "------------------------------------------------------------------------------"
    local row=0 line
    for line in "$@"; do
      printf '%-4s >  %s\n' "$row" "$line"
      row=$((row + 1))
    done
  } >"$listing"
}

run_snapshot() {
  : >"$calls"
  TEST_LOG="$calls" TEST_LISTING="$listing" PATH="$fake_bin:$PATH" bash "$snapshot" "$@"
}

create_call=$'timeshift\t--create\t--scripted\t--tags\tO\t--comments\tomarchy-update 4.0.4'
list_call=$'timeshift\t--list\t--scripted'

deletes() {
  grep $'^timeshift\t--delete\t' "$calls" | cut -f4 || true
}

write_listing

# 127 is the quiet "no snapshots here" exit that omarchy-update lets through.
set +e
TEST_TIMESHIFT_MISSING=1 run_snapshot create >/dev/null 2>&1
status=$?
set -e
(( status == 127 )) || fail "snapshot create exits 127 without timeshift" "got $status"
[[ ! -s $calls ]] || fail "snapshot create runs no timeshift without timeshift" "$(cat "$calls")"
pass "snapshot create exits 127 when Timeshift is missing"

set +e
TEST_FSTYPE=ext4 run_snapshot create >/dev/null 2>&1
status=$?
set -e
(( status == 127 )) || fail "snapshot create exits 127 on a non-btrfs root" "got $status"
[[ ! -s $calls ]] || fail "snapshot create takes no snapshot of a non-btrfs root" "$(cat "$calls")"
pass "snapshot create exits 127 when the root is not btrfs"

grep -qF 'omarchy-snapshot create || (($? == 127))' "$ROOT/bin/omarchy-update" ||
  fail "update ignores only the snapshots-absent exit code"
pass "update keeps treating 127 as snapshots deliberately absent"

for command in "" bogus; do
  set +e
  output=$(run_snapshot "$command" 2>&1)
  status=$?
  set -e
  (( status == 1 )) || fail "snapshot '$command' exits 1" "got $status"
  [[ $output == *"Usage: omarchy-snapshot <create|restore>"* ]] ||
    fail "snapshot '$command' prints the usage" "$output"
  ! grep -q $'^timeshift\t--create' "$calls" || fail "snapshot '$command' creates nothing"
done
pass "snapshot without a known command prints the usage and exits 1"

write_listing \
  "2026-10-10_12-00-00  O     omarchy-update 4.0.3" \
  "2026-10-11_12-00-00  D     " \
  "2026-10-16_12-00-00  O     omarchy-update 4.0.4"
run_snapshot create >/dev/null
[[ $(sed -n 1p "$calls") == "$create_call" ]] ||
  fail "snapshot create takes an on-demand Timeshift snapshot described by the version" "$(cat "$calls")"
[[ $(sed -n 2p "$calls") == "$list_call" ]] ||
  fail "snapshot create lists the snapshots after creating one" "$(cat "$calls")"
[[ -z $(deletes) ]] || fail "snapshot create deletes nothing within the limit" "$(cat "$calls")"
pass "snapshot create takes a tagged, described Timeshift snapshot and keeps all within the limit"

# Seven of the update's own snapshots, interleaved with ones the update did not take: a manual
# on-demand snapshot, a scheduled snapshot that carries the update's description, a snapshot
# with two tags, and a description that only starts with the prefix's letters.
write_listing \
  "2026-10-01_12-00-00  O     omarchy-update 4.0.0" \
  "2026-10-02_12-00-00  O     before trying a kernel" \
  "2026-10-03_12-00-00  O     omarchy-update 4.0.1" \
  "2026-10-04_12-00-00  D     omarchy-update 4.0.1" \
  "2026-10-05_12-00-00  O D   omarchy-update 4.0.1" \
  "2026-10-06_12-00-00  O     omarchy-updated by hand" \
  "2026-10-07_12-00-00  O     omarchy-update 4.0.2" \
  "2026-10-08_12-00-00  O     omarchy-update 4.0.3" \
  "2026-10-09_12-00-00  O     omarchy-update 4.0.3" \
  "2026-10-10_12-00-00  O     omarchy-update 4.0.4" \
  "2026-10-16_12-00-00  O     omarchy-update 4.0.4"

run_snapshot create >/dev/null
[[ $(deletes) == $'2026-10-01_12-00-00\n2026-10-03_12-00-00' ]] ||
  fail "snapshot create deletes the oldest of its own snapshots beyond five" "$(cat "$calls")"
grep -qx $'timeshift\t--delete\t--snapshot\t2026-10-01_12-00-00\t--scripted' "$calls" ||
  fail "snapshot create deletes through Timeshift's scripted delete" "$(cat "$calls")"
pass "snapshot create keeps the newest five of its own snapshots and leaves all others alone"

: >"$calls"
TEST_LOG="$calls" TEST_LISTING="$listing" PATH="$fake_bin:$PATH" OMARCHY_SNAPSHOT_KEEP=2 \
  bash "$snapshot" create >/dev/null
[[ $(deletes) == $'2026-10-01_12-00-00\n2026-10-03_12-00-00\n2026-10-07_12-00-00\n2026-10-08_12-00-00\n2026-10-09_12-00-00' ]] ||
  fail "OMARCHY_SNAPSHOT_KEEP sets how many of its own snapshots are kept" "$(cat "$calls")"
pass "OMARCHY_SNAPSHOT_KEEP sets the number of update snapshots kept"
