# Display fix for ASUS ExpertBook B9406 (Panther Lake / Xe3 iGPU).
#
# Panel Replay is Xe3-new, default-on in the xe driver, and has a broken
# exit/wake path on this eDP panel: the panel latches the last-presented
# frame in self-refresh and never wakes for subsequent atomic commits, so
# the screen only updates on a full modeset (e.g. a VT switch). The older
# xe.enable_psr=0 knob does not cover Panel Replay.
#
# Omarchy passes the option on the kernel command line through a Limine drop-in;
# here it goes to the module in /etc/modprobe.d, as in
# fix-asus-ptl-display-backlight.sh.

if omarchy-hw-asus-expertbook-b9406; then
  mkdir -p /etc/modprobe.d
  cat > /etc/modprobe.d/omarchy-asus-expertbook-b9406-display.conf <<'CONF'
# ASUS ExpertBook B9406 (Panther Lake / Xe3) display workaround (install/hardware/asus/fix-asus-ptl-b9406-display.sh)
options xe enable_panel_replay=0
CONF
fi
