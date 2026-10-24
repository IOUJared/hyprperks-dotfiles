pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as C

Singleton {
  id: root

  property real nightLightKelvin: 6000
  property bool needUpdate: true

  function setIntensity(perc) {
    const low_k = 2500;
    const high_k = 6500;

    let inverse_x = (100 - perc) / 100.0;

    const kelv = (high_k - low_k) * inverse_x + low_k;

    nightLightKelvin = kelv;
    needUpdate = true;
    updateTimer.running = true;
  }

  function buildProfileConfig() {
    let content = "# PART OF HYPRLAND-DE, DO NOT EDIT, USE THE BAR\n";
    const profiles = C.Config.misc.nightLightProfiles;
    for (let i = 0; i < profiles.length; i++) {
      const p = profiles[i];
      content += "\nprofile {\n";
      content += "    time = " + p.time + "\n";
      if (p.temperature === -1)
        content += "    identity = true\n";
      else
        content += "    temperature = " + p.temperature + "\n";
      content += "}\n";
    }
    needUpdate = true;
    hyprsunsetConfigProc.command = ["bash", "-c", "cat > ~/.config/hypr/hyprsunset.conf << '__hyprde' " + content + "__hyprde"];
    hyprsunsetConfigProc.running = true;
    updateTimer.running = true;
    return content;
  }

  function reloadHyprsunset() {
    needUpdate = true;
    updateTimer.running = true;
  }

  Process {
    id: configWriteProc
    running: false
    onExited: {
      hyprsunsetReloadProc.running = true;
    }
  }

  Process {
    id: hyprsunsetProc
    running: true
    command: ["hyprsunset", "-i"]
  }

  Process {
    id: hyprsunsetConfigProc
    running: true
    command: ["bash", "-c", "cat << '__hyprde' " + content + "__hyprde"]
  }

  Process {
    id: hyprctlUpdateProc
    running: false
  }

  Timer {
    id: updateTimer
    interval: 100
    repeat: true
    running: false

    onTriggered: () => {
      if (!needUpdate)
        return;

      needUpdate = false;

      if (!C.Config.misc.nightLightEnabled) {
        hyprctlUpdateProc.command = ["hyprctl", "hyprsunset", "identity"];
        hyprctlUpdateProc.running = true;

        hyprctlUpdateProc.running = true;
        updateTimer.running = false;
        return;
      }

      if (C.Config.misc.nightLightUseProfiles && C.Config.misc.nightLightEnabled) {
        hyprsunsetProc.running = false;
        hyprsunsetProc.command = ["hyprsunset"];
        hyprsunsetProc.running = true;
        return;
      }

      hyprsunsetProc.command = ["hyprsunset", "-i"];

      if (nightLightKelvin < 2500)
        nightLightKelvin = 2500;
      if (nightLightKelvin > 4000)
        nightLightKelvin = 4000;

      hyprctlUpdateProc.command = ["hyprctl", "hyprsunset", "temperature", "" + nightLightKelvin];
      hyprctlUpdateProc.running = true;

      updateTimer.running = false;
    }
  }
}
