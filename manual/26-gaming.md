# Gaming

Omarchy isn't just for _pRoDUcTiVItY_, it's also for having fun, and what's more fun than gaming? Omarchy ships with a whole suite of gaming options — Steam and RetroArch for native and retro play, Battle.net, Lutris, and Heroic for non-Steam stores, Xbox Cloud Gaming + NVIDIA GeForce NOW for cloud, plus the evergreen Minecraft.

> **Oaxaca: removed.** Omarchy's version of this paragraph also names Moonlight for PC streaming, which Oaxaca does not preinstall (the distro's docs/6, choice 71). Battle.net, in the list above, is not in Oaxaca either.

Thanks to Valve's incredible work on [the proton compatibility layer](https://en.wikipedia.org/wiki/Proton_(software)), there are now tens of thousands of playable modern games on Linux. Oh, and did you know that the [Steam Deck](https://store.steampowered.com/steamdeck/) actually runs Arch!

All gaming installers live under _Install > Gaming_ in the Omarchy menu (`Super + Space`). If you ever want to undo one, use _Remove > Gaming_.

## Steam

Install [Steam](https://store.steampowered.com/) by selecting _Install > Gaming > Steam_ from the Omarchy menu (`Super + Space`).

After you've installed it, you'll be able to launch Steam with `Super + Space`.

> **Oaxaca: works differently.** The Steam installer enables 32-bit packages and installs Ubuntu's `steam-installer` package (from the archive's multiverse component) plus the 32-bit graphics drivers; the `steam-installer` package downloads Steam's client itself.

Note that Steam can take 10-20 seconds to start up, and it's not going to provide any visual feedback that it's loading.

> **Oaxaca: added.** Steam's windows float, so Steam's main window stays above a game that opens in a window. Click the game and press `Super + F` to make it full screen, or click Steam's window and press `Super + W` to close it; Steam and the game keep running.

 ![gaming-steam](images/gaming-steam.webp)

## RetroArch

Install [RetroArch](https://www.retroarch.com/) by selecting _Install > Gaming > RetroArch_ from the Omarchy menu (`Super + Space`). It comes with the full set of libretro cores, so all the classic systems are covered.

RetroArch is fully preconfigured with the beautiful CRT Royale shader for that perfect retro look.

> **Oaxaca: works differently.** Ubuntu 26.10 packages a smaller set of libretro cores than Arch and no shaders, so Oaxaca installs every libretro core Ubuntu packages and no CRT Royale shader. RetroArch's own Online Updater fetches shaders, overlays, the game database and joypad profiles once RetroArch is running.

To get going:

1. Drop your BIOS files into `~/Games/bios` and your ROMs into `~/Games/roms`.
2. Launch RetroArch with `Super + Space` and typing `retro`.
3. Scan the `~/Games/roms` directory and you're ready to play.

You can also give a favorite game its own entry in the app launcher with _Install > Gaming > RetroArch Game Launcher_, which lets you pick a core and a ROM, and jump straight into the game from `Super + Space`.

 ![gaming-retroarch](images/gaming-retroarch.webp)

## Xbox Cloud Gaming

Install the Xbox Cloud Gaming web app by selecting _Install > Gaming > Xbox Cloud Gaming_ from the Omarchy menu (`Super + Space`). It's "just" a web app for the service, but it's quick to start and runs great at 1080p.

If you already have Xbox Game Pass, this is a solid way to play Fortnite and other titles you can't run natively on Linux.

 ![gaming-xbox-cloud](images/gaming-xbox-cloud.webp)

## NVIDIA GeForce Now

Install the cloud-gaming service [NVIDIA GeForce NOW](https://www.nvidia.com/en-us/geforce-now/) by selecting _Install > Gaming > NVIDIA GeForce NOW_ from the Omarchy menu (`Super + Space`). Another great way to play titles that aren't available natively on Linux.

 ![gaming-geforce-now](images/gaming-geforce-now.webp)

## Minecraft

Install Minecraft by selecting _Install > Gaming > Minecraft_ from the Omarchy menu (`Super + Space`).

> **Oaxaca: works differently.** The Minecraft installer downloads Mojang's own `Minecraft.deb` and installs that package with apt, after the distro's `oaxaca-gdk-pixbuf-compat` package, which provides an old library package name that Mojang's package still depends on and Ubuntu no longer provides (the distro's docs/6, choice 76).

Like Steam, note that it can take a while after logging in or starting up for the next screen to appear, and you're not going to get any feedback while you're waiting.

 ![gaming-minecraft](images/gaming-minecraft.webp)

## Xbox Controllers

Install support for Bluetooth Xbox controllers by selecting _Install > Gaming > Xbox Controllers_ from the Omarchy menu (`Super + Space`). Pair the controllers via Bluetooth (`Super + Ctrl + B`) and they'll work in all your games. You don't need this if you're just hardwiring your controller with a USB-C cable.

> **Oaxaca: works differently.** The Xbox Controllers installer installs Ubuntu's `xpadneo-dkms`, a kernel module compiled on the machine, which needs a Secure Boot key (a Machine Owner Key) enrolled when Secure Boot is on. The installer then asks you to choose a one-time password; at the next restart, press a key within 10 seconds when the blue screen says "Press any key to perform MOK management", choose _Enroll MOK_, type that password, and choose _Reboot_. Ubuntu's kernel already runs Xbox controllers over USB and Bluetooth with its own drivers.

> **Oaxaca: removed.** Omarchy's manual has a section here, "Moonlight (Game streaming from a PC)": Omarchy preinstalls the Moonlight client, and `omarchy install service sunshine` installs Sunshine, the streaming host, and opens Moonlight's streaming ports for the LAN and Tailscale. Oaxaca has neither; Moonlight and Sunshine (`dev.lizardbyte.app.Sunshine`) can be installed from Flathub with _Install > Flatpak_, without Omarchy's firewall rules (the distro's docs/6, choices 71 and 78).

