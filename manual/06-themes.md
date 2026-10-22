# Themes

Omarchy comes with twenty-two beautiful themes. You can select between them via _Style > Theme_ in the Omarchy Menu (`Super + Space`) or hop directly to the theme selector using `Super + Ctrl + Shift + Space`.

Each theme styles the desktop, terminal, neovim, activity screen (btop), Chromium, and the entire Omarchy shell: top bar, menu, notifications, OSD, and the lock screen. (For Obsidian, you must manually select the Omarchy theme via _Appearance > Themes_ inside the app).

> **Oaxaca: works differently.** Neovim is preinstalled without Omarchy's LazyVim configuration, and that configuration is what loads a theme's `neovim.lua` (a plugin list for lazy.nvim, the plugin manager LazyVim runs on), so a theme change does not restyle Neovim (the distro's docs/6, choices 26 and 71).

> **Oaxaca: works differently.** Obsidian is not preinstalled: Install > Productivity > Obsidian installs its snap, and a theme change then themes it as above (the distro's docs/6, choices 71 and 97).

Themes have a set of background images that you can pick between using `Super + Ctrl + Space`.

You can find even more themes on [the extra themes page](https://omarchy.org/themes/) or even [make your own theme](43-making-your-own-theme.md).

> **Oaxaca: added.** Install > Style > Theme scans a theme's repository for Arch Linux's package tools (`pacman`, `yay`, `paru`, `makepkg`) and, when it finds any, shows the matching lines and asks "Install it anyway?" with no as the default, since such a theme may call tools Oaxaca does not have (the distro's docs/6, choice 86).

 ![tokyo-night](../themes/tokyo-night/preview.png)
_Tokyo Night_

 ![catppuccin](../themes/catppuccin/preview.png)
_Catppuccin_

 ![lumon](../themes/lumon/preview.png)
_Lumon_

 ![ethereal](../themes/ethereal/preview.png)
_Ethereal_

 ![everforest](../themes/everforest/preview.png)
_Everforest_

 ![gruvbox](../themes/gruvbox/preview.png)
_Gruvbox_

 ![miasma](../themes/miasma/preview.png)
_Miasma_

 ![hackerman](../themes/hackerman/preview.png)
_Hackerman_

 ![osaka-jade](../themes/osaka-jade/preview.png)
_Osaka Jade_

 ![kanagawa](../themes/kanagawa/preview.png)
_Kanagawa_

 ![nord](../themes/nord/preview.png)
_Nord_

 ![matte-black](../themes/matte-black/preview.png)
_Matte Black_

 ![vantablack](../themes/vantablack/preview.png)
_Vantablack_

 ![ristretto](../themes/ristretto/preview.png)
_Ristretto_

 ![retro-82](../themes/retro-82/preview.png)
_Retro 82_

 ![flexoki-light](../themes/flexoki-light/preview.png)
_Flexoki Light_

 ![rose-pine](../themes/rose-pine/preview.png)
_Rose Pine_

 ![catppuccin-latte](../themes/catppuccin-latte/preview.png)
_Catppuccin Latte_

 ![white](../themes/white/preview.png)
_White_

### Unlocks

Themes can also have a custom unlock design, which is used for the boot decryption process. You can select one of these under _Style > Unlock_. They look like this:

> **Oaxaca: works differently.** Style > Unlock selects the boot splash theme (Plymouth's) through Ubuntu's `update-alternatives` on `default.plymouth` and rebuilds the initramfs with `update-initramfs -u`, where Omarchy runs `plymouth-set-default-theme` and mkinitcpio or Limine's `limine-mkinitcpio` (the distro's docs/7, section "Plymouth").

 ![catppuccin](../themes/catppuccin/preview-unlock.png)
_Catppuccin_

 ![catppuccin-latte](../themes/catppuccin-latte/preview-unlock.png)
_Catppuccin Latte_

 ![ethereal](../themes/ethereal/preview-unlock.png)
_Ethereal_

 ![everforest](../themes/everforest/preview-unlock.png)
_Everforest_

 ![flexoki-light](../themes/flexoki-light/preview-unlock.png)
_Flexoki Light_

 ![gruvbox](../themes/gruvbox/preview-unlock.png)
_Gruvbox_

 ![hackerman](../themes/hackerman/preview-unlock.png)
_Hackerman_

 ![kanagawa](../themes/kanagawa/preview-unlock.png)
_Kanagawa_

 ![lumon](../themes/lumon/preview-unlock.png)
_Lumon_

 ![matte-black](../themes/matte-black/preview-unlock.png)
_Matte Black_

![miasma](../themes/miasma/preview-unlock.png)
_Miasma_

 ![nord](../themes/nord/preview-unlock.png)
_Nord_

 ![osaka-jade](../themes/osaka-jade/preview-unlock.png)
_Osaka Jade_

 ![retro-82](../themes/retro-82/preview-unlock.png)
_Retro 82_

 ![ristretto](../themes/ristretto/preview-unlock.png)
_Ristretto_

![rose-pine](../themes/rose-pine/preview-unlock.png)
_Rose Pine_

 ![tokyo-night](../themes/tokyo-night/preview-unlock.png)
_Tokyo Night_

 ![vantablack](../themes/vantablack/preview-unlock.png)
_Vantablack_

 ![white](../themes/white/preview-unlock.png)
_White_
