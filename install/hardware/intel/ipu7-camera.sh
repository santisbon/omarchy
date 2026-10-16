# Install MIPI camera support for Intel IPU7 hardware
#
# Omarchy installs its intel-ipu7-camera stack (Intel's camera HAL with DKMS
# modules). Ubuntu's signed kernel already carries the IPU7 drivers, the
# OV08X40 sensor driver and the firmware, so no DKMS is needed; the user-space
# side is libcamera, whose simple pipeline supports intel-ipu7 with a software
# ISP, plus its GStreamer element and PipeWire plugin so apps and browsers
# (through the camera portal) see the camera.

if grep -q "OVTI08F4" /sys/bus/acpi/devices/*/hid 2>/dev/null; then
  omarchy-pkg-add libcamera0.7 libcamera-ipa gstreamer1.0-libcamera libspa-0.2-libcamera
fi
