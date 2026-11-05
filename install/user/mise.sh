# mise is not part of the distro's base install. Without it there is nothing
# to configure, and every omarchy-mise-install below would fail.
if omarchy-cmd-missing mise; then
  exit 0
fi

# Build the lazy shims for Omarchy's default tools and the account dispatchers,
# both declared by /etc/mise/conf.d, without resolving versions over the network.
MISE_OFFLINE=true mise reshim --system
MISE_OFFLINE=true mise reshim
