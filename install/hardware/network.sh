# Ubuntu enables NetworkManager when the network-manager package is installed,
# so nothing enables it here. iwd would compete with wpa_supplicant for Wi-Fi.
systemctl disable iwd.service 2>/dev/null || true

# Prevent systemd-networkd-wait-online timeout on boot.
systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true
