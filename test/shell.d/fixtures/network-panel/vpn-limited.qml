import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.Commons
import qs.Commons as Commons
import "mocks"
import "network" as Network

// Drives the VPN check: Wi-Fi limited with a VPN device at full connectivity
// reads as full, then the VPN device goes away, nmcli monitor prints a line, and
// the panel reads limited again without a poll. The runner stubs nmcli.
ShellRoot {
  id: test
  property bool failed: false
  function check(ok, message) {
    if (!ok) {
      failed = true
      console.log("RESULT fail " + message)
    }
  }

  Item {
    Network.Panel {
      id: panel
      bar: QtObject {
        property color foreground: Commons.Color.foreground
        property color barForeground: Commons.Color.foreground
        property color urgent: Commons.Color.urgent
        property string fontFamily: Style.font.family
        property string position: "top"
        property int barSize: 24
        property bool vertical: false
        property bool foregroundAnimationEnabled: false
        property var activePopout: null
        function requestPopout(owner) { activePopout = owner }
        function releasePopout(owner) { activePopout = null }
        function registerClickTarget(target) {}
        function unregisterClickTarget(target) {}
        function hideTooltip(target) {}
        function showTooltip(target, text) {}
      }
    }
  }

  Process {
    id: dropVpn
    command: ["sh", "-c", "printf 'GENERAL.TYPE:wifi\\nGENERAL.IP4-CONNECTIVITY:3 (limited)\\n' >\"$NETWORK_TEST_DEVICES\"; : >\"$NETWORK_TEST_EVENT\""]
  }

  Component.onCompleted: NetworkMock.connectivity = NetworkConnectivity.Limited

  Timer {
    interval: 1500
    running: true
    onTriggered: {
      test.check(panel.reportedConnectivity === "limited", "the device reports limited")
      test.check(panel.vpnHasInternet, "the check finds the VPN device")
      test.check(panel.connectivity === "full" && !panel.restricted, "a VPN device with the internet reads as full")
      spent.start()
    }
  }

  // Only once the checks from startup are spent can a re-check come from nothing
  // but the line from nmcli monitor.
  Timer {
    id: spent
    interval: 15000
    onTriggered: {
      test.check(panel.vpnChecksLeft === 0, "the checks stop when nothing changes")
      dropVpn.running = true
      afterDrop.start()
    }
  }

  Timer {
    id: afterDrop
    interval: 1500
    onTriggered: {
      test.check(!panel.vpnHasInternet, "a line from nmcli monitor re-checks the devices")
      test.check(panel.connectivity === "limited" && panel.restricted, "limited returns when the VPN device goes")
      console.log(test.failed ? "RESULT fail" : "RESULT pass")
      Qt.quit()
    }
  }
}
