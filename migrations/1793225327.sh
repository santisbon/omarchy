echo "Install Node.js before OpenCode in its mise wrapper"

# mise's registry resolves opencode to an npm package, whose install scripts run node, and
# omarchy-mise-install added Node.js only for names that start with npm:, so on a system whose first
# login had no network, and so no Node.js, the wrapper failed with "node: not found". Rewriting the
# wrapper with the fixed omarchy-mise-install adds the Node.js line; a user's own install is left alone.
for tool in opencode; do
  wrapper="$HOME/.local/bin/$tool"
  if [[ -f $wrapper && ! -L $wrapper ]] && grep -qx "mise use -g --quiet \"$tool\" || exit 1" "$wrapper" && ! grep -q node@lts "$wrapper"; then
    omarchy-mise-install "$tool"
  fi
done
