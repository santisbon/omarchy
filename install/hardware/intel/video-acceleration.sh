# This installs hardware video acceleration for Intel GPUs.
#
# Ubuntu's image already carries the VA-API driver for current Intel GPUs
# (intel-media-va-driver-non-free, Omarchy's intel-media-driver) and the oneVPL
# dispatcher (libvpl2, Omarchy's libvpl). What it lacks is the Quick Sync
# runtime the dispatcher loads for encoding (libmfx-gen1.2, Omarchy's
# vpl-gpu-rt; universe) and, for GMA-era GPUs from about 2008 to 2017, the older
# VA-API driver (i965-va-driver, Omarchy's libva-intel-driver; universe).

if INTEL_GPU=$(lspci | grep -iE 'vga|3d|display' | grep -i 'intel'); then
  # HD Graphics / Iris / Xe / Arc / Non-Arc Panther Lake use intel-media-driver + VPL
  if [[ ${INTEL_GPU,,} =~ (hd\ graphics|uhd\ graphics|xe|iris|arc|panther\ lake) ]]; then
    omarchy-pkg-add intel-media-va-driver-non-free libvpl2 libmfx-gen1.2
  elif [[ ${INTEL_GPU,,} =~ "gma" ]]; then
    # Older generations from 2008 to ~2014-2017 use libva-intel-driver
    omarchy-pkg-add i965-va-driver
  fi
fi
