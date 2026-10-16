#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

stub_dir=$(mktemp -d)
trap 'rm -rf "$stub_dir"' EXIT

for cmd in ufw sed systemctl; do
  cat >"$stub_dir/$cmd" <<STUB
#!/bin/bash
printf '$cmd %s\n' "\$*" >>"\$TEST_LOG"
STUB
done
chmod +x "$stub_dir"/*

export TEST_LOG="$stub_dir/firewall.log"
PATH="$stub_dir:$PATH" bash -eE -c 'source "$1"' bash "$ROOT/install/config/firewall.sh"

grep -qx "ufw allow 53317/udp comment localsend" "$TEST_LOG" || fail "LocalSend's udp port is allowed"
grep -qx "ufw allow 53317/tcp comment localsend" "$TEST_LOG" || fail "LocalSend's tcp port is allowed"
grep -qx "sed -i s/^ENABLED=.*/ENABLED=yes/ /etc/ufw/ufw.conf" "$TEST_LOG" || fail "ufw is turned on for the next boot"
grep -qx "systemctl enable ufw" "$TEST_LOG" || fail "ufw.service is enabled"
! grep -qE '^ufw (enable|default)' "$TEST_LOG" || fail "the live firewall and Ubuntu's policies are left alone"
! grep -q 'docker' "$TEST_LOG" || fail "no Docker rules"

pass "firewall config allows LocalSend and turns ufw on for the next boot without touching the live firewall"
