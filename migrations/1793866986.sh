echo "Turn on hardware video decoding in mpv"

# Omarchy sets this in /etc/mpv/mpv.conf, a file Ubuntu's mpv package owns, so here it is the
# user's file. A file the user already has is left alone.
config="${XDG_CONFIG_HOME:-$HOME/.config}/mpv/mpv.conf"
[[ -e $config ]] && exit 0
mkdir -p "${config%/*}"
cp "$OMARCHY_PATH/config/mpv/mpv.conf" "$config"
