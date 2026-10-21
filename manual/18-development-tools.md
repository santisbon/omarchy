# Development Tools

## Alternative Editors

Omarchy ships with [Neovim](https://neovim.io/) by default, but if you'd like something a bit more mainstream and familiar, you can run the Omarchy Menu (`Super + Space`) and see the options under _Install > Editor_. We have VSCode, Cursor, Zed, Sublime Text, Helix, Vim, and Emacs listed there. If you don't find what you're looking for, checkout _Install > Package_, and see if it isn't in an Arch package (and if not, try _Install > AUR_ to check the AUR).

Theme matching is offered for `VSCode`, `Cursor`, `VSCodium`, and `Helix`.

You can set the system-wide default editor under `Setup > Defaults > Editor`.

## Environment

Omarchy supports setting up a whole host of development environments through the _Install > Development_ section of the Omarchy Menu (`Super + Space`). You'll of course find _Ruby on Rails_, but also all three major runtimes for JavaScript (Node.js, Bun, Deno), as well as popular PHP frameworks like Laravel and Symfony. Oh, and there's Go, Rust, Python, Java, Elixir (with Phoenix), .NET, OCaml, Zig, Clojure, and Scala too. It's a very broad selection!

The majority of these environments are managed by [Mise](https://mise.jdx.dev/). It's a tool that lets you install and run multiple versions of a programming language on the same machine. It's like rbenv or rvm for Ruby or virtualenv for Python, but it works for a bunch of different environments.

To install, say, Ruby, you'd run `mise use -g ruby`, which will both install Ruby and set it as the global default. Or, if your project has a .ruby-version file, you can just run `mise i` in the root of that project.

## Docker

[Docker](https://www.docker.com/) hardly needs any introduction. It allows you to run isolated containers.

It's not part of the base install: install Docker Desktop from _Install > Development > Docker Desktop_ in the Omarchy menu (`Super + Space`). The installer follows [Docker's own instructions for Ubuntu](https://docs.docker.com/desktop/setup/install/linux/ubuntu/): it adds Docker's apt repository, installs gnome-terminal (Docker Desktop opens container terminals in it), installs Docker's package, and adds you to the `kvm` group, since Docker Desktop runs its engine in a virtual machine. Docker Desktop comes with the `docker` command and [Docker Compose](https://docs.docker.com/compose/). Sign out and back in if Docker Desktop says it can't reach `/dev/kvm`.

To sign in to Docker Hub, Docker Desktop stores your credentials with [`pass`](https://www.passwordstore.org/), which you set up once: run `gpg --generate-key`, then `pass init` with the key ID it prints ([Docker's steps](https://docs.docker.com/desktop/setup/install/linux/#signing-in-with-docker-desktop-for-linux)).

_Remove > Development > Docker Desktop_ removes it with its containers, images and settings.

## GitHub CLI

[The GitHub CLI](https://cli.github.com/) lets you authenticate with your GitHub account and clone private repositories using it. Install it from _Install > Development > GitHub CLI_ in the Omarchy menu: the installer follows [GitHub's instructions for Debian and Ubuntu](https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian), adding GitHub's apt repository and installing the `gh` package, so `gh` updates with the rest of the system. If you already added GitHub's repository by hand from those instructions, the installer replaces your `github-cli.list` with its own source. _Remove > Development > GitHub CLI_ removes `gh` and GitHub's repository, and keeps your sign-in in `~/.config/gh`.

`gh` is also wired up as one of the lazy-loading mise stubs, `~/.local/bin/gh`: without the package, the first time you run `gh`, mise installs it. With the package installed, `/usr/bin/gh` comes first on your `PATH` and the stub stays unused. To authenticate, run `gh auth login`. Then you can checkout private repositories using `gh repo clone org/repo`.

You can also perform a bunch of other GitHub operations using this command. Just run `gh` to see everything that's possible.

There's a lazy-installing stub for `ghui` for managing your pull requests in a TUI too. And [lazygit](https://github.com/jesseduffield/lazygit) is preinstalled, if you'd like to drive git itself from a TUI as well.
