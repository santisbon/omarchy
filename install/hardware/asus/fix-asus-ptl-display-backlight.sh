# Display backlight fix for ASUS Panther Lake / Xe3 iGPU laptops.
# Enabled only for ExpertBook B9406 and Zenbook UX5406AA for now.
# Other models need confirmation whether the issue exists there too.
#
# The panel's EDID on eDP-1 reads as empty, so xe takes backlight type from
# VBT (which says PWM) but the panel actually wants DPCD AUX backlight.
# Without xe.enable_dpcd_backlight=1, intel_backlight sysfs writes succeed
# but produce no visible change; brightness is effectively binary.
#
# Omarchy passes the option on the kernel command line through a Limine drop-in;
# this desktop boots with Ubuntu's GRUB, so the option goes to the module
# instead, in /etc/modprobe.d. The installer rebuilds the initramfs after this
# step, and initramfs-tools copies /etc/modprobe.d in, so the option also
# applies when xe loads from the initramfs.

if omarchy-hw-asus-expertbook-b9406 || omarchy-hw-asus-zenbook-ux5406aa; then
  mkdir -p /etc/modprobe.d
  cat > /etc/modprobe.d/omarchy-asus-ptl-display-backlight.conf <<'CONF'
# ASUS Panther Lake display backlight fix (install/hardware/asus/fix-asus-ptl-display-backlight.sh)
options xe enable_dpcd_backlight=1
CONF
fi
