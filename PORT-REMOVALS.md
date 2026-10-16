# Audit of what the port removed from Omarchy

Written 2026-10-16, after three removals turned out to be wrong: the agent skills (deleted as Omarchy's contributing workflow, though seven of their nine files are help for users), the update snapshots (deleted with Limine, though only the boot menu needed Limine), and the launcher's handling of desktop ids that end in `.desktop`. This document lists everything the port removed from Omarchy v4.0.4, why, whether the reason holds, and what to restore. The [restore list](#restore-list) is for the distro's maintainer to choose from; restored so far: all of tiers 1 and 2, and items 1 to 5 of tier 2b (2026-10-16). Since 2026-10-16 the port supports other hardware (docs/6, choice 48), so Omarchy's fixes for other machines are candidates too: tier 2b.

The port follows the rule the distro's Ubuntu base follows: nothing is installed and then removed. The port starts from a minimal base, Ubuntu's own configuration plus the parts of Omarchy the desktop needs to run, and adds each further Omarchy feature by a recorded choice that gives the reason. Restoring an item below is such an addition: it is written for Ubuntu, recorded as a choice in the build repository's `docs/6 - omarchy-port.md`, and is not a revert of the commit that removed Omarchy's version.

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
- **Restore**: the reason does not hold, and the feature works on Ubuntu within the project's requirements (Secure Boot without a MOK, Ubuntu's signed GRUB and kernel, packages from Ubuntu's archive, vendor apt repositories, the Snap Store or Flathub).
- **Partial**: part of the feature can come back, or it can come back another way.
- **Restored**: an item the port has since added back, with the date and the choice in docs/6 that records it.
- **Unclear**: the facts needed were not reachable.

## How the audit was done

The deleted files are `git diff --name-status --diff-filter=D v4.0.4 oaxaca` on this branch: 321 files. The 106 migrations among them are covered in `migrations/README.md`; the deleted tests are listed in [Tests](#tests) below. The rest, 183 files, plus the 70 menu entries removed from `default/omarchy/omarchy-menu.jsonc`, the 97 package names that Omarchy's `install/omarchy-base.packages` has and the port's does not, and the features cut inside the 121 files both sides have, were read one by one against the reasons recorded in this repository's docs and the fork, and checked against stonking on Launchpad, the Snap Store (`snap info`), Flathub, vendor apt repositories, mainline Linux 7.3 and the live root filesystem built 2026-10-16.

## What the audit found overall

- **No commit says why anything was removed.** The commits that deleted the files, `ef4c9211` "Port Omarchy v4.0.4 to Ubuntu", `c304e943` "Trim pre-installed software", `4b680c26` "Remove features we provide through Ubuntu", `3c21fd64` "Don't customize firewall" and `963b196e`, have no message body. Every recorded reason is in docs/6, docs/1, docs/0, `PORT.md` or the comments in the port's package list.
- **The preinstall trim rests on one choice.** docs/6 choice 15 ("nothing of Omarchy's taste") dropped Omarchy's command-line tools and preinstalled apps; neither the plan nor the policy has a rule about what to preinstall. Some of what went is basic (no `unzip`, no calculator, no system monitor), and some is still wired into the port's own files (the prompt, the `ls` and `cd` aliases, the debug report).
- **Removals were coupled to Limine and Snapper wholesale.** Snapshots, the factory reset and two ASUS display fixes went because Omarchy delivered them through Limine or Snapper, though the feature itself works with GRUB and Timeshift.
- **Reasons that expired were not revisited.** Voxtype's invitation went when Voxtype could not be installed and stayed gone after it could; Brave and Edge went as "proprietary builds replaced by open counterparts" and stayed gone after Chrome and VS Code came back; the `ic`/`ix`/`icx` aliases stayed gone after tmux came back.
- **Some "Ubuntu's configuration" removals dropped a reason specific to this desktop.** docs/6's rule follows Ubuntu's settings unless a reason is specific to this desktop; Wi-Fi power save (link drops on Intel BE200 firmware, the Legion's card), the SSH keepalive (needed by the kept `ssh-reconnect`) and the out-of-memory killer's scope (keeps the compositor out) had such reasons.
- **The rule "Delete rather than stub" was not followed through.** Scripts were kept with nothing calling them, and kept scripts call deleted programs (section [Broken references](#broken-references-and-leftovers)).

## Restore list

Ranked by what a user meets first. Each item names its section below.

**1. Broken or weaker than Omarchy today**

1. Firewall, **restored 2026-10-16** (docs/6, choice 40): ufw shipped off (`ENABLED=no`), so nothing filtered inbound traffic, and Setup > Security > SSH's `ufw limit 22/tcp` did nothing. `install/config/firewall.sh` now allows LocalSend's port 53317 and turns ufw on for the next boot, with Ubuntu's policies (deny incoming) and without Omarchy's Docker rules. ([System files](#system-install-and-hardware-files))
2. Wi-Fi power save, **restored 2026-10-16** (docs/6, choice 42): Ubuntu's `wifi.powersave = 3` was back on; Omarchy turned it off for link drops on Intel BE200/BE211 firmware, the Legion's card. ([System files](#system-install-and-hardware-files))
3. Broken references, **restored 2026-10-16** (docs/6, choice 43): kept files that call a program the port dropped. Each is fixed by restoring the program, except where the port replaced it on purpose, in which case the reference moves to the replacement. ([Broken references](#broken-references-and-leftovers))
   - Screensaver, which never runs because `bin/omarchy-launch-screensaver` exits without `ttfx`: restore ttfx 0.5.0 (`omacom/ttfx`, MIT, Rust), built in the distro's apt repository as LocalSend is.
   - Debug report, which has no hardware section: restore `inxi` (stonking universe 3.3.41).
   - Shell prompt and the `ls`, `lt` and `cd` aliases, which `default/bash/init` and `default/bash/aliases` wire but which stay dormant: restore starship (universe 1.26.0) with Omarchy's `config/starship.toml`, eza (universe 0.23.5-5) and zoxide (universe 0.10.0).
   - The ported `omarchy` agent skill, which points at btop's, lazygit's and starship's configuration files: restore btop (universe 1.4.7-1) and lazygit (universe 0.57.0) with their configurations; starship comes with the shell item above.
   - Image editing, where the clipboard's open action (`bin/omarchy-clipboard-open`) and imv's Ctrl+E (`config/imv/config`) call `tensaku-edit`: **not restored**, because Tensaku was replaced by swappy on purpose (docs/6, choice 29); both references move to swappy.
4. Reload guard, **restored 2026-10-16** (docs/6, choice 44): Hyprland's reload guard shipped but nothing pauses it during an upgrade; wire it into the config package's preinst and postinst. ([System files](#system-install-and-hardware-files))
5. Out-of-memory killer, **restored 2026-10-16** (docs/6, choice 45): the out-of-memory killer could pick the compositor: Ubuntu's policy is on `user@.service`, the case Omarchy's `app.slice` drop-in avoided. ([System files](#system-install-and-hardware-files))
6. SSH keepalive, **restored 2026-10-16** (docs/6, choice 46), which the kept `ssh-reconnect` needs. ([Kept files](#features-cut-inside-files-the-port-kept))
7. Basic tools, **restored 2026-10-16** (docs/6, choices 43 and 47; `oaxaca-desktop-apps` dropped): `unzip`, a calculator (gnome-calculator, with the Calculator key), a system monitor (btop, with Super+Ctrl+T and theme sync; restored with item 3), and Disks (`gnome-disk-utility`, today only Suggested, so never installed). ([Packages](#packages-dropped-from-the-base-list-and-their-configurations))

**2. Cheap restores**

Share > Receive and Chromium's Google account (one menu line each; [Commands](#commands-launchers-and-menu-entries)); the `ic`/`ix`/`icx` aliases, the Voxtype invitation, 1Password's Chromium extension, the fingerprint lid-closed gate and DNS for networks joined later ([Kept files](#features-cut-inside-files-the-port-kept)); the ASUS Panther Lake display fixes, Intel Quick Sync and i965 video drivers, BCM4331 Wi-Fi firmware and the inotify limit ([System files](#system-install-and-hardware-files)); `inxi` and `whois` ([Packages](#packages-dropped-from-the-base-list-and-their-configurations)).

**Restored** 2026-10-16: all of tier 2 (docs/6, choices 49 to 59; `inxi` came back with tier 1, item 3).

**2b. Hardware for other machines** (added 2026-10-16 with docs/6, choice 48; facts from Launchpad's stonking indexes, the live root filesystem built 2026-10-16 with kernel 7.3.0-9, and mainline Linux v7.3-rc7)

Restore, ranked by how many machines each one helps:

1. **Restored** 2026-10-16 (docs/6, choice 62). Wireless regulatory domain (`install/hardware/set-wireless-regdom.sh`): Omarchy derives the country from the timezone for every machine with Wi-Fi. `cfg80211` is a module in the image with the parameter `ieee80211_regdom`, and `wireless-regdb` is installed, so the port can write `options cfg80211 ieee80211_regdom=XX` to `/etc/modprobe.d` at install, XX from `zone.tab`. Small.
2. **Restored** 2026-10-16 (docs/6, choice 63), as an initramfs-tools hook with `force_load`. Surface keyboard at the disk encryption passphrase prompt (`fix-surface-keyboard.sh`): the image's initramfs (`MODULES=most`) already holds the Surface keyboard modules except `surface_aggregator_hub`; an initramfs-tools hook gated on DMI "Microsoft Corporation" and "Surface" adds it. The Marvell Wi-Fi firmware (`surface.sh`) is already in the image. Small.
3. **Restored** 2026-10-16 (docs/6, choice 64), as an initramfs-tools hook for Omarchy's whole module list. MacBook SPI keyboard (`apple/fix-spi-keyboard.sh`): `applespi` and its SPI modules are in the initramfs except `spi-pxa2xx-pci`, which Omarchy lists for the MacBook8,1; one gated `manual_add_modules` line. Omarchy's `macbook12-spi-driver-dkms` is not needed (and is DKMS). One line.
4. **Restored** 2026-10-16 (docs/6, choice 66): `packages/dell-xps-touchpad-haptics` in the distro's build repository. Dell XPS haptic touchpad (`dell-xps-touchpad-haptics.sh`, detector `omarchy-hw-dell-xps-haptic-touchpad`, kept): Omarchy's package is a CLI, a Python daemon over hidraw, a systemd unit and a udev rule, MIT, no kernel module. Package it natively in the distro's apt repository, install it on the detector's match, and restore the menu's `trigger.hardware.touchpad-haptics` entries (moved here from tier 5). Small.
5. **Restored, partial** 2026-10-16 (docs/6, choice 65): libcamera on the match, untested without the hardware. Intel IPU7 camera (`intel/ipu7-camera.sh`, ACPI id `OVTI08F4`, the OV08X40 sensor on Lunar Lake and Panther Lake laptops): the kernel side, sensor driver and firmware included, is in Ubuntu's signed kernel (`intel-ipu7`, `intel-ipu7-isys`, `ov08x40`, `ipu7ptl_fw.bin`), which corrects the earlier "no sensor module". Omarchy's user-space stack is DKMS throughout; libcamera 0.7.0 (main) supports `intel-ipu7` through its simple pipeline with a software ISP. **Partial**: install `libcamera0.7`, `libcamera-ipa`, `gstreamer1.0-libcamera` and `libspa-0.2-libcamera` on the match; image quality is unverified without the hardware.
6. Framework 16 keyboard lighting (`framework16.sh`): `qmk_hid` (BSD-3-Clause, Rust, no releases, built from a tag) in the distro's apt repository, installed on the DMI match; the kept `omarchy-theme-set-keyboard-f16` and `framework/qmk-hid.sh` udev rule then have their tool. Cosmetic. Small to larger.
7. ASUS ROG tools (`asus-rog.sh`, with the GPU-mode toggle `omarchy-hw-hybrid-gpu`, `-toggle-hybrid-gpu`, `system-sleep/force-igpu` and `supergfxd.service.d/delay-start.conf`): `asusctl` 6.3.8 and `supergfxctl` 5.2.7 (both MPL-2.0, Rust) built in the distro's apt repository the way Voxtype is, installed on the DMI match; the kernel side (`asus-wmi`, `asus-armoury`, `hid-asus`) is in Ubuntu's kernel. The kept `omarchy-theme-set-keyboard-asus-rog` then works. Larger (moved from Justified: "not in stonking" is not a reason once the distro builds it).

Replaced: `nvidia.sh` (`oaxaca-drivers-install` with Canonical's signed modules, including the 580 branch for GPUs before Turing); `vulkan.sh` (`mesa-vulkan-drivers` in the image); the YT6801 Ethernet fix (`dwmac-motorcomm` is in Ubuntu's kernel).

Still justified: the BCM4360 (`broadcom-sta-dkms` only); TUXEDO and Slimbook keyboard backlight (`tuxedo-drivers` is DKMS, not in stonking); Apple T2 (an out-of-tree kernel and pacman repository); FRED on Panther Lake (`CONFIG_X86_FRED=y` and mainline's default is on, so the option is a no-op); Apple-style F-keys (`hid_apple fnmode=2` is module-wide and would flip real Apple keyboards; taste, not a device fix).

Found in a kept file: `install/hardware/intel/fix-wifi7-eht.sh` set `options iwlwifi disable_11be=Y` for every `8086:e440` or `8086:272b` card (the BE211 and BE200), so the Legion ran with Wi-Fi 7 off, though the script's comment describes a Dell XPS Panther Lake fix. **Narrowed** 2026-10-16 (docs/6, choice 60) to a Dell XPS on Panther Lake; `oaxaca-config`'s postinst removes the file from other machines.

**3. Omarchy's defaults dropped by choice 15**

dua-cli with its launcher (starship, zoxide, eza and lazygit moved to tier 1, item 3); mise from its vendor apt repository; Docker with sudoless Docker and the database installer; the preinstalled apps (Xournal++, OBS Studio, Kdenlive, Pinta and Moonlight from Flathub, LibreOffice and Obsidian from their vendors' snaps); Omarchy's LazyVim configuration through `/etc/skel`. ([Packages](#packages-dropped-from-the-base-list-and-their-configurations), [Commands](#commands-launchers-and-menu-entries))

**4. Menu installers that work on Ubuntu**

Brave, Edge and Zen; Helix, Cursor and Zed; the six Nerd Fonts, built from the release zip `oaxaca-fonts` already uses; OpenClaw through mise; Heroic, NordVPN, Bitwarden, Sunshine and Minecraft. ([Commands](#commands-launchers-and-menu-entries))

**5. Larger projects**

A factory reset on Timeshift and `oem-config`; Omarchy's own MIT-licensed apps (herdr, cliamp, omawrite, omacut, omacalc, try) built in the distro's apt repository as LocalSend is (ttfx moved to tier 1, item 3); the Windows VM after Docker; an NVIDIA-only GPU toggle through `prime-select`; Learn > Omarchy with a caveat. (Dell XPS touchpad haptics moved to tier 2b.)


## Commands, launchers and menu entries

85 deleted files under `bin/` and `applications/` and 70 removed menu entries, grouped by feature. The commits that deleted them, `ef4c9211` (47 files), `c304e943` (37) and `963b196e` (the HEY handler), give no reason per item; the reasons are from docs/6, docs/1, docs/0 and `PORT.md`.

### Restore or partly restore

| Feature | Files and menu entries | What it did | Removed because | Checked facts | Verdict |
|---|---|---|---|---|---|
| Share > Receive | `trigger.share.receive` | opened LocalSend to receive files | none recorded; removed when LocalSend was not packaged yet | LocalSend is preinstalled since `8a7a6b3a`; Share > File, Folder and Clipboard already use it | **Restored** 2026-10-16 (docs/6, choice 49) |
| Chromium's Google account | `install.service.chromium-account` | adds Google's OAuth client to `~/.config/chromium-flags.conf` so Chromium can sign in and sync | none recorded | `bin/omarchy-install-chromium-google-account` is still on this branch and `omarchy-refresh-chromium` calls it; Chromium reads that file since `/etc/chromium.d/zz-oaxaca-user-flags` | **Restored** 2026-10-16 (docs/6, choice 49) |
| Docker: sudoless Docker, Docker databases, Docker TUI | `bin/omarchy-sudo-docker`, `-setup-security-sudoless-docker`, `-remove-security-sudoless-docker`, `-install-docker-dbs`, `-launch-docker-tui`, `applications/Docker.desktop`; `install.development.docker-dbs`, `setup.security.sudoless-docker`, `remove.security.sudoless-docker` | Omarchy preinstalls Docker, keeps the user out of the root-equivalent `docker` group behind an opt-in, and offers one-click MySQL, Postgres, Redis, MongoDB, MariaDB and MSSQL containers | `PORT.md`: they "run on Docker, whose setup the port removed"; docs/6, "Core and apps" | `docker.io` 29.7.2 is in main, `docker-compose-v2` and `docker-buildx` in universe; the scripts only use `docker run` and `usermod`; the reason is circular | **Restore** after an Install > Development > Docker entry; the TUI (lazydocker, not in stonking) is **partial** |
| Factory reset | `bin/omarchy-system-factory-reset`, `-factory-reset-finish`, `-provision-owner`; `setup.reset` | on btrfs, swapped `@` for the installer's factory snapshot, re-keyed the disk encryption and recreated the owner at first boot | docs/6: among "programs the distro cannot install"; docs/1: scripts tied to Limine and Snapper | the same mistake as snapshots: only the Limine and mkinitcpio steps were Arch-specific; btrfs installs have Timeshift; `oem-config` (universe) creates a user at first boot | **Partial**: a factory Timeshift snapshot at install, restored by the reset, then `oem-config-prepare`; the re-keying needs rewriting |
| Brave, Edge | `install.browser.brave`, `.edge`, and their remove and default-browser entries | regular Brave and Microsoft Edge | docs/6: Chrome, Edge and VS Code replaced by open counterparts | Chrome and VS Code are back in the menu, so the rule no longer holds; Brave's repository (already added for Brave Origin) has `brave-browser`; `packages.microsoft.com/repos/edge` has `microsoft-edge-stable` | **Restore** through `omarchy-pkg-repo-add` |
| Zen | `install.browser.zen` and its remove and default entries | Firefox-based browser | `PORT.md` only notes Omarchy offers it | Flathub `app.zen_browser.zen` (verified); no apt repository or snap | **Partial**: from Flathub |
| Nerd Font installers | `install.style.font` with Bitstream, Cascadia, Fira, Iosevka, Meslo, Victor | install a patched Nerd Font and switch to it | docs/6: "the Nerd Font installers" | the `ttf-*-nerd` names are Arch's; `oaxaca-fonts` already builds JetBrains Mono from the Nerd Fonts release zip; `bin/omarchy-install-font` stayed, unused, with Arch names | **Restore**: build the six from the same zip |
| Helix | `bin/omarchy-install-editor-helix`; `install.editor.helix` | Helix linked to the theme | `PORT.md`: Install > Package, without Omarchy's setup | `hx` in universe; the branch still has `helix.toml.tpl` and `omarchy-restart-helix` | **Restore** |
| Cursor | `install.editor.cursor` | Cursor editor | none recorded | Cursor's apt repository (`downloads.cursor.com/aptrepo`) has `cursor`; its signing key URL not verified | **Restore** through `omarchy-pkg-repo-add` |
| Zed | `bin/omarchy-install-editor-zed`; `install.editor.zed` | Zed themed by Omarchy's `omazed` | `PORT.md` | Ubuntu's `zed` is another program; Flathub `dev.zed.Zed` (unverified); `omazed` is nowhere | **Partial**: Flathub, no theme sync |
| btop and Obsidian theme sync | `bin/omarchy-restart-btop`, `-theme-set-obsidian` | reload btop's colors; copy the theme's `obsidian.css` into every vault | `c304e943` (the apps were no longer preinstalled) | the themes still render `btop.theme` and `obsidian.css` | btop's part **restored** 2026-10-16 (docs/6, choice 43); Obsidian's **Restore** with the app |
| OpenClaw | `bin/omarchy-install-ai-openclaw`, `-remove-ai-openclaw`, `-install-openclaw-cli`; `install.ai.openclaw`, `remove.ai.openclaw`, `setup.default.agent.openclaw`, `remove.ai` | the OpenClaw agent, its gateway and Control UI, and the default-agent choice | `PORT.md`: the snap is a third party's | Omarchy's package is the npm module; npm has `openclaw` 2026.10.4 from the project; the port installs other npm agents through mise; `omarchy-launch-openclaw` and `-openclaw-onboard` were kept | **Restore** through `mise use -g npm:openclaw` |
| Heroic, Minecraft | `bin/omarchy-install-gaming-heroic`, `-remove-gaming-heroic`, `-remove-gaming-minecraft`; their menu entries | game launchers | `PORT.md`: Install > Flatpak | Flathub `com.heroicgameslauncher.hgl` (verified), `com.mojang.Minecraft` (unverified) | **Restore** Heroic as a Flathub entry; Minecraft **partial** |
| NordVPN, Bitwarden | `bin/omarchy-install-service-nordvpn`; `install.service.nordvpn`, `install.service.bitwarden` | VPN client; password manager | `PORT.md`: Install > Snap | NordVPN's apt repository answers and its snap is the vendor's; Bitwarden's snap and Flatpak are verified | **Restore** (NordVPN like Mullvad; Bitwarden like Thunderbird) |
| Sunshine | `bin/omarchy-install-service-sunshine`, `-remove-service-sunshine` | game-streaming host | `PORT.md`: Flathub | Flathub `dev.lizardbyte.app.Sunshine` (verified) | **Partial** |
| Windows VM | `bin/omarchy-windows-vm`; `install.windows`, `remove.windows` | Windows in the `dockurr/windows` container over RDP | `PORT.md`: runs on Docker | needs Docker, `freerdp3-x11` (universe), `netcat-openbsd`; the image is from Docker Hub, not one of the project's package sources | **Partial**, after Docker, if a Docker Hub image is acceptable |
| Hybrid-GPU toggle | `bin/omarchy-hw-hybrid-gpu`, `-toggle-hybrid-gpu`; `trigger.hardware.hybrid-gpu` | ASUS-only GPU modes through supergfxd | docs/6 | `supergfxctl` is not in stonking; `nvidia-prime` (main) has `prime-select intel` / `on-demand` | **Partial**: an NVIDIA-only toggle |
| Dell XPS touchpad haptics | `trigger.hardware.touchpad-haptics` with High, Mid, Low | haptic strength on XPS Synaptics touchpads | none recorded | the tool is MIT in `omacom-io/omarchy-pkgs` (a script, a udev rule, a service); `omarchy-hw-dell-xps-haptic-touchpad` was kept | **Restore** (niche): package it like `oaxaca-hw-legion` |
| Learn > Omarchy | `learn.omarchy` | Omarchy's manual | none recorded | parts of the manual do not apply (the firewall's Docker rules, pacman, Limine), most does | **Partial**: with a caveat, or a page of the port's own |
| Disk Usage | `applications/Disk Usage.desktop` and icon | `dua i /` in a terminal | docs/6 | `dua-cli` in universe | **Partial** (with the package, section "Packages") |

### Replaced

the AUR commands (Install > Package, Snap and Flatpak); pacman upkeep (`omarchy-update-system-pkgs` with apt); the 32-bit GPU libraries (`omarchy-install-32bit-graphics`); the local package test (`UPSTREAM_DIR=… scripts/build.sh`); Learn > Arch (Learn > Ubuntu); the preinstalled web-app launchers and HEY's mailto handler (Install > Web App; Omarchy's set could come back as presets); LM Studio (Install > Flatpak).

### Justified

Battle.net (umu-launcher not in stonking); ONCE (a GitHub binary, needs Docker); ChatGPT desktop, Grok Bot, Hermes Desktop, Perplexity (only third parties' snaps or nothing; web apps and the agents cover them); T3 Code (a GitHub release only); hibernation (out of the first release; docs/0 and docs/1 give different reasons, Secure Boot lockdown versus scope); direct boot of a UKI and Limine's refresh (GRUB only); package channels (the apt repository has none); upgrade to Quattro (Omarchy's own migration path); log upload and the Omarchy Discord (Omarchy's services); Learn > Herdr (Herdr is not available); the preinstalls toggle (nothing removable is preinstalled); the PHP development environment, Install and Remove > Development > PHP with its PHP, Laravel and Symfony entries (nothing in the desktop uses PHP; Symfony was removed with the port, PHP and Laravel on 2026-10-16 by the distro's maintainer, docs/6 choice 41).

## System, install and hardware files

The 92 files deleted under `install/`, `etc/` and `default/` went in four port commits, none of whose messages gives a reason: `ef4c9211` "Port Omarchy v4.0.4 to Ubuntu" (60 files), `4b680c26` "Remove features we provide through Ubuntu" (29), `c304e943` "Trim pre-installed software" (2), `3c21fd64` "Don't customize firewall" (1). The reasons below are from docs/6, docs/1, docs/4 and `PORT.md`. Facts were read from the live root filesystem tarball built 2026-10-16 (kernel 7.3.0-9), stonking's packages on Launchpad, and mainline Linux 7.3-rc7.

### Restore or partly restore

| Feature | Files | What it did | Removed because | Checked facts | Verdict |
|---|---|---|---|---|---|
| Wi-Fi power save off | `etc/NetworkManager/conf.d/omarchy-wifi-powersave.conf` | `wifi.powersave = 2` | docs/6: Ubuntu's configuration | Omarchy's commit `da157fb9`: power save causes "20-300ms latency spikes" and "outright link drops on Intel BE200/BE211 firmware"; the Legion has a BE200; the image ships `default-wifi-powersave-on.conf` (`wifi.powersave = 3`) | **Restored** 2026-10-16 (docs/6, choice 42): Omarchy's file is back, with a note on why it overrides Ubuntu's |
| ASUS Panther Lake display fixes | `install/hardware/asus/fix-asus-ptl-b9406-display.sh`, `fix-asus-ptl-display-backlight.sh` | ExpertBook B9406: `xe.enable_panel_replay=0` (the panel froze on the last frame); B9406 and Zenbook UX5406AA: `xe.enable_dpcd_backlight=1` (brightness was on or off only) | docs/6: they wrote Limine drop-ins | the image's `xe.ko` has both parameters; mainline has no ASUS quirk for them; the DMI checks `omarchy-hw-asus-expertbook-b9406` and `-zenbook-ux5406aa` are still on the branch | **Restored** 2026-10-16 (docs/6, choice 55): the same options in `/etc/modprobe.d` on the same DMI match |
| Firewall | `install/config/firewall.sh` | ufw on: deny incoming, allow outgoing, allow LocalSend (53317 tcp/udp) | docs/6 choice 13 (ufw as Ubuntu ships it) | the image's `/etc/ufw/ufw.conf` has `ENABLED=no`: nothing filters inbound traffic; `omarchy-setup-security-sshd` adds `ufw limit 22/tcp`, which does nothing while ufw is off; LocalSend is preinstalled | **Restored** 2026-10-16 (docs/6, choice 40): a new `install/config/firewall.sh` allows LocalSend's port and sets `ENABLED=yes`; Ubuntu's policies, no Docker rules |
| Hyprland reload guard around upgrades | `default/libalpm/hooks/10-omarchy-hyprland-reload-pause.hook`, `90-…-resume.hook` | paused Hyprland's automatic config reload while the config package was being upgraded | docs/6: libalpm hooks gone | `oaxaca-hyprland-reload-guard` ships and `omarchy-hyprland-monitor-watch` asks it whether it is paused, but nothing pauses it; dpkg unpacks Hyprland's defaults under a running session | **Restored** 2026-10-16 (docs/6, choice 44): `oaxaca-config`'s preinst pauses, its postinst resumes |
| SSH keepalive | `install/config/ssh-keepalive.sh` | `ServerAliveInterval 15`, `ServerAliveCountMax 3`, `ConnectTimeout 10` | docs/6: `ssh_config.d` ships empty | the kept `ssh-reconnect` wrapper needs it | **Restored** 2026-10-16 (docs/6, choice 46): a package file in `etc/ssh/ssh_config.d/` |
| systemd-oomd scope | `default/systemd/user/app.slice.d/10-oomd.conf`, `etc/systemd/oomd.conf.d/10-omarchy.conf` | made the user's apps (`app.slice`) the kill candidates under memory pressure, never the compositor | docs/6: Ubuntu's three files | Ubuntu's `user@.service.d/10-oomd-user-service-defaults.conf` sets the kill policy on `user@.service`, the case Omarchy's comment warns "would put the compositor back in the candidate pool"; the thresholds match | **Restored** 2026-10-16 (docs/6, choice 45): the `app.slice` drop-in, plus `user@.service` set to `auto`; the global thresholds file is not needed |
| Intel video acceleration | `install/hardware/intel/video-acceleration.sh` | Quick Sync runtime and the i965 driver for older Intel | no specific reason | `intel-media-va-driver-non-free` and `libvpl2` are in the image; `libmfx-gen1.2` (QSV encode) and `i965-va-driver` are not (both universe) | **Restored** 2026-10-16 (docs/6, choice 56): `libmfx-gen1.2` or `i965-va-driver` by GPU, at install |
| Broadcom BCM4331 Wi-Fi | `install/hardware/fix-bcm43xx.sh` | `broadcom-wl-dkms` for BCM4360 and BCM4331 | docs/6: DKMS | BCM4360 needs DKMS (a MOK); BCM4331 works with the in-kernel `b43` and `firmware-b43-installer` (main) | **Restored** 2026-10-16 (docs/6, choice 57) for the BCM4331: `firmware-b43-installer` (multiverse, not main; its postinst downloads the firmware from a third party's GitHub release at install). The BCM4360 stays out: DKMS only |
| inotify watch limit | `etc/sysctl.d/90-omarchy-file-watchers.conf` | `fs.inotify.max_user_watches=524288` | docs/6: Ubuntu's value | the kernel sizes the limit from RAM (1%, up to 1048576); localsearch's `30-localsearch.conf` forces 65536, which lowers it on any machine above about 8 GB | **Restored** 2026-10-16 (docs/6, choice 58) |
| `tcp_mtu_probing=1` | `etc/sysctl.d/99-omarchy-sysctl.conf` | fixes stalled SSH and HTTPS over broken path-MTU networks | docs/6 grouped the whole file under zram | unrelated to zram | **Partial** (low) |
| PATH for `ssh host command` | `install/config/ssh-command-path.sh` | mise shims and `~/.local/bin` for non-interactive SSH commands | docs/6: Omarchy's line lacked `/usr/sbin`; `/etc/profile.d` covers login shells | `ssh host cmd` is not a login shell | **Partial** (low): with Ubuntu's full PATH |
| Wireless regulatory domain | `install/hardware/set-wireless-regdom.sh` | country code from the timezone | no reason recorded | the script writes an Arch file; Ubuntu sets no country | **Restored** 2026-10-16 (docs/6, choice 62): `options cfg80211 ieee80211_regdom=XX` |
| Voxtype first-run invitation | `install/user/first-run/install-voxtype.hook` | one-time "Install Dictation" notification | removed when Voxtype was AUR-only | Voxtype is in the distro's apt repository since choice 30 | **Restored** 2026-10-16 (docs/6, choice 51) |
| Dell XPS haptic touchpad | `install/hardware/dell-xps-touchpad-haptics.sh` | installed Omarchy's `dell-xps-touchpad-haptics` | docs/6: Arch-only package | the package's source was not reachable then; it is now (`omacom/omarchy-pkgs`, 1.0.0-4, MIT) | **Restored** 2026-10-16 (docs/6, choice 66) |

### Replaced

mkinitcpio files (initramfs-tools, `oaxaca-nvidia`'s hook, `oaxaca-base`'s Thunderbolt option); Snapper (Timeshift, choice 38); SDDM's Wayland greeter (`oaxaca-session`); the passwordless keyring (keyring unlocked by the login password, docs/4 choice 14); Plymouth's theme file (the distro's plymouth package); `nsswitch.conf` (Ubuntu's, with mDNS); the DNS and timezone sudoers rules (`omarchy-dns` on nmcli; `omarchy-timezone`); the icon links and Chromium first-run preferences; the Bluetooth pairing agent (blueman's applet; to confirm it runs under the session); CUPS hardening (Ubuntu's `cups-browsed` runs as its own user, browses only DNS-SD and has an AppArmor profile; `CreateRemoteCUPSPrinterQueues No` is the one setting missing); the MacBook SPI and Surface keyboards (in-kernel modules that initramfs-tools already adds); Motorcomm YT6801 Ethernet (in-kernel `dwmac-motorcomm`); NVIDIA (`oaxaca-drivers-install`); Vulkan drivers (`mesa-vulkan-drivers`).

### Justified

pacman's update guard, configuration and mirrors; Limine (docs/1 section 6); Battle.net (umu-launcher not in stonking); ASUS ROG tools' hibernate branch (hibernation is out; the tools themselves moved to tier 2b on 2026-10-16); shutdown timeouts and open-file limits (taste; Ubuntu's user manager already stops in 5 s); plocate tuning; zram and zswap; Docker's daemon setup (Docker is not preinstalled); resolved's multicast setting (a no-op); dirmngr keyservers; faillock (Ubuntu's stack has no `pam_faillock`); sudo's password tries; the powerprofilesctl shebang (Ubuntu's is already `/usr/bin/python3`); Omarchy's ISO provisioning and factory reset (Calamares installs; the reset relied on Limine and mkinitcpio); Apple T2 (needs a custom kernel); Apple-style F-keys for every keyboard (taste); TUXEDO and Slimbook backlight (DKMS only, so a MOK); Framework 16's qmk_hid (not in stonking; its udev rule stays); Intel FRED (`fred=on` is already the default in 7.3); Intel IPU7 camera (no sensor module or HAL within the requirements; worth stating as unsupported); network cleanup (archinstall leftovers).

## Packages dropped from the base list, and their configurations

Omarchy's `install/omarchy-base.packages` (v4.0.4) names 97 packages that the port's list does not. The port's commits that removed them, `ef4c9211` ("Port Omarchy v4.0.4 to Ubuntu") and `c304e943` ("Trim pre-installed software"), have empty message bodies; the recorded reasons are the comments in the port's package list (lines 174 to 212) and docs/6, "Core and apps" and choice 15 ("nothing of Omarchy's taste"). Neither the plan nor the policy has a rule about what to preinstall, so the trim rests on choice 15 alone.

### Renamed for Ubuntu or provided another way (no loss)

avahi (`avahi-daemon`); bluez-utils (`bluez`, `bluez-tools`); fcitx5-gtk and fcitx5-qt (`fcitx5-frontend-gtk3`, `-gtk4`, `-qt6`); fd (`fd-find`); gpu-screen-recorder (`gpu-screen-recorder-cli`); gvfs-mtp, gvfs-nfs, gvfs-smb (`gvfs-backends`); libvips (`libvips-tools`); nautilus-python (`python3-nautilus`); networkmanager (`network-manager`); noto-fonts, -cjk, -emoji (`fonts-noto-core`, `-cjk`, `-color-emoji`); nss-mdns (`libnss-mdns`); nvim (`neovim`); python-gobject (`python3-gi`); qt6-imageformats (`qt6-image-formats-plugins`); sushi (`gnome-sushi`); tesseract and tesseract-data-eng (`tesseract-ocr`, `tesseract-ocr-eng`); tldr (`tealdeer`); woff2-font-awesome (`fonts-font-awesome`); yaru-icon-theme (`yaru-theme-icon`); zbar (`zbar-tools`); libsecret (`libsecret-1-0`; Arch's `secret-tool` is lost, low value); libyaml (`libyaml-0-2`). Moved into the distro's own packages: asdcontrol, hyprland-preview-share-picker, localsend, ffmpegthumbnailer and pamixer (desktop packages); hyprland, quickshell, sddm, uwsm, gnome-keyring, wireplumber, xdg-desktop-portal-gtk and -hyprland (session packages); ttf-ia-writer and ttf-jetbrains-mono-nerd-basic (`oaxaca-fonts`). Replaced: chromium (the xtradeb PPA's build, preinstalled; the list's comment calling it a snap placeholder with snapd pinned out is stale), evince (Papers; stonking's evince is an alpha).

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

### Restore candidates

| Package | What it is | Facts (stonking, 2026-10-16) | How |
|---|---|---|---|
| unzip | extract .zip files | main 6.0-31; the image has no unzip, zip or 7zip | **Restored** 2026-10-16 (docs/6, choice 47) |
| btop, with `config/btop/btop.conf` | system monitor (Super+Ctrl+T, theme sync) | universe 1.4.7-1; the image has no system monitor at all | **Restored** 2026-10-16 (docs/6, choice 43) |
| starship, with `config/starship.toml` | shell prompt | universe 1.26.0; `default/bash/init` still starts it when present | **Restored** 2026-10-16 (docs/6, choice 43) |
| zoxide | smarter `cd` | universe 0.10.0; `default/bash/aliases` still wires it | **Restored** 2026-10-16 (docs/6, choice 43) |
| eza | modern `ls` | universe 0.23.5-5; the `ls`/`lt` aliases still call it | **Restored** 2026-10-16 (docs/6, choice 43) |
| mise and usage | Omarchy's developer-tool manager, behind dev-env and the coding-agent launchers | not in stonking; mise's vendor apt repository (`mise.jdx.dev/deb`) is live, and the vendor publishes a classic snap | vendor apt repository (today a curl script installs it on demand) |
| gnome-disk-utility | Disks: format, SMART, images | main 46.1; `oaxaca-desktop-apps` holds it but is only Suggested, so it is never installed and no menu entry installs it | **Restored** 2026-10-16 (docs/6, choice 47) |
| a calculator | Calculator key, Super+Ctrl+Q | Omacalc is not in stonking; gnome-calculator 1:50.0 in main; the image has no calculator | **Restored** 2026-10-16 (docs/6, choice 47) |
| inxi | hardware summary in `omarchy-debug` | universe 3.3.41; the debug report says "inxi is not installed" | **Restored** 2026-10-16 (docs/6, choice 43) |
| dua-cli | disk usage TUI behind the "Disk Usage" launcher | universe 2.34.0-1 | base list, launcher |
| lazygit, with its (empty) config | git TUI | universe 0.57.0 | **Restored** 2026-10-16 (docs/6, choice 43) |
| Obsidian | notes (Super+Shift+O, theme sync) | the vendor's snap (`obsidianmd`, classic) and Flathub | snap, `omarchy-theme-set-obsidian`, binding |
| whois | small tool Omarchy ships on purpose | main | **Restored** 2026-10-16 (docs/6, choice 59) |
| ruby | Omarchy ships it on purpose ("Ensure the system always has a base ruby", upstream `b7989ac8`) | main | base list |
| Docker (docker.io, docker-buildx, docker-compose-v2) | containers, enabled by Omarchy with sudoless access | main and universe | with Omarchy's deleted setup scripts; lazydocker would need a build of the distro's own |
| xournalpp, obs-studio, kdenlive | Omarchy's preinstalled apps | universe | base list (kdenlive is large) |
| Pinta, Moonlight | Omarchy's preinstalled apps | not in stonking; Flathub (Pinta's snap is a third party's) | Flathub |
| LibreOffice | office suite | Install > Productivity installs Canonical's snap | preinstall the snap to match Omarchy |
| Omarchy's own MIT apps: herdr, cliamp, omawrite, omacut, try | terminal multiplexer, music player, writing app, video trimmer, throwaway directories | not in stonking; licensed MIT or Apache-2.0 | build in the distro's apt repository, as LocalSend is (ttfx done: `packages/ttfx`, docs/6, choice 43) |
| Omarchy's LazyVim configuration (omarchy-nvim), with lua5.1, luarocks, tree-sitter-cli and a C compiler | Neovim set up by Omarchy | the port dropped it because the package build cannot fetch plugins | ship the configuration in `/etc/skel` and let lazy.nvim fetch plugins on first launch |
| libpq-dev, libmariadb-dev | headers for Rails' pg and mysql2 gems | main | add to `dev-env ruby` |

## Features cut inside files the port kept

| Feature | Where | What it did | Removed because | Checked facts | Verdict |
|---|---|---|---|---|---|
| SSH client keepalive | `install/config/all.sh` ran `ssh-keepalive.sh` | wrote `/etc/ssh/ssh_config.d/20-omarchy-keepalive.conf`: `ServerAliveInterval 15`, `ServerAliveCountMax 3`, `ConnectTimeout 10` | docs/6, "Ubuntu's configuration, not Omarchy's" (stonking ships `ssh_config.d` empty) | the port kept `default/bash/fns/ssh-reconnect`, which Omarchy's script says the keepalive exists for; without it a dead connection hangs until TCP gives up | **Restored** 2026-10-16 (docs/6, choice 46) |
| btop: Super+Ctrl+T "Activity", theme sync, restart on theme change | `default/hypr/bindings/utilities.lua`, `bin/omarchy-theme-set`, `install/user/theme.sh` | themed system monitor on a key | docs/6 choice 15 ("Command-line preferences") | btop 1.4.7-1 in universe; the plan (docs/0, line 380) said to keep btop and add GPU boxes | **Restored** 2026-10-16 (docs/6, choice 43) |
| Voxtype first-run invitation | `bin/omarchy-provision-first-run` | one-time "Install Dictation with Voxtype" notification | removed 2026-10-10 when Voxtype could not be installed (choice 5) | Voxtype is in the distro's apt repository since choice 30 (2026-10-14) | **Restored** 2026-10-16 (docs/6, choice 51) |
| DNS for every network, present and future | `bin/omarchy-dns` | Cloudflare, Google or custom DNS for all connections, with a Quad9 fallback | docs/6: rewritten on nmcli as the user, no sudoers rule, no edit of `resolved.conf` | the port changes only the connection profiles that exist when it runs; a network joined later uses DHCP's DNS | **Restored** 2026-10-16 (docs/6, choice 54): NetworkManager's global DNS over D-Bus as well as the profiles |
| Edge, Brave, Zen | `bin/omarchy-install-browser`, `-remove-browser`, `-theme-set-browser`, `-theme-set-browser-policy`, `-install-chromium-copy-url` | install, remove and theme these browsers | docs/6: proprietary builds replaced by open counterparts | Chrome and VS Code came back since, so that rule no longer holds; Microsoft's Edge apt repository, Brave's repository (already added for Brave Origin) and Flathub's `app.zen_browser.zen` (verified) exist | **Restore** |
| 1Password extension in Chromium | `bin/omarchy-install-service-1password` | wrote `/usr/share/chromium/extensions/<id>.json` so the extension installs itself | no reason recorded | Chromium is preinstalled and reads that directory | **Restored** 2026-10-16 (docs/6, choice 52) |
| Fingerprint skipped with the lid closed | `bin/omarchy-setup-security-fingerprint` (`pam_exec.so quiet /usr/bin/omarchy-hw-laptop-closed`) | a docked, closed laptop went straight to the password | docs/6: Ubuntu's `fprintd` pam-auth-update profile is used | `omarchy-hw-laptop-closed` still ships; `pam_fprintd` now sits in `common-auth` for sudo, polkit and SDDM, so a docked laptop waits up to 10 s on the reader | **Restored** 2026-10-16 (docs/6, choice 53): the port's own `omarchy-fprintd` pam-auth-update profile |
| `ic`, `ix`, `icx` aliases | `default/bash/aliases` | tmux development layouts with an agent | none recorded (removed when tmux was out) | `tdl` is back (choice 25) | **Restored** 2026-10-16 (docs/6, choice 50) |
| Calculator key | `utilities.lua` (`XF86Calculator`, Super+Ctrl+Q → `omacalc`) | the keyboard's Calculator key | choice 5 (Omarchy's own app) | gnome-calculator 1:50.0-1ubuntu1 in main | **Partial**: bind to gnome-calculator |
| Obsidian binding and theme sync | `applications.lua` (Super+Shift+O), `omarchy-theme-set` | launch and theme Obsidian | docs/6, core and apps | Snap Store (`obsidianmd`) and Flathub | **Partial**: a binding shown only when Obsidian is installed |
| Symfony development environment | `bin/omarchy-install-dev-env`, `-remove-dev-env` | `omarchy install dev-env symfony`, which installed PHP and `symfony-cli` | none recorded; the branches were removed cleanly in `ef4c9211` | Symfony is a PHP web framework; nothing in Omarchy or the port uses it; the rest of Install > Development > PHP went too (docs/6 choice 41) | **Justified**: dropped by the distro's maintainer, 2026-10-16 |
| Kernel parameters for ASUS Panther Lake laptops and FRED | `install/hardware/all.sh` (`xe.enable_dpcd_backlight=1`, `xe.enable_panel_replay=0`, `fred=on`) | backlight and display on ASUS B9406 and UX5406AA | docs/6: wrote Limine drop-ins | Ubuntu's GRUB passes parameters too (`/etc/default/grub.d/*.cfg`); the kernel's FRED default is not checked | **Partial** (ASUS); FRED unclear |
| Surface and MacBook SPI keyboard modules in the initramfs | `install/hardware/all.sh` | the keyboard works at the disk encryption passphrase prompt | docs/6: mkinitcpio and DKMS | the DKMS part rightly stays out; `applespi` and the Surface modules are in the mainline kernel | **Partial**: hardware-gated `/etc/initramfs-tools/modules` lines |
| Wireless regulatory domain from the timezone | `install/hardware/all.sh` | sets the country for Wi-Fi channels | the script writes an Arch file | `wireless-regdb` is in the base list | **Partial** (low): `options cfg80211 ieee80211_regdom=XX` |
| RetroArch CRT shader and full core set | `bin/omarchy-install-gaming-retroarch` | CRT look, about 30 cores | in-file comment: no Ubuntu packages; the Online Updater fetches them | | **Justified** |
| HEY bindings and mailto | `applications.lua`, `mimeapps.list` | HEY web app | choice 27, the maintainer's request | Super+Shift+E opens Thunderbird | **Replaced** |
| Herdr, Cliamp, Omawrite, lazydocker bindings; `h` alias | `applications.lua`, `utilities.lua`, `aliases` | Omarchy's own apps | choice 5 | not in stonking | **Justified** |
| OpenClaw as default agent | `bin/omarchy-default-agent` | `omarchy default agent openclaw` | `PORT.md`: only a third party's snap | | **Justified** |
| Bluetooth pairing agent `bt-agent.service` | `install/user/first-run/enable-user-units.sh` | headless pairing | docs/6: blueman's applet autostarts | not checked that XDG autostart runs under the uwsm session | **Replaced**, to confirm on a booted Oaxaca |
| Debug log upload | `bin/omarchy-debug` | 24-hour shareable URL on logs.omarchy.org | in-file comment: no upload service | Omarchy's own service | **Justified** |
| Performance power profile on AC | `bin/omarchy-powerprofiles-set` | performance on AC | in-file comment (Legion fans; Ubuntu's default is balanced) | | **Justified** |
| Snapshots | `omarchy-snapshot`, `omarchy-update` | Snapper and Limine | choice 38 | | **Replaced** (Timeshift on btrfs) |
| Faillock (10 tries, 120 s) | `omarchy-apply-lock`, `install/config/all.sh` | lockout after failed passwords | docs/6 | Ubuntu's `common-auth` has no `pam_faillock` | **Justified** |
| Passwordless default keyring | `install/user/all.sh`, `install/login/all.sh` | keyring without a password | docs/4 choice 14 | | **Justified** |
| Arch setup steps (docker.sh, theme-system.sh, pacman, module cleanup, service enables) | `install/config/*`, `install/post-install/all.sh`, `enable-services.sh` | Arch-specific setup | docs/6, choice 13 | | **Justified** |
| Arch, AUR and DKMS drivers (NVIDIA, Vulkan, VA, IPU7, T2, bcm43xx, yt6801, Tuxedo, asusctl, Dell haptics, Surface firmware) | `install/hardware/all.sh` | drivers | docs/6 | NVIDIA through `oaxaca-drivers-install`; Mesa Vulkan and VA drivers in `oaxaca-session`; the rest need DKMS (a MOK) or a custom kernel, or are not in stonking | **Replaced** or **Justified** |
| Emacs daemon theme integration | `bin/omarchy-install-editor-emacs` | themed Emacs | Omarchy's own AUR package | | **Justified** |
| umu-launcher, wine-staging for Lutris | `bin/omarchy-install-gaming-lutris` | Proton runner | in-file comment | not in stonking | **Justified** |
| Package cache keeps two versions | `omarchy-update-pkg-prune` | offline downgrade | in-file comment | | **Justified** |
| Update conflict handler, keyring, AUR steps, stable-channel downgrade | `omarchy-update*`, `omarchy-reinstall-pkgs` | pacman-only | docs/6 | | **Justified** |

## Tests

On 2026-10-16 the 62 shell test files that failed on this branch were sorted (`PORT.md`, "Tests"): a test of something the port deleted was deleted, a test of Arch behavior in a script the port kept was rewritten for the port's behavior. All of these are **Justified**: each tested a removal recorded above or in `migrations/README.md`.

Deleted test files, each with what it tested and the port commit that deleted that (`provision-user-test.sh`, deleted the same day with the agent skills, came back with them):

| Test file | What it tested | Deleted by |
|---|---|---|
| `battlenet-test.sh` | the Battle.net installer and launcher | `ef4c9211` (Port Omarchy v4.0.4 to Ubuntu) |
| `copy-url-shortcut-migration-test.sh` | migration `1786643346` | `46dc3cdc` (Handle migrations) |
| `hermes-cli-migration-test.sh` | migration `1787760281` | `46dc3cdc` |
| `hermes-skills-migration-test.sh` | migration `1787843905` | `46dc3cdc` |
| `hermes-skin-migration-test.sh` | migration `1788619462` | `46dc3cdc` |
| `hw-hybrid-gpu-test.sh`, `hybrid-gpu-test.sh` | `omarchy-hw-hybrid-gpu` and `omarchy-toggle-hybrid-gpu`, the ASUS hybrid-GPU toggle | `ef4c9211` |
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
| `voxtype-invitation-test.sh` | the first-run Voxtype invitation hook | `ef4c9211` |
| `zram-migration-test.sh` | migration `1785013000` | `46dc3cdc` |

Test cases deleted from files that stay: Bluetooth's `bt-agent.service` (`4b680c26`); migrations `1787515927`, `1787815267`, `1788724825`, `1785617047`, `1788577553`, `1785846769` (`46dc3cdc`); `omarchy-remove-preinstalls` (`c304e943`); the OpenClaw installer, the Zed and Heroic installers, Omarchy's CUPS hardening, the update's file- and package-conflict handler and its keyring and AUR steps, the hibernation setup, Remove > AI, and the omarchy-dev package channel (all `ef4c9211`).

## Broken references and leftovers

Things in the port today that call something deleted, or ship without the feature they served:

- ~~`bin/omarchy-launch-screensaver` exits when `ttfx` is missing~~ fixed 2026-10-16: ttfx is packaged and preinstalled.
- ~~`bin/omarchy-clipboard-open` and imv's Ctrl+E call `tensaku-edit`~~ fixed 2026-10-16: both call swappy.
- ~~`bin/omarchy-debug` prints "inxi is not installed"~~ fixed 2026-10-16: inxi is preinstalled.
- ~~`default/bash/init` and `default/bash/aliases` wire starship, eza and zoxide, none of which is installed~~ fixed 2026-10-16: all three are preinstalled.
- ~~The ported agent skill points at the btop, lazygit and starship configuration files, which were deleted~~ fixed 2026-10-16: the files and the programs are back.
- Scripts with nothing calling them: `omarchy-launch-terminal-herdr`, `-menu-herdr-keybindings`, `-refresh-herdr`, `-restart-herdr` and `config/herdr/`; `omarchy-launch-openclaw`, `-openclaw-onboard`; `omarchy-install-font` (with Arch package names); `omarchy-hw-dell-xps-haptic-touchpad`; `omarchy-theme-set-t3code`.
- Comments and docs that are out of date: `omarchy-default-agent` names `omarchy-install-openclaw-cli`; `enable-services.sh` describes a wait-online mask that is gone; the package list says Chromium is a snap placeholder with snapd pinned out, and that "dev-env installs" lua51, luarocks and python-poetry-core through mise (it does not; and Omarchy shipped `dotnet-runtime` for Pinta); `PORT.md` says Omarchy's list does not install `try` (it has `tobi-try`); docs/6 says Chrome and VS Code were replaced (both are back); docs/0 and docs/1 give different reasons for leaving out hibernation.
