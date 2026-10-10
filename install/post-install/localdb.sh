# Update localdb so locate can find the installed system files immediately.
# Match the scheduled service while installation runs without a system manager.
# Omarchy's Arch build also pruned /.snapshots; there is no snapper here.
updatedb --prune-bind-mounts=no
