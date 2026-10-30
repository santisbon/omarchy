echo "Give the current Hackerman theme its VS Code extension's real ID"

# The distro's build renamed the Hackerman theme's VS Code extension ID along with the rest of
# the tree, so VS Code was asked for an extension that does not exist and kept its old theme.
# The packaged theme has the right ID again; the current theme holds its own copy of
# vscode.json from when Hackerman was picked, so that copy is replaced and VS Code re-themed.
current="$HOME/.local/state/omarchy/current"
packaged="$OMARCHY_PATH/themes/hackerman/vscode.json"
if [[ $(cat "$current/theme.name" 2>/dev/null) == "hackerman" && -f $packaged ]] &&
  ! cmp -s "$packaged" "$current/theme/vscode.json"; then
  cp "$packaged" "$current/theme/vscode.json"
  omarchy-theme-set-vscode
fi
