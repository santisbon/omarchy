echo "Tell VS Code users how to get the .deb's fixes for extension installs and start-up"

# Install > Editor > VSCode installs Microsoft's .deb with libssl3t64, without which no signed
# extension installs (vsce-sign finds no OpenSSL older than 4), and loads apparmor's VS Code
# profile, without which VS Code crashes at start. Installing a package needs sudo, which a
# migration cannot do, so this only prints the command: for a .deb without libssl3t64, and for
# the snap the menu installed for two releases.
if omarchy-pkg-present code && omarchy-pkg-missing libssl3t64; then
  echo "VS Code can't install extensions on this system, because its signature check needs OpenSSL 3."
  echo "Add it, and make sure VS Code's AppArmor profile is loaded, with:"
  echo "  omarchy-install-editor-vscode"
elif omarchy-pkg-snap-present code && omarchy-pkg-missing code; then
  echo "Install > Editor > VSCode installs Microsoft's .deb again, instead of the snap."
  echo "Switch back to the .deb, which keeps your settings and extensions, with:"
  echo "  omarchy-install-editor-vscode"
fi
