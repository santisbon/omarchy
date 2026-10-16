# Detect MacBook models that need SPI keyboard modules
#
# Omarchy installs macbook12-spi-driver-dkms and lists the modules in a
# mkinitcpio drop-in. Ubuntu's kernel has applespi and the SPI modules built in
# as signed modules (a DKMS module would need a MOK under Secure Boot), and
# builds the initramfs with initramfs-tools, so the list goes into a hook in
# /etc/initramfs-tools/hooks that force-loads each module at boot, for the
# keyboard at the disk encryption passphrase prompt. The installer rebuilds the
# initramfs after this step.
product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
if [[ $product_name =~ MacBook[89],1|MacBook1[02],1|MacBookPro13,[123]|MacBookPro14,[123] ]]; then
  echo "Detected MacBook with SPI keyboard"

  if [[ $product_name == "MacBook8,1" ]]; then
    modules="applespi spi_pxa2xx_platform spi_pxa2xx_pci"
  else
    modules="applespi intel_lpss_pci spi_pxa2xx_platform"
  fi
  mkdir -p /etc/initramfs-tools/hooks
  cat > /etc/initramfs-tools/hooks/omarchy-macbook-spi-keyboard <<HOOK
#!/bin/sh
# MacBook SPI keyboard modules for the disk encryption passphrase prompt (install/hardware/apple/fix-spi-keyboard.sh)
case "\$1" in prereqs) exit 0 ;; esac
. /usr/share/initramfs-tools/hook-functions
for module in $modules; do
  force_load "\$module"
done
HOOK
  chmod 0755 /etc/initramfs-tools/hooks/omarchy-macbook-spi-keyboard
fi
