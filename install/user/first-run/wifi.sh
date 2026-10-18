notify_update() {
  omarchy-notification-send -u critical -g  "Update System" "Click to update the system." \
    --exec omarchy-launch-floating-terminal-with-presentation omarchy-update
}

notify_wifi() {
  omarchy-notification-send -u critical -g 󰖩 "Setup Wi-Fi" "Click to configure the wireless network." \
    --exec omarchy-shell shell toggle omarchy.network
}

announce_network() {
  # Ethernet is still negotiating DHCP when the session starts, so probing
  # right away calls a working machine offline. NetworkManager reports startup
  # complete once it has tried every connection it could auto-activate, which
  # is the first moment the answer means anything.
  nm-online -q -s -t 30

  # -x takes that answer as it stands rather than waiting out the timeout, so
  # a laptop with nothing to connect to gets prompted immediately.
  if ! nm-online -q -x -t 30; then
    notify_wifi
    # Nothing to update against until a link lands, so hold that prompt.
    nm-online -q -t 3600 || return
  fi

  # The live session installs the system; it has nothing to update. An installed system is
  # prompted only when something is newer: a fresh install from a current ISO has nothing, and
  # the prompt's update then only took a snapshot (the laptop, 2026-10-17). omarchy-update-available
  # exits 0 when updates are available, from the package lists apt last fetched; the bar's update
  # indicator reports later ones.
  [[ ${OMARCHY_LIVE_SESSION:-0} == 1 ]] && return
  omarchy-update-available >/dev/null 2>&1 && notify_update
}

# Detached, so a slow or absent connection never holds up the rest of first run.
announce_network &
