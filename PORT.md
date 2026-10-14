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
  `oaxaca-*`, every path `/usr/share/oaxaca`, the Lua module `oaxaca` and the icon font family
  `oaxaca`. The script is not run on this checkout.
- `PORT.md`, this file.

Nothing here is a Debian package: `debian/` lives in `santisbon/oaxaca` under `packages/desktop/`,
whose `upstream` file names this repository and the ref to build, and whose `scripts/build.sh`
makes the orig tarball with `git archive` (or from a local checkout with `UPSTREAM_DIR=...` while
a change is being developed).

## Rules for a change

- Keep Omarchy's names in every file. Write `omarchy-foo`, `$OMARCHY_PATH`, `/usr/share/omarchy`;
  the rename script does the rest at build time.
- Keep Omarchy's script conventions (`# omarchy:summary=` headers, `omarchy-cmd-present`,
  `omarchy-notification-send`, `gum`).
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
| **Preinstalled** | **Ubuntu's archive, main component:** Files (Nautilus); Papers, the document viewer and the PDF default (since 2026-10-14; Omarchy ships Evince, which stonking has only as an alpha); nano, the default editor (since 2026-10-14); tmux (since 2026-10-14), with Omarchy's configuration (`~/.config/tmux/tmux.conf`), theme sync, Super+Alt+Return (the Work session) and Super+Alt+K (tmux's keybindings)<br><br>**Ubuntu's archive, universe component:** Foot (terminal); imv; mpv; Neovim (since 2026-10-14), without Omarchy's LazyVim configuration; Setup > Defaults > Editor makes Neovim the default; fzf, ripgrep, fd (fd-find), bat; tldr (Omarchy's Python client; here the tealdeer package, a Rust client that installs the same tldr command; since 2026-10-14, set to download its pages on first use); swappy, the screenshot editor the screenshot notification opens (since 2026-10-14; Omarchy uses its own Tensaku); yt-dlp, for Chromium's Download Video extension; Fastfetch (About)<br><br>**The xtradeb PPA on Launchpad**, a community build of upstream Chromium: Chromium, the default browser (`155.0.8059.39-1xtradeb1.2610.1`; since 2026-10-14; unlike Omarchy, Remove > Browser can take it off)<br><br>**The distro's own apt repository**, built from LocalSend's release (Ubuntu's archive has none): LocalSend, behind the Share menu and Files' "Send via LocalSend"<br><br>**This branch's `default/bash`, in the distro's config package:** the shell functions (compress and decompress, iso2sd, format-drive, the git worktree, rsync watcher, SSH port forwarding and SSH reconnection functions, and the tmux layout functions) |
| **Installable directly from the menu**<br>An entry of its own installs the app, with Omarchy's setup where the port kept one; the entry is in parentheses | **Ubuntu's archive, main component:** Vim (Install > Editor); PHP (Install > Development)<br><br>**Ubuntu's archive, universe component:** Alacritty, Ghostty, Kitty, and Foot again after it was removed (Install > Terminal); Emacs, as emacs-pgtk (Install > Editor); RetroArch and its game launcher, Xbox Controllers (xpadneo) (Install > Gaming)<br><br>**Ubuntu's archive, multiverse component:** Dropbox, whose package downloads Dropbox's client on first run (Install > Service); Steam and Lutris, with NVIDIA's 32-bit libraries from the restricted component when an NVIDIA driver is installed (Install > Gaming)<br><br>**Vendors' apt repositories:** Chrome (Google's package, which adds Google's repository), Brave Origin (Brave's), Firefox (Mozilla's) (Install > Browser; Omarchy also offers Edge, Brave and Zen); VS Code (Microsoft's), Sublime Text (Sublime HQ's) (Install > Editor); 1Password, Spotify, Signal, Mullvad VPN, Tailscale, each from its vendor's (Install > Service)<br><br>**The xtradeb PPA on Launchpad:** Chromium again after it was removed (Install > Browser)<br><br>**The distro's own apt repository**, built from Voxtype's release package: Dictation (Voxtype), with its speech model (Whisper `base.en`, 142 MB) downloaded from Voxtype's model server, `models.voxtype.io`, at install, running on the discrete GPU when one has a Vulkan driver (Install > AI; the bar's Dictation indicator opens the same installer)<br><br>**The Snap Store:** Wave (Install > Terminal); Thunderbird, which Super+Shift+E opens while it is installed (Install > Service)<br><br>**Flathub:** VSCodium (Install > Editor); LibreOffice, published and verified by The Document Foundation (Install > Productivity, a category the port added; also in Ubuntu's archive, the `libreoffice` package in universe and its apps in main, and on the Snap Store, published by Canonical, which carried an older release on 2026-10-14: 26.2.5.2 against Flathub's 26.8.1.1); NVIDIA GeForce NOW, through NVIDIA's installer, which adds Flathub itself (Install > Gaming)<br><br>**Vendors' install scripts:** mise (`mise.run`), Rust (rustup), OCaml (opam) (Install > Development); Ollama (Install > AI)<br><br>**Through mise, from each project's releases:** Ruby, Node.js, Bun, Deno, Go, Python, Zig, Java, .NET, Clojure, Scala, Elixir (Install > Development, which installs mise first when it is missing); the coding agents Claude Code, Codex, OpenCode, Gemini CLI, Copilot CLI, Crush, Grok CLI (from npm), Pi, Oh My Pi (from GitHub), Hermes, Muse (through Meta's launcher script), Cursor CLI (Setup > Defaults > Agent)<br><br>**Language package registries**, after the language above: Rails from RubyGems, Phoenix from Hex, Laravel from Composer's registry (Install > Development)<br><br>**Nothing installed**, a launcher that opens the site in the browser: any web app, Omarchy's default set (ChatGPT, Grok, WhatsApp, Google Messages, Photos, Maps and Contacts, X, YouTube, Zoom, Discord) included, one at a time (Install > Web App); Xbox Cloud Gaming (Install > Gaming) |
| **Not included, available elsewhere**<br>No entry of its own; the general entry named installs the app as its source publishes it, without Omarchy's setup (checked 2026-10-14) | **Ubuntu's archive, main component** (Install > Package): Docker, as docker.io, without Omarchy's Docker setup<br><br>**Ubuntu's archive, universe component** (Install > Package): Helix (hx), Lazygit, btop, zoxide, eza, Disk Usage (dua-cli), GitHub CLI (gh), Kdenlive, OBS Studio, Xournal++<br><br>**The Snap Store** (Install > Snap): Bitwarden (published by Bitwarden; also on Flathub), NordVPN (published by NordVPN), Obsidian (published as `obsidianmd`; also on Flathub), OpenClaw (published by a Snap Store developer, not by the OpenClaw project)<br><br>**Flathub** (Install > Flatpak): LM Studio, Heroic, Minecraft Launcher, the Sunshine streaming host, Moonlight, Pinta, Obsidian, Bitwarden |
| **Not included**<br>No entry of its own, and not in Ubuntu's archive, the Snap Store or Flathub (checked 2026-10-14) | Omarchy's own apps (the `omacom-io` projects), shipped with Omarchy: Herdr, Omawrite, Omacalc, Omacut, and Tensaku, Omarchy's screenshot editor (swappy takes its place, above).<br><br>Other apps Omarchy shipped: Aether, Cliamp, Lazydocker. Also try, which Omarchy's shell sets up when it is present but which Omarchy 4.0.4's package list does not install either.<br><br>Shipped with Omarchy, removed with their setup: Omarchy's LazyVim configuration for Neovim; the Docker database installer and the Windows VM, which run on Docker, whose setup the port removed.<br><br>Menu installers dropped because they install Arch or AUR packages: the AI desktop apps ChatGPT (Omarchy installed OpenAI's Codex desktop app), Grok Bot, Hermes Desktop (the Snap Store has only the Hermes agent's command-line tool) and Perplexity (the Snap Store's Perplexity desktop app is a third party's, not matched to Omarchy's package); ONCE; Battle.net (Omarchy ran Blizzard's installer through umu-launcher).<br><br>Arch's package sources: the AUR and Arch packages (Install > AUR), replaced by Install > Package (Ubuntu's archive), Install > Snap (the Snap Store) and Install > Flatpak (Flathub). |

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

- Ubuntu components keep Ubuntu's configuration (stonking's packages, not another release's) unless a reason specific to this desktop is written down; see the distro repository's `docs/6 - omarchy-port.md`, section "Ubuntu's configuration, not Omarchy's".
