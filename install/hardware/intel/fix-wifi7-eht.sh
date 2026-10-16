# Temporary fix for Dell XPS 14/16 on Panther Lake
# Disable WiFi 7 (EHT/802.11be) on Intel BE200/BE211 cards
# The iwlwifi driver has a broken EHT RX data path — APs drop to MCS 0 NSS 1
# when EHT is negotiated, making WiFi unusable. Disabling EHT falls
# back to WiFi 6 (HE/802.11ax) which works at full speed.
# This should be removed when Intel fixes the firmware/driver.
#
# Omarchy matches the card alone, which turns Wi-Fi 7 off on every machine with
# a BE200 or BE211. The port also requires the machines the fix is for, a Dell
# XPS on Panther Lake (docs/6, choice 60): other BE200 machines, such as the
# Lenovo Legion Pro 7, keep Wi-Fi 7.

if omarchy-hw-match "XPS" && omarchy-hw-intel-ptl && lspci -nn | grep -qE '\[8086:(e440|272b)\]'; then
  mkdir -p /etc/modprobe.d
  cat > /etc/modprobe.d/iwlwifi-disable-eht.conf <<'EOF'
# Temporary fix Dell XPS 14/16 on Panther lake
# Disable WiFi 7 (EHT) on Intel BE200/BE211 — broken RX rate adaptation
# Remove this file when fixes land in the iwlwifi EHT data path
options iwlwifi disable_11be=Y
EOF
fi
