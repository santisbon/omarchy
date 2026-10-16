#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_path="$test_tmp/pkg-drop-bin"
mkdir -p "$mock_path"

# dpkg-query -W -f='${db:Status-Status}' NAME answers "installed" only for an
# installed package of exactly that name; a virtual package has no status of
# its own, so dpkg-query prints nothing for it and fails.
cat >"$mock_path/dpkg-query" <<'EOF'
#!/bin/bash
case "${!#}" in
  exact-package | provider-package) printf 'installed' ;;
  *) echo "dpkg-query: no packages found matching ${!#}" >&2; exit 1 ;;
esac
EOF

cat >"$mock_path/sudo" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >"$TEST_TMP/pkg-drop-command"
EOF

chmod +x "$mock_path/dpkg-query" "$mock_path/sudo"

PATH="$mock_path:$PATH" TEST_TMP="$test_tmp" \
  "$ROOT/bin/omarchy-pkg-drop" exact-package virtual-package provider-package exact-package

[[ $(<"$test_tmp/pkg-drop-command") == "apt-get purge -y --autoremove exact-package provider-package" ]] ||
  fail "package removal targets exact installed names only" "actual: $(<"$test_tmp/pkg-drop-command")"
pass "package removal ignores providers and duplicate arguments"

rm -f "$test_tmp/pkg-drop-command"
PATH="$mock_path:$PATH" TEST_TMP="$test_tmp" \
  "$ROOT/bin/omarchy-pkg-drop" virtual-package missing-package
[[ ! -e $test_tmp/pkg-drop-command ]] ||
  fail "nothing installed runs no removal" "actual: $(<"$test_tmp/pkg-drop-command")"
pass "nothing installed runs no removal"
