# Migrations

A migration is a script in this directory, named by a Unix timestamp (`omarchy-dev-add-migration`
takes the latest commit's date), that `omarchy-migrate` runs once per user, as that user, and then
marks done with a file of the same name under `~/.local/state/omarchy/migrations/`. The runner is
`bin/omarchy-migrate`; `omarchy-update` runs the runner after the package upgrade, and
`omarchy-migrate-notify.service` offers the pending migrations at login. A fresh user starts with
every shipped migration marked done (`omarchy-provision-user`, first install), so a migration only
ever runs for users who existed before the change the migration repairs.

This directory holds only the port's own migrations. Omarchy's migrations up to the pinned tag
(106 files, `1778623107.sh` to `1789444024.sh`) were deleted on the port branch on 2026-10-11:
those scripts repair Arch installs made before that tag, call pacman, limine and snapper, and no
system built from this branch ever ran the state those scripts move away from. On every rebase onto
a new Omarchy tag, each migration the new tag adds is either ported (apt in place of pacman,
Ubuntu's names) or deleted; none is kept as it comes. See `PORT.md`, "Rebase".

A migration edits the user's files only, needs no root, and must be safe to run for a user who
never had the old state (exit 0 when there is nothing to do).
