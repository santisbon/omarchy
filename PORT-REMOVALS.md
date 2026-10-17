# What the port removed from Omarchy

This document lists every feature of Omarchy v4.0.4 that the port does not have today, why it was removed, whether that reason holds on Ubuntu, and what restoring it would take. The audit behind it was written on 2026-10-16, after three removals turned out to be wrong: the agent skills (deleted as Omarchy's contributing workflow, though seven of their nine files are help for users), the update snapshots (deleted with Limine, though only the boot menu needed Limine), and the launcher's handling of desktop ids that end in `.desktop`. Features restored since then are not in the sections about removals: they are listed once, in [Restored](#restored), at the end, with the choice that records each.

The port follows the rule the distro's Ubuntu base follows: nothing is installed and then removed. The port starts from a minimal base, Ubuntu's own configuration plus the parts of Omarchy the desktop needs to run, and adds each further Omarchy feature by a recorded choice that gives a reason that holds on Ubuntu. "Omarchy does it on Arch" is not such a reason by itself: some of Omarchy's fixes exist because of how Arch builds the system (mkinitcpio leaves modules out of the initramfs unless told; Ubuntu's initramfs-tools does not). Restoring an item below is such an addition: it is written for Ubuntu, recorded as a choice in the build repository's `docs/6 - omarchy-port.md`, and is not a revert of the commit that removed Omarchy's version.

## Terms

Each entry uses only terms defined above it.

### Omarchy and the port

Omarchy is the Arch Linux desktop the Oaxaca distro follows, at its release tag `v4.0.4`. The port is this branch, `oaxaca`, which rewrites Omarchy for Ubuntu (`PORT.md`). The distro's build repository, `santisbon/oaxaca`, packages it (`packages/desktop`) and holds the distro's design documents under `docs/`.

### stonking

Ubuntu 26.10, the base series. "In stonking" means Launchpad lists the package as published for that series, checked 2026-10-16.

### Choice

A numbered decision in one of the build repository's step documents. "docs/6" is `docs/6 - omarchy-port.md` there, "docs/1" is `docs/1 - policy.md`, "docs/0" is `docs/0 - plan.md`, "docs/4" is `docs/4 - session.md` and "docs/7" is `docs/7 - image-installer.md`; "docs/6, choice 15" is the 15th choice in docs/6.

### Verdicts

- **Justified**: the reason for removing the feature holds.
- **Replaced**: the distro does the same job another way, named in the row.
- **Restore**: the reason does not hold, and the feature works on Ubuntu within the project's requirements (Secure Boot without a MOK, Ubuntu's signed GRUB and kernel, packages from Ubuntu's archive, vendor apt repositories, the Snap Store, Flathub or the distro's own apt repository).
- **Partial**: part of the feature can come back, or it can come back another way.
- **Unclear**: the facts needed to decide were not reachable, such as whether Ubuntu has the problem a fix is for.

## How the audit was done

