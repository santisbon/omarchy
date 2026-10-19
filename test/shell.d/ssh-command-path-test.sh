#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

stub_dir=$(mktemp -d)
trap 'rm -rf "$stub_dir"' EXIT

for cmd in mkdir touch; do
  cat >"$stub_dir/$cmd" <<STUB
#!/bin/bash
printf '$cmd %s\n' "\$*" >>"\$TEST_LOG"
STUB
done
chmod +x "$stub_dir"/*
export TEST_LOG="$stub_dir/ssh-command-path.log"

line='PATH DEFAULT=${PATH}:@{HOME}/.local/share/mise/shims:@{HOME}/.local/bin'
run_step() {
  OMARCHY_PAM_ENV_CONF="$1" PATH="$stub_dir:$PATH" bash -eE -c 'source "$1"' bash "$ROOT/install/config/ssh-command-path.sh"
}

# Ubuntu's pam_env.conf: comments only.
conf="$stub_dir/pam_env.conf"
printf '# Ubuntu comments only\n#PATH DEFAULT=commented\n' >"$conf"
run_step "$conf"
run_step "$conf"
[[ $(grep -cxF "$line" "$conf") == 1 ]] || fail "the PATH line is added once, however often the step runs" "$(cat "$conf")"
[[ $(grep -cE '^PATH[[:space:]]' "$conf") == 1 ]] || fail "no other active PATH line"
grep -qx "touch /var/lib/omarchy/ssh-command-path" "$TEST_LOG" || fail "the set-up marker is written"

# An administrator's own PATH line is left alone.
admin="$stub_dir/admin.conf"
printf 'PATH DEFAULT=/opt/admin/bin\n' >"$admin"
run_step "$admin"
[[ $(cat "$admin") == 'PATH DEFAULT=/opt/admin/bin' ]] || fail "an existing PATH line is left alone" "$(cat "$admin")"

pass "ssh command path appends mise's shims and ~/.local/bin to PAM's PATH once, and leaves an existing PATH line alone"
