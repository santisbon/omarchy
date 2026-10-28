# Other Packages

Arch has an amazing wealth of packages available for almost any type of software between the official repository and the Arch User Repository (AUR).

> **Oaxaca: works differently.** Oaxaca is built on Ubuntu 26.10 and installs software with apt from Ubuntu's archive, not with pacman from Arch's repositories.

It couldn't be easier to use either. You install a new Arch package by going to _Install > Package_ in the Omarchy menu (`Super + Space`) and typing the package you want. It'll automatically fuzzy filter the list of all packages. (You can also do it manually using `omarchy pkg add [package]` in the terminal).

> **Oaxaca: works differently.** _Install > Package_ lists the packages in Ubuntu's archive and in any apt repository added from the menu, and installs the ones you pick with apt. `oaxaca pkg add` installs Ubuntu packages too, and translates the Arch package names that plugins written for Omarchy ask for into Ubuntu's names.

You can do the same with AUR, just use _Install > AUR_. Just remember that the AUR isn't vetted by the Arch team. It's like RubyGems or npm. Anyone can upload.

> **Oaxaca: removed.** The AUR is Arch's, so _Install > AUR_ is gone. `oaxaca-pkg-aur-add` and `oaxaca-pkg-aur-install` remain only as stand-ins that say the system uses apt and change nothing, so that plugins written for Omarchy that call them fail clearly.

> **Oaxaca: added.** The Snap Store and Flathub are both preconfigured. _Install > Snap_ searches the Snap Store and _Install > Flatpak_ lists Flathub's applications; _Remove > Snap_ and _Remove > Flatpak_ remove what those entries installed.

If you want to remove a package, you can use _Remove > Package_ from the Omarchy menu. It'll remove package, config files, and dependencies. (You can also do it manually using `omarchy pkg drop [package]`).

> **Oaxaca: works differently.** _Remove > Package_ lists only the packages installed by name (`apt-mark showmanual`), and removes the ones you pick with `apt-get purge --autoremove`, which also deletes their configuration files and the dependencies apt installed only for them. `oaxaca pkg drop` removes packages the same way.
