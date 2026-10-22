echo "Correct the comment about nwg-displays in monitors.lua"

# The monitors.lua seeded before this migration named Setup > Monitors as the way to nwg-displays,
# which only the app launcher's Displays Settings starts, and the first port's copy also said
# "Lines above it win." about monitors-gui.lua, which monitors.lua loads last: Hyprland keeps the
# last rule per monitor, so nwg-displays' rule replaces a rule above it for the same monitor.
# Only those two comment lines change.
monitors_lua="$HOME/.config/hypr/monitors.lua"
old_menu='^-- Layout saved by nwg-displays \(Setup > Monitors in the menu\): it writes$'
old_order='^-- ~/\.config/hypr/monitors-gui\.lua, loaded here when it exists\. Lines above it win\.$'
if [[ -f $monitors_lua ]] && grep -qE "$old_menu|$old_order" "$monitors_lua"; then
  sed -i -E \
    -e "s|$old_menu|-- Layout saved by nwg-displays (Displays Settings in the app launcher): it writes|" \
    -e "s|$old_order|-- ~/.config/hypr/monitors-gui.lua, loaded here when it exists. Loaded last, its rule for a\\
-- monitor replaces a rule above for the same monitor: Hyprland keeps the last rule per name.|" \
    "$monitors_lua"
fi
