pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as C

Singleton {
  id: root

  property bool updatesAvailable: false
  property bool lastUpdateCheckFailed: false
  property string lastUpdateCheckFailedReason: ""
  property bool updateRunning: false
  property string version: "v0.49.0"
  property int versionInt: 0
  property bool versionMismatch: false
  property bool versionMismatchOpen: false

  function init() {}

  function refreshVersion() {
    if (versionProc.running)
      return;
    versionProc.pending = true;
    versionProc.didStart = false;
    versionProc.running = true;
  }

  function applyVersion(output, exitCode, exitStatus) {
    const match = output.match(/\bTag:\s*(v?\d+\.\d+\.\d+)\b/);
    if (exitCode !== 0 || exitStatus !== 0 || !match) {
      console.warn("Compositor version query failed; keeping the previous version.");
      return false;
    }
    const parsedVersion = match[1];
    const parsedInt = parseInt(parsedVersion.replace(/[^0-9]/g, ""), 10);
    if (!Number.isFinite(parsedInt))
      return false;

    root.version = parsedVersion;
    root.versionInt = parsedInt;
    if (C.Config.misc.lastHyprlandVersion == 0)
      C.Config.misc.lastHyprlandVersion = parsedInt;
    root.versionMismatch = C.Config.misc.lastHyprlandVersion != parsedInt;
    root.versionMismatchOpen = root.versionMismatch;
    C.Config.misc.lastHyprlandVersion = parsedInt;
    // Metadata queries/reloads must not rotate auth tokens. Hourly/manual checks remain.
    return true;
  }

  function markCheckFailed(reason) {
    root.lastUpdateCheckFailed = true;
    root.lastUpdateCheckFailedReason = reason;
    return false;
  }

  function applyUpdateCheck(output, exitCode, exitStatus) {
    C.Config.misc.lastUpdateCheck = Date.now() / 1000;
    if (exitCode !== 0 || exitStatus !== 0)
      return root.markCheckFailed("Update check process failed.");
    try {
      const json = JSON.parse(output);
      if (!json || (json.success !== true && json.success !== false))
        throw new Error("Missing success status");
      if (!json.success)
        return root.markCheckFailed(typeof json.message === "string" ? json.message : "Update check reported failure.");
      if (typeof json.epoch_seconds !== "number" || !Number.isFinite(json.epoch_seconds) || json.epoch_seconds < 0)
        throw new Error("Invalid update epoch");

      root.lastUpdateCheckFailed = false;
      root.lastUpdateCheckFailedReason = "Unknown";
      if (C.Config.misc.lastUpdateEpoch == 0)
        C.Config.misc.lastUpdateEpoch = json.epoch_seconds;
      root.updatesAvailable = C.Config.misc.lastUpdateEpoch < json.epoch_seconds - 10;
      return true;
    } catch (error) {
      return root.markCheckFailed("Invalid or incomplete update response.");
    }
  }

  function checkForUpdates() {
    if (checkUpdateProc.running)
      return;
    if (root.versionInt === 0) {
      root.markCheckFailed("Compositor version is not ready.");
      return;
    }
    checkUpdateProc.pending = true;
    checkUpdateProc.didStart = false;
    checkUpdateProc.running = true;
  }

  function relog() {
    relogProc.running = true;
  }

  function update() {
    if (root.updateRunning)
      return;
    root.updateRunning = true;
    Quickshell.execDetached(["kitty", "bash", "-c", (C.Config.misc.betaChannel ? "HLDE_BETA=1 " : "") + "HLA_CHANNEL=\"" + (C.Config.misc.betaChannel ? "beta" : "release") + "\" HLA_VERSION=\"" + root.version + "\" " + "$HOME/.config/hyprland-de/scripts/update.sh ; echo \"Update finished. Press enter to close this window.\" ; read"]);
    Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.global("hyprland-shell:rightMenuToggle")']);
  }

  function setUpdated(epoch) {
    C.Config.misc.lastUpdateEpoch = epoch;
    root.updateRunning = false;
    root.refreshVersion();
  }

  Timer {
    running: C.Config.misc.autoUpdateCheck
    repeat: true
    interval: 60000 * 60 // 1 hr
    onTriggered: if (root.versionInt != 0) root.checkForUpdates()
  }

  Process {
    id: relogProc
    running: false
    command: ["bash", "-c", "kitty \"$HOME/.config/hyprland-de/scripts/relog.sh\""]
  }

  Process {
    id: versionProc
    property bool pending: true
    property bool didStart: false
    running: true
    command: ["hyprctl", "version"]
    stdout: StdioCollector { id: versionOutput }
    onStarted: didStart = true
    onExited: (exitCode, exitStatus) => {
      pending = false;
      root.applyVersion(versionOutput.text, exitCode, exitStatus);
    }
    onRunningChanged: {
      if (!running && pending && !didStart) {
        pending = false;
        root.applyVersion("", -1, 1);
      }
    }
  }

  Process {
    id: checkUpdateProc
    property bool pending: false
    property bool didStart: false
    running: false
    command: ["bash", "-c", "HLA_CHANNEL=\"" + (C.Config.misc.betaChannel ? "beta" : "release") + "\" HLA_VERSION=\"" + root.version + "\" $HOME/.config/hyprland-de/scripts/checkUpdates.sh"]
    stdout: StdioCollector { id: checkOutput }
    onStarted: didStart = true
    onExited: (exitCode, exitStatus) => {
      pending = false;
      root.applyUpdateCheck(checkOutput.text, exitCode, exitStatus);
    }
    onRunningChanged: {
      if (!running && pending && !didStart) {
        pending = false;
        root.applyUpdateCheck("", -1, 1);
      }
    }
  }
}
