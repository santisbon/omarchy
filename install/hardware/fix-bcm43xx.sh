# Wi-Fi firmware for the Broadcom BCM4331 found in 2012 and early 2013 MacBooks.
#
# Omarchy installs broadcom-wl-dkms for the BCM4331 and the BCM4360. A DKMS
# module needs a Machine Owner Key under Secure Boot, which this distro never
# asks for, so the BCM4360 (14e4:43a0, 2013-2015 MacBooks) is left out. The
# BCM4331 has an in-kernel driver, b43, which needs only its firmware:
# firmware-b43-installer downloads it from the vendor's driver, because the
# firmware itself cannot be redistributed.

pci_info=$(lspci -nn)

if echo "$pci_info" | grep -q "14e4:4331"; then
  echo "BCM4331 detected"
  omarchy-pkg-add firmware-b43-installer
fi
