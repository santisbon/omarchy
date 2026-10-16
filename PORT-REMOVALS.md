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

### Tier

The audit's first ranking of the features to restore, by what a user meets first: tier 1, broken or weaker than Omarchy; tier 2, cheap restores; tier 2b, hardware fixes for other machines (added with docs/6, choice 48); tier 3, Omarchy's preinstalled defaults; tier 4, menu installers; tier 5, larger projects. The choices in docs/6 cite items by tier ("tier 1, item 7"); [Restored](#restored) keeps those numbers.

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

1. **Omarchy's preinstalled defaults** (tier 3): dua-cli with its "Disk Usage" launcher; mise from its vendor apt repository; Docker with sudoless Docker and the database installer; the preinstalled apps (Xournal++, OBS Studio, Kdenlive, Pinta and Moonlight from Flathub, LibreOffice and Obsidian from their vendors' snaps); Omarchy's LazyVim configuration through `/etc/skel`; ruby; the Rails database headers for `dev-env ruby`. ([Packages](#packages-dropped-from-the-base-list), [Commands](#commands-launchers-and-menu-entries))
2. **Menu installers that work on Ubuntu** (tier 4): Brave, Edge and Zen; Helix, Cursor and Zed; the six Nerd Fonts, built from the release zip `oaxaca-fonts` already uses; OpenClaw through mise; Heroic, NordVPN, Bitwarden, Sunshine and Minecraft. ([Commands](#commands-launchers-and-menu-entries))
3. **Two small network settings**: `tcp_mtu_probing=1`, and a PATH for `ssh host command`. ([System files](#system-install-and-hardware-files))
4. **Larger projects** (tier 5): a factory reset on Timeshift and `oem-config`; Omarchy's own MIT-licensed apps (herdr, cliamp, omawrite, omacut, omacalc, try) built in the distro's apt repository as LocalSend is; the Windows VM after Docker; Learn > Omarchy with a caveat.
5. **Waiting for evidence on Ubuntu**: the wireless regulatory domain from the timezone (verdict Unclear). ([System files](#system-install-and-hardware-files))

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
| Docker: sudoless Docker, Docker databases, Docker TUI | `bin/omarchy-sudo-docker`, `-setup-security-sudoless-docker`, `-remove-security-sudoless-docker`, `-install-docker-dbs`, `-launch-docker-tui`, `applications/Docker.desktop`; `install.development.docker-dbs`, `setup.security.sudoless-docker`, `remove.security.sudoless-docker` | Omarchy preinstalls Docker, keeps the user out of the root-equivalent `docker` group behind an opt-in, and offers one-click MySQL, Postgres, Redis, MongoDB, MariaDB and MSSQL containers | `PORT.md`: they "run on Docker, whose setup the port removed"; docs/6, "Core and apps" | `docker.io` 29.7.2 is in main, `docker-compose-v2` and `docker-buildx` in universe; the scripts only use `docker run` and `usermod`; the reason is circular | **Restore** after an Install > Development > Docker entry; the TUI (lazydocker, not in stonking) is **partial** |
| Factory reset | `bin/omarchy-system-factory-reset`, `-factory-reset-finish`, `-provision-owner`; `setup.reset` | on btrfs, swapped `@` for the installer's factory snapshot, re-keyed the disk encryption and recreated the owner at first boot | docs/6: among "programs the distro cannot install"; docs/1: scripts tied to Limine and Snapper | the same mistake as snapshots: only the Limine and mkinitcpio steps were Arch-specific; btrfs installs have Timeshift; `oem-config` (universe) creates a user at first boot | **Partial**: a factory Timeshift snapshot at install, restored by the reset, then `oem-config-prepare`; the re-keying needs rewriting |
| Brave, Edge | `install.browser.brave`, `.edge`, and their remove and default-browser entries | regular Brave and Microsoft Edge | docs/6: Chrome, Edge and VS Code replaced by open counterparts | Chrome and VS Code are back in the menu, so the rule no longer holds; Brave's repository (already added for Brave Origin) has `brave-browser`; `packages.microsoft.com/repos/edge` has `microsoft-edge-stable` | **Restore** through `omarchy-pkg-repo-add` |
| Zen | `install.browser.zen` and its remove and default entries | Firefox-based browser | `PORT.md` only notes Omarchy offers it | Flathub `app.zen_browser.zen` (verified); no apt repository or snap | **Partial**: from Flathub |
| Nerd Font installers | `install.style.font` with Bitstream, Cascadia, Fira, Iosevka, Meslo, Victor | install a patched Nerd Font and switch to it | docs/6: "the Nerd Font installers" | the `ttf-*-nerd` names are Arch's; `oaxaca-fonts` already builds JetBrains Mono from the Nerd Fonts release zip; `bin/omarchy-install-font` stayed, unused, with Arch names | **Restore**: build the six from the same zip |
| Helix | `bin/omarchy-install-editor-helix`; `install.editor.helix` | Helix linked to the theme | `PORT.md`: Install > Package, without Omarchy's setup | `hx` in universe; the branch still has `helix.toml.tpl` and `omarchy-restart-helix` | **Restore** |
| Cursor | `install.editor.cursor` | Cursor editor | none recorded | Cursor's apt repository (`downloads.cursor.com/aptrepo`) has `cursor`; its signing key URL not verified | **Restore** through `omarchy-pkg-repo-add` |
| Zed | `bin/omarchy-install-editor-zed`; `install.editor.zed` | Zed themed by Omarchy's `omazed` | `PORT.md` | Ubuntu's `zed` is another program; Flathub `dev.zed.Zed` (unverified); `omazed` is nowhere | **Partial**: Flathub, no theme sync |
| Obsidian theme sync | `bin/omarchy-theme-set-obsidian` | copy the theme's `obsidian.css` into every vault | `c304e943` (Obsidian was no longer preinstalled) | the themes still render `obsidian.css` | **Restore** with the app |
| OpenClaw | `bin/omarchy-install-ai-openclaw`, `-remove-ai-openclaw`, `-install-openclaw-cli`; `install.ai.openclaw`, `remove.ai.openclaw`, `setup.default.agent.openclaw`, `remove.ai` | the OpenClaw agent, its gateway and Control UI, and the default-agent choice | `PORT.md`: the snap is a third party's | Omarchy's package is the npm module; npm has `openclaw` 2026.10.4 from the project; the port installs other npm agents through mise; `omarchy-launch-openclaw` and `-openclaw-onboard` were kept | **Restore** through `mise use -g npm:openclaw` |
| Heroic, Minecraft | `bin/omarchy-install-gaming-heroic`, `-remove-gaming-heroic`, `-remove-gaming-minecraft`; their menu entries | game launchers | `PORT.md`: Install > Flatpak | Flathub `com.heroicgameslauncher.hgl` (verified), `com.mojang.Minecraft` (unverified) | **Restore** Heroic as a Flathub entry; Minecraft **partial** |
| NordVPN, Bitwarden | `bin/omarchy-install-service-nordvpn`; `install.service.nordvpn`, `install.service.bitwarden` | VPN client; password manager | `PORT.md`: Install > Snap | NordVPN's apt repository answers and its snap is the vendor's; Bitwarden's snap and Flatpak are verified | **Restore** (NordVPN like Mullvad; Bitwarden like Thunderbird) |
| Sunshine | `bin/omarchy-install-service-sunshine`, `-remove-service-sunshine` | game-streaming host | `PORT.md`: Flathub | Flathub `dev.lizardbyte.app.Sunshine` (verified) | **Partial** |
| Windows VM | `bin/omarchy-windows-vm`; `install.windows`, `remove.windows` | Windows in the `dockurr/windows` container over RDP | `PORT.md`: runs on Docker | needs Docker, `freerdp3-x11` (universe), `netcat-openbsd`; the image is from Docker Hub, not one of the project's package sources | **Partial**, after Docker, if a Docker Hub image is acceptable |
| Learn > Omarchy | `learn.omarchy` | Omarchy's manual | none recorded | parts of the manual do not apply (the firewall's Docker rules, pacman, Limine), most does | **Partial**: with a caveat, or a page of the port's own |
| Disk Usage | `applications/Disk Usage.desktop` and icon | `dua i /` in a terminal | docs/6 | `dua-cli` in universe | **Partial** (with the package, section [Packages](#packages-dropped-from-the-base-list)) |

### Replaced

the AUR commands (Install > Package, Snap and Flatpak); pacman upkeep (`omarchy-update-system-pkgs` with apt); the 32-bit GPU libraries (`omarchy-install-32bit-graphics`); the local package test (`UPSTREAM_DIR=… scripts/build.sh`); Learn > Arch (Learn > Ubuntu); the preinstalled web-app launchers and HEY's mailto handler (Install > Web App; Omarchy's set could come back as presets); LM Studio (Install > Flatpak).

### Justified

Battle.net (umu-launcher not in stonking); ONCE (a GitHub binary, needs Docker); ChatGPT desktop, Grok Bot, Hermes Desktop, Perplexity (only third parties' snaps or nothing; web apps and the agents cover them); T3 Code (a GitHub release only); hibernation (out of the first release; docs/0 and docs/1 give different reasons, Secure Boot lockdown versus scope); direct boot of a UKI and Limine's refresh (GRUB only); package channels (the apt repository has none); upgrade to Quattro (Omarchy's own migration path); log upload and the Omarchy Discord (Omarchy's services); Learn > Herdr (Herdr is not available); the preinstalls toggle (nothing removable is preinstalled); the PHP development environment, Install and Remove > Development > PHP with its PHP, Laravel and Symfony entries (nothing in the desktop uses PHP; Symfony was removed with the port, PHP and Laravel on 2026-10-16 by the distro's maintainer, docs/6 choice 41).

## System, install and hardware files

The 92 files deleted under `install/`, `etc/` and `default/` went in four port commits, none of whose messages gives a reason: `ef4c9211` "Port Omarchy v4.0.4 to Ubuntu" (60 files), `4b680c26` "Remove features we provide through Ubuntu" (29), `c304e943` "Trim pre-installed software" (2), `3c21fd64` "Don't customize firewall" (1). The reasons below are from docs/6, docs/1, docs/4 and `PORT.md`. Facts were read from the live root filesystem tarball built 2026-10-16 (kernel 7.3.0-9), stonking's packages on Launchpad, and mainline Linux 7.3-rc7.

### Restore, partly restore, or unclear

| Feature | Files | What it did | Removed because | Checked facts | Verdict |
|---|---|---|---|---|---|
| `tcp_mtu_probing=1` | `etc/sysctl.d/99-omarchy-sysctl.conf` | fixes stalled SSH and HTTPS over broken path-MTU networks | docs/6 grouped the whole file under zram | unrelated to zram | **Partial** (low) |
| PATH for `ssh host command` | `install/config/ssh-command-path.sh` | mise shims and `~/.local/bin` for non-interactive SSH commands | docs/6: Omarchy's line lacked `/usr/sbin`; `/etc/profile.d` covers login shells | `ssh host cmd` is not a login shell | **Partial** (low): with Ubuntu's full PATH |
| Wireless regulatory domain | `install/hardware/set-wireless-regdom.sh` | the country of the timezone chosen at install, written to Arch's `/etc/conf.d/wireless-regdom` | no reason recorded | Ubuntu's equivalent is `options cfg80211 ieee80211_regdom=XX` (the image's `cfg80211` has the parameter); nothing showed Ubuntu needs it, since a Wi-Fi card normally learns the country from the access point (802.11d). Restored and withdrawn the same day (docs/6, choice 62) | **Unclear**: restore when a machine on Ubuntu is seen stuck on the world domain, missing channels |

### Replaced

mkinitcpio files (initramfs-tools, `oaxaca-nvidia`'s hook, `oaxaca-base`'s Thunderbolt option); Snapper (Timeshift, choice 38); SDDM's Wayland greeter (`oaxaca-session`); the passwordless keyring (keyring unlocked by the login password, docs/4 choice 14); Plymouth's theme file (the distro's plymouth package); `nsswitch.conf` (Ubuntu's, with mDNS); the DNS and timezone sudoers rules (`omarchy-dns` on nmcli and D-Bus; `omarchy-timezone`); the icon links and Chromium first-run preferences; the Bluetooth pairing agent (blueman's applet; see [Open questions](#open-questions)); CUPS hardening (Ubuntu's `cups-browsed` runs as its own user, browses only DNS-SD and has an AppArmor profile; `CreateRemoteCUPSPrinterQueues No` is the one setting missing); NVIDIA (`nvidia.sh`: `oaxaca-drivers-install` with Canonical's signed modules, including the 580 branch for GPUs before Turing); Vulkan drivers (`vulkan.sh`: `mesa-vulkan-drivers` in the image); Motorcomm YT6801 Ethernet (`fix-yt6801-ethernet-adapter.sh`: the in-kernel `dwmac-motorcomm`); the Surface's Marvell Wi-Fi firmware (`surface.sh`: `linux-firmware-marvell-wireless` is in the image); most of the Surface and MacBook SPI keyboard modules (Ubuntu's initramfs already holds them; the one each lacks came back, see [Restored](#restored)).

### Justified

pacman's update guard, configuration and mirrors; Limine (docs/1 section 6); Battle.net (umu-launcher not in stonking); the hibernate branch of the ASUS sleep hook (hibernation is out); shutdown timeouts and open-file limits (taste; Ubuntu's user manager already stops in 5 s); plocate tuning; zram and zswap; Docker's daemon setup (Docker is not preinstalled); resolved's multicast setting (a no-op); dirmngr keyservers; faillock (Ubuntu's stack has no `pam_faillock`); sudo's password tries; the powerprofilesctl shebang (Ubuntu's is already `/usr/bin/python3`); Omarchy's ISO provisioning and factory reset (Calamares installs; the reset relied on Limine and mkinitcpio); network cleanup (archinstall leftovers); the BCM4360's Wi-Fi driver (`broadcom-sta-dkms` only, so a MOK); TUXEDO and Slimbook keyboard backlight (`tuxedo-drivers` is DKMS, not in stonking); Apple T2 (an out-of-tree kernel and a pacman repository); FRED on Panther Lake (`intel/fred.sh`: `CONFIG_X86_FRED=y` and mainline's default is on, so `fred=on` is a no-op); MacBook SPI keyboard DKMS (`macbook12-spi-driver-dkms`: Ubuntu's kernel has the driver as signed modules); Apple-style F-keys (`fix-fkeys.sh` sets `hid_apple fnmode=2`, which makes the top row of keys send F1 to F12, with the printed functions such as brightness and volume only while Fn is held. The `hid_apple` driver applies that setting to every keyboard it drives, so genuine Apple keyboards would also lose one-press brightness and volume; Omarchy wants it for third-party keyboards that use Apple's layout, such as Lofree's, and the kernel already sends F1 to F12 first on the clones it recognizes (Keychron, Epomaker and others). A preference, not a fix for a device).

## Packages dropped from the base list

Omarchy's `install/omarchy-base.packages` (v4.0.4) names 97 packages that the port's list did not have when the audit was written. The port's commits that removed them, `ef4c9211` ("Port Omarchy v4.0.4 to Ubuntu") and `c304e943` ("Trim pre-installed software"), have empty message bodies; the recorded reasons are the comments in the port's package list and docs/6, "Core and apps" and choice 15 ("nothing of Omarchy's taste"). Neither the plan nor the policy has a rule about what to preinstall, so the trim rested on choice 15 alone.

### Renamed for Ubuntu or provided another way (no loss)

avahi (`avahi-daemon`); bluez-utils (`bluez`, `bluez-tools`); fcitx5-gtk and fcitx5-qt (`fcitx5-frontend-gtk3`, `-gtk4`, `-qt6`); fd (`fd-find`); gpu-screen-recorder (`gpu-screen-recorder-cli`); gvfs-mtp, gvfs-nfs, gvfs-smb (`gvfs-backends`); libvips (`libvips-tools`); nautilus-python (`python3-nautilus`); networkmanager (`network-manager`); noto-fonts, -cjk, -emoji (`fonts-noto-core`, `-cjk`, `-color-emoji`); nss-mdns (`libnss-mdns`); nvim (`neovim`); python-gobject (`python3-gi`); qt6-imageformats (`qt6-image-formats-plugins`); sushi (`gnome-sushi`); tesseract and tesseract-data-eng (`tesseract-ocr`, `tesseract-ocr-eng`); tldr (`tealdeer`); woff2-font-awesome (`fonts-font-awesome`); yaru-icon-theme (`yaru-theme-icon`); zbar (`zbar-tools`); libsecret (`libsecret-1-0`; Arch's `secret-tool` is lost, low value); libyaml (`libyaml-0-2`). Moved into the distro's own packages: asdcontrol, hyprland-preview-share-picker, localsend, ffmpegthumbnailer and pamixer (desktop packages); hyprland, quickshell, sddm, uwsm, gnome-keyring, wireplumber, xdg-desktop-portal-gtk and -hyprland (session packages); ttf-ia-writer and ttf-jetbrains-mono-nerd-basic (`oaxaca-fonts`). Replaced: chromium (the xtradeb PPA's build, preinstalled), evince (Papers; stonking's evince is an alpha).

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
| mise and usage | Omarchy's developer-tool manager, behind dev-env and the coding-agent launchers | not in stonking; mise's vendor apt repository (`mise.jdx.dev/deb`) is live, and the vendor publishes a classic snap | vendor apt repository (today a curl script installs it on demand) |
| dua-cli | disk usage TUI behind the "Disk Usage" launcher | universe 2.34.0-1 | base list, launcher |
| Obsidian | notes (Super+Shift+O, theme sync) | the vendor's snap (`obsidianmd`, classic) and Flathub | snap, `omarchy-theme-set-obsidian`, binding |
| ruby | Omarchy ships it on purpose ("Ensure the system always has a base ruby", upstream `b7989ac8`) | main | base list |
| Docker (docker.io, docker-buildx, docker-compose-v2) | containers, enabled by Omarchy with sudoless access | main and universe | with Omarchy's deleted setup scripts; lazydocker would need a build of the distro's own |
| xournalpp, obs-studio, kdenlive | Omarchy's preinstalled apps | universe | base list (kdenlive is large) |
| Pinta, Moonlight | Omarchy's preinstalled apps | not in stonking; Flathub (Pinta's snap is a third party's) | Flathub |
| LibreOffice | office suite | Install > Productivity installs Canonical's snap | preinstall the snap to match Omarchy |
| Omarchy's own MIT apps: herdr, cliamp, omawrite, omacut, omacalc, try | terminal multiplexer, music player, writing app, video trimmer, calculator, throwaway directories | not in stonking; licensed MIT or Apache-2.0 | build in the distro's apt repository, as LocalSend and ttfx are |
| Omarchy's LazyVim configuration (omarchy-nvim), with lua5.1, luarocks, tree-sitter-cli and a C compiler | Neovim set up by Omarchy | the port dropped it because the package build cannot fetch plugins | ship the configuration in `/etc/skel` and let lazy.nvim fetch plugins on first launch |
| libpq-dev, libmariadb-dev | headers for Rails' pg and mysql2 gems | main | add to `dev-env ruby` |

## Features cut inside files the port kept

| Feature | Where | What it did | Removed because | Checked facts | Verdict |
|---|---|---|---|---|---|
| Edge, Brave, Zen | `bin/omarchy-install-browser`, `-remove-browser`, `-theme-set-browser`, `-theme-set-browser-policy`, `-install-chromium-copy-url` | install, remove and theme these browsers | docs/6: proprietary builds replaced by open counterparts | Chrome and VS Code came back since, so that rule no longer holds; Microsoft's Edge apt repository, Brave's repository (already added for Brave Origin) and Flathub's `app.zen_browser.zen` (verified) exist | **Restore** |
| Obsidian binding and theme sync | `applications.lua` (Super+Shift+O), `omarchy-theme-set` | launch and theme Obsidian | docs/6, core and apps | Snap Store (`obsidianmd`) and Flathub | **Partial**: a binding shown only when Obsidian is installed |
| Symfony development environment | `bin/omarchy-install-dev-env`, `-remove-dev-env` | `omarchy install dev-env symfony`, which installed PHP and `symfony-cli` | none recorded; the branches were removed cleanly in `ef4c9211` | Symfony is a PHP web framework; nothing in Omarchy or the port uses it; the rest of Install > Development > PHP went too (docs/6 choice 41) | **Justified**: dropped by the distro's maintainer, 2026-10-16 |
| FRED kernel parameter | `install/hardware/all.sh` (`fred=on` on Panther Lake) | turns on Intel's FRED event delivery | docs/6: wrote Limine drop-ins | `CONFIG_X86_FRED=y` in the image's kernel, and mainline's default is on | **Justified** (a no-op on Ubuntu's kernel) |
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

Test cases deleted from files that stay: Bluetooth's `bt-agent.service` (`4b680c26`); migrations `1787515927`, `1787815267`, `1788724825`, `1785617047`, `1788577553`, `1785846769` (`46dc3cdc`); `omarchy-remove-preinstalls` (`c304e943`); the OpenClaw installer, the Zed and Heroic installers, Omarchy's CUPS hardening, the update's file- and package-conflict handler and its keyring and AUR steps, the hibernation setup, Remove > AI, and the omarchy-dev package channel (all `ef4c9211`).

## Broken references and leftovers

Things in the port today that call something deleted, or ship without the feature they served (fixed ones are in [Restored](#restored)):

- Scripts with nothing calling them: `omarchy-launch-terminal-herdr`, `-menu-herdr-keybindings`, `-refresh-herdr`, `-restart-herdr` and `config/herdr/`; `omarchy-launch-openclaw`, `-openclaw-onboard`; `omarchy-install-font` (with Arch package names); `omarchy-theme-set-t3code`; `install/omarchy-other.packages` (Arch package names, read by nothing).
- Comments and docs that are out of date: `omarchy-default-agent` names `omarchy-install-openclaw-cli`; `enable-services.sh` describes a wait-online mask that is gone; the package list says Chromium is a snap placeholder with snapd pinned out, and that "dev-env installs" lua51, luarocks and python-poetry-core through mise (it does not; and Omarchy shipped `dotnet-runtime` for Pinta); `PORT.md` says Omarchy's list does not install `try` (it has `tobi-try`); docs/6 says Chrome and VS Code were replaced (both are back); docs/0 and docs/1 give different reasons for leaving out hibernation; `docs/file-layout.md` mentions `keyboard-backlight` and `limine-entry-tool`.

## Restored

Every feature added back since the audit, with its tier and item, the date, and the choice in docs/6 that records the reason it holds on Ubuntu.

| Tier, item | Feature | What came back | Choice |
|---|---|---|---|
| 1, 1 | Firewall | ufw on for the next boot, LocalSend's port 53317 allowed, Ubuntu's policies (deny incoming), no Docker rules; `install/config/firewall.sh` | 40 |
| 1, 2 | Wi-Fi power save off | Omarchy's `etc/NetworkManager/conf.d/omarchy-wifi-powersave.conf` (`wifi.powersave = 2`), over Ubuntu's `wifi.powersave = 3`: link drops on Intel BE200/BE211 firmware | 42 |
| 1, 3 | Tools kept files call | ttfx (built in the distro's apt repository) for the screensaver; inxi for the debug report; starship, eza and zoxide for the prompt and the `ls`, `lt` and `cd` aliases; btop and lazygit with Omarchy's configurations for the agent skill. Tensaku's two callers (`omarchy-clipboard-open`, imv's Ctrl+E) moved to swappy instead, which replaced Tensaku on purpose (choice 29) | 43 |
| 1, 4 | Hyprland's reload guard around upgrades | `oaxaca-config`'s preinst pauses, its postinst resumes (Omarchy's libalpm hooks, for dpkg) | 44 |
| 1, 5 | systemd-oomd scope | Omarchy's `app.slice` drop-in, plus `user@.service` set to `auto`, so the compositor is not a kill candidate | 45 |
| 1, 6 | SSH keepalive | `ServerAliveInterval 15`, `ServerAliveCountMax 3`, `ConnectTimeout 10` as a package file in `etc/ssh/ssh_config.d/`, for the kept `ssh-reconnect` | 46 |
| 1, 7 | Basic tools | unzip, GNOME Disks, GNOME Calculator in place of Omacalc (Super+Ctrl+Q, the Calculator key), btop with Super+Ctrl+T and theme sync; `oaxaca-desktop-apps` dropped | 43, 47 |
| 2 | Share > Receive, Install > Service > Chromium Account | Omarchy's two menu lines | 49 |
| 2 | `ic`, `ix`, `icx` aliases | `tdl c`, `tdl cx`, `tdl c cx` | 50 |
| 2 | Voxtype's first-run invitation | the post-update hook, its line in `omarchy-provision-first-run`, and `voxtype-invitation-test.sh` | 51 |
| 2 | 1Password's Chromium extension | written and removed with 1Password | 52 |
| 2 | Fingerprint skipped while the lid is closed | the port's own pam-auth-update profile, `omarchy-fprintd`: Ubuntu's line with Omarchy's `pam_exec` gate in front | 53 |
| 2 | DNS for networks joined later | NetworkManager's global DNS over D-Bus as well as the profiles, granted by a polkit rule | 54 |
| 2 | ASUS Panther Lake display options | `xe.enable_dpcd_backlight=1` (B9406, UX5406AA) and `xe.enable_panel_replay=0` (B9406) in `/etc/modprobe.d`, on the same DMI match; need on Ubuntu not verified ([Open questions](#open-questions)) | 55 |
| 2 | Intel video acceleration | `libmfx-gen1.2` (Quick Sync) or `i965-va-driver` (GMA-era GPUs), by GPU, at install | 56 |
| 2 | BCM4331 Wi-Fi firmware | `firmware-b43-installer` on that PCI id (multiverse; its postinst downloads the firmware from a third party's GitHub release at install) | 57 |
| 2 | inotify watch limit | `fs.inotify.max_user_watches=524288` over localsearch's 65536 | 58 |
| 2 | whois | in the base list | 59 |
| 2 | inxi | with tier 1, item 3 | 43 |
| found | Wi-Fi 7 off only on a Dell XPS on Panther Lake | the kept `fix-wifi7-eht.sh` turned Wi-Fi 7 off on every BE200 and BE211, the Legion's card included; now only on the machines its comment names, and `oaxaca-config`'s postinst removes the file elsewhere; need on Ubuntu not verified | 60 |
| 2b, 2 | Surface keyboard at the disk encryption passphrase prompt | an initramfs-tools hook that adds `surface_aggregator_hub`, the one of Omarchy's ten modules Ubuntu's initramfs lacks | 63 |
| 2b, 3 | MacBook8,1 SPI keyboard at the same prompt | an initramfs-tools hook that adds `spi-pxa2xx-pci`, the one module Ubuntu's initramfs lacks | 64 |
| 2b, 5 | Intel IPU7 camera (partial) | libcamera, its GStreamer element and its PipeWire plugin on the OV08X40 match; Ubuntu's kernel has the drivers and firmware | 65 |
| 2b, 4 | Dell XPS haptic touchpad | `packages/dell-xps-touchpad-haptics` in the build repository, installed on the detector's match; Hardware > Touchpad Haptics | 66 |
| 2b, 6 | Framework 16 keyboard lighting | `packages/qmk-hid` in the build repository, installed by `framework16.sh` | 67 |
| 2b, 7 | ASUS ROG tools and the Hybrid GPU toggle | `packages/asusctl` (6.5.0, from `github.com/OpenGamingCollective/asusctl`) and `packages/supergfxctl` (5.2.7); `asus-rog.sh`, `omarchy-hw-hybrid-gpu`, `omarchy-toggle-hybrid-gpu`, `force-igpu`, the start delay and their tests (`hw-hybrid-gpu-test.sh`, `hybrid-gpu-test.sh`); Hybrid GPU shows only on ASUS ROG laptops with two GPUs, and the scripts call `gnutimeout` | 68 |
