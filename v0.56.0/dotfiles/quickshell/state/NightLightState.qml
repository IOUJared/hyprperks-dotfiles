pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as C

Singleton {
  id: root

  // Keep the full slider range, including the persisted value on first load.
  property real nightLightKelvin: kelvinForIntensity(C.Config.misc.nightLightIntense)
  property bool needUpdate: false
  property string activeMode: ""
  property int appliedKelvin: 0
  property bool stoppingDaemon: false
  property bool restartDaemon: false
  property bool writingConfig: false
  property bool configLoaded: false
  property string savedConfig: ""
  property string pendingConfig: ""

  function kelvinForIntensity(perc) {
    const value = Number(perc);
    const intensity = Number.isFinite(value) ? Math.max(0, Math.min(100, value)) : 50;
    return Math.round(6500 - 40 * intensity);
  }

  function setIntensity(perc) {
    nightLightKelvin = kelvinForIntensity(perc);
    requestUpdate();
  }

  function profileConfig() {
    let content = "# PART OF HYPRLAND-DE, DO NOT EDIT, USE THE BAR\n";
    const profiles = C.Config.misc.nightLightProfiles;
    if (!Array.isArray(profiles)) {
      console.warn("Night light: invalid profile list; config left unchanged");
      return null;
    }
    for (let i = 0; i < profiles.length; i++) {
      const p = profiles[i];
      // Validate before generating Hyprlang, not just shell-escape it.
      if (!p || !/^(?:[01]?\d|2[0-3]):[0-5]\d$/.test(String(p.time))
          || !Number.isInteger(p.temperature)
          || (p.temperature !== -1 && (p.temperature < 1000 || p.temperature > 20000))) {
        console.warn("Night light: invalid profile " + i + "; config left unchanged");
        return null;
      }
      content += "\nprofile {\n    time = " + p.time + "\n";
      content += p.temperature === -1 ? "    identity = true\n"
                                     : "    temperature = " + p.temperature + "\n";
      content += "}\n";
    }
    return content;
  }

  function buildProfileConfig() {
    const content = profileConfig();
    if (content !== null)
      requestUpdate();
    return content;
  }

  function requestUpdate() {
    needUpdate = true;
    updateTimer.restart();
  }

  function reloadHyprsunset() {
    // Reading here also restores intensity if the JSON adapter loaded late.
    nightLightKelvin = kelvinForIntensity(C.Config.misc.nightLightIntense);
    requestUpdate();
  }

  function update() {
    if (!needUpdate || writingConfig || stoppingDaemon || hyprctlUpdateProc.running)
      return;

    const mode = !C.Config.misc.nightLightEnabled ? "disabled"
                 : C.Config.misc.nightLightUseProfiles ? "profiles" : "manual";
    // -i and IPC temperature do not disable hyprsunset's profile scheduler.
    // Never load scheduled profiles into the disabled/manual daemon.
    const content = mode === "profiles" ? profileConfig() : "";
    if (content === null) {
      needUpdate = false;
      return;
    }

    if (!configLoaded) {
      savedConfig = hyprsunsetConfig.text();
      configLoaded = true;
    }
    if (content !== savedConfig) {
      pendingConfig = content;
      writingConfig = true;
      hyprsunsetConfig.setText(content);
      return; // Only saved() may permit a restart with the new config.
    }

    if (hyprsunsetProc.running
        && (restartDaemon || (activeMode === "profiles") !== (mode === "profiles"))) {
      stoppingDaemon = true;
      hyprsunsetProc.running = false;
      return; // Wait for exited(), not merely running=false (SIGTERM).
    }

    const kelvin = Math.round(Math.max(2500, Math.min(6500, nightLightKelvin)));
    if (!hyprsunsetProc.running) {
      restartDaemon = false;
      activeMode = mode;
      appliedKelvin = mode === "manual" ? kelvin : 0;
      hyprsunsetProc.command = mode === "profiles" ? ["hyprsunset"]
                               : mode === "manual" ? ["hyprsunset", "-t", String(kelvin)]
                               : ["hyprsunset", "-i"];
      needUpdate = false;
      hyprsunsetProc.running = true;
      return;
    }

    needUpdate = false;
    if (mode === "profiles" || (mode === activeMode && (mode === "disabled" || appliedKelvin === kelvin)))
      return;

    hyprctlUpdateProc.command = mode === "disabled" ? ["hyprctl", "hyprsunset", "identity"]
                               : ["hyprctl", "hyprsunset", "temperature", String(kelvin)];
    hyprctlUpdateProc.targetMode = mode;
    hyprctlUpdateProc.targetKelvin = kelvin;
    hyprctlUpdateProc.running = true;
  }

  FileView {
    id: hyprsunsetConfig
    path: Quickshell.env("HOME") + "/.config/hypr/hyprsunset.conf"
    preload: false
    blockLoading: true
    atomicWrites: true
    onSaved: {
      root.savedConfig = root.pendingConfig;
      root.writingConfig = false;
      root.restartDaemon = hyprsunsetProc.running;
      root.requestUpdate();
    }
    onSaveFailed: error => {
      root.writingConfig = false;
      root.needUpdate = false;
      console.warn("Night light: config write failed (" + error + "); daemon left unchanged");
    }
  }

  Process {
    id: hyprsunsetProc
    running: false
    onExited: (exitCode, exitStatus) => {
      root.activeMode = "";
      if (root.stoppingDaemon) {
        root.stoppingDaemon = false;
        root.requestUpdate();
      } else {
        console.warn("Night light: daemon exited (" + exitCode + ", " + exitStatus + ")");
      }
    }
  }

  Process {
    id: hyprctlUpdateProc
    property string targetMode: ""
    property int targetKelvin: 0
    stdout: StdioCollector { id: ipcOutput }
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && exitStatus === 0 && ipcOutput.text.trim() === "ok") {
        root.activeMode = targetMode;
        root.appliedKelvin = targetMode === "manual" ? targetKelvin : 0;
      } else {
        console.warn("Night light: IPC update failed: " + ipcOutput.text.trim());
      }
      if (root.needUpdate)
        updateTimer.restart();
    }
  }

  Timer {
    id: updateTimer
    interval: 100
    repeat: false
    onTriggered: root.update()
  }
}
