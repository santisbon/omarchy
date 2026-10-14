echo "Add Omarchy's tmux configuration"

# tmux is back in the desktop's package list, with Omarchy's configuration, theme sync and
# bindings. New users get ~/.config/tmux/tmux.conf from /etc/skel; this copies it for users who
# existed before. A user's own configuration is left alone.
src="$OMARCHY_PATH/config/tmux/tmux.conf"
dest="$HOME/.config/tmux/tmux.conf"
if [[ -f $src && ! -e $dest && ! -e $HOME/.tmux.conf ]]; then
  mkdir -p "${dest%/*}"
  cp "$src" "$dest"
fi
