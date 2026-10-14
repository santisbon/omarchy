echo "Remove HEY as the email link handler"

# HEY and Basecamp are gone from the catalogue, and the port never shipped HEY's web app, so the
# mailto handler omarchy-provision-user set (HEY.desktop) named a launcher that does not exist:
# email links opened nothing. Drop that line from the user's own defaults unless the user made a
# HEY web app of their own; the system's mimeapps.list no longer names a mailto handler.
list="$HOME/.config/mimeapps.list"
if [[ -f $list && ! -e $HOME/.local/share/applications/HEY.desktop ]]; then
  sed -i '/^x-scheme-handler\/mailto=HEY\.desktop;\?$/d' "$list"
fi
