# Security

Omarchy takes security extremely seriously. This is meant to be an operating system that you can use to do _Real Work_ in the _Real World_. Where losing a laptop can't lead to a security emergency. So here's what we do:

1. *Full-disk encryption is on by default*: This is the most important step to securing the physical protection of your data. If your computer is lost or stolen, the data is fully encrypted using standard LUKS (Linux Unified Key Setup). The installer lets you opt out for throw-away machines (see [Getting started](02-getting-started.md)); an install without encryption has none of this protection, and anyone holding the drive can read it.
2. *Firewall is enabled by default*: All incoming traffic is blocked by default, with a few exceptions: port 53317 for [LocalSend](https://localsend.org/); DNS queries to the computer's own resolver at the Docker bridge address (172.17.0.1), accepted from the private address ranges Docker gives its containers; and multicast DNS (port 5353), which lets printers and other devices on your network find each other and also announces your computer's name there. On top of those, the firewall keeps UFW's standard allowances for ping, getting an address from your router (DHCP), and UPnP discovery. Even ssh is off until you turn it on via _Setup > Security > SSHD_, which opens port 22 (rate limited against brute force) as part of the setup. We even lock down Docker access using the [ufw-docker](https://github.com/chaifeng/ufw-docker) setup to prevent your containers from accidentally being exposed to the world.
3. *Arch always has the latest updates*: Arch, the underlying distro that Omarchy is built on, is a rolling distribution. This means that any security vulnerability that's discovered and patched in any package is quickly available for install using `omarchy-update`. You're always running the latest, most secure versions of everything that way.
4. *Omarchy maintains its own packages and mirror*: Omarchy only relies on packages from Arch's own core/extra/multilib repositories and its own Omarchy Package Repository by default. You can install software directly from AUR, but the base install doesn't — only a few optional installs, like the third-party browsers, pull from the AUR.
5. *Cloudflare protects us from DDoS*: Omarchy distribution infrastructure — the ISOs, the Omarchy packages, the Arch mirror — is protected behind Cloudflare's formidable DDoS shield and hosted on their CDN. This provides superb availability.

> **Oaxaca: works differently.** Item 1: encryption is optional in Oaxaca's installer, with the "Encrypt system" box checked by default; an encrypted install puts the root on LUKS2 and keeps a separate unencrypted 4 GB `/boot`, because Ubuntu's GRUB cannot unlock LUKS2.

> **Oaxaca: works differently.** Item 2: ufw is on with LocalSend's port, on Ubuntu's policies, without Omarchy's Docker rules and without `ufw-docker`, because Docker Engine is not preinstalled and `ufw-docker` is not in Ubuntu 26.10. Setup > Security > SSHD installs Ubuntu's `openssh-server` and enables its `ssh.service`.

> **Oaxaca: works differently.** Item 3: Oaxaca is built on Ubuntu 26.10, an interim release with nine months of support, not on a rolling distribution. Packages come from Ubuntu's release, `-updates` and `-security` suites; Ubuntu's unattended-upgrades installs security fixes daily, and `oaxaca-update` runs a full apt upgrade.

> **Oaxaca: works differently.** Item 4: there is no AUR. Software comes from Ubuntu's archive, the distro's own apt repository, vendors' apt repositories, the xtradeb PPA for Chromium, the Snap Store and Flathub.

> **Oaxaca: works differently.** Item 5: Oaxaca's apt repository is a self-hosted aptly repository in an Amazon S3 bucket, not Omarchy's infrastructure.

## Changing your passwords

You have two passwords on an encrypted install: the one that unlocks the drive at boot, and the one you log in and `sudo` with. Setup makes them the same. Both can be changed under _Update > Password_ in the Omarchy menu — _Drive Encryption_ for the first, _User_ for the second. Changing the drive password asks for the current one first, so have it handy. If a change is interrupted, run _Drive Encryption_ again: it asks for the password that unlocks the drive now and finishes the change.

> **Oaxaca: added.** Setup > Security > TPM Unlock lets the TPM unlock the encrypted disk at boot, so the disk encryption password is not typed. The entry refuses with Secure Boot off and states its trade-off before binding: any boot with the same Secure Boot state, an Ubuntu live USB stick included, gets the same key, so TPM unlock protects a disk taken out of the computer but not a stolen computer. Remove > Security > TPM Unlock takes the TPM unlock off.

## Passing on a machine you've already used

If you're handing your machine over to someone else, you don't have to reinstall it. Run _Setup > Reset Computer_ in the Omarchy menu, type `reset` to confirm, and reboot. That wipes every user account and everything in `/home`, throws away all the packages and system changes you made since installation, and clears the machine's identity — network connections, host keys, and all. What comes back up is the setup wizard from the first boot, ready for its new owner to enter their own name, password, and encryption password.

It works by restoring the baseline snapshot the installer takes, so it's only available on machines installed from the Omarchy ISO. And on a drive without encryption, a reset is deletion rather than a secure erase, so if the data was sensitive, do a fresh install instead.

> **Oaxaca: works differently.** Reset Computer shows only on btrfs installs and returns the machine to `@factory`, a read-only snapshot that Oaxaca's installer takes at the end of the install. A machine installed on ext4 or xfs, or by an installer older than that step, is turned away with "Reinstall from the Oaxaca ISO to make this machine resettable". The reset also deletes the previous owner's Timeshift snapshots. The first-boot form asks for keyboard, user, password, name, email, hostname and timezone, and the new owner's user password also becomes the disk encryption password.

## Passwordless sudo

Sometimes you want `sudo` to stop asking, most often when an AI agent is doing a long stretch of system work for you. _Setup > Security > Passwordless Sudo_ asks how long to allow access: **15 minutes**, **1 Hour**, **1 Day**, or **Permanently**. A red warning icon appears beside the other menu bar indicators while access is active. Click it or run the command again to turn access off. You can also pass your own number of minutes (from 1 to 1440) with `omarchy-sudo-passwordless 30`, or use `omarchy-sudo-passwordless permanent`.

Timed access expires automatically, including immediately after resuming from a suspend that crossed the deadline. Restarting the computer ends it early. Permanent access survives reboots and stays enabled until you disable it.

Updating or removing Omarchy's settings package ends any temporary grant before its expiry support changes. If the command reports an authorization or cleanup error, resolve it before trying to enable another grant; an error does not mean passwordless access is inactive.

Be clear-eyed about this one: while it's on, anything running as your user can do anything as root without being asked. That's the whole point, and it's also the whole risk.

## Signing Keys

The public key for all ISO signatures and Omarchy repo package is `40DFB630FF42BCFFB047046CF0134EE680CAC571` ([verify at openpgp.org](https://keys.openpgp.org/search?q=pkgs%40omarchy.org)). The `omarchy/omarchy-keyring` package contains this as well and will be used to rollout any potential updates seamlessly.

You can find the signature for any ISO release by adding `.sig` to its URL, like `https://iso.omarchy.org/omarchy-x.x.x.iso.sig`.

> **Oaxaca: works differently.** The key above and the `omarchy-keyring` package are Omarchy's. Oaxaca's apt repository is signed with the distro's own RSA 4096 key, whose public half the `oaxaca-archive-keyring` package installs as `/etc/apt/keyrings/oaxaca-archive-keyring.gpg`.
