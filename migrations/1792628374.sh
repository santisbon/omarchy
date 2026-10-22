echo "Point the nwg-displays launcher at monitors-gui.lua"

# nwg-displays' own launcher runs it without -m, so a layout saved from the app launcher was
# written to ~/.config/hypr/monitors.lua, over the hand-edited file. The port's launcher of the
# same name runs omarchy-launch-monitors instead, which saves to monitors-gui.lua like
# Setup > Monitors. New users get it at first login (omarchy-refresh-applications); this copies
# it for users who existed before, unless they have a launcher of that name of their own.
launcher="nwg-displays.desktop"
if [[ ! -e $HOME/.local/share/applications/$launcher && -f $OMARCHY_PATH/applications/$launcher ]]; then
  mkdir -p "$HOME/.local/share/applications"
  cp "$OMARCHY_PATH/applications/$launcher" "$HOME/.local/share/applications/"
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi
