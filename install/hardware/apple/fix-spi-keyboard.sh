# Detect MacBook models that need SPI keyboard modules
#
# The keyboard has to work at the disk encryption passphrase prompt, which runs
# from the initramfs. Omarchy installs macbook12-spi-driver-dkms and lists the
# modules in a mkinitcpio drop-in for 2015 to 2017 MacBooks and MacBook Pros.
# Ubuntu's kernel has the driver as signed modules (no DKMS), and its
# initramfs-tools build with MODULES=most already carries applespi,
# spi_pxa2xx_platform and intel_lpss_pci (read from the image's initramfs on
# 2026-10-16). The one module on Omarchy's lists it lacks is spi_pxa2xx_pci,
# which Omarchy adds for the MacBook8,1 only, so only that model gets a hook in
# /etc/initramfs-tools/hooks that adds it and loads it at boot. The installer
# rebuilds the initramfs after this step.
product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
if [[ $product_name == "MacBook8,1" ]]; then
  echo "Detected MacBook8,1, whose SPI keyboard needs spi_pxa2xx_pci in the initramfs"
  mkdir -p /etc/initramfs-tools/hooks
  cat > /etc/initramfs-tools/hooks/omarchy-macbook-spi-keyboard <<'HOOK'
#!/bin/sh
# MacBook8,1 SPI keyboard module for the disk encryption passphrase prompt (install/hardware/apple/fix-spi-keyboard.sh)
case "$1" in prereqs) exit 0 ;; esac
. /usr/share/initramfs-tools/hook-functions
force_load spi_pxa2xx_pci
HOOK
  chmod 0755 /etc/initramfs-tools/hooks/omarchy-macbook-spi-keyboard
fi
