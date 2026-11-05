echo "Make agent account selection apply to scripts and subprocesses"

# mise is not part of the distro's base install.
omarchy-cmd-missing mise && exit 0

# The settings package ships the mise wrapper declarations. Build the dispatch
# links for this user without installing or changing any agent version.
mise reshim
