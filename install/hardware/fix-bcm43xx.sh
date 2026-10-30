# Wi-Fi for the Broadcom chips in 2012 to 2015 Macs.
#
# Omarchy installs broadcom-wl-dkms for the BCM4331 and the BCM4360. The BCM4331
# (14e4:4331, 2012 and early 2013 MacBooks) has an in-kernel driver, b43, which
# needs only its firmware: firmware-b43-installer downloads it from the vendor's
# driver, because the firmware itself cannot be redistributed.
#
# The BCM4360 (14e4:43a0, 2013 to 2015 Macs) has no in-kernel driver; its only
# driver is Broadcom's wl, which broadcom-sta-dkms builds on the machine with
# DKMS. Under Secure Boot the kernel loads such a module only when it is signed
# with a Machine Owner Key, which this distro never asks for, so wl is installed
# only on an Apple machine whose firmware is not enforcing Secure Boot. These
# Macs predate the T2 chip, and their firmware has no UEFI Secure Boot at all.
# The package's /etc/modprobe.d/broadcom-sta-dkms.conf blacklists b43, bcma and
# ssb, which otherwise claim the chip, and wl loads by its PCI alias.

pci_info=$(lspci -nn)
sys_vendor="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"

if echo "$pci_info" | grep -q "14e4:4331"; then
  echo "BCM4331 detected"
  omarchy-pkg-add firmware-b43-installer
fi

if [[ $sys_vendor == Apple* ]] && echo "$pci_info" | grep -q "14e4:43a0"; then
  if mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
    echo "BCM4360 detected, but Secure Boot is enabled: its DKMS driver would not load, so it is not installed"
  else
    echo "BCM4360 detected"
    omarchy-pkg-add broadcom-sta-dkms
  fi
fi
