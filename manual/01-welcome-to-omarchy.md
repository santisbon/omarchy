# Welcome to Omarchy!

Omarchy is an [omakase](https://manuals.omamix.org/3/omacom/76/omakase-computing) Linux distribution based on [Arch](https://archlinux.org/), the tiling window manager [Hyprland](https://hypr.land/), and the desktop construction-kit [Quickshell](https://quickshell.org/). It ships with everything a modern, savvy computer user needs to be productive immediately. From [Neovim](https://neovim.io/) (btw) to Chromium, [Obsidian](https://obsidian.md/) to LibreOffice, and Kdenlive to OBS Studio. Hell, even a retro Winamp-style music player is there!

> **Oaxaca: works differently.** Oaxaca is built on Ubuntu 26.10 ("stonking") with apt for packages, instead of Arch Linux with pacman, and keeps Hyprland, Quickshell and Omarchy's shell, themes and fonts on top. Of the applications named above, Chromium and Neovim are preinstalled (Neovim without Omarchy's LazyVim configuration), while LibreOffice (Canonical's snap), Kdenlive and OBS Studio (both from Flathub) are installed on demand from Install > Productivity, and the Winamp-style player, cliamp, from Install > Service (the distro's docs/6, choices 26, 71, 80, 83 and 84).

> **Oaxaca: works differently.** Obsidian is not preinstalled: Install > Productivity > Obsidian installs Obsidian's own snap from the Snap Store (the distro's docs/6, choices 71 and 97).

> **Oaxaca: works differently.** On Oaxaca the commands are named `oaxaca-*` (with `oaxaca` as the command dispatcher), the user's folders are `~/.config/oaxaca`, `~/.local/state/oaxaca` and `~/.local/share/oaxaca`, and the menu calls itself the Oaxaca menu. Links under Omarchy's names (`omarchy-*`, `omarchy`, `~/.config/omarchy` and the other two folders) point to Oaxaca's, so the `omarchy` commands and paths this manual uses still work (the distro's docs/6, choice 86).

This isn't just a grab bag of preinstalled packages, though. It's a complete system designed with both aesthetics and productivity in mind. Because a _beautiful_ system is a _motivating_ system, and productivity has always been [downstream from motivation](https://world.hey.com/dhh/beautiful-motivations-6fef7c73). There's zero bloat here: Just everything I use.

It's true that developing an eye for the beauty of a TUI-heavy, theme-delighted, tiling-window-managed system like Omarchy can be an acquired taste. But that's why you're here, isn't it? To experience something a little outside of your comfort zone? To embark on a little bit of an adventure into a new way of working with computers? I hope so.

Omarchy isn't like Windows and it's not like macOS either. It's not trying to be as familiar as possible. It's trying to be beautiful and _better_. Embrace the Linux-ness of it all. Manually editing some config files, sure. Heavy on the terminal, definitely.

Let's get started with the basics.
