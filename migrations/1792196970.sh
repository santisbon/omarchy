echo "Add the Disk Usage launcher"

# dua-cli is preinstalled again with Omarchy's "Disk Usage" launcher, which opens "dua i /" in a
# floating terminal. New users get the launcher at first login (omarchy-refresh-applications);
# this copies it for users who existed before, unless they have one of their own.
launcher="Disk Usage.desktop"
if [[ ! -e $HOME/.local/share/applications/$launcher && -f $OMARCHY_PATH/applications/$launcher ]]; then
  mkdir -p "$HOME/.local/share/applications"
  cp "$OMARCHY_PATH/applications/$launcher" "$HOME/.local/share/applications/"
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi
