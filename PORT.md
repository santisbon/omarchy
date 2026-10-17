# The `oaxaca` branch

This branch is Omarchy ported from Arch Linux and pacman to Ubuntu and apt, for the distro
whose build repository is `santisbon/oaxaca`. It starts at Omarchy's release tag named in that
repository's `distro.conf` (`OMARCHY_TAG`, `v4.0.4` today) and is rebased onto each new Omarchy
tag the distro adopts.

## What the branch holds

- Every change to Omarchy's own files, as commits on top of the tag: scripts under `bin/`
  rewritten from pacman to apt, Arch-only scripts and files deleted, Ubuntu paths and names
  (PAM stacks, the `sudo` group, package names in `install/omarchy-base.packages`).
- `port/rename.sh`, the rename script. The branch keeps Omarchy's names (`omarchy-*` commands,
  `OMARCHY_PATH`, `/usr/share/omarchy`), so that a rebase onto the next Omarchy tag meets the
  same names on both sides. The distro's packaging copies the tree and runs the script on the
  copy with `DISTRO_ID` and `DISTRO_NAME` from `distro.conf`, which is what makes every command
  `oaxaca-*`, every path `/usr/share/oaxaca` and the Lua module `oaxaca`. Since 2026-10-17 the
  script keeps Omarchy's spelling for the names plugins and themes written for Omarchy use and
  users do not see (built-in plugin IDs such as `omarchy.clock`, `OMARCHY_*` variables, app IDs
  such as `org.omarchy.terminal`, a plugin manifest's `omarchy` section, the menu's entry keys,
  the icon font family `omarchy`), fails when any other "omarchy" is left, and the packaging
  adds `omarchy-*` links beside the commands (the distro's docs/6, choice 86). The script is not
  run on this checkout.
- `PORT.md`, this file.

Nothing here is a Debian package: `debian/` lives in `santisbon/oaxaca` under `packages/desktop/`,
whose `upstream` file names this repository and the ref to build, and whose `scripts/build.sh`
makes the orig tarball with `git archive` (or from a local checkout with `UPSTREAM_DIR=...` while
a change is being developed).

## Rules for a change

- Keep Omarchy's names in every file. Write `omarchy-foo`, `$OMARCHY_PATH`, `/usr/share/omarchy`;
  the rename script does the rest at build time. Where a script needs Omarchy's own name after
  the rename (to link or rewrite toward it), write it in two parts, `"omar""chy"`, as
  `bin/omarchy-compat-links` does; the rename leaves that alone.
- Keep Omarchy's script conventions (`# omarchy:summary=` headers, `omarchy-cmd-present`,
  `omarchy-notification-send`, `gum`).
- Start minimal and add, never install and remove: the branch carries Ubuntu's configuration plus
  the parts of Omarchy the desktop needs to run. An Omarchy feature beyond that comes back as a
  change written for Ubuntu, with its reason recorded as a choice in the build repository's
  `docs/6 - omarchy-port.md`; `PORT-REMOVALS.md` lists the candidates.
- Delete rather than stub: a script the distro cannot support is removed together with its menu
  entries and bindings, so that the menu never shows an entry that fails.
- Ubuntu facts in comments: when a package name, unit name or path differs from Arch, the comment
  says what was checked and where.

## The Applications

What the manual's "The Applications" chapters (`manual/15-terminal.md` to `manual/29-other-packages.md`, listed in `README.md`) describe, as this port has it. Checked 2026-10-13 against the distro's installation image (its package list and files); the sources, including each Ubuntu package's archive component (main, universe, multiverse), checked 2026-10-14 against stonking's published packages on Launchpad and the scripts behind each menu entry; this branch's menu (`default/omarchy/omarchy-menu.jsonc`), Ubuntu's archive for the base series (stonking's package indexes), and, for what Omarchy shipped and offered, the `v4.0.4` tag's `install/omarchy-base.packages`, menu and `bin/omarchy-install-*` scripts. "Install > Package" is the menu's entry for any package in Ubuntu's archive; it installs the program without the configuration Omarchy shipped for it. "Install > Snap" searches the Snap Store and "Install > Flatpak" lists Flathub's applications, the same way; Remove > Snap and Remove > Flatpak list what those installed.

Ubuntu's archive is split into four components, which the table names for each package from it (Ubuntu's definitions, from `help.ubuntu.com/community/Repositories`, read 2026-10-14):

