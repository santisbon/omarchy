# Allow nothing in, everything out.
ufw default deny incoming
ufw default allow outgoing

# Allow ports for LocalSend.
ufw allow 53317/udp
ufw allow 53317/tcp

# Allow Docker containers to use DNS on host.
ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'
ufw allow in proto udp from 192.168.0.0/16 to 172.17.0.1 port 53 comment 'allow-docker-dns'

# Omarchy on Arch ran ufw-docker here so Docker's own iptables rules could not
# punch published container ports through ufw. Ubuntu stonking has no
# ufw-docker package (checked the main, restricted, universe and multiverse
# Packages indexes), so until that is handled Docker's published ports bypass
# ufw. Carried item.

# Installs are followed by reboot, so configure UFW to start on the installed
# system instead of mutating the live install session's firewall.
sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf
systemctl enable ufw