## Battle.net

Install [Battle.net](https://eu.shop.battle.net/en-us) by selecting _Install > Gaming > Battle.net_ from the Omarchy menu (`Super + Space`). This gives you titles like Diablo, Starcraft, and World of Warcraft as a standalone install running under GE-Proton — no Steam, Lutris, or Heroic needed.

> **Oaxaca: removed.** Battle.net is not in the menu: Omarchy runs Blizzard's installer through umu-launcher, which is not in Ubuntu 26.10's archive.

 ![gaming-starcraft](images/gaming-starcraft.webp)

## Lutris (Windows games)

Install [Lutris](https://lutris.net/) by selecting _Install > Gaming > Lutris_ from the Omarchy menu (`Super + Space`). Lutris is the way to play Windows games from stores like EA and Ubisoft Connect that don't have their own installer above.

> **Oaxaca: works differently.** Lutris comes from Ubuntu's archive with Ubuntu's Wine, after the installer enables 32-bit packages. umu-launcher and wine-staging, which Omarchy installs with Lutris, are not in Ubuntu 26.10; Lutris downloads its own runners.

Installation is a little janky and looks like nothing is happening at times — just be patient, it's working in the background.

## Heroic Launcher (Epic Games)

Install the [Heroic Launcher](https://heroicgameslauncher.com/) by selecting _Install > Gaming > Heroic (Epic Games)_ from the Omarchy menu (`Super + Space`). Heroic lets you run Epic Games titles, like OddSparks, that don't rely on anti-cheat — plus games from GOG and Amazon Prime Gaming. Sadly, that means no Fortnite and no Rocket League — until Tim Sweeney comes to Linux, this is as close as it gets.

> **Oaxaca: works differently.** The Heroic installer installs Flathub's `com.heroicgameslauncher.hgl`, published by Heroic's developers and marked verified, instead of Omarchy's own package, and Flatpak keeps Heroic updated. _Remove > Gaming > Heroic (Epic Games)_ deletes Heroic's data and `~/Games/Heroic`, as Omarchy's remover does (the distro's docs/6, choice 75).

Like Lutris, it can feel slow and janky while installing games. Give it time.
