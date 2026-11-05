# Development Tools

## Alternative Editors

Omarchy ships with [Neovim](https://neovim.io/) by default, but if you'd like something a bit more mainstream and familiar, you can run the Omarchy Menu (`Super + Space`) and see the options under _Install > Editor_. We have VSCode, Cursor, Zed, Sublime Text, Helix, Vim, and Emacs listed there. If you don't find what you're looking for, checkout _Install > Package_, and see if it isn't in an Arch package (and if not, try _Install > AUR_ to check the AUR).

> **Oaxaca: removed.** Cursor, Zed and Helix are not in Oaxaca's _Install > Editor_, and the menu has no _Install > AUR_.

> **Oaxaca: works differently.** Oaxaca's _Install > Editor_ offers VS Code (Microsoft's apt repository), VSCodium (Flathub), Sublime Text (Sublime HQ's apt repository), Vim and Emacs (Ubuntu's archive, Emacs as `emacs-pgtk`). _Install > Package_ searches Ubuntu's archive, and _Install > Snap_ and _Install > Flatpak_ search the Snap Store and Flathub in place of the AUR. _Remove > Editor_ removes VS Code or Sublime Text together with its vendor's apt repository, which _Remove > Package_ would leave behind.

Theme matching is offered for `VSCode`, `Cursor`, `VSCodium`, and `Helix`.

> **Oaxaca: works differently.** VSCodium's theme matching follows the Flatpak's settings paths under `~/.var/app/com.vscodium.codium/`. Helix's theme template still themes a Helix installed through _Install > Package_, though the menu no longer offers Helix by name.

You can set the system-wide default editor under `Setup > Defaults > Editor`.

> **Oaxaca: works differently.** The default editor out of the box is nano, preinstalled from Ubuntu's archive, not Neovim; `Setup > Defaults > Editor` lists nano and VSCodium as well.

## Environment

Omarchy supports setting up a whole host of development environments through the _Install > Development_ section of the Omarchy Menu (`Super + Space`). You'll of course find _Ruby on Rails_, but also all three major runtimes for JavaScript (Node.js, Bun, Deno), as well as popular PHP frameworks like Laravel and Symfony. Oh, and there's Go, Rust, Python, Java, Elixir (with Phoenix), .NET, OCaml, Zig, Clojure, and Scala too. It's a very broad selection!

> **Oaxaca: removed.** _Install > Development_ has no PHP section: PHP, Laravel and Symfony are not offered, since nothing in the desktop uses PHP.

> **Oaxaca: works differently.** Oaxaca's base install has no C compiler, so the Ruby on Rails, Node.js, Python, Elixir, Phoenix, Rust and OCaml entries install Ubuntu's `build-essential` first (OCaml also `unzip`). A `mise use -g ruby` typed in a terminal needs `build-essential` installed the same way.

> **Oaxaca: added.** _Install > Development_ also offers Docker Desktop, the GitHub CLI and the AWS CLI (each described below), and Herdr, a terminal workspace manager for AI coding agents installed through mise.