The deleted files are `git diff --name-status --diff-filter=D v4.0.4 oaxaca` on this branch: 321 files. The 106 migrations among them are covered in `migrations/README.md`; the deleted tests are listed in [Tests](#tests) below. The rest, 183 files, plus the 70 menu entries removed from `default/omarchy/omarchy-menu.jsonc`, the 97 package names that Omarchy's `install/omarchy-base.packages` has and the port's does not, and the features cut inside the 121 files both sides have, were read one by one against the reasons recorded in this repository's docs and the fork, and checked against stonking on Launchpad, the Snap Store (`snap info`), Flathub, vendor apt repositories, mainline Linux 7.3 and the live root filesystem built 2026-10-16.

## What the audit found overall

- **No commit says why anything was removed.** The commits that deleted the files, `ef4c9211` "Port Omarchy v4.0.4 to Ubuntu", `c304e943` "Trim pre-installed software", `4b680c26` "Remove features we provide through Ubuntu", `3c21fd64` "Don't customize firewall" and `963b196e`, have no message body. Every recorded reason is in docs/6, docs/1, docs/0, `PORT.md` or the comments in the port's package list.
- **The preinstall trim rested on one choice.** docs/6 choice 15 ("nothing of Omarchy's taste") dropped Omarchy's command-line tools and preinstalled apps; neither the plan nor the policy has a rule about what to preinstall. Some of what went was basic (no `unzip`, no calculator, no system monitor), and some was still wired into the port's own files (the prompt, the `ls` and `cd` aliases, the debug report).
- **Removals were coupled to Limine and Snapper wholesale.** Snapshots, the factory reset and two ASUS display fixes went because Omarchy delivered them through Limine or Snapper, though the feature itself works with GRUB and Timeshift.
- **Reasons that expired were not revisited.** Voxtype's invitation went when Voxtype could not be installed and stayed gone after it could; Brave and Edge went as "proprietary builds replaced by open counterparts" and stayed gone after Chrome and VS Code came back; the `ic`/`ix`/`icx` aliases stayed gone after tmux came back.
- **Some "Ubuntu's configuration" removals dropped a reason specific to this desktop.** Wi-Fi power save, the SSH keepalive and the out-of-memory killer's scope had such reasons.
- **The rule "Delete rather than stub" was not followed through.** Scripts were kept with nothing calling them, and kept scripts called deleted programs ([Broken references](#broken-references-and-leftovers)).

## Still to restore

The candidates left, in the order to take them. Each names its section below; the sections give the facts.

1. **Larger projects**: a factory reset on Timeshift and `oem-config`; Learn > Omarchy with a caveat.

## Open questions

Checks that came up while restoring, not yet done:

- **uutils `timeout`.** Ubuntu's `timeout` is uutils' (`coreutils-from-uutils`), which on timeout kills only the process it started; GNU's signals the whole process group. When the timed-out program has started children and the caller reads its output (`$(timeout … cmd)`), the caller waits for those children: 30 s instead of 2 s in Omarchy's own test of a wedged `supergfxctl`. The restored Hybrid GPU scripts call `gnutimeout` (GNU's, `gnu-coreutils`, Priority: required). Kept scripts that time out a program which starts children may have the same problem, the likeliest being the callers of `omarchy-shell` (`omarchy-theme-set`, `omarchy-system-sleep-lock`).
- **Hardware fixes kept without proof that Ubuntu needs them**, by the maintainer's decision of 2026-10-16: the ASUS Panther Lake display options (docs/6, choice 55) and Wi-Fi 7 off on a Dell XPS on Panther Lake (choice 60). Whether Ubuntu's kernel 7.3 has those bugs was not checked.
- **Untested on the hardware**: the Surface and MacBook8,1 keyboard modules (choices 63, 64), the IPU7 camera through libcamera (65), the Dell XPS haptic touchpad (66), qmk_hid (67), asusctl and the Hybrid GPU toggle (68).
- **Bluetooth pairing agent.** Omarchy's `bt-agent.service` was replaced by blueman's applet, which autostarts through XDG; not confirmed that XDG autostart runs under the uwsm session.

## Commands, launchers and menu entries

85 deleted files under `bin/` and `applications/` and 70 removed menu entries, grouped by feature. The commits that deleted them, `ef4c9211` (47 files), `c304e943` (37) and `963b196e` (the HEY handler), give no reason per item; the reasons are from docs/6, docs/1, docs/0 and `PORT.md`.

### Restore or partly restore

| Feature | Files and menu entries | What it did | Removed because | Checked facts | Verdict |
|---|---|---|---|---|---|
| Factory reset | `bin/omarchy-system-factory-reset`, `-factory-reset-finish`, `-provision-owner`; `setup.reset` | on btrfs, swapped `@` for the installer's factory snapshot, re-keyed the disk encryption and recreated the owner at first boot | docs/6: among "programs the distro cannot install"; docs/1: scripts tied to Limine and Snapper | the same mistake as snapshots: only the Limine and mkinitcpio steps were Arch-specific; btrfs installs have Timeshift; `oem-config` (universe) creates a user at first boot | **Partial**: a factory Timeshift snapshot at install, restored by the reset, then `oem-config-prepare`; the re-keying needs rewriting |
| Learn > Omarchy | `learn.omarchy` | Omarchy's manual | none recorded | parts of the manual do not apply (the firewall's Docker rules, pacman, Limine), most does | **Partial**: with a caveat, or a page of the port's own |

### Replaced

| Feature | What does the job instead |
|---|---|
| The AUR commands | Install > Package, Snap and Flatpak |
| pacman upkeep | `omarchy-update-system-pkgs` with apt |
| The 32-bit GPU libraries | `omarchy-install-32bit-graphics` |
| The local package test | `UPSTREAM_DIR=… scripts/build.sh` in the build repository |
| Learn > Arch | Learn > Ubuntu |
| The preinstalled web-app launchers and HEY's mailto handler | Install > Web App (Omarchy's set could come back as presets) |
| LM Studio | Install > Flatpak |

### Justified

| Feature | Why it stays out |
|---|---|
| Battle.net | umu-launcher is not in stonking |
| ONCE | a GitHub binary, and it needs Docker |
| ChatGPT desktop, Grok Bot, Hermes Desktop, Perplexity | only third parties' snaps or nothing; web apps and the agents cover them |
| T3 Code | a GitHub release only |
| Hibernation | out of the first release (docs/0 and docs/1 give different reasons: Secure Boot lockdown versus scope) |
| Direct boot of a UKI, Limine's refresh | the distro boots with GRUB only |
| Package channels | the distro's apt repository has none |
| Upgrade to Quattro | Omarchy's own migration path |
| Log upload, the Omarchy Discord | Omarchy's own services |
| The preinstalls toggle | nothing removable is preinstalled |
| Docker: sudoless Docker, the Docker databases, the Docker TUI | Docker is not preinstalled: the distro's maintainer's decision (2026-10-16, docs/6 choice 71) |
| Obsidian's theme sync | Obsidian is not preinstalled: the distro's maintainer's decision (2026-10-16, docs/6 choice 71) |
| Windows VM | it runs in a Docker container, so it stays out with Docker |
| Brave, Edge and Zen (Install > Browser, with their remove and default-browser entries) | the distro's maintainer's decision (2026-10-16, docs/6 choice 74); the menu keeps Chromium, Chrome, Brave Origin and Firefox, and the browser-detection lists still recognize these if installed another way |
| Helix, Cursor and Zed (Install > Editor) | the distro's maintainer's decision (2026-10-16, docs/6 choice 74); the menu keeps VS Code, VSCodium, Sublime Text, Vim and Emacs, and Helix's theme template still themes a Helix installed another way |
| Sunshine, the game-streaming host, with its installer and remover | the distro's maintainer's decision (2026-10-16, docs/6 choice 78); Flathub's `dev.lizardbyte.app.Sunshine` stays installable through Install > Flatpak |
| Omarchy's own apps try, omawrite, omacut and omacalc | the distro's maintainer's decision (2026-10-16, docs/6 choice 80): none has a release build to install without a package of the distro's own (try needs Ruby, which choice 71 keeps out), and GNOME Calculator replaced omacalc (choice 47) |
| The six Nerd Font installers (Install > Style > Font) and `omarchy-install-font` | the distro's maintainer's decision (2026-10-16, docs/6 choice 72): nothing in Omarchy uses these fonts by name; Style > Font already offers the image's monospace fonts, and its one Nerd Font, JetBrains Mono, carries the icon glyphs |
| OpenClaw: installer, remover, CLI installer, default-agent choice, launcher, onboarding | the distro's maintainer's decision (2026-10-16, docs/6 choice 73); Omarchy installs it from its own npm-based package |
| The PHP development environment (Install and Remove > Development > PHP, with PHP, Laravel and Symfony) | nothing in the desktop uses PHP; Symfony was removed with the port, PHP and Laravel by the distro's maintainer's decision (2026-10-16, docs/6 choice 41) |

## System, install and hardware files

The 92 files deleted under `install/`, `etc/` and `default/` went in four port commits, none of whose messages gives a reason: `ef4c9211` "Port Omarchy v4.0.4 to Ubuntu" (60 files), `4b680c26` "Remove features we provide through Ubuntu" (29), `c304e943` "Trim pre-installed software" (2), `3c21fd64` "Don't customize firewall" (1). The reasons below are from docs/6, docs/1, docs/4 and `PORT.md`. Facts were read from the live root filesystem tarball built 2026-10-16 (kernel 7.3.0-9), stonking's packages on Launchpad, and mainline Linux 7.3-rc7.

### Restore, partly restore, or unclear

| Feature | Files | What it did | Removed because | Checked facts | Verdict |
|---|---|---|---|---|---|

### Replaced

| Feature | What does the job instead |
|---|---|
| mkinitcpio files | initramfs-tools, `oaxaca-nvidia`'s hook, `oaxaca-base`'s Thunderbolt option |
| Snapper | Timeshift (docs/6 choice 38) |
| SDDM's Wayland greeter | `oaxaca-session` |
| The passwordless keyring | the keyring unlocked by the login password (docs/4 choice 14) |
| Plymouth's theme file | the distro's plymouth package |
| `nsswitch.conf` | Ubuntu's, with mDNS |
| The DNS and timezone sudoers rules | `omarchy-dns` on nmcli and D-Bus; `omarchy-timezone` |
| The icon links, Chromium's first-run preferences | the distro's own setup |
| The Bluetooth pairing agent | blueman's applet (see [Open questions](#open-questions)) |
| CUPS hardening | Ubuntu's `cups-browsed` runs as its own user, browses only DNS-SD and has an AppArmor profile; `CreateRemoteCUPSPrinterQueues No` is the one setting missing |
| NVIDIA drivers (`nvidia.sh`) | `oaxaca-drivers-install` with Canonical's signed modules, including the 580 branch for GPUs before Turing |
| Vulkan drivers (`vulkan.sh`) | `mesa-vulkan-drivers`, in the image |
| Motorcomm YT6801 Ethernet (`fix-yt6801-ethernet-adapter.sh`) | the in-kernel `dwmac-motorcomm` |
| The Surface's Marvell Wi-Fi firmware (`surface.sh`) | `linux-firmware-marvell-wireless`, in the image |
| Most of the Surface and MacBook SPI keyboard modules | Ubuntu's initramfs already holds them; the one each lacks came back (see [Restored](#restored)) |

### Justified

| Feature | Why it stays out |
|---|---|
| pacman's update guard, configuration and mirrors | Ubuntu uses apt |
| Limine | the distro boots with GRUB (docs/1 section 6) |
| Battle.net | umu-launcher is not in stonking |
| The hibernate branch of the ASUS sleep hook | hibernation is out |
| Shutdown timeouts and open-file limits | taste; Ubuntu's user manager already stops in 5 s |
| plocate tuning, dirmngr keyservers, sudo's password tries | Ubuntu's defaults |
| zram and zswap, and the zram tuning in `99-omarchy-sysctl.conf` | swap on zram is not used |
| Docker's daemon setup | Docker is not preinstalled |
| resolved's multicast setting | a no-op on Ubuntu |
| faillock | Ubuntu's PAM stack has no `pam_faillock` |
| The powerprofilesctl shebang | Ubuntu's is already `/usr/bin/python3` |
| Omarchy's ISO provisioning and factory reset | Calamares installs; the reset relied on Limine and mkinitcpio |
| Network cleanup | archinstall leftovers |
| The PATH for `ssh host command` (`ssh-command-path.sh` added mise's shims and `~/.local/bin` to `/etc/security/pam_env.conf`) | the distro's maintainer's decision (2026-10-16, docs/6 choice 79) |
| The BCM4360's Wi-Fi driver | `broadcom-sta-dkms` only, so it needs a MOK |
| TUXEDO and Slimbook keyboard backlight | `tuxedo-drivers` is DKMS and not in stonking |
| Apple T2 | an out-of-tree kernel and a pacman repository |
| FRED on Panther Lake (`intel/fred.sh`) | `CONFIG_X86_FRED=y` and mainline's default is on, so `fred=on` changes nothing |
| MacBook SPI keyboard DKMS (`macbook12-spi-driver-dkms`) | Ubuntu's kernel has the driver as signed modules |
| Apple-style F-keys (`fix-fkeys.sh`, `hid_apple fnmode=2`) | a preference, not a fix for a device: it makes the top row send F1 to F12 (brightness and volume only with Fn) on every keyboard the driver handles, genuine Apple keyboards included; Omarchy wants it for Apple-layout keyboards such as Lofree's, and the kernel already sends F1 to F12 first on the clones it recognizes (Keychron, Epomaker and others) |

## Packages dropped from the base list

Omarchy's `install/omarchy-base.packages` (v4.0.4) names 97 packages that the port's list did not have when the audit was written. The port's commits that removed them, `ef4c9211` ("Port Omarchy v4.0.4 to Ubuntu") and `c304e943` ("Trim pre-installed software"), have empty message bodies; the recorded reasons are the comments in the port's package list and docs/6, "Core and apps" and choice 15 ("nothing of Omarchy's taste"). Neither the plan nor the policy has a rule about what to preinstall, so the trim rested on choice 15 alone.

### Renamed for Ubuntu or provided another way (no loss)

| Omarchy's package (Arch) | On Oaxaca |
|---|---|
| avahi | `avahi-daemon` |
| bluez-utils | `bluez`, `bluez-tools` |
| fcitx5-gtk, fcitx5-qt | `fcitx5-frontend-gtk3`, `-gtk4`, `-qt6` |
| fd | `fd-find` |
| gpu-screen-recorder | `gpu-screen-recorder-cli` |
| gvfs-mtp, gvfs-nfs, gvfs-smb | `gvfs-backends` |
| libvips | `libvips-tools` |
| nautilus-python | `python3-nautilus` |
| networkmanager | `network-manager` |
| noto-fonts, -cjk, -emoji | `fonts-noto-core`, `-cjk`, `-color-emoji` |
| nss-mdns | `libnss-mdns` |
| nvim | `neovim` |
| python-gobject | `python3-gi` |
| qt6-imageformats | `qt6-image-formats-plugins` |
| sushi | `gnome-sushi` |
| tesseract, tesseract-data-eng | `tesseract-ocr`, `tesseract-ocr-eng` |
| tldr | `tealdeer` |
| woff2-font-awesome | `fonts-font-awesome` |
| yaru-icon-theme | `yaru-theme-icon` |
| zbar | `zbar-tools` |
| libsecret | `libsecret-1-0` (Arch's `secret-tool` is lost; low value) |
| libyaml | `libyaml-0-2` |
| asdcontrol, hyprland-preview-share-picker, localsend, ffmpegthumbnailer, pamixer | the distro's desktop packages |
| hyprland, quickshell, sddm, uwsm, gnome-keyring, wireplumber, xdg-desktop-portal-gtk, -hyprland | the distro's session packages |
| ttf-ia-writer, ttf-jetbrains-mono-nerd-basic | `oaxaca-fonts` |
| chromium | the xtradeb PPA's build, preinstalled |
| evince | Papers (stonking's evince is an alpha) |

### Justified

| Package | Why |
|---|---|
| expac, fakeroot, pacman-contrib, yay | pacman and AUR tooling |
| kernel-modules-hook | an Arch pacman hook; Ubuntu keeps old kernel packages installed |
| inetutils | `hostname` and `iputils-ping` cover what is used |
| tzupdate | not in stonking; Calamares guesses the timezone itself |
| ufw-docker | not in stonking; re-check if Docker comes back with ufw enabled |
| aether | Omarchy's theme designer; not in stonking, and its repository has no licence, so it cannot be redistributed |
| python-poetry-core | nothing uses it (the list's recorded reason, "dev-env installs them via mise", is wrong: dev-env does not) |
| dotnet-runtime | Omarchy shipped it for Pinta; justified only if Pinta comes from Flathub, which bundles .NET (the recorded reason is wrong too) |
| qemu-user-static-binfmt | for multi-architecture Docker builds; justified while Docker is out |
| Obsidian | Omarchy's preinstalled notes app, with Super+Shift+O and theme sync; the distro's maintainer chose not to restore it (2026-10-16, docs/6 choice 71) |
| ruby | Omarchy ships a base Ruby on purpose (upstream `b7989ac8`); the distro's maintainer chose not to restore it (2026-10-16, docs/6 choice 71) |
| docker.io, docker-buildx, docker-compose-v2 | Omarchy preinstalls and enables Docker; the distro's maintainer chose not to restore Docker (2026-10-16, docs/6 choice 71) |
| Pinta, Moonlight | Omarchy's preinstalled apps (Flathub here); the distro's maintainer chose not to restore them (2026-10-16, docs/6 choice 71) |
| LibreOffice (preinstalled) | the distro's maintainer chose not to restore it (2026-10-16, docs/6 choice 71); Install > Productivity > LibreOffice installs Canonical's snap on demand |
| omarchy-nvim, with lua5.1, luarocks and tree-sitter-cli | Omarchy's LazyVim configuration for Neovim; the distro's maintainer chose not to restore it (2026-10-16, docs/6 choice 71); Neovim is preinstalled with its own defaults |
| libpq-dev, libmariadb-dev | headers for Rails' PostgreSQL and MySQL drivers in Omarchy's dev-env ruby; the distro's maintainer chose not to restore it (2026-10-16, docs/6 choice 71) |

### Restore candidates

| Package | What it is | Facts (stonking, 2026-10-16) | How |
|---|---|---|---|

## Features cut inside files the port kept

| Feature | Where | What it did | Removed because | Checked facts | Verdict |
|---|---|---|---|---|---|
| Obsidian binding and theme sync | `applications.lua` (Super+Shift+O), `omarchy-theme-set` | launch and theme Obsidian | docs/6, core and apps | Snap Store (`obsidianmd`) and Flathub | **Justified**: the distro's maintainer chose not to restore it (2026-10-16, docs/6 choice 71) |
| Symfony development environment | `bin/omarchy-install-dev-env`, `-remove-dev-env` | `omarchy install dev-env symfony`, which installed PHP and `symfony-cli` | none recorded; the branches were removed cleanly in `ef4c9211` | Symfony is a PHP web framework; nothing in Omarchy or the port uses it; the rest of Install > Development > PHP went too (docs/6 choice 41) | **Justified**: dropped by the distro's maintainer, 2026-10-16 |
| FRED kernel parameter | `install/hardware/all.sh` (`fred=on` on Panther Lake) | turns on Intel's FRED event delivery | docs/6: wrote Limine drop-ins | `CONFIG_X86_FRED=y` in the image's kernel, and mainline's default is on | **Justified** (a no-op on Ubuntu's kernel) |
| RetroArch CRT shader and full core set | `bin/omarchy-install-gaming-retroarch` | CRT look, about 30 cores | in-file comment: no Ubuntu packages; the Online Updater fetches them | | **Justified** |
| HEY bindings and mailto | `applications.lua`, `mimeapps.list` | HEY web app | choice 27, the maintainer's request | Super+Shift+E opens Thunderbird | **Replaced** |
| Omawrite and lazydocker bindings | `applications.lua` | Omarchy's own apps | choice 5 | omawrite stays out (docs/6 choice 80); lazydocker is not in stonking | **Justified** |
| OpenClaw as default agent | `bin/omarchy-default-agent`, `bin/omarchy-agent` | `omarchy default agent openclaw`, and the agent launcher's OpenClaw branch | `PORT.md`: only a third party's snap | OpenClaw is not restored (docs/6 choice 73); the launcher's branch went with it on 2026-10-16 | **Justified** |
| Bluetooth pairing agent `bt-agent.service` | `install/user/first-run/enable-user-units.sh` | headless pairing | docs/6: blueman's applet autostarts | not checked that XDG autostart runs under the uwsm session | **Replaced**, to confirm on a booted Oaxaca |
| Debug log upload | `bin/omarchy-debug` | 24-hour shareable URL on logs.omarchy.org | in-file comment: no upload service | Omarchy's own service | **Justified** |
| Performance power profile on AC | `bin/omarchy-powerprofiles-set` | performance on AC | in-file comment (Legion fans; Ubuntu's default is balanced) | | **Justified** |
| Snapshots | `omarchy-snapshot`, `omarchy-update` | Snapper and Limine | choice 38 | | **Replaced** (Timeshift on btrfs) |
| Faillock (10 tries, 120 s) | `omarchy-apply-lock`, `install/config/all.sh` | lockout after failed passwords | docs/6 | Ubuntu's `common-auth` has no `pam_faillock` | **Justified** |
| Passwordless default keyring | `install/user/all.sh`, `install/login/all.sh` | keyring without a password | docs/4 choice 14 | | **Justified** |
| Arch setup steps (docker.sh, theme-system.sh, pacman, module cleanup, service enables) | `install/config/*`, `install/post-install/all.sh`, `enable-services.sh` | Arch-specific setup | docs/6, choice 13 | | **Justified** |
| Emacs daemon theme integration | `bin/omarchy-install-editor-emacs` | themed Emacs | Omarchy's own AUR package | | **Justified** |
| umu-launcher, wine-staging for Lutris | `bin/omarchy-install-gaming-lutris` | Proton runner | in-file comment | not in stonking | **Justified** |
| Package cache keeps two versions | `omarchy-update-pkg-prune` | offline downgrade | in-file comment | | **Justified** |
| Update conflict handler, keyring, AUR steps, stable-channel downgrade | `omarchy-update*`, `omarchy-reinstall-pkgs` | pacman-only | docs/6 | | **Justified** |

## Tests

On 2026-10-16 the 62 shell test files that failed on this branch were sorted (`PORT.md`, "Tests"): a test of something the port deleted was deleted, a test of Arch behavior in a script the port kept was rewritten for the port's behavior. All of these are **Justified**: each tested a removal recorded above or in `migrations/README.md`.

Deleted test files, each with what it tested and the port commit that deleted it (tests that came back with their feature are listed in [Restored](#restored)):

| Test file | What it tested | Deleted by |
|---|---|---|
| `battlenet-test.sh` | the Battle.net installer and launcher | `ef4c9211` (Port Omarchy v4.0.4 to Ubuntu) |
| `copy-url-shortcut-migration-test.sh` | migration `1786643346` | `46dc3cdc` (Handle migrations) |
| `hermes-cli-migration-test.sh` | migration `1787760281` | `46dc3cdc` |
| `hermes-skills-migration-test.sh` | migration `1787843905` | `46dc3cdc` |
| `hermes-skin-migration-test.sh` | migration `1788619462` | `46dc3cdc` |
| `legacy-power-udev-rules-migration-test.sh` | migration `1788102906` | `46dc3cdc` |
| `limine-cmdline-migration-test.sh`, `limine-defaults-test.sh` | Limine's defaults (`etc/limine-entry-tool.d/`) and migration `1786482992` | `ef4c9211`, `46dc3cdc` |
| `nvidia-kms-hook-test.sh` | the mkinitcpio hook file `etc/mkinitcpio.conf.d/omarchy_hooks.conf` | `ef4c9211` |
| `retired-installer-artifacts-migration-test.sh` | migration `1788025225` | `46dc3cdc` |
| `security-fido2-migration-test.sh` | migration `1787494718` | `46dc3cdc` |
| `snapper-timeline-leak-test.sh` | migration `1784809452` (Snapper) | `46dc3cdc` |
| `t2-hardware-test.sh` | the Apple T2 setup (`install/hardware/apple/fix-t2.sh`) and migrations `1785944594`, `1786137597` | `ef4c9211`, `46dc3cdc` |
| `t3code-install-test.sh` | the T3 Code installer and remover | `ef4c9211` |
| `terminal-keybinding-migration-test.sh` | migration `1780057136` (Shift+Enter in terminals; the shipped terminal configurations already have the bindings) | `46dc3cdc` |
| `update-pacman-guard-test.sh` | `omarchy-update-pacman-guard` | `ef4c9211` |
| `zram-migration-test.sh` | migration `1785013000` | `46dc3cdc` |
| `launch-openclaw-test.sh`, `openclaw-onboard-test.sh` | `omarchy-launch-openclaw` and `omarchy-openclaw-onboard`, removed with OpenClaw (docs/6 choice 73) | 2026-10-16 |

Test cases deleted from files that stay: the OpenClaw cases in `default-agent-test.sh` (the launcher branch) and `remove-ai-test.sh` (the remover), and the `omarchy-install-font` cases in `desktop-entry-launch-test.sh` (2026-10-16, docs/6 choices 72 and 73); Bluetooth's `bt-agent.service` (`4b680c26`); migrations `1787515927`, `1787815267`, `1788724825`, `1785617047`, `1788577553`, `1785846769` (`46dc3cdc`); `omarchy-remove-preinstalls` (`c304e943`); the OpenClaw installer, the Zed and Heroic installers, Omarchy's CUPS hardening, the update's file- and package-conflict handler and its keyring and AUR steps, the hibernation setup, Remove > AI, and the omarchy-dev package channel (all `ef4c9211`).

## Broken references and leftovers

Things in the port today that call something deleted, or ship without the feature they served (fixed ones are in [Restored](#restored)):

- Scripts with nothing calling them: `omarchy-theme-set-t3code`; `install/omarchy-other.packages` (Arch package names, read by nothing).

## Restored

Every feature added back since the audit, with the choice in docs/6 that records the reason it holds on Ubuntu.

| Feature | What came back | Choice |
|---|---|---|
| Firewall | ufw on for the next boot, LocalSend's port 53317 allowed, Ubuntu's policies (deny incoming), no Docker rules; `install/config/firewall.sh` | 40 |
| Wi-Fi power save off | Omarchy's `etc/NetworkManager/conf.d/omarchy-wifi-powersave.conf` (`wifi.powersave = 2`), over Ubuntu's `wifi.powersave = 3`: link drops on Intel BE200/BE211 firmware | 42 |
| Tools kept files call | ttfx (built in the distro's apt repository) for the screensaver; inxi for the debug report; starship, eza and zoxide for the prompt and the `ls`, `lt` and `cd` aliases; btop and lazygit with Omarchy's configurations for the agent skill. Tensaku's two callers (`omarchy-clipboard-open`, imv's Ctrl+E) moved to swappy instead, which replaced Tensaku on purpose (choice 29) | 43 |
| Hyprland's reload guard around upgrades | `oaxaca-config`'s preinst pauses, its postinst resumes (Omarchy's libalpm hooks, for dpkg) | 44 |
| systemd-oomd scope | Omarchy's `app.slice` drop-in, plus `user@.service` set to `auto`, so the compositor is not a kill candidate | 45 |
| SSH keepalive | `ServerAliveInterval 15`, `ServerAliveCountMax 3`, `ConnectTimeout 10` as a package file in `etc/ssh/ssh_config.d/`, for the kept `ssh-reconnect` | 46 |
| Basic tools | unzip, GNOME Disks, GNOME Calculator in place of Omacalc (Super+Ctrl+Q, the Calculator key), btop with Super+Ctrl+T and theme sync; `oaxaca-desktop-apps` dropped | 43, 47 |
| Share > Receive, Install > Service > Chromium Account | Omarchy's two menu lines | 49 |
| `ic`, `ix`, `icx` aliases | `tdl c`, `tdl cx`, `tdl c cx` | 50 |
| Voxtype's first-run invitation | the post-update hook, its line in `omarchy-provision-first-run`, and `voxtype-invitation-test.sh` | 51 |
| 1Password's Chromium extension | written and removed with 1Password | 52 |
| Fingerprint skipped while the lid is closed | the port's own pam-auth-update profile, `omarchy-fprintd`: Ubuntu's line with Omarchy's `pam_exec` gate in front | 53 |
| DNS for networks joined later | NetworkManager's global DNS over D-Bus as well as the profiles, granted by a polkit rule | 54 |
| ASUS Panther Lake display options | `xe.enable_dpcd_backlight=1` (B9406, UX5406AA) and `xe.enable_panel_replay=0` (B9406) in `/etc/modprobe.d`, on the same DMI match; need on Ubuntu not verified ([Open questions](#open-questions)) | 55 |
| Intel video acceleration | `libmfx-gen1.2` (Quick Sync) or `i965-va-driver` (GMA-era GPUs), by GPU, at install | 56 |
| BCM4331 Wi-Fi firmware | `firmware-b43-installer` on that PCI id (multiverse; its postinst downloads the firmware from a third party's GitHub release at install) | 57 |
| inotify watch limit | `fs.inotify.max_user_watches=524288` over localsearch's 65536 | 58 |
| whois | in the base list | 59 |
| inxi | with the tools the kept files call | 43 |
| Wi-Fi 7 off only on a Dell XPS on Panther Lake | the kept `fix-wifi7-eht.sh` turned Wi-Fi 7 off on every BE200 and BE211, the Legion's card included; now only on the machines its comment names, and `oaxaca-config`'s postinst removes the file elsewhere; need on Ubuntu not verified | 60 |
| Surface keyboard at the disk encryption passphrase prompt | an initramfs-tools hook that adds `surface_aggregator_hub`, the one of Omarchy's ten modules Ubuntu's initramfs lacks | 63 |
| MacBook8,1 SPI keyboard at the same prompt | an initramfs-tools hook that adds `spi-pxa2xx-pci`, the one module Ubuntu's initramfs lacks | 64 |
| Intel IPU7 camera (partial) | libcamera, its GStreamer element and its PipeWire plugin on the OV08X40 match; Ubuntu's kernel has the drivers and firmware | 65 |
| Dell XPS haptic touchpad | `packages/dell-xps-touchpad-haptics` in the build repository, installed on the detector's match; Hardware > Touchpad Haptics | 66 |
| Framework 16 keyboard lighting | `packages/qmk-hid` in the build repository, installed by `framework16.sh` | 67 |
| ASUS ROG tools and the Hybrid GPU toggle | `packages/asusctl` (6.5.0, from `github.com/OpenGamingCollective/asusctl`) and `packages/supergfxctl` (5.2.7); `asus-rog.sh`, `omarchy-hw-hybrid-gpu`, `omarchy-toggle-hybrid-gpu`, `force-igpu`, the start delay and their tests (`hw-hybrid-gpu-test.sh`, `hybrid-gpu-test.sh`); Hybrid GPU shows only on ASUS ROG laptops with two GPUs, and the scripts call `gnutimeout` | 68 |
| mise | preinstalled from mise's own apt repository (`mise.jdx.dev/deb`) by the distro's image build, so apt updates it, as Omarchy preinstalls it; the port's own menu entry and on-demand installer (`omarchy-mise-ensure`) are gone, so the commands that use mise are Omarchy's again | 69 |
| dua-cli and the Disk Usage launcher | `dua-cli` in the base list and Omarchy's `applications/Disk Usage.desktop` (`dua i /` in a floating terminal), with Yaru's `disk-usage-app` icon since no theme in the image has Omarchy's `disk-usage`; migration `1792196970` adds the launcher for existing users | 70 |
| Heroic Games Launcher | Install and Remove > Gaming > Heroic (Epic Games), Omarchy's menu lines, from Flathub's verified `com.heroicgameslauncher.hgl` instead of Omarchy's repository; the remover deletes the app's data and `~/Games/Heroic`, as Omarchy's does | 75 |
| Minecraft | Install and Remove > Gaming > Minecraft, Omarchy's menu lines and remover; the installer downloads Mojang's own `Minecraft.deb` and installs it with apt, after the distro's `oaxaca-gdk-pixbuf-compat`, which provides the GdkPixbuf library's old package name that Mojang's package still depends on and Ubuntu no longer provides | 76 |
| NordVPN and Bitwarden | Install > Service > NordVPN and > Bitwarden, Omarchy's menu lines, from the vendors' own snaps (`nordvpn`, publisher NordVPN; `bitwarden`, publisher 8bit Solutions LLC, Bitwarden's company; both verified on the Snap Store; Omarchy's Bitwarden CLI is left out) instead of the AUR; Remove > Snap removes them, as Omarchy's general remove does | 77 |
| `tcp_mtu_probing=1` | Omarchy's `etc/sysctl.d/99-omarchy-sysctl.conf` with only its MTU probing line, so connections recover on networks that drop path-MTU messages | 79 |
| herdr and cliamp | Install and Remove > Development > Herdr and > Service > cliamp, installed per user through mise (`mise use -g`, both in mise's registry, from their own release binaries); Omarchy's bindings (Super+Ctrl+Return, Super+Ctrl+K, Super+Shift+Alt+M) and the `h` alias, and the kept herdr helpers are used again | 80 |
| Learn > Herdr | Omarchy's menu line, which lists herdr's key bindings (`omarchy-menu-herdr-keybindings`), shown only when herdr is installed | 80 |
| Wireless regulatory domain | `install/hardware/set-wireless-regdom.sh`: the country of the timezone chosen at install, written as `options cfg80211 ieee80211_regdom=XX` to `/etc/modprobe.d/omarchy-wireless-regdom.conf` instead of Arch's `/etc/conf.d/wireless-regdom`; a Wi-Fi card that manages its own regulatory domain, such as Intel's, ignores it | 82 |
| OBS Studio | Install and Remove > Productivity > OBS Studio, from Flathub's `com.obsproject.Studio`, one of the OBS project's two official channels (its PPA has no build for this Ubuntu release); Omarchy preinstalls it, the port offers it instead. Omarchy's window rule for `com.obsproject.Studio` was kept and matches the Flatpak | 83 |
| Xournal++ and Kdenlive | Install and Remove > Productivity > Xournal++ and > Kdenlive, from Flathub's `com.github.xournalpp.xournalpp` (verified, the Xournal++ team's) and `org.kde.kdenlive` (verified, KDE's), each an official channel its project names; Omarchy preinstalls both, the port offers them instead. Omarchy's `config/xournalpp/settings.xml` (dark mode forced) is not restored; Omarchy's window rule for `org.kde.kdenlive` was kept and matches the Flatpak | 84 |
