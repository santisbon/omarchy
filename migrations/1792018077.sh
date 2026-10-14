echo "Add the tldr client's configuration"

# tldr is preinstalled again, as Ubuntu's tealdeer package (a Rust client that installs the same
# tldr command as Omarchy's Python client). New users get ~/.config/tealdeer/config.toml from
# /etc/skel, which turns on downloading the pages on first use; this copies it for users who
# existed before. A user's own configuration is left alone.
src="$OMARCHY_PATH/config/tealdeer/config.toml"
dest="$HOME/.config/tealdeer/config.toml"
if [[ -f $src && ! -e $dest ]]; then
  mkdir -p "${dest%/*}"
  cp "$src" "$dest"
fi
