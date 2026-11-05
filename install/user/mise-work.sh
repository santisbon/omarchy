# mise is preinstalled (the distro's docs/6, choice 69) but can be removed. The Node.js install
# below needs it, and the Work directory goes with it, so skip the whole file without mise.
if omarchy-cmd-missing mise; then
  exit 0
fi

# Setup default work directory (and tries)
mkdir -p "$HOME/Work"
mkdir -p "$HOME/Work/tries"
