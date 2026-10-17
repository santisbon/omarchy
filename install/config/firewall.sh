# Turn the firewall on for the installed system, with one hole: LocalSend's port.
#
# Ubuntu ships ufw installed and off (ENABLED=no in /etc/ufw/ufw.conf), so nothing filters
# inbound traffic. This desktop preinstalls LocalSend, which listens on 53317 tcp and udp, and
# Setup > Security > SSH adds "ufw limit 22/tcp", which only filters once ufw is on. Ubuntu's
# own policies in /etc/default/ufw (stonking's ufw 0.36.2-10) already deny incoming, allow
# outgoing and deny forwarding, so this script sets no policy. Omarchy's Docker DNS rules and
# its ufw-docker add-on are left out: Docker is not preinstalled and ufw-docker is not in
# stonking.

ufw allow 53317/udp comment 'localsend'
ufw allow 53317/tcp comment 'localsend'

# Installs are followed by reboot, and the installer's chroot shares the live session's kernel
# firewall, so turn ufw on for the next boot instead of running "ufw enable" here. ufw.service
# is already enabled by the package's postinst; ufw-init loads the rules when ENABLED=yes.
sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf
systemctl enable ufw

# Marks the firewall as set up. The config package's postinst turns ufw on once for systems
# installed before this script existed, and skips any system with this marker, so a user who
# later turns ufw off keeps it off.
mkdir -p /var/lib/omarchy
touch /var/lib/omarchy/firewall-on
