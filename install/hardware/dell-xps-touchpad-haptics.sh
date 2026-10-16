# Haptic feedback for the Synaptics touchpad of Dell XPS 14 and 16 laptops.
#
# Omarchy's package, built for this distro in its own apt repository
# (packages/dell-xps-touchpad-haptics in the distro's build repository), so the
# install fetches it from there; Hardware > Touchpad Haptics sets the preset.

if omarchy-hw-dell-xps-haptic-touchpad; then
  omarchy-pkg-add dell-xps-touchpad-haptics
fi
