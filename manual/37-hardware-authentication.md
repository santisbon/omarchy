# Hardware authentication

### Fingerprint authentication

A lot of laptops come with a fingerprint sensor to do authentication. You can use this with Omarchy by running _Setup > Security > Fingerprint_ in the Omarchy menu (`Super + Space`).

That'll install the fingerprint package, collect your print, verify it, and you'll be set to go using your fingerprint to unlock from the lock screen (which you can trigger with `Super + Ctrl + L`), enter sudo mode, and authorize system prompts.

> **Oaxaca: works differently.** Oaxaca preinstalls the fingerprint packages (`fprintd` and `libpam-fprintd`), so _Setup > Security > Fingerprint_ installs nothing. The entry enables Oaxaca's own pam-auth-update profile, which puts `pam_fprintd` into Ubuntu's shared `common-auth` stack, instead of editing sudo's and polkit's PAM files as Omarchy does.

When your laptop lid is closed, the fingerprint prompt is automatically skipped, so you go straight to the password prompt instead of waiting on a sensor you can't reach. If you otherwise need to work on an external keyboard that doesn't have a sensor, just hit `CTRL + C`, when you're prompted for your fingerprint during `sudo`.

You can remove the fingerprint authentication under _Remove > Security > Fingerprint_ in the Omarchy menu.

> **Oaxaca: works differently.** On Oaxaca, _Remove > Security > Fingerprint_ disables the pam-auth-update profile and removes the lock screen's fingerprint PAM file, but leaves `fprintd` and `libpam-fprintd` installed, since both are part of the distro's base install.

### Fido2 authentication

If you're using a Fido2 device, you can set it up for `sudo` authentication using _Setup > Security > Fido2_ in the Omarchy menu (`Super + Space`). It covers `sudo` and system authorization prompts, though, not unlocking your computer.

> **Oaxaca: works differently.** Oaxaca preinstalls the FIDO2 packages (`libpam-u2f`, `pamu2fcfg` and `fido2-tools`), and _Setup > Security > Fido2_ enables Oaxaca's own pam-auth-update profile, which puts `pam_u2f` into Ubuntu's shared `common-auth` stack, instead of editing sudo's and polkit's PAM files. The lock screen's password check names `pam_unix` directly, so the FIDO2 device still does not unlock the lock screen.

You can remove the fido2 authentication under _Remove > Security > Fido2_ in the Omarchy menu.

> **Oaxaca: added.** _Setup > Security > TPM Unlock_ lets the computer start without typing the disk encryption passphrase. Clevis, a program that keeps a LUKS key sealed by the TPM in a key slot of its own, is preinstalled, and the entry shows when the computer has a TPM 2.0 and the root filesystem is on a LUKS-encrypted partition. The entry refuses to run with Secure Boot off and explains the trade-off first: the binding uses the TPM's Secure Boot register (PCR 7), so any boot with the same Secure Boot state, an Ubuntu live USB stick included, gets the key, which protects a disk taken out of the computer but not a stolen computer. _Remove > Security > TPM Unlock_ wipes the TPM's key slot.
