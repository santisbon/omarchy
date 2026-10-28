echo "Tell AirPods users how to install the AirPods daemon's Bluetooth fix"

# The AirPods daemon kept Bluetooth discovery on while the AirPods were away, which kept bonded LE
# keyboards and mice from reconnecting after a restart, and its AppArmor profile kept it from
# PulseAudio. The fix is in the plugin's repository; installing it reloads the daemon's AppArmor
# profile with sudo, which a migration cannot do, so this only prints the command. The installed
# profile names RegisterMonitor once the fix is in, and then nothing is printed.
plugin_id="io.github.thisisgm.omapods"
if [[ -x $HOME/.config/omarchy/plugins/$plugin_id/setup ]] && ! grep -qs RegisterMonitor /etc/apparmor.d/librepods; then
  echo "The AirPods plugin has a fix: Bluetooth keyboards and mice reconnect within seconds after a restart,"
  echo "and the AirPods play at their best quality. Install it with:"
  echo "  omarchy plugin update $plugin_id --yes && ~/.config/omarchy/plugins/$plugin_id/setup"
fi
