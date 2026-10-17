# Enable services only. Installs are followed by reboot, so don't start/reload
# daemons mid-install. Hardware-gated services stay in their own scripts. ufw is
# turned on by firewall.sh, which runs after this script.
#
# Ubuntu enables a package's units when the package is installed, so most of
# these are already on. The repeats are harmless and keep the list explicit.
# Unit names were checked in the stonking Contents index under
# usr/lib/systemd/system/: cups.service (cups-daemon), avahi-daemon.service
# (avahi-daemon), power-profiles-daemon.service
# (power-profiles-daemon), sddm.service (sddm), bluetooth.service (bluez),
# systemd-oomd.service (systemd-oomd), NetworkManager-wait-online.service
# (network-manager).
systemctl enable cups.service
systemctl enable avahi-daemon.service
# Omarchy masks NetworkManager-wait-online.service here, so network-online.target
# does not hold up boot. The port keeps Ubuntu's setup instead: network-manager's
# postinst enables the unit (the distro's docs/6, "Ubuntu's configuration").
systemctl enable power-profiles-daemon.service
systemctl enable sddm.service
systemctl enable bluetooth.service
# Kill one runaway app scope instead of letting reclaim thrashing take the
# whole session down. [Install] pulls in systemd-oomd.socket via Also=, which
# is what the user manager reports app.slice candidacy over.
systemctl enable systemd-oomd.service
