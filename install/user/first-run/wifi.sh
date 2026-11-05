notify_update() {
  omarchy-notification-send -u critical -g  "$(omarchy-i18n firstRun.updateTitle)" "$(omarchy-i18n firstRun.updateBody)" \
    --exec omarchy-launch-floating-terminal-with-presentation omarchy-update
}

notify_wifi() {
  omarchy-notification-send -u critical -g 󰖩 "$(omarchy-i18n firstRun.wifiTitle)" "$(omarchy-i18n firstRun.wifiBody)" \
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
    # Nothing to install or update until a link lands, so hold those prompts
    # for however long that takes. nm-online has no "forever", so wait out its
    # timeout as often as needed.
    until nm-online -q -t 86400; do :; done
  fi

  # The live session installs the system; it has nothing to update, and nothing to set up.
  [[ ${OMARCHY_LIVE_SESSION:-0} == 1 ]] && return

  # Both setups install packages, so they wait for the link rather than for the
  # first update. Each invites only once, and only when there is something to
  # set up.
  bash "$OMARCHY_PATH/install/user/first-run/setup-agent.hook"
  bash "$OMARCHY_PATH/install/user/first-run/setup-fingerprint.hook"

  # An installed system is prompted only when something is newer: a fresh install from a current
  # ISO has nothing. omarchy-update-available exits 0 when updates are available, from the package
  # lists apt last fetched; the bar's update indicator reports later ones.
  omarchy-update-available >/dev/null 2>&1 && notify_update
}

# Detached, so a slow or absent connection never holds up the rest of first run.
announce_network &
