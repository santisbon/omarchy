echo "Link Omarchy's agent skills for Claude Code, Codex, Pi and Hermes"

# The agent skills (default/agents/skills: "omarchy" for customizing the desktop and
# "diagnose-crash" for crashes) were left out of the first releases and are shipped again.
# New users get the links from omarchy-provision-user at their first login; this makes the same
# links for users who existed before. A link only replaces a link: a skill directory of the
# user's own with the same name is left alone.
for skill in "$OMARCHY_PATH"/default/agents/skills/*/; do
  [[ -d $skill ]] || continue
  skill=${skill%/}
  name=${skill##*/}
  for dir in ~/.agents/skills ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills ~/.hermes/skills; do
    mkdir -p "$dir"
    if [[ -L $dir/$name || ! -e $dir/$name ]]; then
      ln -sfn "$skill" "$dir/$name"
    fi
  done
done
