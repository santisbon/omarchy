#!/bin/bash

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const network = requireFromRoot('shell/plugins/panels/network/Model.js')
const states = { Unknown: 0, None: 1, Portal: 2, Limited: 3, Full: 4 }

for (const kind of ['wifi', 'ethernet']) {
  for (const [native, expected] of [
    ['Unknown', 'unknown'], ['None', 'none'], ['Portal', 'portal'],
    ['Limited', 'limited'], ['Full', 'full']
  ]) {
    assertEqual(network.connectivityState(kind, states[native], states, true), expected,
      `${kind} maps native ${native} connectivity without confusing an outage with a portal`)
  }
  assertEqual(network.connectivityState(kind, 99, states, true), 'unknown', `${kind} handles unknown connectivity`)
  for (const native of Object.values(states)) {
    assertEqual(network.connectivityState(kind, native, states, false), 'unknown', `${kind} ignores stale results with probing disabled (${native})`)
  }
}
for (const native of Object.values(states)) {
  assertEqual(network.connectivityState('disconnected', native, states, true), 'none', `disconnect clears stale connectivity (${native})`)
}
for (const state of ['portal', 'limited']) {
  assertEqual(network.connectionIcon('wifi', 80, state), '󰤩', `${state} uses a blocked Wi-Fi icon`)
  assertEqual(network.connectionIcon('ethernet', 80, state), '󰈂', `${state} uses a blocked Ethernet icon`)
  assertEqual(network.connectionIcon('disconnected', 80, state), '󰤮', `${state} does not override the disconnected icon`)
}
for (const state of ['full', 'unknown', 'none', undefined]) {
  for (const signal of [-1, 0, 20, 40, 60, 80, 100]) {
    assertEqual(network.connectionIcon('wifi', signal, state), network.wifiIconFor(signal), `${state} preserves Wi-Fi strength ${signal}`)
  }
  assertEqual(network.connectionIcon('ethernet', -1, state), '󰈀', `${state} preserves the Ethernet icon`)
}
const tunnelFull = 'GENERAL.TYPE:wifi\nGENERAL.IP4-CONNECTIVITY:3 (limited)\nGENERAL.TYPE:wireguard\nGENERAL.IP4-CONNECTIVITY:4 (full)\n'
assertEqual(network.vpnHasInternet(tunnelFull), true, 'a tunnel with full connectivity answers for a VPN that blocks the Wi-Fi check')
assertEqual(network.vpnHasInternet('GENERAL.TYPE:wifi\nGENERAL.IP4-CONNECTIVITY:4 (full)\n'), false, 'a Wi-Fi device is not a VPN')
assertEqual(network.vpnHasInternet('GENERAL.TYPE:wireguard\nGENERAL.IP4-CONNECTIVITY:3 (limited)\n'), false, 'a tunnel that is itself limited does not hide the warning')
assertEqual(network.vpnHasInternet(''), false, 'no nmcli output hides nothing')
const url = new URL(network.captivePortalUrl)
assertEqual(url.protocol, 'http:', 'browser entry point uses plain HTTP so a portal can intercept it')
assertEqual(url.hostname, 'connectivity-check.ubuntu.com', 'browser entry point is fixed rather than portal-supplied')
assertEqual(url.username + url.password, '', 'browser entry point contains no credentials')
JS

# NetworkManager's probe is Ubuntu's own default: the port ships no connectivity drop-in.
[[ ! -e $ROOT/etc/NetworkManager/conf.d/omarchy-connectivity.conf ]] || fail "the port ships no NetworkManager connectivity drop-in"
pass "the port ships no NetworkManager connectivity drop-in"
