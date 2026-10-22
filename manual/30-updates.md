# Updates

Omarchy and your packages are kept up to date via _Update > Omarchy_ in the Omarchy menu (`Super + Space`).

Omarchy itself is installed as regular pacman packages from the [Omarchy Package Repository](https://github.com/omacom-io/omarchy-pkgs), so an update installs [the latest Omarchy release](https://github.com/basecamp/omarchy/releases), runs any pending migrations to get your system in sync with the latest, and updates all system packages from the [Omarchy Arch Mirror](https://github.com/omacom-io/omarchy-mirror) and [AUR](https://aur.archlinux.org/) (if you have installed any AUR packages).

> **Oaxaca: works differently.** Oaxaca's own packages come from the distro's apt repository, and everything else from Ubuntu's archive and the apt repositories added from the menu; there is no AUR. An update runs `apt-get update` and `apt-get full-upgrade`, then the migrations, your post-update hooks and a mise update, offers to remove packages nothing needs any more, and offers a reboot when a newer kernel was installed or Hyprland was replaced (the distro's docs/8).

When new releases are made, a circle arrow icon will appear to the right of your clock. Click it and the update process will start.

> **Oaxaca: works differently.** The icon appears when `apt list --upgradable` shows a newer version of one of the desktop's own `oaxaca-*` packages; apt refreshes its package lists daily (the distro's docs/8).

![update-available](images/update-available.webp)

### Four channels

Omarchy is updated along four channels: stable, RC, edge, and dev. New installations start on the stable channel, which tracks the [official releases](https://github.com/basecamp/omarchy/releases/), as well as the [stable Omarchy Arch mirror](https://github.com/omacom-io/omarchy-mirror) that's running one month behind the latest, so we can catch any new incompatibilities that require config changes before they cause problems for people.

But if you'd like to help spot those potential issues, you can run on the edge channel. That'll keep your Omarchy packages tracking the latest development builds, and lets you update to the latest Arch packages as soon as they're available. You should only do this if you're experienced with Linux, and know how to recover a system that has problems.

Before any new major release, we'll be doing final validation using the RC channel. If you're interested in helping with final polishing, come hang out in #omarchy-release-candidates on the Discord.

Finally, there's the dev channel, which links Omarchy directly to a git checkout of the source code in `~/omarchy`, combined with the edge packages. You should only use this channel if you're an experienced Linux user, working directly on Omarchy, and willing to tolerate breakage.

You can switch between channels using _Update > Channel_ from the Omarchy menu (or `omarchy-channel-set` in the terminal).

> **Oaxaca: removed.** Oaxaca has no update channels: the distro's apt repository has none, so _Update > Channel_ and `omarchy-channel-set` are gone, and every install follows the one published release.

### Firmware updates

Your packages aren't the only thing that goes stale. Many laptops and peripherals ship BIOS, SSD, and dock firmware through the Linux Vendor Firmware Service, and _Update > Firmware_ in the Omarchy menu will fetch and install whatever your hardware has waiting. It installs `fwupd` the first time you run it. Plenty of firmware can only be written during a reboot, so don't be surprised to be asked for one.

### Warning about direct pacman/yay updates

If you're already familiar with Arch, you might be tempted to just run `pacman -Syu` or `yay -Syu` yourself, but if you do that, you'll miss the snapshot, migrations, and configuration updates that Omarchy runs together with new packages. That's why Omarchy will actually stop a direct system upgrade and point you to `omarchy update` instead. (If you really know what you're doing, the guard will tell you how to bypass it for a single transaction.)

> **Oaxaca: works differently.** Oaxaca has no guard on apt: a direct `sudo apt full-upgrade` is not stopped, and the snapshot and the update's other steps do not run with that upgrade. Migrations of the desktop's packages then wait for the notification at your next login. `pacman` and `yay` exist on Oaxaca only as stand-ins for plugins written for Omarchy: they change nothing, say that the system uses apt, and exit with an error (the distro's docs/6, choice 86).

> **Oaxaca: added.** Ubuntu's unattended-upgrades installs Ubuntu's security updates automatically every day. The desktop's own packages are left out of unattended-upgrades on purpose and move only through _Update > Omarchy_, which runs their migrations (the distro's docs/8, choice 1).

### Rolling back bad updates

If you ever have a problem after doing an update, you can rollback your system to the snapshot taken before the update. Just restart and pick the snapshot in the boot loading menu from before you started the update.

> **Oaxaca: works differently.** Oaxaca boots with GRUB, which cannot list snapshots of an encrypted root, so the boot menu has no snapshot entries. On installs with a btrfs root, the update takes a Timeshift snapshot first and keeps the newest five of its own; restore one with `omarchy-snapshot restore`, which opens Timeshift, or with Timeshift from the installation USB stick. Installs on ext4 or xfs get no snapshots (the distro's docs/6, choice 38).

![bootloader](images/bootloader.webp)

If somehow your configuration files have been corrupted, you can also perform an Omarchy reinstall using `omarchy reinstall` in the terminal. This will reinstall all the default Omarchy packages, put you on stable and downgrade any packages that are too new, and reset all the configuration files. Note that all your user config changes to the Omarchy defaults will be overwritten doing this!

> **Oaxaca: works differently.** `omarchy reinstall` installs the desktop's meta package again, reinstalls every package in the desktop's base package list with apt, and resets the configuration files. With no channels, nothing switches you to stable or downgrades packages.
