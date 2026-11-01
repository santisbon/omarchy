#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1793473840.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

export LAUNCHER_TEST_HOME="$test_dir/home with spaces"
export LAUNCHER_TEST_PROFILE="$test_dir/apparmor.d/librepods"
entry="$LAUNCHER_TEST_HOME/.local/share/applications/me.kavishdevar.librepods.desktop"
shipped="$LAUNCHER_TEST_HOME/.config/omarchy/plugins/io.github.thisisgm.omapods/daemon/assets/me.kavishdevar.librepods.desktop"

# Redirect only the filesystem roots; never touch the developer's HOME or /etc.
python3 - "$migration" "$test_dir/migration.sh" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
source = source.replace('$HOME', '$LAUNCHER_TEST_HOME')
source = source.replace('/etc/apparmor.d/librepods', '$LAUNCHER_TEST_PROFILE')
pathlib.Path(sys.argv[2]).write_text(source)
PY

reset_home() {
  rm -rf "$LAUNCHER_TEST_HOME" "$test_dir/apparmor.d"
  mkdir -p "$(dirname "$entry")" "$(dirname "$shipped")" "$test_dir/apparmor.d"
  printf '[Desktop Entry]\nName=OpenPods\nExec=librepods\n' > "$shipped"
  : > "$LAUNCHER_TEST_PROFILE"
}

run_migration() {
  bash -euo pipefail "$test_dir/migration.sh" > "$test_dir/output" 2>&1
}

reset_home
cp "$shipped" "$entry"
run_migration
[[ ! -e $entry ]] || fail "the installed launcher entry is removed"
[[ -f $shipped ]] || fail "the plugin's own copy is untouched"
pass "remove the launcher entry the plugin installed"

run_migration
pass "launcher entry removal is idempotent"

reset_home
cp "$shipped" "$entry"
printf 'Exec=librepods --hide\n' >> "$entry"
cp "$entry" "$test_dir/custom.desktop"
run_migration
cmp "$test_dir/custom.desktop" "$entry" || fail "an edited launcher entry is preserved"
pass "preserve a launcher entry the user edited"

reset_home
cp "$shipped" "$entry"
rm "$LAUNCHER_TEST_PROFILE"
run_migration
[[ -f $entry ]] || fail "the launcher entry is kept without the AppArmor profile"
pass "keep the launcher entry when the AppArmor profile is not installed"

reset_home
cp "$shipped" "$test_dir/target.desktop"
ln -s "$test_dir/target.desktop" "$entry"
run_migration
[[ -L $entry ]] || fail "a symlinked launcher entry is preserved"
pass "preserve a launcher entry that is a symlink"

reset_home
cp "$shipped" "$entry"
rm -rf "$LAUNCHER_TEST_HOME/.config/omarchy/plugins"
run_migration
[[ -f $entry ]] || fail "the launcher entry is kept without the plugin"
pass "keep the launcher entry when the plugin is not installed"

reset_home
run_migration
pass "handle installs without the launcher entry"
