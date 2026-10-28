# Coming From Mac or Windows

If you've spent years on macOS or Windows, your fingers know a hundred things your brain has forgotten it ever learned. This chapter is the translation layer: where those instincts go in Omarchy. The features themselves are covered in depth elsewhere — this is just the map.

### Super is the center of everything

All the muscle memory you've built around Cmd or the Windows key transfers to one key: Super. That's the Windows key on a PC keyboard, and it's the anchor for nearly every hotkey in Omarchy.

Your Spotlight or Raycast or Start-menu reflex becomes `Super + Space`. That opens the Omarchy menu, which launches apps, changes settings, installs software, captures the screen — just about everything. Start typing to filter. There's also a dedicated apps-only menu on `Super + Alt + Space`. See [navigation](04-navigation.md).

### There's no dock and no desktop icons

Nothing to click to launch things, no icons to arrange on the desktop. Apps start from a hotkey (`Super + Return` for the terminal, `Super + Shift + Return` for the browser, and `Super + K` for a list of everything that's mapped) or from the menu. The one persistent piece of UI is [the top bar](05-the-top-bar.md), which covers what the menu bar, system tray, and Notification Center did for you before — and nearly every widget on it does something on left, right, and middle click.

### Windows place themselves

The biggest mindset shift: you don't drag windows around or snap them to screen halves. Open a window and it takes the whole screen. Open a second and they split it. You never fish a window out from under another one, because windows don't overlap.

When you genuinely need a floating window, `Super + T` toggles the active one out of the tiling (and back). But give the tiling a real chance first — it's the heart of the whole thing. [Navigation](04-navigation.md) walks you through it.

Workspaces will feel familiar: they're macOS Spaces or Windows virtual desktops, except you'll actually use them, because `Super + 1/2/3/4` jumps straight to one and `Super + Shift + 1/2/3/4` sends the active window there. No animation delay, just instant jumps. This means that you might not even need multiple monitors, if you were used to that before.

### Copy and paste just work

On the Mac you had Cmd + C everywhere. On Windows you had Ctrl + C everywhere — except the terminal, where it kills your program. Omarchy gives you `Super + C`, `Super + X`, and `Super + V`, and they work everywhere, including the terminal. No separate reflex to learn for the shell.

Windows folks: your Win + V clipboard history lives on `Super + Ctrl + V`, and it holds images as well as text. See [unified clipboard & history](08-unified-clipboard-history.md).

### The translation table

| You reach for | In Omarchy |
| ------------- | ---------- |
| Spotlight / Raycast / Start menu | `Super + Space` — the Omarchy menu |
| AirDrop | LocalSend, via `Super + Ctrl + S` — see [GUIs](22-guis.md) |
| Cmd + Shift + 4 / Win + Shift + S | `Print Screen` — see [screenshots & recording](12-screenshots-recording.md) |
| Notification Center | Notification history on `Super + Shift + Alt + ,` |
| Time Machine (for the system) | Automatic [system snapshots](47-system-snapshots.md) on every update |
| App Store / downloading an installer | _Install_ in the menu, or `omarchy pkg add` — see [other packages](29-other-packages.md) |
| System Settings / Control Panel | _Setup_ in the menu, which edits plain config files — see [dotfiles](31-dotfiles.md) |

> **Oaxaca: works differently.** LocalSend is preinstalled from the distro's own apt repository, built from LocalSend's release. System snapshots are taken by Timeshift before each update, and only on installs whose root file system is btrfs, the installer's default; an ext4 or xfs install updates without a snapshot. `oaxaca pkg add` installs Ubuntu packages with apt and translates Arch package names into Ubuntu's, and the menu's Install offers Package (Ubuntu's archive), Snap (the Snap Store) and Flatpak (Flathub) where Omarchy offers Package and AUR.

### Some things really are different

A lot of settings live in text files you edit, not panels you click through. That sounds primitive until you realize it means every tweak can be seen, copied to your next machine, and put in version control. The _Setup_ menu drops you straight into the right file and restarts whatever needs restarting when you're done.

Updates come through one command — _Update > Omarchy_ — that updates Omarchy itself and every package on the system, taking a snapshot first. No per-app updaters nagging you at random. See [updates](30-updates.md).

> **Oaxaca: works differently.** Update > Oaxaca upgrades the apt packages (`apt-get full-upgrade`) and the tools installed through mise, then runs the desktop's migrations; the snapshot before the upgrade happens only on btrfs installs. The update runs no `snap` or `flatpak` command, so apps from the Snap Store or Flathub are not part of Update > Oaxaca.

> **Oaxaca: added.** Ubuntu's unattended-upgrades installs security updates from Ubuntu's archive automatically, as on Ubuntu; the desktop's own packages move only through Update > Oaxaca.

Software comes from a package manager, not from downloaded installers.

And when you close a window, the app actually quits. There's no macOS limbo where the program keeps running with no windows. `Super + W` means gone.

### On Mac hardware

Omarchy runs well on Intel Macs — see [Mac support](44-mac-support.md). And the keyboard is kind to you: Omarchy doesn't remap anything, and Linux treats the Command key as Super, so Super sits right where Cmd always was. Your thumb won't notice the move.

> **Oaxaca: removed.** Oaxaca does not support Macs with Apple's T2 chip (most Macs from 2018 to 2020), whose setup in Omarchy needs an out-of-tree kernel from a pacman repository, nor the Broadcom BCM4360 Wi-Fi of 2013 to 2015 MacBooks, whose only driver is a DKMS module that Secure Boot would refuse without an enrolled key. No Mac has run Oaxaca yet.

> **Oaxaca: works differently.** Omarchy does remap one key: Caps Lock becomes the Compose key, with Caps Lock moved to both Shift keys pressed together. Oaxaca keeps the keyboard exactly as chosen at installation, so Caps Lock stays Caps Lock.

### Give it two weeks

The instincts transfer faster than you'd think. Skim the [hotkeys](07-hotkeys.md) chapter once, and whenever you blank on a binding, hit `Super + K` — it shows you all of them. That's the only hotkey you actually have to memorize.
