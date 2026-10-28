# System sleep

Omarchy enables suspend and hibernation by default, but if you're having issues with either on your machine, you can toggle them off.

> **Oaxaca: removed.** Oaxaca enables suspend only. Hibernation is out of the distro's first release in every configuration, for scope: it needs swap sized to RAM on the encrypted disk, resume wiring in Ubuntu's initramfs, and a port of Omarchy's scripts away from Limine, btrfs and mkinitcpio; with Secure Boot on, the kernel's lockdown also blocks hibernation.

### Power profiles

On a laptop, Omarchy remembers your power profile separately for plugged in and running on battery, and switches between the two as you plug and unplug. Out of the box that means performance on AC and balanced on battery.

> **Oaxaca: works differently.** Out of the box Oaxaca uses balanced on AC as well as on battery, which is the default of Ubuntu's power-profiles-daemon; performance on AC ran the fans at every login on the port's first test laptop. A profile you pick is still remembered per power source.

You can see what your machine offers with `omarchy powerprofiles list`, and set the one you want for the state you're currently in with `omarchy powerprofiles set autodetect power-saver`. To set the other state without unplugging anything, name it directly: `omarchy powerprofiles set battery power-saver`. Whatever you pick is what you'll get back the next time you're in that state.

### Toggle suspend

You toggle suspend by running `omarchy toggle suspend` from the terminal. That just reveals/hides the option under _System_ (or `Super + Esc`), and then you can see if it works consistently on your system. If not, you can hide it again with the same command.

> **Oaxaca: works differently.** Oaxaca's _System > Suspend_ shows "Suspending" on screen for a moment before suspending, as Reboot and Shutdown show their messages; Omarchy's entry suspends with no message.

### Toggle hibernation

You set up hibernation by running `omarchy hibernation setup` from the terminal. Hibernation creates a /swap subvolume on your boot drive the size of your physical RAM allocation, so make sure you have plenty of room to spare. On a 32GB machine, you'll always need 32GB+ free for this volume. Hibernation also requires the default Limine bootloader.

When set up, you'll see the hibernate option under _System_ (or `Super + Esc`), and then you can see if it works consistently on your system. If not, you can remove it again by running `omarchy hibernation remove`.

> **Oaxaca: removed.** Oaxaca has no `omarchy hibernation setup`, `omarchy hibernation remove` or Hibernate entry under _System_, and boots with GRUB instead of Limine. Oaxaca's installer offers a swap file or no swap, never a swap partition sized for hibernation.
