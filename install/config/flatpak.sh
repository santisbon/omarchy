# Flathub as a system-wide Flatpak remote, from the repository file Ubuntu's flatpak
# package ships (/usr/share/doc/flatpak/examples/flathub.flatpakrepo in flatpak 1.18.4-1),
# so nothing is downloaded at install time. Snap needs no counterpart here: snapd's
# postinst enables snapd.socket and its store is built in.
flatpak remote-add --if-not-exists --system flathub /usr/share/doc/flatpak/examples/flathub.flatpakrepo
