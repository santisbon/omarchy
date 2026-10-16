#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

# The port reads the version of omarchy-tools, the package that ships these
# scripts, through dpkg-query -W -f='${Version}'. dpkg-query fails for a
# package it has never heard of, and prints nothing for one that was removed
# but left its configuration files behind.
cat >"$stub_bin/dpkg-query" <<'STUB'
#!/bin/bash
[[ $1 == "-W" && $2 == '-f=${Version}' ]] || exit 1
package=$3
case ",${OMARCHY_TEST_PACKAGES:-}," in
  *",$package,"*)
    printf '%s' "${OMARCHY_TEST_VERSION:-0.1.8}"
    exit 0
    ;;
  *",$package:removed,"*)
    exit 0
    ;;
esac
echo "dpkg-query: no packages found matching $package" >&2
exit 1
STUB
chmod +x "$stub_bin/dpkg-query"

version() {
  OMARCHY_TEST_PACKAGES="$1" \
    OMARCHY_PATH="${2:-/usr/share/omarchy}" \
    PATH="$stub_bin:$PATH" \
    "$ROOT/bin/omarchy-version"
}

[[ $(version omarchy-tools) == "0.1.8" ]] || fail "version reports the omarchy-tools package"
pass "version reports the omarchy-tools package"

# A checkout reports its hash instead, so packages are irrelevant there.
[[ $(version "" "$test_tmp/checkout") == "dev" ]] || fail "version reports a dev checkout"
pass "version reports a dev checkout"

if version "" >/dev/null 2>&1; then
  fail "version fails when no Omarchy package is installed"
fi
pass "version fails when no Omarchy package is installed"

if version "omarchy-tools:removed" >/dev/null 2>&1; then
  fail "version fails when omarchy-tools was removed but left its configuration"
fi
pass "version fails when omarchy-tools was removed but left its configuration"

# The snapshot description is only a label, so a failed lookup must not abort
# the update under set -e.
snapshot_desc=$(
  set -e
  PATH="$stub_bin:$PATH" OMARCHY_TEST_PACKAGES="" OMARCHY_PATH=/usr/share/omarchy \
    bash -c 'DESC="$(omarchy-version 2>/dev/null || echo unknown)"; echo "$DESC"' 2>/dev/null
) || fail "snapshot survives an unknown version"

[[ $snapshot_desc == "unknown" ]] || fail "snapshot labels an unknown version" "actual: $snapshot_desc"
pass "snapshot survives an unknown version"
