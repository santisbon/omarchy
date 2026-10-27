# Development Tools

## Alternative Editors

Omarchy ships with [Neovim](https://neovim.io/) by default, but if you'd like something a bit more mainstream and familiar, you can run the Omarchy Menu (`Super + Space`) and see the options under _Install > Editor_. We have VSCode, Cursor, Zed, Sublime Text, Helix, Vim, and Emacs listed there. If you don't find what you're looking for, checkout _Install > Package_, and see if it isn't in an Arch package (and if not, try _Install > AUR_ to check the AUR).

> **Oaxaca: removed.** Cursor, Zed and Helix are not in Oaxaca's _Install > Editor_, and the menu has no _Install > AUR_ (the distro's docs/6, choice 74).

> **Oaxaca: works differently.** Oaxaca's _Install > Editor_ offers VS Code (Microsoft's apt repository), VSCodium (Flathub), Sublime Text (Sublime HQ's apt repository), Vim and Emacs (Ubuntu's archive, Emacs as `emacs-pgtk`). _Install > Package_ searches Ubuntu's archive, and _Install > Snap_ and _Install > Flatpak_ search the Snap Store and Flathub in place of the AUR (the distro's docs/6, choice 22). _Remove > Editor_ removes VS Code or Sublime Text together with its vendor's apt repository, which _Remove > Package_ would leave behind (choice 107).

Theme matching is offered for `VSCode`, `Cursor`, `VSCodium`, and `Helix`.

> **Oaxaca: works differently.** VSCodium's theme matching follows the Flatpak's settings paths under `~/.var/app/com.vscodium.codium/`. Helix's theme template still themes a Helix installed through _Install > Package_, though the menu no longer offers Helix by name.

You can set the system-wide default editor under `Setup > Defaults > Editor`.

> **Oaxaca: works differently.** The default editor out of the box is nano, preinstalled from Ubuntu's archive, not Neovim; `Setup > Defaults > Editor` lists nano and VSCodium as well (the distro's docs/6, choice 26).

## Environment

Omarchy supports setting up a whole host of development environments through the _Install > Development_ section of the Omarchy Menu (`Super + Space`). You'll of course find _Ruby on Rails_, but also all three major runtimes for JavaScript (Node.js, Bun, Deno), as well as popular PHP frameworks like Laravel and Symfony. Oh, and there's Go, Rust, Python, Java, Elixir (with Phoenix), .NET, OCaml, Zig, Clojure, and Scala too. It's a very broad selection!

