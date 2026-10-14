echo "Make Papers the document viewer"

# Papers replaces Evince as the document viewer and the PDF default. The system's mimeapps.list
# names Papers now; a user's own list that still names Evince, which is not installed, would
# keep PDFs from opening, so that line is pointed at Papers. A user who installed Evince keeps it.
list="$HOME/.config/mimeapps.list"
if [[ -f $list ]] && ! omarchy-cmd-present evince; then
  sed -i 's/^application\/pdf=org\.gnome\.Evince\.desktop;\?$/application\/pdf=org.gnome.Papers.desktop/' "$list"
fi
