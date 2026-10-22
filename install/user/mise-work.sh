# mise is preinstalled (the distro's docs/6, choice 69) but can be removed. The Node.js install
# below needs it, and the Work directory goes with it, so skip the whole file without mise.
if omarchy-cmd-missing mise; then
  exit 0
fi

# Setup default work directory (and tries)
mkdir -p "$HOME/Work"
mkdir -p "$HOME/Work/tries"

# Offline installs unpack a Node tarball bundled under /opt/packages in the
# image build chroot. Omarchy's first-boot provisioning context is gone with
# omarchy-provision-owner, so the chroot is the only offline source left.
case ${OMARCHY_SETUP_CONTEXT:-runtime} in
  iso-chroot) NODE_PACKAGE_DIR=/opt/packages ;;
  *) NODE_PACKAGE_DIR="" ;;
esac

if [[ -n $NODE_PACKAGE_DIR ]]; then
  NODE_TARBALL=$(find "$NODE_PACKAGE_DIR" -name "node-v*-linux-x64.tar.gz" -type f 2>/dev/null | head -n1)
  if [[ -z $NODE_TARBALL ]]; then
    echo "Error: bundled Node.js tarball missing from $NODE_PACKAGE_DIR" >&2
    exit 1
  else
    NODE_VERSION=$(basename "$NODE_TARBALL" | sed 's/node-v\(.*\)-linux-x64.tar.gz/\1/')
    NODE_INSTALL_DIR="$HOME/.local/share/mise/installs/node/$NODE_VERSION"

    mkdir -p "$NODE_INSTALL_DIR"
    tar -xzf "$NODE_TARBALL" --strip-components=1 -C "$NODE_INSTALL_DIR"
    mise use -g node@"$NODE_VERSION"
  fi
else
  # mise downloads Node.js, and a new user's first login usually comes before Wi-Fi is set up.
  # A failure here would stop the rest of the user's setup (mise.sh's tool stubs, the default
  # browser, the finalize-user marker), which needs no network; Node.js can come later.
  if ! mise use -g node@latest; then
    echo "Node.js was not installed (no network?); install it later with: mise use -g node@latest" >&2
  fi
fi
