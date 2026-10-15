echo "Add swappy's configuration: Ctrl+S saves an edited copy next to the screenshot"

# The screenshot editor, swappy, saved Ctrl+S's file in the home folder and also wrote the
# drawing over the screenshot when its window closed. New users get ~/.config/swappy/config
# from /etc/skel (save next to the screenshot as screenshot-<date>-edited.png, then close);
# this copies it for users who existed before. A user's own configuration is left alone.
src="$OMARCHY_PATH/config/swappy/config"
dest="$HOME/.config/swappy/config"
if [[ -f $src && ! -e $dest ]]; then
  mkdir -p "${dest%/*}"
  cp "$src" "$dest"
fi
