#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

packages="$ROOT/install/omarchy-base.packages"

# Only discovery goes. Everything else printing needs stays, or this stops
# being a removal of one daemon and becomes a removal of printing.
grep -qxF cups "$packages" || fail "CUPS itself remains in the base package set"
grep -qxF cups-filters "$packages" || fail "the CUPS filters remain in the base package set"
grep -qxF system-config-printer "$packages" || fail "Print Settings remains in the base package set"
grep -qxF cups-pk-helper "$packages" || fail "Polkit printer administration is installed"
! grep -qxF cups-pdf "$packages" || fail "the root CUPS-PDF backend is removed"

# Automatic discovery is out of the default install.
! grep -qxF cups-browsed "$packages" || fail "automatic printer discovery is out of the base package set"
! grep -q 'cups-browsed' "$ROOT/install/config/enable-services.sh" ||
  fail "a fresh install does not enable a discovery service it no longer installs"

pass "the base install keeps CUPS and Polkit administration, without automatic discovery"

# Omarchy's CUPS hardening (etc/cups/, the cups-browsed sysusers entry and
# service drop-in, install/post-install/pacman.sh and migration 1787815267)
# is not part of the port: the port keeps Ubuntu's CUPS configuration
# (docs/6 - omarchy-port.md, "What the port changed").
for path in etc/cups/cups-files.conf etc/cups/cups-browsed.conf \
  etc/sysusers.d/omarchy-cups-browsed.conf \
  etc/systemd/system/cups-browsed.service.d/10-omarchy.conf; do
  [[ ! -e $ROOT/$path ]] || fail "Ubuntu's CUPS configuration is kept: $path is not shipped"
done

pass "the port ships no CUPS configuration of its own"
