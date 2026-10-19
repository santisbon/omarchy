# Give commands run over SSH (ssh host cmd) the user-level tool paths: mise's shims and
# ~/.local/bin, so tools installed through mise (herdr, cliamp, editors, agent CLIs) are found.
#
# Such a command runs without a login shell and without an interactive one: sshd starts
# "bash -c cmd", Ubuntu's ~/.bashrc returns before anything when the shell is not interactive,
# and Omarchy's environment (default/bash/env-bootstrap, which appends the same two directories
# for login and interactive shells) loads from ~/.bash_aliases after that return. The command's
# PATH is what PAM's pam_env module sets for the session, so the directories go there.
#
# Ubuntu's PAM services run pam_env twice (stonking's openssh-server 1:10.5p1-1ubuntu2, login,
# su, sudo, sddm): the first pass reads /etc/security/pam_env.conf and then /etc/environment,
# which sets Ubuntu's full PATH; the second reads pam_env.conf again and then
# /etc/default/locale. The line below appends to ${PATH} instead of setting a PATH of its own
# (Omarchy's line names one without /usr/sbin, /sbin, /bin and Ubuntu's /snap/bin), so on the
# second pass it adds the two directories after Ubuntu's PATH. @{HOME} is the session user's home
# from passwd. Ubuntu's pam_env reads no drop-in directory, so the line goes into
# pam_env.conf itself, which has no active line on Ubuntu; a PATH line already there (the
# administrator's) is left alone. Keep the directories in sync with default/bash/env-bootstrap.
conf="${OMARCHY_PAM_ENV_CONF:-/etc/security/pam_env.conf}"
if ! grep -qE '^PATH[[:space:]]' "$conf"; then
  cat >>"$conf" <<'EOF'

# Omarchy: give SSH commands and other non-shell logins the user-level tool paths
PATH DEFAULT=${PATH}:@{HOME}/.local/share/mise/shims:@{HOME}/.local/bin
EOF
fi

# Marks the line as set up. The config package's postinst adds it once for systems installed
# before this script came back, and skips any system with this marker, so a user who later
# removes the line keeps it removed.
mkdir -p /var/lib/omarchy
touch /var/lib/omarchy/ssh-command-path