The majority of these environments are managed by [Mise](https://mise.jdx.dev/). It's a tool that lets you install and run multiple versions of a programming language on the same machine. It's like rbenv or rvm for Ruby or virtualenv for Python, but it works for a bunch of different environments.

To install, say, Ruby, you'd run `mise use -g ruby`, which will both install Ruby and set it as the global default. Or, if your project has a .ruby-version file, you can just run `mise i` in the root of that project.

## Preinstalled CLI tools

Omarchy makes tools such as `gh`, `uv`, and most [coding agents](17-ai.md) available through [mise's lazy installation](https://mise.jdx.dev/dev-tools/shims.html#lazy-tools). The first time you run one, mise installs it. Later runs reuse the installed version; they do not check for an update on every launch.

You can also inspect the defaults or install them ahead of time:

```bash
mise ls --current              # List the tools configured for this directory
mise install gh               # Install one tool now
mise install --include-lazy    # Install all configured tools, including lazy tools
```

Run `omarchy update` to update installed tools with the rest of Omarchy. The `mup` alias updates mise-managed tools only. To add another tool to your own configuration, use `mise use -g <tool>`.

Python setup also installs `uv` through mise. Removing the Python development environment leaves `uv` available as an independent tool.

### Using your own installation

mise's commands come before `~/.local/bin` on `PATH`, so a tool you installed yourself, for example with Claude Code's or Cursor's own installer, still runs mise's copy. Apps launched from the desktop also find mise's commands before system packages, so an app that runs `gh` gets mise's copy even if you installed the `gh` package with apt, and mise installs that copy the first time. To use yours instead, disable mise's copy in `~/.config/mise/config.toml`. For example, if you installed Cursor CLI yourself:

```toml
[settings]
disable_tools = ["cursor-agent"]
```

If you already have a `[settings]` table, add the entry there; extend an existing `disable_tools` list rather than replacing it. Make sure your installation is on `PATH`. Use the mise tool name, which can differ from its command: `oh-my-pi` provides `omp`, for example. The default-agent launcher also prefers a user-installed Cursor or Muse in `~/.local/bin`.

## Docker

[Docker](https://www.docker.com/) hardly needs any introduction. It allows you to run isolated containers.

It's not part of the base install: install Docker Desktop from _Install > Development > Docker Desktop_ in the Omarchy menu (`Super + Space`). The installer follows [Docker's own instructions for Ubuntu](https://docs.docker.com/desktop/setup/install/linux/ubuntu/): it adds Docker's apt repository, installs gnome-terminal (Docker Desktop opens container terminals in it), installs Docker's package, and adds you to the `kvm` group, since Docker Desktop runs its engine in a virtual machine. Docker Desktop comes with the `docker` command and [Docker Compose](https://docs.docker.com/compose/). Sign out and back in if Docker Desktop says it can't reach `/dev/kvm`.

To sign in to Docker Hub, Docker Desktop stores your credentials with [`pass`](https://www.passwordstore.org/), which you set up once: run `gpg --generate-key`, then `pass init` with the key ID it prints ([Docker's steps](https://docs.docker.com/desktop/setup/install/linux/#signing-in-with-docker-desktop-for-linux)).

_Remove > Development > Docker Desktop_ removes it with its containers, images and settings.

> **Oaxaca: works differently.** Omarchy instead preinstalls Docker Engine with Docker Compose and keeps the user out of the `docker` group, so `docker` runs with `sudo` unless _Setup > Security > Sudoless Docker_ adds the user to the group and offers _Install > Development > Docker DB_ for local databases. Oaxaca keeps all of Omarchy's Docker setup out and offers Docker Desktop instead, which runs its own engine in a virtual machine.

## GitHub CLI

[GitHub CLI](https://cli.github.com/) is available as `gh` for working with repositories, issues, and pull requests from the terminal. Run `gh auth login` to install it on first use and authenticate, then `gh repo clone org/repo` to clone a repository. Run `gh --help` to explore its commands.

To get `gh` from a package instead, use _Install > Development > GitHub CLI_ in the Omarchy menu: the installer follows [GitHub's instructions for Debian and Ubuntu](https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian), adding GitHub's apt repository and installing the `gh` package, so `gh` updates with the rest of the system. If you already added GitHub's repository by hand from those instructions, the installer replaces your `github-cli.list` with its own source. Since mise's commands come before system packages on `PATH`, add `gh` to `disable_tools` as [Using your own installation](#using-your-own-installation) shows, or mise's copy still runs. _Remove > Development > GitHub CLI_ removes `gh` and GitHub's repository, and keeps your sign-in in `~/.config/gh`.

For a terminal interface to pull requests, run `ghui`; mise installs it on first use too. [Lazygit](https://github.com/jesseduffield/lazygit) is preinstalled for working with Git itself.

> **Oaxaca: works differently.** Oaxaca preinstalls lazygit from Ubuntu's archive with Omarchy's configuration.

## AWS CLI

[The AWS CLI](https://aws.amazon.com/cli/) manages your Amazon Web Services resources from the terminal with the `aws` command. Install it from _Install > Development > AWS CLI_ in the Omarchy menu: the installer runs `snap install aws-cli --classic`, the snap Amazon Web Services publishes on the Snap Store, with classic confinement so `aws` can read your `~/.aws` profiles and any file you pass it. Snaps update themselves. To set up a profile, run `aws configure`. _Remove > Development > AWS CLI_ removes the snap and keeps `~/.aws`.
