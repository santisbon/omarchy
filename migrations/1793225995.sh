echo "Replace the Gemini coding agent with Antigravity"

# Google stopped serving Gemini CLI's Sign in with Google for individual accounts on June 18, 2026,
# and points them to Antigravity, so the Gemini menu entry became Antigravity (agy).
agent_file="$HOME/.config/omarchy/defaults/agent"
skills_source="$OMARCHY_PATH/default/agents/skills"

# Read the default the way omarchy-default-agent reads it, so this migration and the launcher agree.
selected_agent=""
if [[ -f $agent_file ]]; then
  read -r selected_agent <"$agent_file" || true
fi

if omarchy-cmd-missing agy; then
  omarchy-mise-install antigravity-cli agy
fi

if [[ $selected_agent == "gemini" ]]; then
  printf '%s\n' agy >"$agent_file"
fi

# Only the wrapper omarchy-mise-install wrote goes; a hand-written one is left alone.
if [[ -f $HOME/.local/bin/gemini && ! -L $HOME/.local/bin/gemini ]] && grep -Eq '^mise use -g .*"gemini"' "$HOME/.local/bin/gemini"; then
  rm -f "$HOME/.local/bin/gemini"
fi

if [[ -d $skills_source ]]; then
  mkdir -p "$HOME/.gemini/config/skills"
  for skill in "$skills_source"/*/; do
    [[ -d $skill ]] || continue
    name=${skill%/}
    ln -sfn "$name" "$HOME/.gemini/config/skills/${name##*/}"
  done
fi
