pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
  id: root

  property alias host: displayState.host
  property alias uptime: displayState.uptime
  property alias username: displayState.username
  property alias ram: displayState.ram
  property alias cpu: displayState.cpu
  property alias networkD: displayState.networkD
  property alias networkU: displayState.networkU
  property alias temp: displayState.temp
  property string osString: {
    const match = /^NAME=(.*)$/m.exec(osRelease.text());
    return match ? match[1].replace(/^["']|["']$/g, "") : "";
  }

  // Preserve displayed values across HMR, never rate counters/consumer ownership.
  PersistentProperties {
    id: displayState
    reloadableId: "system-statistics-display"
    property string host: ""
    property string uptime: ""
    property string username: ""
    property real ram: 0
    property real cpu: 0
    property string networkD: ""
    property string networkU: ""
    property string temp: ""
  }

  property alias idleInhibitEnabled: idleState.enabled

  PersistentProperties {
    id: idleState
    reloadableId: "system-idle-inhibit"
    property bool enabled: false
  }

  function setIdleInhibited(enabled) {
    idleState.enabled = enabled;
  }

  // Keep the inhibitor independent of menu lifetime, bar visibility and focus.
  // Its mapped transparent surface takes no input, focus or exclusive space.
  PanelWindow {
    id: idleSurface
    visible: root.idleInhibitEnabled
    screen: Quickshell.screens[0] ?? null
    anchors { top: true; left: true }
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.namespace: "hyprland-shell:idle-inhibit"
    WlrLayershell.layer: WlrLayer.Overlay
  }

  IdleInhibitor {
    window: idleSurface
    enabled: root.idleInhibitEnabled
  }

  // Globals.isFedora is a static platform dependency, not a visible consumer.
  // Native one-time file read keeps it correct without hidden subprocesses/timers.
  FileView {
    id: osRelease
    path: "/etc/os-release"
    watchChanges: false
    blockLoading: true
  }

  property var consumers: ({})
  property int consumerSequence: 0
  property bool statsWanted: false
  property bool metadataWanted: false
  readonly property bool sampleWanted: statsWanted || metadataWanted
  property int requestGeneration: 0
  property var previousSample: null
  property bool warmupAvailable: false
  property int nextDelay: 5000

  function newConsumer() {
    return "consumer-" + (++root.consumerSequence);
  }

  function itemVisible(item) {
    // Opacity is local, unlike effective item visibility; check each ancestor so
    // closed opacity-only menus do not retain demand. Reparenting/opacity reads
    // participate in the consumer's QML binding dependency tracking.
    for (let node = item; node; node = node.parent) {
      if (!node.visible || node.opacity <= 0) return false;
    }
    return true;
  }

  function setConsumer(id, kind, enabled) {
    if (!id || (kind !== "stats" && kind !== "metadata")) return;
    const oldDemand = root.sampleWanted;
    const oldStats = root.statsWanted;
    const next = Object.assign({}, root.consumers);
    if (enabled) next[id] = kind;
    else delete next[id];
    root.consumers = next;
    const kinds = Object.values(next);
    root.statsWanted = kinds.indexOf("stats") !== -1;
    root.metadataWanted = kinds.indexOf("metadata") !== -1;
    if (!root.statsWanted || !oldStats) {
      root.previousSample = null;
      root.warmupAvailable = root.statsWanted;
    }
    if (!root.sampleWanted) {
      root.requestGeneration++;
      sampleTimer.stop();
      sampleDeadline.stop();
      root.previousSample = null;
      // Only this singleton-owned one-shot sampler is cancelled, never hypridle.
      if (sampleProc.running) sampleProc.signal(9);
      return;
    }
    if (!oldDemand || oldStats !== root.statsWanted || enabled) root.requestSample();
  }

  function requestSample() {
    if (!root.sampleWanted || sampleProc.pending || sampleProc.running) return;
    sampleTimer.stop();
    sampleProc.withStats = root.statsWanted;
    sampleProc.generation = root.requestGeneration;
    sampleProc.didStart = false;
    sampleProc.pending = true;
    sampleProc.running = true;
    if (sampleProc.pending) sampleDeadline.restart();
  }

  function validCounter(value) {
    return Number.isSafeInteger(value) && value >= 0;
  }

  function validCpu(cpu) {
    return cpu && root.validCounter(cpu.total) && root.validCounter(cpu.idle)
      && cpu.idle <= cpu.total && root.validCounter(cpu.count) && cpu.count > 0;
  }

  function validNetwork(network) {
    if (!network || typeof network !== "object" || Array.isArray(network)) return false;
    return Object.values(network).every(value => value && root.validCounter(value.rx)
      && root.validCounter(value.tx) && root.validCounter(value.index) && value.index > 0);
  }

  function netSpeedToString(bytes) {
    if (bytes > 1e+06) return (Math.floor(bytes / 100000) / 10) + "M";
    if (bytes > 1000) return (Math.floor(bytes / 100) / 10) + "K";
    return Math.floor(bytes) + "B";
  }

  function applySample(text, exitCode, exitStatus, withStats) {
    if (exitCode !== 0 || exitStatus !== 0) return false;
    let value;
    try { value = JSON.parse(text); } catch (_) { return false; }
    if (!value || value.version !== 1 || !Number.isFinite(value.mono) || value.mono < 0) return false;
    for (const name of ["host", "username", "uptime"]) {
      if (typeof value[name] === "string" && value[name] !== "") root[name] = value[name];
    }
    if (!withStats || !root.statsWanted) return true;
    if (Number.isFinite(value.ram) && value.ram >= 0 && value.ram <= 100) root.ram = value.ram;
    if (Number.isFinite(value.temp) && value.temp >= -40 && value.temp <= 150) root.temp = String(Math.round(value.temp));

    const old = root.previousSample;
    const elapsed = old ? value.mono - old.mono : 0;
    // A long pause, clock regression, reload or hidden period needs a new baseline.
    const intervalValid = elapsed > 0 && elapsed <= 15;
    const cpuValid = root.validCpu(value.cpu);
    const netValid = root.validNetwork(value.network);
    let needBaseline = false;
    if (cpuValid && intervalValid && root.validCpu(old.cpu) && old.cpu.count === value.cpu.count) {
      const total = value.cpu.total - old.cpu.total;
      const idle = value.cpu.idle - old.cpu.idle;
      if (total > 0 && idle >= 0 && idle <= total) root.cpu = Math.round(100 * (total - idle) / total);
      else needBaseline = true;
    } else if (cpuValid) needBaseline = true;
    if (netValid && intervalValid && root.validNetwork(old.network)) {
      const names = Object.keys(value.network);
      const oldNames = Object.keys(old.network);
      if (names.length === oldNames.length && names.every(name => oldNames.indexOf(name) !== -1
          && value.network[name].index === old.network[name].index
          && value.network[name].rx >= old.network[name].rx && value.network[name].tx >= old.network[name].tx)) {
        const down = names.reduce((sum, name) => sum + value.network[name].rx - old.network[name].rx, 0) / elapsed;
        const up = names.reduce((sum, name) => sum + value.network[name].tx - old.network[name].tx, 0) / elapsed;
        root.networkD = root.netSpeedToString(down);
        root.networkU = root.netSpeedToString(up);
      } else needBaseline = true;
    } else if (netValid) needBaseline = true;
    root.previousSample = { mono: value.mono, cpu: cpuValid ? value.cpu : null, network: netValid ? value.network : null };
    // One cold baseline-followup supplies genuine short-interval rates, not a boot
    // average. Steady visible cadence remains 5s; failed reads never tight-loop.
    root.nextDelay = needBaseline && root.warmupAvailable ? 250 : 5000;
    if (needBaseline) root.warmupAvailable = false;
    return true;
  }

  function finishSample(text, exitCode, exitStatus, generation, withStats) {
    sampleDeadline.stop();
    if (!root.sampleWanted || generation !== root.requestGeneration) {
      if (root.sampleWanted) root.requestSample();
      return;
    }
    root.nextDelay = root.statsWanted ? 5000 : 60000;
    root.applySample(text, exitCode, exitStatus, withStats);
    if (withStats !== root.statsWanted) root.requestSample();
    else sampleTimer.restart();
  }

  Process {
    id: sampleProc
    property bool pending: false
    property bool didStart: false
    property bool withStats: false
    property int generation: 0
    running: false
    command: ["/usr/bin/python3", (StandardPaths.writableLocation(StandardPaths.HomeLocation)
      + "/.local/bin/desktop-stats-sample").replace("file://", "")].concat(withStats ? [] : ["--metadata-only"])
    stdout: StdioCollector { id: sampleOutput }
    onStarted: {
      didStart = true;
      // Covers final release/reopen while QProcess was still starting (no PID).
      if (!root.sampleWanted || generation !== root.requestGeneration) sampleProc.signal(9);
    }
    onExited: (exitCode, exitStatus) => {
      pending = false;
      root.finishSample(sampleOutput.text, exitCode, exitStatus, generation, withStats);
    }
    onRunningChanged: {
      if (!running && pending && !didStart) {
        pending = false;
        root.finishSample("", -1, 1, generation, withStats);
      }
    }
  }

  Timer {
    id: sampleTimer
    interval: root.nextDelay
    running: false
    repeat: false
    onTriggered: root.requestSample()
  }

  Timer {
    id: sampleDeadline
    interval: 1500
    running: false
    repeat: false
    onTriggered: {
      if (sampleProc.running) sampleProc.signal(9);
    }
  }
}
