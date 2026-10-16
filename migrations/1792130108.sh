echo "Give tmux extended keys in every xterm-type terminal, so Shift+Enter works inside tmux"

# tmux's configuration turned extended keys on only for Kitty ("xterm-kitty:extkeys"), so inside
# tmux in Foot, Alacritty or Ghostty, Shift+Enter arrived as a plain Enter. The shipped
# configuration now says "xterm*:extkeys". This changes the one line in a user's copy that still
# has the old value; a copy without that exact line is the user's own and is left alone.
conf="$HOME/.config/tmux/tmux.conf"
old='set -ag terminal-features "xterm-kitty:extkeys"'
new='set -ag terminal-features "xterm*:extkeys"'
if [[ -f $conf ]] && grep -qxF "$old" "$conf"; then
  sed -i "s/^set -ag terminal-features \"xterm-kitty:extkeys\"\$/set -ag terminal-features \"xterm*:extkeys\"/" "$conf"
  if [[ -n ${TMUX:-} ]] || tmux has-session 2>/dev/null; then
    tmux source-file "$conf" 2>/dev/null || true
  fi
fi
