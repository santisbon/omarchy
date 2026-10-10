# Nothing to run at the login layer. Omarchy's Arch build stripped
# pam_gnome_keyring out of /etc/pam.d/sddm here to pair with a passwordless
# default keyring. This distro keeps Ubuntu's stock sddm PAM stack, where the
# login password unlocks the GNOME keyring, so the file stays as the recorded
# home of that decision.
