echo "Shorten the LibreOffice snap's launcher names"

# Install > Productivity > LibreOffice now writes per-user launchers named "Writer", "Calc" and
# so on, since the snap's own names ("LibreOffice 26.2 Writer") were cut off in the launcher.
# This does the same for a LibreOffice snap installed before.
if [[ -n $(compgen -G "/var/lib/snapd/desktop/applications/libreoffice_*.desktop") ]]; then
  omarchy-libreoffice-snap-launchers
fi
