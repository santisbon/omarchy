# GUIs

## Files

Files (Nautilus) is the graphical file manager. `Super + Shift + F` opens it, and `Super + Shift + Alt + F` opens it in the directory your terminal is sitting in, which saves a lot of clicking. `Ctrl + L` lets you type a path, and hitting `Space` on any file gives you a quick preview without opening anything.

Plug in a USB stick or an SD card and it's mounted automatically, so it just shows up in the sidebar. For anything more involved — formatting a drive, checking SMART health, creating partitions — launch _Disks_ from the app launcher (`Super + Space`).

Double-clicking follows sensible defaults: images open in imv, video in mpv, PDFs in Document Viewer, and plain text in Neovim.

> **Oaxaca: works differently.** PDFs open in Papers, GNOME's successor to Document Viewer (Evince) and Ubuntu's own default viewer, because Ubuntu 26.10 carries Evince only as an alpha (the distro's docs/6, choice 28).

## Obsidian

[Obsidian](https://obsidian.md/) is a free and highly extensible note taking application that uses simple Markdown files for storage.

Obsidian is free for all purposes, including personal, commercial, and non-profit use.

Obsidian also offers a [commercial add-on for syncing](https://obsidian.md/sync) with mobile apps on iOS and Android. (https://obsidian.md/pricing).

You start Obsidian with `Super + Shift + O`. To use theme syncing, you must select the `Omarchy` theme under settings.

> **Oaxaca: removed.** Obsidian is not preinstalled, and the `Super + Shift + O` binding and Obsidian's theme syncing are gone with Obsidian (the distro's docs/6, choice 71). Obsidian can still be installed, without Omarchy's setup, from the Snap Store with _Install > Snap_ (published as `obsidianmd`) or from Flathub with _Install > Flatpak_.

## Omawrite

[Omawrite](https://github.com/omacom-io/omawrite) is Omarchy's own dead-simple Markdown writing app. No vaults, no plugins, just you and the words.

You start Omawrite with `Super + Shift + W`.

> **Oaxaca: removed.** Omawrite and its `Super + Shift + W` binding are not in Oaxaca: Omawrite has no build in Ubuntu's archive, on Flathub or on the Snap Store (the distro's docs/6, choice 80).

## Pinta

[Pinta](https://www.pinta-project.com/) is a basic image editing tool that's great for cropping, resizing, and other basic manipulations. Just don't expect a Photoshop alternative. But it's still got a Magic Wand and layers!

You start Pinta via the application launcher (`Super + Space`).

> **Oaxaca: removed.** Pinta is not preinstalled (the distro's docs/6, choice 71). Pinta can be installed from Flathub with _Install > Flatpak_.

## Aether

[Aether](https://github.com/bjarneo/aether) is a theming application that can extract colors from a background image and turn them into a complete, cohesive theme. It's the easiest way to [make your own theme](43-making-your-own-theme.md).

You start Aether via the application launcher (`Super + Space`).

> **Oaxaca: removed.** Aether is not in Oaxaca: Aether is not in Ubuntu 26.10's archive, and Aether's repository has no licence, so the distro cannot redistribute Aether.

## LocalSend

[LocalSend](https://localsend.org/) lets you send files to other devices on the same network running the app, like Apple's AirDrop. It's cross-platform, though, so you can send files to and from Windows, macOS, Android, iOS, and of course Linux.

> **Oaxaca: works differently.** Ubuntu's archive has no LocalSend, so Oaxaca preinstalls LocalSend from the distro's own apt repository, repackaged from LocalSend's own release builds (the distro's docs/6, choice 19).

You can open the Share menu on `Super + Ctrl + S` or under _Trigger > Share_ in the Omarchy menu. It gives you four options:

- **Clipboard** sends whatever you've copied as a text file. Great for getting a link or a snippet onto your phone without emailing yourself.
- **File** opens a file picker where you can select several at once.
- **Folder** sends an entire directory.
- **Receive** opens LocalSend proper so another device can send something to you.

The same thing works from the terminal with `omarchy share clipboard`, `omarchy share file [path]`, and `omarchy share folder [path]`. Leave the path off and you get the picker.

You can also send straight from the file manager: right-click any selection in Nautilus and pick _Send via LocalSend_.

Omarchy's firewall is closed by default except for LocalSend's port, so this works out of the box on a fresh install. See [security](48-security.md).

## LibreOffice

[LibreOffice](https://www.libreoffice.org/) is a complete office package with word processor, spreadsheet, presentations, drawing application, and more. It's compatible with files from Microsoft Office, so this is a great way to be able to open those Word documents.

You start LibreOffice via the application launcher (`Super + Space`).

> **Oaxaca: works differently.** LibreOffice is not preinstalled. _Install > Productivity > LibreOffice_ in the menu installs Canonical's LibreOffice snap from the Snap Store, and _Remove > Productivity > LibreOffice_ removes LibreOffice again (the distro's docs/6, choices 31 and 71).

## Omacalc

[Omacalc](https://github.com/omacom-io/omacalc) is Omarchy's own dead-simple calculator, which opens in a floating window.

You start Omacalc with `Super + Ctrl + Q` (or the calculator key, if your keyboard has one).

> **Oaxaca: works differently.** Omacalc is not in Oaxaca, because Omacalc has no Ubuntu build. GNOME Calculator is preinstalled in Omacalc's place, takes Omacalc's bindings (`Super + Ctrl + Q` and the calculator key) and opens in a floating window as Omacalc does (the distro's docs/6, choice 47).

## Signal

[Signal](https://signal.org/) is the pioneer of E2E encrypted messaging, and a great communication option for anyone who'd prefer not to go through one of the big tech conglomerates.

You start Signal with `Super + Shift + G`. It's not part of the base install, so the first time you hit that, Omarchy will offer to install it for you (it's also under _Install > Service_ in the Omarchy menu).

> **Oaxaca: works differently.** Signal's installer adds Signal's own apt repository and installs the `signal-desktop` package from there, so Signal's updates arrive with the system's.

## mpv

[mpv](https://mpv.io/) is a simple, fast media player that'll play almost anything from any source. Great for watching videos.

You start mpv via the application launcher (`Super + Space`) or just double-click on a video in the file manager.

## OBS Studio

[OBS Studio](https://obsproject.com/) lets you record or stream video from multiple inputs. You can mix a screencast with a webcam with a microphone input. It's what was used to record the Omarchy screencasts.

It's not part of the base install: install it from _Install > Productivity > OBS Studio_ in the Omarchy menu (`Super + Space`), which installs the OBS project's own Flatpak from Flathub. Then start it via the application launcher (`Super + Space`).

> **Oaxaca: works differently.** The paragraph above is Oaxaca's. Omarchy preinstalls OBS Studio (`obs-studio` in Omarchy's base package list) and has no menu entry for OBS Studio. Oaxaca offers the Flathub build because the OBS project's other official channel, its PPA, has no build for Ubuntu 26.10; _Remove > Productivity > OBS Studio_ removes OBS Studio again (the distro's docs/6, choice 83).

## Kdenlive

[Kdenlive](https://kdenlive.org/) is an excellent video editor. Perfect for working on video that comes out of OBS Studio before sharing it.

It's not part of the base install: install it from _Install > Productivity > Kdenlive_ in the Omarchy menu (`Super + Space`), which installs KDE's Flatpak from Flathub. Then start it via the application launcher (`Super + Space`).

> **Oaxaca: works differently.** The paragraph above is Oaxaca's. Omarchy preinstalls Kdenlive (`kdenlive` in Omarchy's base package list) and has no menu entry for Kdenlive. Oaxaca offers KDE's Flatpak instead, and _Remove > Productivity > Kdenlive_ removes Kdenlive again (the distro's docs/6, choice 84).

## Omacut

[Omacut](https://github.com/omacom-io/omacut) is Omarchy's own dead-simple video trimmer. When all you need is to cut the start and end off a clip, it beats firing up a full video editor.

You start Omacut via the application launcher (`Super + Space`).

> **Oaxaca: removed.** Omacut is not in Oaxaca: Omacut has no build in Ubuntu's archive, on Flathub or on the Snap Store (the distro's docs/6, choice 80).
