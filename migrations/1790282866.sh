echo "Apply the NVIDIA video driver fix on hybrid laptops"

# The port's session already keeps these drivers off on hybrid graphics whenever its GPU
# generator set OMARCHY_GPU_OFFLOAD=nvidia, so only a session without it needs the reboot.
if [[ ${OMARCHY_GPU_OFFLOAD:-} != "nvidia" ]] && omarchy-hw-nvidia && ! omarchy-hw-nvidia-display; then
  # Hyprland applies env at startup. Reloading the updated defaults cannot
  # clear the old overrides inherited by the compositor and its applications.
  omarchy-state set reboot-required
  echo "Reboot to stop forcing NVIDIA VA-API/GLX drivers on the integrated GPU."
fi
