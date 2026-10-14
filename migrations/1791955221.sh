echo "Add Files' \"Send via LocalSend\" extension and Chromium's Download Video host"

# LocalSend is back in the desktop's package list. New users get the extension from /etc/skel;
# this copies it for users who existed before. The extension offers its menu item only when a
# localsend command or LocalSend's Flatpak is installed. A user's own copy is left alone.
src="$OMARCHY_PATH/default/nautilus-python/extensions/localsend.py"
dest="$HOME/.local/share/nautilus-python/extensions/localsend.py"
if [[ -f $src && ! -e $dest ]]; then
  mkdir -p "${dest%/*}"
  cp "$src" "$dest"
fi

# yt-dlp is back in the desktop's package list, with the native messaging host the Download
# Video extension calls. A Chromium installed before this got the copy-url host only;
# install/user/chromium.sh and the browser installer register both from now on.
if omarchy-cmd-present chromium; then
  omarchy-install-chromium-ytdlp
fi
