#!/bin/bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TEST_LOG="$work/log"
mkdir -p "$work/bin"
for cmd in omarchy-pkg-add omarchy-pkg-drop omarchy-pkg-repo-add omarchy-pkg-repo-remove; do
  printf '#!/bin/bash\necho "%s $*" >>"$TEST_LOG"\n' "$cmd" >"$work/bin/$cmd"
done
printf '#!/bin/bash\necho "sudo $*" >>"$TEST_LOG"\n' >"$work/bin/sudo"
printf '#!/bin/bash\necho amd64\n' >"$work/bin/dpkg"
# The installer reads the machine's own /etc/apt; this grep answers for those files from
# TEST_LIST (the page's hand-made source is there) and TEST_KEYRING_USED (another source
# names the page's keyring), and hands every other call to the real grep.
real_grep=$(command -v grep)
cat >"$work/bin/grep" <<SH
#!/bin/bash
case "\$*" in
  *"/etc/apt/sources.list.d/github-cli.list"*) [[ \${TEST_LIST:-0} == 1 ]] ;;
  *"githubcli-archive-keyring.gpg /etc/apt/sources.list /etc/apt/sources.list.d"*) [[ \${TEST_KEYRING_USED:-0} == 1 ]] ;;
  *) exec "$real_grep" "\$@" ;;
esac
SH
chmod +x "$work/bin"/*

run_install() {
  : >"$TEST_LOG"
  PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-install-dev-github-cli" >/dev/null
}

run_install
mapfile -t calls <"$TEST_LOG"
[[ ${calls[0]} == "omarchy-pkg-repo-add github-cli https://cli.github.com/packages/githubcli-archive-keyring.gpg https://cli.github.com/packages stable main amd64" ]] ||
  fail "GitHub's apt repository is added as the page gives it" "$(cat "$TEST_LOG")"
[[ ${calls[1]} == "omarchy-pkg-add gh" ]] || fail "apt installs gh after the repository" "$(cat "$TEST_LOG")"
! grep -q '^sudo rm' "$TEST_LOG" || fail "nothing is deleted without a hand-made source" "$(cat "$TEST_LOG")"
pass "the GitHub CLI installs from GitHub's apt repository"

TEST_LIST=1 run_install
grep -qx 'sudo rm -f /etc/apt/sources.list.d/github-cli.list' "$TEST_LOG" ||
  fail "a source made by hand from GitHub's page gives way" "$(cat "$TEST_LOG")"
grep -qx 'sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg' "$TEST_LOG" ||
  fail "the page's keyring goes with the page's source" "$(cat "$TEST_LOG")"
[[ $(grep -n 'omarchy-pkg-repo-add' "$TEST_LOG" | cut -d: -f1) == 3 ]] ||
  fail "the hand-made source goes before the repository is added" "$(cat "$TEST_LOG")"
pass "a source made by hand from GitHub's page is replaced"

TEST_LIST=1 TEST_KEYRING_USED=1 run_install
! grep -qx 'sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg' "$TEST_LOG" ||
  fail "the page's keyring stays while another source names it" "$(cat "$TEST_LOG")"
pass "the page's keyring stays while another source names it"

: >"$TEST_LOG"
PATH="$work/bin:$PATH" bash "$ROOT/bin/omarchy-remove-dev-github-cli" >/dev/null
mapfile -t calls <"$TEST_LOG"
[[ ${calls[0]} == "omarchy-pkg-drop gh" && ${calls[1]} == "omarchy-pkg-repo-remove github-cli" ]] ||
  fail "the remover drops gh, then GitHub's repository" "$(cat "$TEST_LOG")"
pass "the GitHub CLI removes with its repository"
