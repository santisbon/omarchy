# No browser is preinstalled on this distro, so the Chromium native messaging
# hosts only make sense once Chromium is actually on the machine. Without this
# gate the two installers below would run against a browser that is not there.
if omarchy-cmd-missing chromium; then
  exit 0
fi

# Fresh installs mark every migration as already applied, so a Chromium that
# was put on the machine by hand gets its native messaging hosts from here.
# Without them the bundled extensions load but have nothing to talk to.
omarchy-install-chromium-copy-url
