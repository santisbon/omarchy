# Omarchy on...

> **Oaxaca: works differently.** The guides on this page are written for Omarchy on Arch Linux; Oaxaca installs from its own Ubuntu-based ISO. Oaxaca is built only for 64-bit Intel and AMD processors (amd64), so Apple M1/M2 machines are not supported (the distro's docs/README.md, "Apple hardware"), and Oaxaca's ISO boots on UEFI only, so a virtual machine needs UEFI firmware (the distro's docs/7, choice 4). Omarchy's Discord is Omarchy's own: Oaxaca's problems go to the distro's GitHub issues (`DISTRO_BUG_URL` in the build repository's `distro.conf`).

### Apple M1/M2 chips

[Asahi Alarm](https://asahi-alarm.org/) is a version of Arch for Apple M1/M2 computers built on top of [Asahi Linux](https://asahilinux.org/). You can get Omarchy running on top of that with some effort. See [the user-driven guide](https://codeberg.org/malik-na/omarchy-mac).

### Apple Virtual Machine

You can also install Omarchy inside a Parallels VM. Quite the cumbersome process, but there's [a user-driven guide](https://github.com/basecamp/omarchy/discussions/452) for that too.

### VirtualBox

VirtualBox is a popular VM runner. [You can run Omarchy inside that too](https://github.com/basecamp/omarchy/discussions/176). But performance probably won't be great.

### VMware Workstation on Windows 11

Another popular VM runner for Windows. [Omarchy has been setup inside of that as well](https://github.com/basecamp/omarchy/discussions/572).

### Steam Deck

The Steam Deck runs on Arch, which means you can run Omarchy on your Steam Deck. Altynbek Orumbayev has [a full setup script and explanation on how to do it](https://github.com/aorumbayev/deckarchy). How cool is that!

### NixOS

Omarchy is really Arch + Hyprland, but Henry Sipp has [ported the essence of the setup to NixOS](https://github.com/henrysipp/omarchy-nix). So if you've been nix-pilled, here's a good starting point. It may or may not stay up-to-date with the latest Omarchy changes, but it's pretty cool none the less!

### Something else!

If you're trying to get Omarchy running on a configuration that isn't the default, you should join the #omarchy-on-other channel on [our community Discord](https://discord.gg/tXFUdasqhY).
