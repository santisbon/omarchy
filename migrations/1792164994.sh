echo "Seed btop, lazygit and starship's configurations and link btop to the current theme"

# btop, lazygit and starship are preinstalled again, with Omarchy's configurations in /etc/skel
# for new users. This copies each configuration for users who existed before, only where the
# user has none, and links btop's "current" theme to the theme omarchy-theme-set renders, as
# install/user/theme.sh does for a new user.
for rel in btop/btop.conf lazygit/config.yml starship.toml; do
  if [[ ! -e $HOME/.config/$rel && -f $OMARCHY_PATH/config/$rel ]]; then
    mkdir -p "$(dirname "$HOME/.config/$rel")"
    cp "$OMARCHY_PATH/config/$rel" "$HOME/.config/$rel"
  fi
done

mkdir -p ~/.config/btop/themes
if [[ -L ~/.config/btop/themes/current.theme || ! -e ~/.config/btop/themes/current.theme ]]; then
  ln -snf "$HOME/.local/state/omarchy/current/theme/btop.theme" ~/.config/btop/themes/current.theme
fi
