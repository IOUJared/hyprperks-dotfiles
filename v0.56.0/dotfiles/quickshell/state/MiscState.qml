pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../config" as C

Singleton {
  id: root

  property bool shortcutsOpen: false
  property bool shortcutsOpenGrab: false
  property bool settingsOpen: false
  property bool settingsOpenGrab: false
  property string keyboardLayout: ""

  property bool trayInBar: C.Config.settings.bar.moduleCenter.indexOf("tray") != -1 || C.Config.settings.bar.modulesLeft.indexOf("tray") != -1 || C.Config.settings.bar.modulesRight.indexOf("tray") != -1

  function applyDevices(output, exitCode, exitStatus) {
    if (exitCode !== 0 || exitStatus !== 0) {
      console.warn("Keyboard device query failed; keeping the previous layout.");
      return false;
    }
    try {
      const devices = JSON.parse(output);
      if (!devices || !Array.isArray(devices.keyboards))
        throw new Error("Missing keyboard list");
      if (devices.keyboards.length === 0)
        return true;
      const layout = devices.keyboards[0]?.active_keymap;
      if (typeof layout !== "string")
        throw new Error("Missing active keymap");
      root.keyboardLayout = layout;
      return true;
    } catch (error) {
      console.warn("Invalid keyboard device response; keeping the previous layout.");
      return false;
    }
  }

  function refreshDevices() {
    if (devicesProc.running)
      return;
    devicesProc.pending = true;
    devicesProc.didStart = false;
    devicesProc.running = true;
  }

  Process {
    id: devicesProc
    property bool pending: true
    property bool didStart: false
    running: true
    command: ["hyprctl", "-j", "devices"]

    stdout: StdioCollector { id: devicesOutput }
    onStarted: didStart = true
    // 0.3.1 flushes collectors before emitting exited, so text is complete here.
    onExited: (exitCode, exitStatus) => {
      pending = false;
      root.applyDevices(devicesOutput.text, exitCode, exitStatus);
    }
    onRunningChanged: {
      if (!running && pending && !didStart) {
        pending = false;
        root.applyDevices("", -1, 1);
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activelayout") {
        const data = event.data.split(",");
        if (data.length <= 1 || data[0].indexOf("hl-virtual-") == 0)
          return;
        root.keyboardLayout = data[1];
      } else if (event.name == "configreloaded")
        root.refreshDevices();
    }
  }
}
