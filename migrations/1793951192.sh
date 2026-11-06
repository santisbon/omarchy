echo "Remove Voxtype, which this distro no longer offers for dictation"

if omarchy-pkg-present voxtype; then
  # The user's settings and models in ~/.config/voxtype and ~/.local/share/voxtype stay.
  systemctl --user disable --now voxtype.service 2>/dev/null || true
  rm -rf ~/.config/systemd/user/voxtype.service ~/.config/systemd/user/voxtype.service.d
  systemctl --user daemon-reload 2>/dev/null || true
  # A failure here must not stop the migrations after this one, and Voxtype left behind does no harm.
  omarchy-pkg-drop voxtype || echo "Could not remove Voxtype. Remove it with: sudo apt purge voxtype" >&2
  omarchy-notification-send -g  "Voxtype Was Removed" "Install Superwhisper from Install > AI > Dictation." -t 20000 2>/dev/null || true
fi

backend_config="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/defaults/dictation"
if [[ -f $backend_config && $(< "$backend_config") == "voxtype" ]]; then
  rm "$backend_config"
fi
omarchy-restart-hyprctl 2>/dev/null || true
