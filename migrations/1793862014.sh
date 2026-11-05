echo "Move your keyboard layouts to the file the new Setup > Keyboard reads"

# Setup > Keyboard saved to ~/.config/hypr/keyboard-gui.conf before Omarchy v4.5.0's picker
# replaced it. The new file holds layouts and variants only, so a switching key saved in the old
# file's XKBOPTIONS stops applying; the bar's layout widget switches layouts.
old="$HOME/.config/hypr/keyboard-gui.conf"
new="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/keyboard-layouts"

[[ -f $old ]] || exit 0

if [[ ! -e $new ]]; then
  value() { sed -n "s/^[[:space:]]*$1=//p" "$old" | tail -1 | tr -d "\"'"; }
  layouts=$(value XKBLAYOUT)
  if [[ -n $layouts ]]; then
    mkdir -p "${new%/*}"
    printf 'XKBLAYOUT=%s\nXKBVARIANT=%s\n' "$layouts" "$(value XKBVARIANT)" >"$new"
  fi
fi

rm -f "$old"
hyprctl reload >/dev/null 2>&1 || true
