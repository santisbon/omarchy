# Getting Started

Omarchy is installed using an ISO. You can choose between a full-disk install, which takes over the entire drive, or a free-space install, which puts Omarchy in the unallocated space on a drive — that's how you dual boot alongside Windows or another OS (see [dual-boot install](50-dual-boot-install.md) — note that you'll need to turn off BitLocker in Windows first). Either way, the installation defaults to full encryption, and the full-disk option will wipe the selected drive, so be sure to take a backup before using an existing one!

> **Oaxaca: works differently.** Oaxaca's ISO boots an Ubuntu live session (casper) that opens Calamares, a graphical installer, instead of Omarchy's installer. Calamares's partition page offers modes such as "Erase disk" and "Replace a partition"; its "Encrypt system" box starts checked (LUKS2, with a separate unencrypted 4 GB `/boot`), and btrfs is the default file system, with ext4 and xfs also offered.

Download the ISO first, put it on a USB stick (use [balenaEtcher](https://etcher.balena.io/) on Mac/Windows or [caligula](https://github.com/ifd3f/caligula) on Linux), and boot off the stick.

> **Oaxaca: added.** The website's front page, under _Check the download_, has the commands that check the ISO. gpg's "WARNING: This key is not certified with a trusted signature!" only means you haven't signed Oaxaca's key yourself; the ISO is genuine when gpg reports "Good signature" with the fingerprint shown on that page and `sha256sum` prints OK.

_You must turn off Secure Boot and/or TPM in the BIOS. You have to turn these off to be able to install Omarchy. They're Microsoft security schemes meant for Windows and Microsoft-affiliated Linux distributions._

> **Oaxaca: works differently.** Secure Boot can stay on or off: Oaxaca's live USB and installed system boot through Ubuntu's signed chain (shim, then Canonical's signed GRUB and kernel). Oaxaca boots in UEFI mode only. The TPM can stay on too, and Setup > Security > TPM Unlock can use the TPM to unlock the encrypted disk at boot, an opt-in that requires Secure Boot on.

Then answer the configuration questions, and confirm them like this:

 ![install-config](images/install-config.webp)

Then select a drive for your installation, and sit back and watch the installation show go. It can be done in under a minute on the fastest modern machines, but it shouldn't take more than 5 minutes even on an older computer.

 ![install-done](images/install-done.webp)

Now you're ready to Omarchy!

> **Oaxaca: works differently.** The screenshots above show Omarchy's installer. Calamares shows its own pages in this order: welcome, locale, keyboard, partition, users and a summary; it then copies the installed system to the disk and offers the reboot.

> **Oaxaca: added.** Which NVIDIA driver a graphics card needs depends on its architecture. The installer installs NVIDIA's open driver for Turing and newer cards from the USB stick. Older cards need NVIDIA's closed driver, branch 580, the last one for them, which comes from Ubuntu's archive after installation. Both drivers load with Secure Boot on.
>
> | Architecture | Example GPUs | Driver needed | On the USB stick | After installation |
> |---|---|---|---|---|
> | Blackwell | GeForce RTX 50 series | NVIDIA's open driver | Yes | NVIDIA's open driver |
> | Ada Lovelace | GeForce RTX 40 series | NVIDIA's open driver | Yes | NVIDIA's open driver |
> | Ampere | GeForce RTX 30 series | NVIDIA's open driver | Yes | NVIDIA's open driver |
> | Turing | GeForce RTX 20 series, GTX 16 series | NVIDIA's open driver | Yes | NVIDIA's open driver |
> | Volta | TITAN V | NVIDIA's closed driver, branch 580 | No | Nouveau, until you install the 580 driver |
> | Pascal | GeForce GTX 10 series, such as the GTX 1080 and GTX 1050 Ti Mobile | NVIDIA's closed driver, branch 580 | No | Nouveau, until you install the 580 driver |
> | Maxwell | GeForce GTX 900 series, GTX 750 Ti | NVIDIA's closed driver, branch 580 | No | Nouveau, until you install the 580 driver |
> | Kepler and older | Most of the GeForce GTX 600 and 700 series, such as the GTX 680 and GTX 780 | None: Ubuntu 26.10 has no NVIDIA driver for them | No | Nouveau |
>
> Nouveau is the open NVIDIA driver built into Linux. To install the 580 driver on a Volta, Pascal or Maxwell card, connect to the internet, run `sudo oaxaca-drivers-install` in a terminal, and restart. `oaxaca-drivers-install --show` prints the driver it would install, without installing anything.

### Use a wired or 2.4ghz keyboard!

The full-disk encryption won't allow you to enter the password from a Bluetooth keyboard at startup. Just like you can't use a Bluetooth keyboard to enter the BIOS on a PC. You'll need a keyboard that either uses a 2.4ghz dongle or a cable (which is much nicer for latency anyway!). I personally love the [Lofree Flow84](https://www.lofree.co/products/lofree-flow-the-smoothest-mechanical-keyboard)!

### Installing for another owner

If you're setting up a machine for someone else — a family member, a new employee, a buyer — you shouldn't be answering the personal questions on their behalf. Hit `Ctrl + C` on the very first screen of the installer (the keyboard selection), and Omarchy will offer to prepare the machine for another owner instead. The system installs right away, but all the personal setup — keyboard layout, username, password — is deferred until the machine boots for the first time. The drive is still encrypted by default, and the password the new owner picks on that first boot becomes the encryption password too. (A machine you've already been using can be handed over without a reinstall too — see [resetting the computer](48-security.md).)

> **Oaxaca: removed.** Omarchy's deferred install for another owner, started with `Ctrl + C` on the installer's first screen, is not in Oaxaca: Calamares asks for the user during the installation. The factory reset that hands a used machine to a new owner is back as Setup > Reset Computer, on btrfs installs only, with Omarchy's first-boot form.

### Unattended installs

The ISO can also install completely on its own — no keyboard, no wizard — when it's handed its configuration on a second drive. That's the way to treat Omarchy as a base image for VMs and fleet machines. See [unattended installs](51-unattended-installs.md).

> **Oaxaca: removed.** The unattended install is a feature of Omarchy's ISO installer, which Oaxaca's ISO does not carry: Oaxaca installs through Calamares.

### No-encryption installations

Omarchy is installed with encryption by default. It's the safe, responsible choice for any computer that can possibly be lost or stolen. You don't want anyone with access to your hardware to be able to get your data!

But in special circumstances, like remote Omarchy installs on protected computers or for throw-away installations without sensitive data, you may want to install without encryption. You can hit `Ctrl + C` on the disk formatting confirmation to switch to an encryption-less installation.

> **Oaxaca: works differently.** Calamares has no `Ctrl + C` switch: an unencrypted install is made by unchecking the "Encrypt system" box on the partition page.

### Help if you're stuck

If you get stuck, you can usually find someone willing to help in the _#omarchy-help_ channel on [the community Discord](https://omarchy.org/discord).

> **Oaxaca: removed.** The Omarchy Discord is Omarchy's own service, and Oaxaca's menu has no Learn > Community entry pointing to it.
