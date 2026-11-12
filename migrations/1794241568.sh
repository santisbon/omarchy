echo "Replace the old placeholder logos in the About and screensaver branding with the distro's artwork"

# A user's ~/.config/omarchy/branding/about.txt (fastfetch's and About's logo) and screensaver.txt
# (the screensaver's text art) are copied from /etc/skel when the user is created, and nothing
# updates them afterwards, so a user created before the distro's artwork keeps the artwork the
# desktop package shipped then. Each file that is byte for byte one of the earlier shipped versions
# is replaced with the current one: about.txt with $OMARCHY_PATH/icon.txt, screensaver.txt with
# $OMARCHY_PATH/logo.txt, as `omarchy-branding-about reset` and `omarchy-branding-screensaver reset`
# do. A file the user set or edited (`omarchy-branding-about image|text`) matches none and stays.
#
# The SHA-256 hashes of the earlier versions, from the build repository (santisbon/oaxaca),
# packages/desktop/debian/extra/: the placeholders of its first commit, 0d3514e (a box around the
# distro's name), and the artwork of its choice 104, edd21fd (a fret and wordmark lockup).
old_about=(
  2b7af0e9757886f4c35134563841ad8b33dceaf9124c487ace0fc27c8b6b05a5
  bf69486855d653e98949fc3a8ebb1e99ff62e55678b6bed40e5b527f352591b8
)
old_screensaver=(
  589a9abe1a08aef1dc47205ccd9ec3c3be2a37d5edb9abd21f5c2338aa1b83d1
  661ff0e7acd933bff56581b5db2badf32454bdff0d01b072e8d5b9906fcebd9c
)

replace_if_old() {
  local file=$1 current=$2 hash old
  shift 2
  [[ -f $file && -f $current ]] || return 0
  hash=$(sha256sum "$file" | cut -d' ' -f1)
  for old in "$@"; do
    if [[ $hash == "$old" ]]; then
      cp "$current" "$file"
      return 0
    fi
  done
}

replace_if_old "$HOME/.config/omarchy/branding/about.txt" "$OMARCHY_PATH/icon.txt" "${old_about[@]}"
replace_if_old "$HOME/.config/omarchy/branding/screensaver.txt" "$OMARCHY_PATH/logo.txt" "${old_screensaver[@]}"
