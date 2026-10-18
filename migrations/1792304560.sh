echo "Hide the NVIDIA X Server Settings launcher, whose settings do not apply to the Wayland session"

# New users get the hidden launcher from omarchy-refresh-applications, which copies
# applications/*.desktop into ~/.local/share/applications; existing users get the one file.
if [[ -f $OMARCHY_PATH/applications/nvidia-settings.desktop ]]; then
  mkdir -p ~/.local/share/applications
  cp "$OMARCHY_PATH/applications/nvidia-settings.desktop" ~/.local/share/applications/
  update-desktop-database ~/.local/share/applications 2>/dev/null || true
fi
