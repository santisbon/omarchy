# Detect Surface devices which require additional modules for the keyboard to work.
# Module list derived from Chris McLeod's manual install instructions
# https://chrismcleod.dev/blog/installing-arch-linux-with-secure-boot-on-a-microsoft-surface-laptop-studio/
#
# The keyboard has to work at the disk encryption passphrase prompt, which runs
# from the initramfs. Omarchy lists the modules in a mkinitcpio drop-in; Ubuntu
# builds the initramfs with initramfs-tools, so the list goes into a hook in
# /etc/initramfs-tools/hooks that force-loads each module at boot. The
# installer rebuilds the initramfs after this step.
if omarchy-hw-surface; then
  product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
  echo "Detected Surface Device"

  # Modules already exist in the rootfs for the default kernel.
  if [[ $product_name != "Surface Laptop 3" ]]; then
    echo "Untested Surface Device: $product_name, additional modules may be required for your device."
  fi

  echo "Attempting to autodetect required pinctrl module"
  pinctrl_module=$(lsmod | grep pinctrl_ | cut -f 1 -d" " || true)
  if [[ -z $pinctrl_module ]]; then
    echo "Failed to autodetect pinctrl module."
  else
    echo "Detected pinctrl module: $pinctrl_module"
    mkdir -p /etc/initramfs-tools/hooks
    cat > /etc/initramfs-tools/hooks/omarchy-surface-keyboard <<HOOK
#!/bin/sh
# Surface keyboard modules for the disk encryption passphrase prompt (install/hardware/fix-surface-keyboard.sh)
case "\$1" in prereqs) exit 0 ;; esac
. /usr/share/initramfs-tools/hook-functions
for module in $(echo $pinctrl_module) surface_aggregator surface_aggregator_registry surface_aggregator_hub surface_hid_core surface_hid surface_kbd intel_lpss_pci 8250_dw; do
  force_load "\$module"
done
HOOK
    chmod 0755 /etc/initramfs-tools/hooks/omarchy-surface-keyboard
  fi
fi
