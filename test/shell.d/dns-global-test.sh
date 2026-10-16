#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

stub_dir=$(mktemp -d)
trap 'rm -rf "$stub_dir"' EXIT
export TEST_LOG="$stub_dir/dns.log" TEST_GLOBAL="$stub_dir/global"

# busctl holds the global configuration in a file, so the read after a write sees it.
cat >"$stub_dir/busctl" <<'STUB'
#!/bin/bash
printf 'busctl %s\n' "$*" >>"$TEST_LOG"
case $* in
  *get-property*) cat "$TEST_GLOBAL" 2>/dev/null || echo 'a{sv} 0' ;;
  *"set-property"*"a{sv} 0") echo 'a{sv} 0' >"$TEST_GLOBAL" ;;
  *set-property*) args="$*"; servers=${args##* as }; n=${servers%% *}; read -ra list <<<"${servers#* }"
    printf 'a{sv} 1 "domains" a{sv} 1 "*" a{sv} 1 "servers" as %s %s\n' "$n" "$(printf '"%s" ' "${list[@]}")" >"$TEST_GLOBAL" ;;
esac
STUB
cat >"$stub_dir/nmcli" <<'STUB'
#!/bin/bash
printf 'nmcli %s\n' "$*" >>"$TEST_LOG"
case $* in
  "-t -f UUID,TYPE connection show"*) echo "u1:802-11-wireless" ;;
  "-g ipv4.ignore-auto-dns"*) echo no ;;
esac
STUB
chmod +x "$stub_dir"/*

dns() { PATH="$stub_dir:$PATH" bash "$ROOT/bin/omarchy-dns" "$@"; }

dns Cloudflare
grep -qF "set-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager GlobalDnsConfiguration a{sv} 1 domains a{sv} 1 * a{sv} 1 servers as 4 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001" "$TEST_LOG" ||
  fail "Cloudflare goes into NetworkManager's global DNS, for networks joined later" "$(cat "$TEST_LOG")"
grep -q 'allow-interactive-authorization=yes' "$TEST_LOG" || fail "the global DNS change may ask through the polkit agent"
grep -q '^nmcli connection modify u1 .*1.1.1.1 1.0.0.1.*dns-over-tls opportunistic' "$TEST_LOG" || fail "existing profiles still get the servers and DNS over TLS"
[[ $(dns) == Cloudflare ]] || fail "the provider is read from the global configuration, even on a profile using DHCP"

dns DHCP
grep -qF 'GlobalDnsConfiguration a{sv} 0' "$TEST_LOG" || fail "DHCP clears the global configuration"
[[ $(dns) == DHCP ]] || fail "after DHCP, the provider reads DHCP"

pass "DNS choices reach networks joined later through NetworkManager's global DNS"
