#!/bin/bash

source "$(dirname "$0")/base-test.sh"

require_command jq

TEST_HOME=$(mktemp -d)
FAKE_OMARCHY=$(mktemp -d)
trap 'rm -rf "$TEST_HOME" "$FAKE_OMARCHY"' EXIT

mkdir -p "$FAKE_OMARCHY/bin"

cat >"$FAKE_OMARCHY/bin/omarchy-agent-usage-good" <<'EOF'
#!/bin/bash
echo '{"schemaVersion":1,"id":"good","name":"Good Agent","totalPrompts":3}'
EOF

cat >"$FAKE_OMARCHY/bin/omarchy-agent-usage-noisy" <<'EOF'
#!/bin/bash
echo "this is not json"
EOF

cat >"$FAKE_OMARCHY/bin/omarchy-agent-usage-skipped" <<'EOF'
#!/bin/bash
echo '{"id":"skipped"}'
EOF

# The updater itself lives in the same namespace as the collectors it globs.
cat >"$FAKE_OMARCHY/bin/omarchy-agent-usage-update" <<'EOF'
#!/bin/bash
echo '{"id":"update"}'
EOF

chmod +x "$FAKE_OMARCHY/bin/"omarchy-agent-usage-*

usage_dir="$TEST_HOME/.local/state/omarchy/agents/usage"

HOME="$TEST_HOME" OMARCHY_PATH="$FAKE_OMARCHY" XDG_STATE_HOME="" \
  "$ROOT/bin/omarchy-agent-usage-update" --except skipped 2>/dev/null && fail "update reports a failing collector"
pass "update reports a failing collector"

[[ $(jq -r '.name' "$usage_dir/good.json") == "Good Agent" ]] ||
  fail "update writes each collector's record to the usage directory"
pass "update writes each collector's record to the usage directory"

[[ ! -e $usage_dir/noisy.json ]] ||
  fail "update refuses records that are not valid JSON"
pass "update refuses records that are not valid JSON"

[[ ! -e $usage_dir/skipped.json ]] ||
  fail "update skips agents excluded with --except"
pass "update skips agents excluded with --except"

[[ ! -e $usage_dir/update.json ]] ||
  fail "update does not treat itself as a collector"
pass "update does not treat itself as a collector"

HOME="$TEST_HOME" OMARCHY_PATH="$FAKE_OMARCHY" XDG_STATE_HOME="" \
  "$ROOT/bin/omarchy-agent-usage-update" skipped 2>/dev/null ||
  fail "update succeeds when the requested collectors all pass"
pass "update succeeds when the requested collectors all pass"

[[ -e $usage_dir/skipped.json && ! -e $usage_dir/noisy.json ]] ||
  fail "update with agent arguments only runs the named collectors"
pass "update with agent arguments only runs the named collectors"

# dpkg keeps <name>.dpkg-new and <name>.dpkg-tmp in the same folder as each file it replaces, with
# the file's own mode. Run as collectors, the updater's two copies start the updater again, without
# end, until memory runs out.
planted_log="$TEST_HOME/planted-runs"
for planted in good.dpkg-new good.dpkg-tmp update.dpkg-new update.dpkg-tmp; do
  cat >"$FAKE_OMARCHY/bin/omarchy-agent-usage-$planted" <<EOF
#!/bin/bash
echo $planted >>"$planted_log"
echo '{"id":"$planted"}'
EOF
  chmod +x "$FAKE_OMARCHY/bin/omarchy-agent-usage-$planted"
done

HOME="$TEST_HOME" OMARCHY_PATH="$FAKE_OMARCHY" XDG_STATE_HOME="" \
  "$ROOT/bin/omarchy-agent-usage-update" --except noisy 2>/dev/null ||
  fail "update succeeds with dpkg's temporary files in its folder"
[[ ! -e $planted_log ]] ||
  fail "update does not run dpkg's temporary files as collectors" "$(cat "$planted_log")"
[[ -z $(find "$usage_dir" -name '*.dpkg-*') ]] ||
  fail "update writes no records for dpkg's temporary files"
[[ $(jq -r '.name' "$usage_dir/good.json") == "Good Agent" ]] ||
  fail "update still runs the real collectors with dpkg's temporary files in its folder"
pass "update does not run dpkg's temporary files as collectors"
