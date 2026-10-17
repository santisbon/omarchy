echo "Use the plugin IDs, app IDs and variables that plugins and themes expect, and link the folders they use"

# Since the distro's docs/6, choice 86, the build keeps Omarchy's names for what plugins and
# themes written for Omarchy use and users do not see: the built-in plugins' IDs (omarchy.clock),
# OMARCHY_* variables, app IDs (org.omarchy.terminal), the "omarchy" section of a plugin
# manifest, and the icon font's family. Before, the build renamed them, and copies of the old
# names sit in this user's files: the bar layout in ~/.config/omarchy/shell.json, Hyprland's
# config, uwsm's environment, plugin clones' manifests, Chromium's native-messaging hosts.
# This puts the upstream names back in those files and adds the links omarchy-compat-links makes
# for new users. "omar""chy" is written in two parts so the build's rename leaves it alone.
upstream="omar""chy"
upstream_upper="OMAR""CHY"
own="omarchy"
own_upper="OMARCHY"
[[ $own != "$upstream" ]] || exit 0

omarchy-compat-links

# The built-in plugins' IDs without the prefix, as one alternation (clock|menu|...). A manifest
# jq cannot read is skipped; the IDs it did read still count.
ids=$({ find "$OMARCHY_PATH/shell/plugins" \( -name manifest.json -o -name '*.manifest.json' \) -print0 |
  xargs -0 -r jq -r '.id // empty' 2>/dev/null || true; } | sed -n "s/^$upstream\.//p" | sort -u | paste -sd'|')

files=()
while IFS= read -r -d '' file; do
  files+=("$file")
done < <(find "$HOME/.config/$own" "$HOME/.config/hypr" "$HOME/.config/uwsm" "$HOME/.config/swappy" \
  -name .git -prune -o -type f -size -1024k -print0 2>/dev/null)

for file in "${files[@]}"; do
  grep -Iq . "$file" 2>/dev/null || continue
  grep -qE "$own|$own_upper" "$file" || continue
  OWN="$own" OWN_UPPER="$own_upper" UP="$upstream" UP_UPPER="$upstream_upper" IDS="$ids" perl -pi -e '
    s/\b$ENV{OWN_UPPER}_/$ENV{UP_UPPER}_/g;
    s/\b(org|com)\.$ENV{OWN}\./$1.$ENV{UP}./g;
    s/"$ENV{OWN}"(\s*:)/"$ENV{UP}"$1/g;
    s/(iconFont"\s*:\s*")$ENV{OWN}"/$1$ENV{UP}"/g;
    s/(fontFamily:\s*")$ENV{OWN}"/$1$ENV{UP}"/g;
    if ($ENV{IDS} ne q{}) { s/\b$ENV{OWN}\.($ENV{IDS})(?![\w-])/$ENV{UP}.$1/g; }
  ' "$file"
done

# Chromium's native-messaging hosts are files named after the host; the browser extensions
# now ask for the upstream host names, so the old files go and the installers write the new ones.
old_hosts=$(compgen -G "$HOME/.config/*/NativeMessagingHosts/com.$own.*.json"; compgen -G "$HOME/.config/BraveSoftware/*/NativeMessagingHosts/com.$own.*.json") || true
if [[ -n $old_hosts ]]; then
  printf '%s\n' "$old_hosts" | while IFS= read -r host; do rm -f -- "$host"; done
  omarchy-install-chromium-copy-url
  omarchy-install-chromium-ytdlp
fi
