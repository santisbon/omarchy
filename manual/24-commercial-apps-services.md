# Commercial apps/services

Omarchy is mostly focused on providing free, open source software, but it's not religious about it. Sometimes the best solution is a commercial offering, and that's just fine. Here are some of the options we provide an easy installation for.

## 1Password

Keeping your passwords in a password manager is a best practice. Doubly so if you're working with a team. And [1password](https://1password.com/) is a great solution, which also comes with a command line tool for integrating key lookups in scripts.

You start 1Password with `Super + Shift + /`. If it isn't installed yet, that hotkey kicks off the installation first (you can also use _Install > Service > 1Password_ from the Omarchy menu). The installer sets up the 1Password extension for Chromium as well.

> **Oaxaca: works differently.** The 1Password installer adds 1Password's own apt repository and installs the `1password` and `1password-cli` packages from there; _Remove > Services > 1Password_ removes both packages, the repository and the Chromium extension setting.

## Bitwarden

[Bitwarden](https://bitwarden.com/) is the open source alternative in the password manager space, with a free tier that covers most personal use. Install it with _Install > Service > Bitwarden_ from the Omarchy menu, which brings along the Bitwarden command line tool as well.

> **Oaxaca: works differently.** _Install > Service > Bitwarden_ installs Bitwarden's own snap from the Snap Store (publisher 8bit Solutions LLC, Bitwarden's company), connects the snap to the `password-manager-service` interface Bitwarden needs for secure storage, and opens Bitwarden. The Bitwarden command line tool is not installed with it: Bitwarden publishes the command line tool as the `bw` snap, which _Install > Snap_ can add. _Remove > Snap_ removes either snap (the distro's docs/6, choice 77).

## Spotify

[Spotify](https://spotify.com/) is the world's most popular streaming music service. And the Linux application provides everything you'd expect, including offline playing.

You start Spotify using `Super + Shift + M`. Like 1Password, the hotkey kicks off the installation first if Spotify isn't installed yet (or use _Install > Service > Spotify_ from the Omarchy menu).

> **Oaxaca: works differently.** The Spotify installer adds Spotify's own apt repository and installs Spotify's `spotify-client` package from there; _Remove > Services > Spotify_ removes the package and the repository.

## Dropbox

[Dropbox](https://www.dropbox.com/) is a great way to sync files between machines while keeping a backup in the cloud. To set it up, select _Install > Service > Dropbox_ from the Omarchy menu. Once it's running, hover the tray in the top right of the bar and right-click the Dropbox icon to finish the setup.

> **Oaxaca: works differently.** The Dropbox installer installs Ubuntu's `nautilus-dropbox` package (from the archive's multiverse component), which downloads Dropbox's own client on first run.

## Tailscale

[Tailscale](https://tailscale.com/) is a mesh VPN that makes getting access to all your computers and servers over the internet securely super simple. To set it up, select _Install > Service > Tailscale_ from the Omarchy menu.

> **Oaxaca: works differently.** The Tailscale installer adds Tailscale's own apt repository for Ubuntu. While Tailscale publishes no packages for Ubuntu 26.10, the installer uses Tailscale's suite for Ubuntu 26.04 (`resolute`), which works because Tailscale's package is a static binary.

It gets a panel in the bar, a web app for the admin console, and Taildrop for sending files between your machines — see [networking](35-networking.md).

## ONCE

[ONCE](https://once.com/) is 37signals' line of software you buy once and run on your own server, like the Campfire chat system. Select _Install > Service > ONCE_ from the Omarchy menu to install it, which enables its background service and drops you into the ONCE terminal interface to take it from there.

> **Oaxaca: removed.** ONCE is not in the menu: ONCE is a binary released on GitHub with no package, and ONCE needs Docker, whose Docker Engine Oaxaca does not preinstall (the distro's docs/6, choice 71).

## NordVPN

[NordVPN](https://nordvpn.com/) is a standard VPN service that lets you exit your traffic from most regions around the world. To set it up, select _Install > Service > NordVPN_ from the Omarchy menu. After the reboot it asks for, run `nordvpn login` to authenticate.

> **Oaxaca: works differently.** _Install > Service > NordVPN_ installs NordVPN's own snap from the Snap Store, which runs NordVPN's daemon as a snap service, and asks for no reboot: Omarchy's group step and reboot are left out because NordVPN's Linux guide does not give them for the snap. _Remove > Snap_ removes NordVPN. Logging in and connecting with the snap have not been tested on Oaxaca (the distro's docs/6, choice 77).

> **Oaxaca: added.** _Install > Service_ also offers Mullvad VPN, from Mullvad's own apt repository, and Thunderbird, from the Snap Store; while Thunderbird is installed, `Super + Shift + E` opens Thunderbird (the distro's docs/6, choice 27). _Remove > Services_ removes both.

> **Oaxaca: added.** _Install > Service > iPhone_ installs [iphonebridge](https://github.com/santisbon/iphonebridge), which brings a paired iPhone's messages, contacts, notifications, calls and music controls to the desktop, and pairs the iPhone: start the pairing on the iPhone when the installer asks. _Remove > Services > iPhone_ removes iphonebridge and its data (the distro's docs/6, choice 109).
