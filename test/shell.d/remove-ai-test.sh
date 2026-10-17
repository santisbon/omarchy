#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin"

cat >"$tmp_dir/bin/omarchy-pkg-drop" <<'SCRIPT'
#!/bin/bash
printf 'drop:%s\n' "$*" >>"$TEST_LOG"
SCRIPT
chmod +x "$tmp_dir/bin/omarchy-pkg-drop"

# omarchy-remove-ai-perplexity asks through gum whether the user's data goes
# too. The stub answers "no" unless a test says otherwise and logs the call: a
# real gum would hang the run, and one that answered "yes" on its own would be
# the data loss the default-no exists to prevent. It logs to its own file
# because the OpenClaw section below greps TEST_LOG to prove gum was never
# reached, and the pty runs here call it on purpose.
cat >"$tmp_dir/bin/gum" <<'SCRIPT'
#!/bin/bash
printf 'gum:%s\n' "$*" >>"$TEST_GUM_LOG"
exit "${TEST_GUM_STATUS:-1}"
SCRIPT
chmod +x "$tmp_dir/bin/gum"

export TEST_GUM_LOG="$tmp_dir/gum-log"
touch "$TEST_GUM_LOG"

export TEST_LOG="$tmp_dir/log"
export PATH="$tmp_dir/bin:$PATH"

fresh_home() {
  rm -rf "$tmp_dir/home"
  mkdir -p "$tmp_dir/home"
  export HOME="$tmp_dir/home"
}

# T3 Code bootstraps the agents it drives; their state outlives it.
fresh_home
mkdir -p "$HOME/.config/t3code" "$HOME/.t3" "$HOME/.grok" "$HOME/.local/share/opencode" "$HOME/.npm"
touch "$HOME/.claude.json"
"$ROOT/bin/omarchy-remove-ai-t3-code" >/dev/null

[[ ! -e $HOME/.t3 ]] || fail "T3 Code removal deletes its own data"
pass "T3 Code removal deletes its own data"

for kept in .grok .claude.json .npm .local/share/opencode; do
  [[ -e $HOME/$kept ]] || fail "T3 Code removal keeps the agent state it bootstrapped" "$kept"
done
pass "T3 Code removal keeps the agent state it bootstrapped"

# Perplexity's other products (the CLI, Comet) share the perplexity-* prefix;
# the desktop app owns only its rpc-server runtime and Electron caches. The
# logins, vault, and flags are the user's and only go when a terminal said so.
seed_perplexity() {
  fresh_home
  mkdir -p "$HOME/.config/Perplexity" "$HOME/.cache/Perplexity" \
    "$HOME/.cache/perplexity-rpc-server" "$HOME/.local/share/perplexity-rpc-server" \
    "$HOME/.local/state/perplexity" "$HOME/.cache/perplexity-personal-computer-poc"
  touch "$HOME/.config/perplexity-flags.conf"
}

# </dev/null pins stdin off a terminal, so this run exercises the
# non-interactive path no matter where the suite itself is running.
seed_perplexity
"$ROOT/bin/omarchy-remove-ai-perplexity" </dev/null >/dev/null

for gone in .cache/Perplexity .cache/perplexity-rpc-server .local/share/perplexity-rpc-server; do
  [[ ! -e $HOME/$gone ]] || fail "Perplexity removal deletes the app's runtime and caches" "$gone"
done
pass "Perplexity removal deletes the app's runtime and caches"

for kept in .config/Perplexity .local/state/perplexity .config/perplexity-flags.conf .cache/perplexity-personal-computer-poc; do
  [[ -e $HOME/$kept ]] || fail "Perplexity removal keeps the user's data and other products' caches" "$kept"
done
pass "Perplexity removal keeps the user's data and other products' caches"

grep -qx 'drop:perplexity' "$TEST_LOG" || fail "Perplexity removal drops the perplexity package"
pass "Perplexity removal drops the perplexity package"

# Without a terminal there is nobody to ask, so gum must not even be reached:
# one that answered "yes" on its own would be a data loss.
! grep -q '^gum:' "$TEST_GUM_LOG" || fail "Perplexity removal keeps the user's data unasked when there is no terminal"
pass "Perplexity removal keeps the user's data unasked when there is no terminal"

# script(1) puts the remover on a pty, the only way -t 0 answers true in a
# test; the stubbed gum then supplies the answer.
seed_perplexity
script -qec "'$ROOT/bin/omarchy-remove-ai-perplexity'" /dev/null >/dev/null 2>&1

[[ -d $HOME/.config/Perplexity && -d $HOME/.local/state/perplexity && -f $HOME/.config/perplexity-flags.conf ]] ||
  fail "Perplexity removal keeps the user's data when the answer is no"
pass "Perplexity removal keeps the user's data when the answer is no"

# The stub answers "no" on its own, so only the logged arguments prove the
# real gum would not default to yes on a bare Enter.
grep -q '^gum:confirm --default=false ' "$TEST_GUM_LOG" ||
  fail "Perplexity removal asks with the destructive answer defaulted off"
pass "Perplexity removal asks with the destructive answer defaulted off"

# A partial install has no user data to measure; du failing must not abort
# the removal between the package and the prompt.
seed_perplexity
rm -rf "$HOME/.config/Perplexity" "$HOME/.local/state/perplexity"
script -qec "'$ROOT/bin/omarchy-remove-ai-perplexity'" /dev/null >/dev/null 2>&1 ||
  fail "Perplexity removal survives user-data directories that are already gone"
pass "Perplexity removal survives user-data directories that are already gone"

# gum draws its prompt on stderr; with stderr redirected the question would be
# invisible, so the remover must keep the data instead of blocking on it.
seed_perplexity
gum_calls_before=$(wc -l <"$TEST_GUM_LOG")
script -qec "'$ROOT/bin/omarchy-remove-ai-perplexity' 2>/dev/null" /dev/null >/dev/null 2>&1 ||
  fail "Perplexity removal completes when stderr is not a terminal"
[[ -d $HOME/.config/Perplexity ]] && (( $(wc -l <"$TEST_GUM_LOG") == gum_calls_before )) ||
  fail "Perplexity removal keeps the user's data unasked when stderr is not a terminal"
pass "Perplexity removal keeps the user's data unasked when stderr is not a terminal"

seed_perplexity
TEST_GUM_STATUS=0 script -qec "'$ROOT/bin/omarchy-remove-ai-perplexity'" /dev/null >/dev/null 2>&1

for gone in .config/Perplexity .local/state/perplexity .config/perplexity-flags.conf; do
  [[ ! -e $HOME/$gone ]] || fail "Perplexity removal deletes the user's data on an explicit yes" "$gone"
done
pass "Perplexity removal deletes the user's data on an explicit yes"

# Without HOME the rm -rf paths would degrade to /-rooted ones; -u makes that a
# refusal instead.
if env -u HOME "$ROOT/bin/omarchy-remove-ai-perplexity" </dev/null >/dev/null 2>&1; then
  fail "Perplexity removal refuses to run without HOME"
fi
pass "Perplexity removal refuses to run without HOME"
