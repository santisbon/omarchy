#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
git_log="$test_tmp/git.log"
mkdir -p "$stub_bin"

# omarchy-update-available reads apt's package lists through apt list
# --upgradable (no apt-get update, so no sudo); the stub prints that command's
# "name/suite new-version arch [upgradable from: old-version]" lines.
cat >"$stub_bin/apt" <<'SH'
#!/bin/bash
[[ $1 == "list" && $2 == "--upgradable" ]] || exit 1
echo "Listing..."
case "${TEST_APT_UPGRADABLE:-updates}" in
  updates)
    printf 'linux-image-generic/stonking 6.1-2 amd64 [upgradable from: 6.1-1]\n'
    printf 'omarchy-config/oaxaca 0.1.9 all [upgradable from: 0.1.8]\n'
    printf 'omarchy-shell/oaxaca 0.2.1 amd64 [upgradable from: 0.2.0]\n'
    printf 'libomarchy-unrelated/stonking 1.1 amd64 [upgradable from: 1.0]\n'
    ;;
  none)
    ;;
esac
exit 0
SH
chmod +x "$stub_bin/apt"

cat >"$stub_bin/git" <<'SH'
#!/bin/bash

printf '%s\n' "$*" >>"$TEST_GIT_LOG"

[[ $1 == "-C" ]] || exit 1
shift 2

case "$1" in
  fetch)
    [[ ${TEST_GIT_FETCH:-ok} == "ok" ]]
    ;;
  rev-parse)
    case "$2" in
      --is-inside-work-tree)
        [[ ${TEST_GIT_CHECKOUT:-yes} == "yes" ]] || exit 1
        echo true
        ;;
      --abbrev-ref)
        [[ ${TEST_GIT_UPSTREAM:-origin/quattro} != "none" ]] || exit 1
        echo "${TEST_GIT_UPSTREAM:-origin/quattro}"
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  rev-list)
    echo "${TEST_GIT_BEHIND:-0}"
    ;;
  *)
    exit 1
    ;;
esac
SH
chmod +x "$stub_bin/git"

run_checker() {
  OMARCHY_PATH="${TEST_OMARCHY_PATH:-/usr/share/omarchy}" \
    TEST_GIT_LOG="$git_log" \
    PATH="$stub_bin:$PATH" \
    "$ROOT/bin/omarchy-update-available"
}

capture_checker() {
  local stdout_file="$1"
  local stderr_file="$2"
  shift 2

  set +e
  (
    export "$@"
    run_checker
  ) >"$stdout_file" 2>"$stderr_file"
  local status=$?
  set -e
  return "$status"
}

stdout="$test_tmp/stdout"
stderr="$test_tmp/stderr"

if capture_checker "$stdout" "$stderr" TEST_APT_UPGRADABLE=updates; then
  status=0
else
  status=$?
fi
(( status == 0 )) || fail "update checker exits successfully when an Omarchy package update is available"
grep -Fx 'omarchy-config 0.1.8 -> 0.1.9' "$stdout" >/dev/null ||
  fail "update checker prints omarchy-config's update as name old -> new" "$(cat "$stdout")"
grep -Fx 'omarchy-shell 0.2.0 -> 0.2.1' "$stdout" >/dev/null ||
  fail "update checker prints every omarchy- package's update" "$(cat "$stdout")"
! grep -q '^linux-image-generic ' "$stdout" || fail "update checker ignores non-Omarchy package updates"
! grep -q '^libomarchy-unrelated ' "$stdout" || fail "update checker matches the omarchy- prefix only"
! grep -q '^Listing' "$stdout" || fail "update checker drops apt's Listing header"
pass "update checker detects Omarchy package updates"

if capture_checker "$stdout" "$stderr" TEST_APT_UPGRADABLE=none; then
  status=0
else
  status=$?
fi
(( status == 1 )) || fail "update checker exits non-zero when no updates are available"
grep -q '^Omarchy is up to date$' "$stdout" || fail "update checker prints up-to-date message"
pass "update checker reports up-to-date Omarchy packages"

: >"$git_log"
if capture_checker "$stdout" "$stderr" \
  TEST_APT_UPGRADABLE=none \
  TEST_OMARCHY_PATH="$test_tmp/checkout" \
  TEST_GIT_BEHIND=2; then
  status=0
else
  status=$?
fi
(( status == 0 )) || fail "update checker exits successfully when dev commits are available"
grep -Fx 'omarchy-dev-checkout 2 new commits on origin/quattro' "$stdout" >/dev/null ||
  fail "update checker reports available dev commits" "$(cat "$stdout")"
grep -Fx -- "-C $test_tmp/checkout fetch --quiet" "$git_log" >/dev/null ||
  fail "update checker fetches the dev checkout upstream" "$(cat "$git_log")"
pass "update checker detects new commits in the dev checkout"

if capture_checker "$stdout" "$stderr" \
  TEST_APT_UPGRADABLE=none \
  TEST_OMARCHY_PATH="$test_tmp/checkout" \
  TEST_GIT_BEHIND=0; then
  status=0
else
  status=$?
fi
(( status == 1 )) || fail "update checker exits non-zero when the dev checkout is current"
grep -q '^Omarchy is up to date$' "$stdout" || fail "update checker reports a current dev checkout"
pass "update checker ignores a current dev checkout"

if capture_checker "$stdout" "$stderr" \
  TEST_APT_UPGRADABLE=none \
  TEST_OMARCHY_PATH="$test_tmp/checkout" \
  TEST_GIT_BEHIND=1 \
  TEST_GIT_FETCH=fail; then
  status=0
else
  status=$?
fi
(( status == 0 )) || fail "update checker uses cached upstream state when fetch fails"
grep -Fx 'omarchy-dev-checkout 1 new commit on origin/quattro' "$stdout" >/dev/null ||
  fail "update checker reports cached dev commits after a fetch failure" "$(cat "$stdout")"
[[ ! -s $stderr ]] || fail "update checker keeps dev fetch failures quiet" "$(cat "$stderr")"
pass "update checker uses cached dev state when fetching is unavailable"

# The update runs the checker from the terminal it was started in, and a session that began
# before the update that introduced OMARCHY_PATH has none (2026-10-17: "line 9: OMARCHY_PATH:
# unbound variable").
if (
  export TEST_APT_UPGRADABLE=none TEST_GIT_LOG="$git_log"
  env -u OMARCHY_PATH PATH="$stub_bin:$PATH" "$ROOT/bin/omarchy-update-available"
) >"$stdout" 2>"$stderr"; then
  status=0
else
  status=$?
fi
(( status == 1 )) || fail "update checker without OMARCHY_PATH reports up to date" "$(cat "$stderr")"
! grep -q 'unbound variable' "$stderr" || fail "update checker tolerates an unset OMARCHY_PATH" "$(cat "$stderr")"
pass "update checker runs in a session without OMARCHY_PATH"
