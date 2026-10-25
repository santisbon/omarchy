# System snapshots

We create snapshots automatically on every Omarchy update, but should you want to create your own, you can use `omarchy-snapshot create`.

> **Oaxaca: works differently.** Oaxaca's `omarchy-snapshot` drives Timeshift, a snapshot tool from Ubuntu's archive, instead of Snapper, and only on btrfs installs, which Oaxaca's installer makes by default; an install on ext4 or xfs has no snapshots. `omarchy-update` takes a snapshot before every update, and each `omarchy-snapshot create` keeps the newest five of the snapshots it took and deletes older ones; snapshots taken in Timeshift's own window are never pruned (the distro's docs/6, choice 38; docs/7, choice 52). The factory snapshot that _Setup > Reset Computer_ restores, `@factory`, is not a Timeshift snapshot but a read-only btrfs subvolume the installer makes, so Timeshift's window doesn't list it and the update never deletes it (the distro's docs/6, choice 87).

To boot and restore a snapshot, you select it from the Limine boot loader. (If you're currently booting straight into the Omarchy decryption screen, you'll need to select Limine as a boot option via the BIOS first).

From that screen, choose the snapshot you'd like to boot into based on the date and version. The version of Omarchy at the time of the snapshot can be seen at the bottom left corner.

 ![snapshots-bootloader](images/snapshots-bootloader.webp)

When you arrive inside, a notification will popup notifying you that you're in a bootable snapshot and if you click it, will start the restoration process. Alternatively, you can utilize `omarchy-snapshot restore`.

> **Oaxaca: works differently.** Oaxaca has no boot menu of snapshots and no restore notification: GRUB, Oaxaca's boot loader, cannot read snapshots on an encrypted root, and `grub-btrfs` is not in Ubuntu 26.10. `omarchy-snapshot restore` opens Timeshift's window, where a restore finishes with a reboot. When the installed system no longer starts, boot the Oaxaca USB stick: Timeshift is part of the live session, which can restore the snapshot from there (the distro's docs/6, choice 38; docs/7, choice 51).

 ![snapshots-restore](images/snapshots-restore.webp)

This will restore your root filesystem, but not your `/home`. So it works for reverting a broken system update, but not for recovering lost personal files.

This also means that your `~/.config` directory is kept as-is. So if you're rolling back to an earlier version of a library or application that stores configuration files in a new format, you'll have to sort that out manually.

> **Oaxaca: works differently.** An encrypted install keeps `/boot` on a separate ext4 partition that snapshots do not cover, so restoring a snapshot older than a kernel update brings back a root filesystem without that kernel's modules; GRUB's "Advanced options" still lists the previous kernel (the distro's docs/6, choice 38).

_Note: This feature is only available on installations using the Limine boot loader, which has been the default since Omarchy 2.0. It's not available if you're on GRUB or systemd-boot._

> **Oaxaca: works differently.** Oaxaca boots only with GRUB and has no Limine; snapshots depend on a btrfs root instead.

### Skipping the boot menu

If you never touch the boot menu and just want the machine to go straight to the decryption screen, run _Setup > Direct Boot_ in the Omarchy menu. That adds an EFI entry pointing directly at Omarchy, so the firmware boots it without stopping at Limine.

The trade-off is the one mentioned at the top: with direct boot on, getting to a snapshot means picking Limine from your BIOS boot menu first. Run _Setup > Direct Boot_ again to remove the entry and go back to booting through Limine. Some firmware doesn't take kindly to custom EFI entries, so the setup refuses to run on American Megatrends and Apple firmware.

> **Oaxaca: removed.** Setup > Direct Boot is gone: Oaxaca boots only with GRUB, so there is no Limine menu to skip (the fork's `PORT-REMOVALS.md`, "Direct boot of a UKI").