> **Oaxaca: removed.** _Install > Development_ has no PHP section: PHP, Laravel and Symfony are not offered, since nothing in the desktop uses PHP (the distro's docs/6, choice 41).

> **Oaxaca: works differently.** Oaxaca's base install has no C compiler, so the Ruby on Rails, Node.js, Python, Elixir, Phoenix, Rust and OCaml entries install Ubuntu's `build-essential` first (OCaml also `unzip`). A `mise use -g ruby` typed in a terminal needs `build-essential` installed the same way (the distro's docs/6, choice 18).

> **Oaxaca: added.** _Install > Development_ also offers Docker Desktop, the GitHub CLI and the AWS CLI (each described below), and Herdr, a terminal workspace manager for AI coding agents installed through mise (the distro's docs/6, choices 80, 85, 93 and 94).

The majority of these environments are managed by [Mise](https://mise.jdx.dev/). It's a tool that lets you install and run multiple versions of a programming language on the same machine. It's like rbenv or rvm for Ruby or virtualenv for Python, but it works for a bunch of different environments.

To install, say, Ruby, you'd run `mise use -g ruby`, which will both install Ruby and set it as the global default. Or, if your project has a .ruby-version file, you can just run `mise i` in the root of that project.

## Docker

[Docker](https://www.docker.com/) hardly needs any introduction. It allows you to run isolated containers.

It's not part of the base install: install Docker Desktop from _Install > Development > Docker Desktop_ in the Omarchy menu (`Super + Space`). The installer follows [Docker's own instructions for Ubuntu](https://docs.docker.com/desktop/setup/install/linux/ubuntu/): it adds Docker's apt repository, installs gnome-terminal (Docker Desktop opens container terminals in it), installs Docker's package, and adds you to the `kvm` group, since Docker Desktop runs its engine in a virtual machine. Docker Desktop comes with the `docker` command and [Docker Compose](https://docs.docker.com/compose/). Sign out and back in if Docker Desktop says it can't reach `/dev/kvm`.

To sign in to Docker Hub, Docker Desktop stores your credentials with [`pass`](https://www.passwordstore.org/), which you set up once: run `gpg --generate-key`, then `pass init` with the key ID it prints ([Docker's steps](https://docs.docker.com/desktop/setup/install/linux/#signing-in-with-docker-desktop-for-linux)).

_Remove > Development > Docker Desktop_ removes it with its containers, images and settings.

> **Oaxaca: works differently.** This Docker section was rewritten for Oaxaca. Omarchy instead preinstalls Docker Engine with Docker Compose and keeps the user out of the `docker` group, so `docker` runs with `sudo` unless _Setup > Security > Sudoless Docker_ adds the user to the group; Omarchy also binds the Lazydocker TUI to `Super + Shift + D` and offers _Install > Development > Docker DB_ for local databases. Oaxaca keeps all of Omarchy's Docker setup out and offers Docker Desktop instead, which runs its own engine in a virtual machine (the distro's docs/6, choices 71 and 85).

## GitHub CLI

[The GitHub CLI](https://cli.github.com/) lets you authenticate with your GitHub account and clone private repositories using it. Install it from _Install > Development > GitHub CLI_ in the Omarchy menu: the installer follows [GitHub's instructions for Debian and Ubuntu](https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian), adding GitHub's apt repository and installing the `gh` package, so `gh` updates with the rest of the system. If you already added GitHub's repository by hand from those instructions, the installer replaces your `github-cli.list` with its own source. _Remove > Development > GitHub CLI_ removes `gh` and GitHub's repository, and keeps your sign-in in `~/.config/gh`.

`gh` is also wired up as one of the lazy-loading mise stubs, `~/.local/bin/gh`: without the package, the first time you run `gh`, mise installs it. With the package installed, `/usr/bin/gh` comes before the stub on your `PATH` and the stub stays unused. One exception: once the stub has run, mise has its own `gh`, and in a terminal mise's tools come before `/usr/bin` on your `PATH`, so that copy wins over the package. `mise ls gh` shows whether mise has one, and `mise unuse -g gh` removes it. To authenticate, run `gh auth login`. Then you can checkout private repositories using `gh repo clone org/repo`.

You can also perform a bunch of other GitHub operations using this command. Just run `gh` to see everything that's possible.

There's a lazy-installing stub for `ghui` for managing your pull requests in a TUI too. And [lazygit](https://github.com/jesseduffield/lazygit) is preinstalled, if you'd like to drive git itself from a TUI as well.

> **Oaxaca: works differently.** The GitHub CLI section above was rewritten for Oaxaca. Omarchy has no _Install > Development > GitHub CLI_ entry: `gh` comes only from the lazy-loading mise stub, installed the first time `gh` runs (the distro's docs/6, choice 93). Oaxaca preinstalls lazygit from Ubuntu's archive with Omarchy's configuration (the distro's docs/6, choice 43).

## AWS CLI

[The AWS CLI](https://aws.amazon.com/cli/) manages your Amazon Web Services resources from the terminal with the `aws` command. Install it from _Install > Development > AWS CLI_ in the Omarchy menu: the installer runs `snap install aws-cli --classic`, the snap Amazon Web Services publishes on the Snap Store, with classic confinement so `aws` can read your `~/.aws` profiles and any file you pass it. Snaps update themselves. To set up a profile, run `aws configure`. _Remove > Development > AWS CLI_ removes the snap and keeps `~/.aws`.

> **Oaxaca: added.** The AWS CLI section describes Oaxaca only: Omarchy's menu has no AWS CLI entry (the distro's docs/6, choice 94).
