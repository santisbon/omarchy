echo "Remove the AirPods plugin's launcher entry, whose window its AppArmor profile keeps from starting"

# The AirPods plugin's setup installed librepods' launcher entry, OpenPods. The daemon's AppArmor
# profile attaches by path to every process started from ~/.local/bin/librepods and denies the
# Wayland socket and fonts, so the window that entry starts aborts in Qt before it opens. The
# plugin no longer installs the entry; this deletes the copy installed before, only while the
# profile is installed and only when the copy still matches the plugin's own file.
plugin_id="io.github.thisisgm.omapods"
entry="$HOME/.local/share/applications/me.kavishdevar.librepods.desktop"
shipped="$HOME/.config/omarchy/plugins/$plugin_id/daemon/assets/me.kavishdevar.librepods.desktop"
if [[ -f /etc/apparmor.d/librepods && -f $entry && ! -L $entry ]] && cmp -s "$shipped" "$entry"; then
  rm "$entry"
fi
