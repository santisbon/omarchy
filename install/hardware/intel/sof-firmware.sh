# Install Sound Open Firmware for Intel audio DSPs. The sof-audio-pci-intel-*
# driver family requires this firmware; without it PipeWire exposes only a
# Dummy Output sink. Ubuntu packages it as firmware-sof-signed (checked in the
# stonking main Packages index).

if omarchy-hw-intel-sof; then
  omarchy-pkg-add firmware-sof-signed
fi
