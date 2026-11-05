echo "Replace the Disk Usage TUI with Disktree"

# oaxaca-desktop depends on disktree now, and the update's autoremove takes dua-cli, which nothing
# depends on any more.

rm -f "$HOME/.local/share/applications/Disk Usage.desktop"
if [[ -d $HOME/.local/share/applications ]]; then
  update-desktop-database "$HOME/.local/share/applications"
fi
