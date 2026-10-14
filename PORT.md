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

What the manual's "The Applications" chapters (`manual/15-terminal.md` to `manual/29-other-packages.md`, listed in `README.md`) describe, as this port has it. Checked 2026-10-13 against the distro's installation image (its package list and files), this branch's menu (`default/omarchy/omarchy-menu.jsonc`), Ubuntu's archive for the base series (stonking's package indexes), and, for what Omarchy shipped and offered, the `v4.0.4` tag's `install/omarchy-base.packages`, menu and `bin/omarchy-install-*` scripts. "Install > Package" is the menu's entry for any package in Ubuntu's archive; it installs the program without the configuration Omarchy shipped for it.

| | Applications |
|---|---|
| **Preinstalled** | Foot (terminal)<br><br>Files (Nautilus), imv, mpv<br><br>fzf, ripgrep, fd, bat<br><br>Fastfetch (About)<br><br>the shell functions (compress and decompress, iso2sd, format-drive, the git worktree, rsync watcher, SSH port forwarding and SSH reconnection functions; the tmux layout functions are there but need tmux, below) |
| **Installable from the menu** | Install > Terminal: Alacritty, Ghostty, Kitty.<br><br>Install > Editor: VS Code, VSCodium, Sublime Text, Vim, Emacs.<br><br>Install > Development: mise, then Ruby on Rails, Node.js, Bun, Deno, Go, Python, Zig, Rust, Java, .NET, OCaml, Clojure, Scala, PHP and Laravel, Elixir and Phoenix.<br><br>Setup > Defaults > Agent: the coding agents Claude Code, Codex, OpenCode, Gemini CLI, Copilot CLI, Crush, Grok CLI, Pi, Oh My Pi, Hermes, Muse, Cursor CLI (installs mise first when it is missing).<br><br>Install > AI: Ollama.<br><br>Install > Browser: Chromium, Chrome, Brave Origin, Firefox.<br><br>Install > Service: 1Password, Spotify, Dropbox, Tailscale, Signal.<br><br>Install > Gaming: Steam, RetroArch and its game launcher, Xbox Cloud Gaming, NVIDIA GeForce NOW, Xbox Controllers (xpadneo), Lutris.<br><br>Install > Web App: any web app, Omarchy's default set (HEY, Basecamp, ChatGPT, Grok, WhatsApp, Google Messages, Photos, Maps and Contacts, X, YouTube, Zoom, Discord) included, one at a time.<br><br>Install > Package, from Ubuntu's archive: Neovim (without Omarchy's LazyVim setup), Helix, tmux, Lazygit, btop, zoxide, eza, tldr (tealdeer), yt-dlp, Disk Usage (dua-cli), GitHub CLI (gh), Docker (docker.io, without Omarchy's Docker setup), LibreOffice, Kdenlive, OBS Studio, Xournal++, Document Viewer (evince; also in the distro's optional desktop-apps package) |
| **Not included** | Omarchy's own apps (the `omacom-io` projects), not in Ubuntu's archive: Herdr, Omawrite, Omacalc, Omacut.<br><br>Other apps Omarchy shipped, not in Ubuntu's archive: Aether, Cliamp, Obsidian, Pinta, LocalSend (so the Share menu has nothing to send with), Moonlight, Lazydocker. Also try, which Omarchy's shell sets up when it is present but which Omarchy 4.0.4's package list does not install either.<br><br>Shipped with Omarchy, removed with their setup: Omarchy's LazyVim configuration for Neovim; the Docker database installer and the Windows VM, which run on Docker, whose setup the port removed.<br><br>Menu installers dropped because they install Arch or AUR packages (another route on Ubuntu, such as a vendor's package, the Snap Store or Flathub, has not been set up for them): the AI desktop apps (ChatGPT, Grok Bot, Hermes Desktop, OpenClaw, Perplexity), LM Studio, Bitwarden, ONCE, NordVPN, Minecraft, Battle.net, Heroic, and the Sunshine streaming host (`omarchy install service sunshine`).<br><br>Arch's package sources: the AUR and Arch packages (Install > AUR), replaced by Install > Package (Ubuntu's archive), the Snap Store and Flathub. |

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
