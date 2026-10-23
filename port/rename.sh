#!/bin/bash
# port/rename.sh: turn a copy of this tree into the distro's tree, by name.
#
# What it does, in order, to the tree named by --tree:
#   1. deletes Omarchy's branded artwork that cannot be renamed into something else: the
#      wallpapers named after Omarchy under themes/*/backgrounds/
#      (the distro ships its own branding files instead, see the packaging);
#   2. rewrites every text file: "omarchy" becomes $DISTRO_ID, "Omarchy" becomes
#      $DISTRO_NAME, "OMARCHY" becomes $DISTRO_ID_UPPER. Omarchy's own addresses are left
#      alone (omarchy.org, the omacom/basecamp GitHub organisations, omarchy-pkgs, the
#      Omarchy manual), because they still point at Omarchy; with DISTRO_BUG_URL and
#      DISTRO_HOME_URL set, the support pointers (omarchy.org/discord, omarchy.org) in
#      user-facing messages become the distro's; with DISTRO_MANUAL_URL set, the address of
#      Omarchy's online manual (omarchy.org/manual/, opened by Learn > Omarchy) becomes the
#      distro's manual; with DISTRO_FORK_REPO set (owner/name of this fork on GitHub, such as
#      santisbon/omarchy), that repository's name is kept too, because the agent skills send
#      bug reports there;
#   3. renames every file and directory whose name contains "omarchy" or "Omarchy", except
#      Chromium's native-messaging host files, which are named after the host they declare.
# The result is what the distro's packages install: bin/<id>-*, /usr/share/<id>/..., the
# <id>-*.service units, the <id> Lua module.
#
# Names kept for Omarchy's plugins and themes (the distro's docs/6, choice 86). Plugins and
# themes written for Omarchy use these, and users do not see them, so step 2 leaves them as
# they are; the packaging adds omarchy-* links for the commands and paths users do see:
#   - environment variables, OMARCHY_* (OMARCHY_PATH, OMARCHY_GPU_OFFLOAD, ...);
#   - the built-in plugins' IDs and IPC targets (omarchy.bar, omarchy.clock, ...: every "id"
#     of a manifest under shell/plugins), and the omarchy.* namespace in the checks that
#     reserve it (omarchy.*, "omarchy.", omarchy.$service, omarchy\.);
#   - the "omarchy" section of a plugin manifest and the code that reads it
#     (manifest.omarchy, .omarchy.clonedFrom);
#   - Wayland app IDs and native-messaging host names (org.omarchy.terminal,
#     com.omarchy.copy_url), which window rules and browser extensions match;
#   - the menu's entry keys (update.omarchy, learn.omarchy);
#   - the icon font's family, "omarchy", which menu entries and plugins name in iconFont and
#     fontFamily (the font file itself moves to default/fonts/<id>/<id>.ttf).
#
# This script never runs on a git checkout (the port is kept un-renamed in git so that
# Omarchy's tags merge into it); the packaging copies the tree first. --force overrides
# that check for experiments.
#
# Usage: DISTRO_ID=<id> DISTRO_NAME=<Name> [DISTRO_ID_UPPER=<ID>] port/rename.sh --tree <dir> [--force]
#   DISTRO_ID    lowercase letters, digits and hyphens (package names, paths, commands)
#   DISTRO_NAME  one word, letters and digits (it replaces "Omarchy" inside identifiers too)
set -euo pipefail

tree="" force=0
while (($#)); do
  case "$1" in
    --tree) tree=${2:?}; shift 2 ;;
    --force) force=1; shift ;;
    *) echo "Usage: DISTRO_ID=.. DISTRO_NAME=.. $0 --tree <dir> [--force]" >&2; exit 1 ;;
  esac
