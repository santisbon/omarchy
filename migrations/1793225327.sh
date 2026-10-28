echo "Install Node.js before Gemini and OpenCode in their mise wrappers"

# mise's registry resolves gemini and opencode to npm packages, whose install scripts run node, and
# omarchy-mise-install added Node.js only for names that start with npm:, so on a system whose first
# login had no network, and so no Node.js, the wrappers failed with "node: not found". Rewriting a
# wrapper with the fixed omarchy-mise-install adds the Node.js line; a user's own install is left alone.
for tool in gemini opencode; do
  wrapper="$HOME/.local/bin/$tool"
  if [[ -f $wrapper && ! -L $wrapper ]] && grep -qx "mise use -g --quiet \"$tool\" || exit 1" "$wrapper" && ! grep -q node@lts "$wrapper"; then
    omarchy-mise-install "$tool"
  fi
done
