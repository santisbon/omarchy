# Persist wireless regulatory domain based on the target timezone. Install is
# followed by reboot, so don't mutate live Wi-Fi state with `iw reg set`.
#
# Omarchy writes Arch's /etc/conf.d/wireless-regdom. Ubuntu has no such file:
# the kernel's cfg80211 module takes the country as its ieee80211_regdom
# parameter, so the country goes into /etc/modprobe.d instead, and
# wireless-regdb (in the image) supplies the rules for it.
regdom_file=/etc/modprobe.d/omarchy-wireless-regdom.conf
[[ -f $regdom_file ]] && exit 0

timezone=""
if [[ -e /etc/localtime ]]; then
  timezone=$(readlink -f /etc/localtime || true)
  timezone=${timezone#/usr/share/zoneinfo/}
fi

country="${timezone%%/*}"
zone_tab=/usr/share/zoneinfo/zone.tab
if [[ ! $country =~ ^[A-Z]{2}$ && -n $timezone && -f $zone_tab ]]; then
  country=$(awk -v tz="$timezone" '$3 == tz {print $1; exit}' "$zone_tab")
fi

if [[ $country =~ ^[A-Z]{2}$ ]]; then
  mkdir -p /etc/modprobe.d
  cat > "$regdom_file" <<CONF
# Wireless regulatory domain from the timezone chosen at install (install/hardware/set-wireless-regdom.sh)
options cfg80211 ieee80211_regdom=$country
CONF
fi
