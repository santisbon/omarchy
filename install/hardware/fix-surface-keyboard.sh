# Detect Surface devices which require additional modules for the keyboard to work.
# Module list derived from Chris McLeod's manual install instructions
# https://chrismcleod.dev/blog/installing-arch-linux-with-secure-boot-on-a-microsoft-surface-laptop-studio/
#
# The keyboard has to work at the disk encryption passphrase prompt, which runs
# from the initramfs. Omarchy lists ten modules in a mkinitcpio drop-in because
# mkinitcpio leaves out what it is not told to include. Ubuntu builds the
# initramfs with initramfs-tools and MODULES=most, which already carries nine
# of them (surface_aggregator, its registry, surface_hid_core, surface_hid,
# surface_kbd, intel_lpss_pci, 8250_dw and the pinctrl modules; read from the
# image's initramfs on 2026-10-16) and loads them through udev. The one it
# lacks is surface_aggregator_hub, so a hook in /etc/initramfs-tools/hooks
# adds that module and loads it at boot. The installer rebuilds the initramfs
# after this step.
if omarchy-hw-surface; then
  echo "Detected Surface Device"
  mkdir -p /etc/initramfs-tools/hooks
  cat > /etc/initramfs-tools/hooks/omarchy-surface-keyboard <<'HOOK'
#!/bin/sh
# Surface keyboard module for the disk encryption passphrase prompt (install/hardware/fix-surface-keyboard.sh)
case "$1" in prereqs) exit 0 ;; esac
. /usr/share/initramfs-tools/hook-functions
force_load surface_aggregator_hub
HOOK
  chmod 0755 /etc/initramfs-tools/hooks/omarchy-surface-keyboard
fi
