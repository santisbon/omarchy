run_logged "$OMARCHY_INSTALL/hardware/network.sh"
run_logged "$OMARCHY_INSTALL/hardware/fix-fkeys.sh"
run_logged "$OMARCHY_INSTALL/hardware/fix-synaptic-touchpad.sh"
run_logged "$OMARCHY_INSTALL/hardware/bluetooth.sh"

run_logged "$OMARCHY_INSTALL/hardware/intel/lpmd.sh"
run_logged "$OMARCHY_INSTALL/hardware/intel/thermald.sh"
run_logged "$OMARCHY_INSTALL/hardware/intel/fix-wifi7-eht.sh"
run_logged "$OMARCHY_INSTALL/hardware/intel/sof-firmware.sh"

run_logged "$OMARCHY_INSTALL/hardware/asus/fix-asus-ptl-b9406-touchpad.sh"
run_logged "$OMARCHY_INSTALL/hardware/asus/fix-z13-touchpad.sh"

run_logged "$OMARCHY_INSTALL/hardware/framework/qmk-hid.sh"

run_logged "$OMARCHY_INSTALL/hardware/apple/fix-suspend-nvme.sh"
run_logged "$OMARCHY_INSTALL/hardware/apple/fix-brcmfmac-supplicant.sh"

run_logged "$OMARCHY_INSTALL/hardware/lenovo/fix-yoga-pro7-bass-speakers.sh"

run_logged "$OMARCHY_INSTALL/hardware/speaker-tuning.sh"
