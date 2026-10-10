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
#      user-facing messages become the distro's;
#   3. renames every file and directory whose name contains "omarchy" or "Omarchy";
#   4. renames the icon font's family inside default/fonts/<id>/<id>.ttf with fontTools,
#      because the shell asks for that family by name.
# The result is what the distro's packages install: bin/<id>-*, /usr/share/<id>/..., the
# <id>-*.service units, the <id> Lua module, the <id> font family.
#
# This script never runs on a git checkout (the port is kept un-renamed in git so that it
# rebases onto Omarchy's tags); the packaging copies the tree first. --force overrides
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
grep -rIlZ --exclude-dir=.git -E 'omarchy|Omarchy|OMARCHY' . | xargs -0 -r perl -pi -e '
  # Support pointers in user-facing messages go to the distro, when the build says where.
  if ($ENV{RENAME_BUG_URL} ne q{}) { s#https://omarchy\.org/discord#$ENV{RENAME_BUG_URL}#g; }
  if ($ENV{RENAME_HOME_URL} ne q{}) { s#https://omarchy\.org(?![/\w])#$ENV{RENAME_HOME_URL}#g; }
  s/OMARCHY/$ENV{RENAME_UPPER}/g;
  s/Omarchy(?!\.org)/$ENV{RENAME_NAME}/g;
  s/(?<!omacom\/)(?<!basecamp\/)(?<!omacom-io\/)(?<!the-)omarchy(?!\.org)(?!-pkgs)(?!-mirror)(?!-site)(?!-audio-tuner)/$ENV{RENAME_ID}/g;
'

# 3. Paths, deepest first so a directory is renamed after its contents.
find . -depth \( -name '*omarchy*' -o -name '*Omarchy*' \) -print0 | while IFS= read -r -d '' path; do
  base=${path##*/}; dir=${path%/*}
  new=${base//omarchy/$id}; new=${new//Omarchy/$name}
  [[ $new != "$base" ]] && mv "$path" "$dir/$new"
done

# 4. The icon font's family name. The shell's QML names the family "omarchy" (now the id),
#    so the font must answer to it.
font="default/fonts/$id/$id.ttf"
if [[ -f $font ]]; then
  python3 - "$font" "$id" "$name" <<'PYEOF'
import sys
from fontTools.ttLib import TTFont
path, ident, name = sys.argv[1:]
font = TTFont(path)
for record in font["name"].names:
    text = record.toUnicode()
    new = text.replace("omarchy", ident).replace("Omarchy", name)
    if new != text:
        record.string = new
font.save(path)
print(f"rename.sh: font family in {path} is now {ident}")
PYEOF
fi

# What is left is Omarchy's own addresses, by design.
left=$(grep -rIo --exclude-dir=.git -E '[^ ]*omarchy[^ ]*' . | sort | uniq -c | sort -rn || true)
echo "rename.sh: done; remaining mentions of omarchy (Omarchy's own addresses):"
printf '%s\n' "$left" | head -n 20