- **main**: "free and open-source applications that are free software, can be freely redistributed and are fully supported by Canonical."
- **universe**: "free and open-source applications that are maintained by the Ubuntu community."
- **restricted**: "close-source tools, codecs, and drivers" (here, NVIDIA's libraries).
- **multiverse**: "applications that do not meet all the requirements to be open source."

A PPA (Personal Package Archive) is an apt repository that a person or team publishes on Launchpad, Canonical's build and hosting service, outside Ubuntu's archive; Canonical does not maintain its packages.

| | Applications |
|---|---|
| **Preinstalled** | **Ubuntu's archive, main component:** Files (Nautilus); Papers, the document viewer and the PDF default (since 2026-10-14; Omarchy ships Evince, which stonking has only as an alpha); nano, the default editor (since 2026-10-14); tmux (since 2026-10-14), with Omarchy's configuration (`~/.config/tmux/tmux.conf`), theme sync, Super+Alt+Return (the Work session) and Super+Alt+K (tmux's keybindings); since 2026-10-16: GNOME Calculator (Super+Ctrl+Q and the Calculator key, in place of Omarchy's Omacalc), GNOME Disks, unzip and whois<br><br>**mise's own apt repository** (`mise.jdx.dev/deb`, added by the distro's image build): mise<br><br>**Ubuntu's archive, universe component:** Foot (terminal); imv; mpv; Neovim (since 2026-10-14), without Omarchy's LazyVim configuration; Setup > Defaults > Editor makes Neovim the default; fzf, ripgrep, fd (fd-find), bat; dua-cli, with Omarchy's Disk Usage launcher (since 2026-10-16); tldr (Omarchy's Python client; here the tealdeer package, a Rust client that installs the same tldr command; since 2026-10-14, set to download its pages on first use); since 2026-10-16: btop (Super+Ctrl+T, theme sync), Lazygit and starship (the prompt), each with Omarchy's configuration, eza and zoxide (the `ls`, `lt` and `cd` aliases), and inxi (the hardware section of the debug report); swappy, the screenshot editor the screenshot notification opens (since 2026-10-14; Omarchy uses its own Tensaku); yt-dlp, for Chromium's Download Video extension; Fastfetch (About)<br><br>**The xtradeb PPA on Launchpad**, a community build of upstream Chromium: Chromium, the default browser (`155.0.8059.39-1xtradeb1.2610.1`; since 2026-10-14; unlike Omarchy, Remove > Browser can take it off)<br><br>**The distro's own apt repository**, built from LocalSend's release (Ubuntu's archive has none): LocalSend, behind the Share menu and Files' "Send via LocalSend"; built from source (since 2026-10-16): ttfx, Omarchy's terminal text effects, which the screensaver runs<br><br>**This branch's `default/bash`, in the distro's config package:** the shell functions (compress and decompress, iso2sd, format-drive, the git worktree, rsync watcher, SSH port forwarding and SSH reconnection functions, and the tmux layout functions) |
| **Installable directly from the menu**<br>An entry of its own installs the app, with Omarchy's setup where the port kept one; the entry is in parentheses | **Ubuntu's archive, main component:** Vim (Install > Editor)<br><br>**Ubuntu's archive, universe component:** Alacritty, Ghostty, Kitty, and Foot again after it was removed (Install > Terminal); Emacs, as emacs-pgtk (Install > Editor); RetroArch and its game launcher, Xbox Controllers (xpadneo) (Install > Gaming)<br><br>**Ubuntu's archive, multiverse component:** Dropbox, whose package downloads Dropbox's client on first run (Install > Service); Steam and Lutris, with NVIDIA's 32-bit libraries from the restricted component when an NVIDIA driver is installed (Install > Gaming)<br><br>**Mojang's own package**, downloaded from Mojang's site by the installer: Minecraft, with the distro's `oaxaca-gdk-pixbuf-compat` from its own apt repository (Install > Gaming; since 2026-10-16)<br><br>**Docker's own package**, downloaded from Docker's site by the installer, with Docker's apt repository for its `docker-ce-cli` dependency: Docker Desktop, with gnome-terminal from Ubuntu's universe component, which Docker asks for outside GNOME (Install > Development; since 2026-10-17)<br><br>**Vendors' apt repositories:** Chrome (Google's package, which adds Google's repository), Brave Origin (Brave's), Firefox (Mozilla's) (Install > Browser; Omarchy also offers Edge, Brave and Zen); VS Code (Microsoft's), Sublime Text (Sublime HQ's) (Install > Editor); 1Password, Spotify, Signal, Mullvad VPN, Tailscale, each from its vendor's (Install > Service)<br><br>**The xtradeb PPA on Launchpad:** Chromium again after it was removed (Install > Browser)<br><br>**The distro's own apt repository**, built from Voxtype's release package: Dictation (Voxtype), with its speech model (Whisper `base.en`, 142 MB) downloaded from Voxtype's model server, `models.voxtype.io`, at install, running on the discrete GPU when one has a Vulkan driver (Install > AI; the bar's Dictation indicator opens the same installer)<br><br>**The Snap Store:** Wave (Install > Terminal); Thunderbird, which Super+Shift+E opens while it is installed (Install > Service); NordVPN, published by NordVPN, and Bitwarden, published by 8bit Solutions LLC, Bitwarden's company, the app only (Install > Service; since 2026-10-16); LibreOffice, published by Canonical (Install > Productivity, a category the port added; also in Ubuntu's archive, the `libreoffice` package in universe and its apps in main, and on Flathub, whose build drew its toolbar icons nearly invisible on the dark theme and its Save dialog larger than the screen on 2026-10-15)<br><br>**Flathub:** VSCodium (Install > Editor); Xournal++, the Xournal++ team's Flatpak, and Kdenlive, KDE's (Install > Productivity; since 2026-10-17); OBS Studio, the OBS project's own Flatpak (Install > Productivity; the project's other official channel, its PPA, has no build for this Ubuntu release, and Ubuntu's archive has its own build in universe); NVIDIA GeForce NOW, through NVIDIA's installer, which adds Flathub itself, and Heroic, published by Heroic's developers (since 2026-10-16) (Install > Gaming)<br><br>**Vendors' install scripts:** Rust (rustup), OCaml (opam) (Install > Development); Ollama (Install > AI)<br><br>**Through mise, from each project's releases:** Ruby, Node.js, Bun, Deno, Go, Python, Zig, Java, .NET, Clojure, Scala, Elixir (Install > Development, through the preinstalled mise); the coding agents Claude Code, Codex, OpenCode, Gemini CLI, Copilot CLI, Crush, Grok CLI (from npm), Pi, Oh My Pi (from GitHub), Hermes, Muse (through Meta's launcher script), Cursor CLI (Setup > Defaults > Agent); since 2026-10-16, Omarchy's Herdr, with Learn > Herdr once it is installed (Install > Development), and Cliamp (Install > Service)<br><br>**Language package registries**, after the language above: Rails from RubyGems, Phoenix from Hex, Laravel from Composer's registry (Install > Development)<br><br>**Nothing installed**, a launcher that opens the site in the browser: any web app, Omarchy's default set (ChatGPT, Grok, WhatsApp, Google Messages, Photos, Maps and Contacts, X, YouTube, Zoom, Discord) included, one at a time (Install > Web App); Xbox Cloud Gaming (Install > Gaming) |
| **Not included, available elsewhere**<br>No entry of its own; the general entry named installs the app as its source publishes it, without Omarchy's setup (checked 2026-10-14) | **Ubuntu's archive, main component** (Install > Package): Docker Engine, as docker.io, without Omarchy's Docker setup (Docker Desktop has its own entry, above)<br><br>**Ubuntu's archive, universe component** (Install > Package): Helix (hx), GitHub CLI (gh)<br><br>**The Snap Store** (Install > Snap): Obsidian (published as `obsidianmd`; also on Flathub), OpenClaw (published by a Snap Store developer, not by the OpenClaw project)<br><br>**Flathub** (Install > Flatpak): LM Studio, the Sunshine streaming host, Moonlight, Pinta, Obsidian |
| **Not included**<br>No entry of its own, and not in Ubuntu's archive, the Snap Store or Flathub (checked 2026-10-14) | Omarchy's own apps (the `omacom-io` projects), shipped with Omarchy: Omawrite, Omacalc (GNOME Calculator takes its place, above), Omacut, and Tensaku, Omarchy's screenshot editor (swappy takes its place, above). Herdr is installable from the menu, above.<br><br>Other apps Omarchy shipped: Aether, Lazydocker. Cliamp is installable from the menu, above. Also try, Omarchy's `tobi-try` package, which Omarchy's shell sets up when it is present; left out by the distro's maintainer (the distro's docs/6, choice 80).<br><br>Shipped with Omarchy, removed with their setup: Omarchy's LazyVim configuration for Neovim; the Docker database installer and the Windows VM, which run on Docker, whose setup the port removed.<br><br>Menu installers dropped because they install Arch or AUR packages: the AI desktop apps ChatGPT (Omarchy installed OpenAI's Codex desktop app), Grok Bot, Hermes Desktop (the Snap Store has only the Hermes agent's command-line tool) and Perplexity (the Snap Store's Perplexity desktop app is a third party's, not matched to Omarchy's package); ONCE; Battle.net (Omarchy ran Blizzard's installer through umu-launcher).<br><br>Arch's package sources: the AUR and Arch packages (Install > AUR), replaced by Install > Package (Ubuntu's archive), Install > Snap (the Snap Store) and Install > Flatpak (Flathub). |

## Removals

`PORT-REMOVALS.md`, next to this file, lists everything the port removed from Omarchy v4.0.4 (files, menu entries, packages, features cut inside kept files, and tests), the reason recorded for each, whether that reason holds, and a ranked restore list (audit of 2026-10-16).

## Tests

`./test/all` runs Omarchy's command-line and shell tests (`test/cli`, `test/shell.d/*-test.sh`); `AGENTS.md` describes them. On 2026-10-16 the 62 shell test files that failed on this branch were sorted: a test of something the port deleted was deleted, a test of Arch behavior in a script the port kept was rewritten for the port's behavior (apt, dpkg, Ubuntu's `sudo` group and unit names), and the failures that were real bugs were fixed in the scripts (`omarchy-launch-desktop` and the application library dropped the `.desktop` suffix that ids such as Telegram's `org.telegram.desktop` need).

The deleted test files and test cases are listed in `PORT-REMOVALS.md`, "Tests".

What the tests need on the machine that runs them, beyond the build tools: `lua` (Ubuntu's `lua5.5`) for the Hyprland configuration tests, `rg` (`ripgrep`) for the plugin, power-profile and Codex usage tests, a UTF-8 locale that loads (a shell exporting `LOCPATH` breaks the locale test), and a checkout whose directories are not group-writable (a checkout made under umask 0002 fails the Plymouth publisher's ownership check, which guards the installed, root-owned tree).

## Rebase

```
git fetch upstream --tags
git rebase <new tag> oaxaca
DISTRO_ID=x DISTRO_NAME=X port/rename.sh --tree <a copy>   # proves the rename still applies
```

Then rebuild `packages/desktop` in `santisbon/oaxaca` and run its boot test and its upgrade test
(`make upgrade-test`, which upgrades the published packages to the new build in a chroot and runs
the migrations for a seeded user).

- Migrations: `migrations/` holds only the port's own (its README says why Omarchy's 106 were
  deleted). Every migration the new tag adds is ported or deleted during the rebase, never kept
  as it comes, because Omarchy's call pacman, limine and snapper. A change on this branch that
  moves a user's files gets a migration of its own through `omarchy-dev-add-migration`.

- Ubuntu components keep Ubuntu's configuration (stonking's packages, not another release's) unless a reason specific to this desktop, or to hardware it runs on, is written down; see the distro repository's `docs/6 - omarchy-port.md`, section "Ubuntu's configuration, not Omarchy's".
- The port supports other hardware, not only the Legion (since 2026-10-16; docs/6, choice 48): Omarchy's fixes for other machines in `install/hardware/` are kept or restored, each gated on Omarchy's own device check and written for Ubuntu (`/etc/modprobe.d` options instead of Limine kernel parameters, Ubuntu package names), within the distro's policy (no DKMS, Ubuntu's kernel and GRUB). A fix that cannot meet it is listed in `PORT-REMOVALS.md` with the reason.
