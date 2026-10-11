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