done
[[ -n $tree && -d $tree ]] || { echo "rename.sh: --tree <dir> is required" >&2; exit 1; }
id=${DISTRO_ID:?DISTRO_ID is not set}
name=${DISTRO_NAME:?DISTRO_NAME is not set}
upper=${DISTRO_ID_UPPER:-$(printf '%s' "$id" | tr 'a-z-' 'A-Z_')}
[[ $id =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "rename.sh: DISTRO_ID '$id' must be lowercase letters, digits and hyphens" >&2; exit 1; }
[[ $name =~ ^[A-Za-z][A-Za-z0-9]*$ ]] || { echo "rename.sh: DISTRO_NAME '$name' must be one word of letters and digits" >&2; exit 1; }
[[ $id != omarchy ]] || { echo "rename.sh: DISTRO_ID is omarchy; nothing to do" >&2; exit 1; }
if [[ -e $tree/.git && $force == 0 ]]; then
  echo "rename.sh: $tree is a git checkout; run on a copy (or pass --force)" >&2; exit 1
fi
cd "$tree"

# 1. Branded artwork with no renamed equivalent.
find themes -path '*/backgrounds/*' -type f -iname '*omarchy*' -print -delete 2>/dev/null | sed 's/^/rename.sh: deleted /' || true

# 2. Text contents. grep -I skips binary files; perl rewrites in place.
#    Negative lookbehinds keep the GitHub organisations' paths, negative lookaheads keep
#    omarchy.org and the names of Omarchy's other repositories.
export RENAME_ID="$id" RENAME_NAME="$name" RENAME_UPPER="$upper"
export RENAME_BUG_URL="${DISTRO_BUG_URL:-}" RENAME_HOME_URL="${DISTRO_HOME_URL:-}"
export RENAME_MANUAL_URL="${DISTRO_MANUAL_URL:-}"
export RENAME_FORK_REPO="${DISTRO_FORK_REPO:-}"
# The built-in plugins' IDs without the omarchy. prefix, as one alternation: clock|menu|...
RENAME_KEEP_IDS=$(grep -rhoE '"id"[[:space:]]*:[[:space:]]*"omarchy\.[a-z0-9-]+"' shell |
  sed -E 's/.*"omarchy\.([a-z0-9-]+)"/\1/' | sort -u | paste -sd'|')
[[ -n $RENAME_KEEP_IDS ]] || { echo "rename.sh: found no plugin IDs under shell/plugins" >&2; exit 1; }
export RENAME_KEEP_IDS
# The names kept for plugins and themes (see the top of this script) and the fork repository
# name, hidden from the renaming rules as numbered placeholders and put back afterwards. The
# check at the end of this script hides the same names before it looks for leftovers.
KEEP='
  our @kept = ();
  my $hide = sub { push @kept, $_[0]; "\x{1}" . $#kept . "\x{1}" };
  if ($ENV{RENAME_FORK_REPO} ne q{}) { s#\Q$ENV{RENAME_FORK_REPO}\E#$hide->($&)#ge; }
  s/OMARCHY_/$hide->($&)/ge;
  s/(?:org|com|\[o\]rg)(?:\\\\|\\)?\.omarchy(?=(?:\\\\|\\)?\.)/$hide->($&)/ge;
  s/omarchy\.(?:$ENV{RENAME_KEEP_IDS})(?![\w-])/$hide->($&)/ge;
  s/omarchy\.(?=[*"\x27\$\\])|omarchy\\\./$hide->($&)/ge;
  s/(?<=\.)omarchy(?=\s*(?:[|=)?:,;]|\.clone|\s+else\b))|(?<=\]\.)omarchy\b/$hide->($&)/ge;
  s/"omarchy"(?=\s*:)/$hide->($&)/ge;
  s/(?<=[a-z]\.)(?<!hypr\.)omarchy(?=")/$hide->($&)/ge;
  s/(?<=iconFont":")omarchy(?=")|(?<=fontFamily: ")omarchy(?=")/$hide->($&)/ge;
'
grep -rIlZ --exclude-dir=.git -E 'omarchy|Omarchy|OMARCHY' . | xargs -0 -r perl -pi -e "$KEEP"'
  # Support pointers in user-facing messages go to the distro, when the build says where.
  if ($ENV{RENAME_BUG_URL} ne q{}) { s#https://omarchy\.org/discord#$ENV{RENAME_BUG_URL}#g; }
  if ($ENV{RENAME_MANUAL_URL} ne q{}) { s#https://omarchy\.org/manual/?#$ENV{RENAME_MANUAL_URL}#g; }
  if ($ENV{RENAME_HOME_URL} ne q{}) { s#https://omarchy\.org(?![/\w])#$ENV{RENAME_HOME_URL}#g; }
  s/OMARCHY/$ENV{RENAME_UPPER}/g;
  s/Omarchy(?!\.org)/$ENV{RENAME_NAME}/g;
  s/(?<!omacom\/)(?<!basecamp\/)(?<!omacom-io\/)(?<!the-)omarchy(?!\.org)(?!-pkgs)(?!-mirror)(?!-site)(?!-audio-tuner)/$ENV{RENAME_ID}/g;
  s/\x{1}(\d+)\x{1}/$kept[$1]/g;
'

# 3. Paths, deepest first so a directory is renamed after its contents.
find . -depth \( -name '*omarchy*' -o -name '*Omarchy*' \) ! -name 'com.omarchy.*' -print0 | while IFS= read -r -d '' path; do
  base=${path##*/}; dir=${path%/*}
  new=${base//omarchy/$id}; new=${new//Omarchy/$name}
  [[ $new != "$base" ]] && mv "$path" "$dir/$new"
done

# 4. The check: after the names kept for plugins and themes and Omarchy's own addresses, no
#    omarchy may be left. A leftover would be a reference the rules above missed; the
#    packaging's omarchy-* links would hide it at run time, so the build fails here instead.
#    This script itself is exempt: it spells out the patterns.
left=$(grep -rIlZ --exclude-dir=.git -E 'omarchy|Omarchy|OMARCHY' . | grep -zv '^\./port/rename\.sh$' |
  xargs -0 -r perl -ne "$KEEP"'
    s/\x{1}\d+\x{1}//g;
    s#(?:omacom|basecamp|omacom-io)/omarchy|the-omarchy|omarchy-(?:pkgs|mirror|site|audio-tuner)|[Oo]marchy\.org##g;
    print "$ARGV:$.: $_" if /omarchy|Omarchy|OMARCHY/;
    close ARGV if eof;
  ' | cut -c1-200)
if [[ -n $left ]]; then
  echo "rename.sh: these mentions of omarchy are neither renamed nor on the keep list:" >&2
  printf '%s\n' "$left" | head -n 20 >&2
  exit 1
fi
echo "rename.sh: done; only Omarchy's own addresses and the names kept for plugins and themes say omarchy"
