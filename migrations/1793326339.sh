echo "Tell users of VS Code's .deb how to switch to the snap, whose extension installs work"

# Microsoft's .deb fails every signed extension install on Ubuntu 26.10: its signature verifier,
# vsce-sign, finds OpenSSL only as libssl.so.3 or older, and the system has OpenSSL 4. The
# installer now installs Microsoft's snap and removes the .deb and its apt repository, which
# needs sudo, so this only prints the command. Settings and extensions carry over.
if omarchy-pkg-present code && ! omarchy-pkg-snap-present code; then
  echo "VS Code can't install extensions on this system, because its signature check needs an older OpenSSL."
  echo "Switch to Microsoft's VS Code snap, which keeps your settings and extensions, with:"
  echo "  omarchy-install-editor-vscode"
fi
