pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../config" as C

Singleton {
  id: root
  property list<string> monitors: Quickshell.screens.map(x => x.name)
  property list<real> monitorsDdcBuses: []
  property list<real> brightnesses: []
  property list<bool> needUpdate: []
  property bool hasBacklight: false
  property bool backlightNeedUpdate: false
  property real backlightBrightness: -1
  property string backlightDevice: ""
  property string backlightConnector: ""
  property int backlightMonitorIndex: backlightConnector == "" ? -1 : monitors.indexOf(backlightConnector)
  property real overallBrightness: 50
  property bool anyControls: monitorsDdcBuses.some(x => validBus(x)) || hasBacklight

  // One finite read queue. No polling, mutable in-flight monitor index or parallel reads.
  property bool readsReady: false
  property int readGeneration: 0
  property var valueVersions: ({})
  property var knownMonitors: []
  property var knownBuses: ({})
  property var readQueue: []

  function load() {
  // Dummy func to force init lazy singleton
  }

  readonly property list<string> brightnessIcons: ["brightness_3", "brightness_4", "brightness_6", "brightness_7"]

  function iconFor(level) {
    const n = brightnessIcons.length;
    return brightnessIcons[Math.max(0, Math.min(n - 1, Math.ceil(level * n) - 1))];
  }

  function brightnessOf(name) {
    const i = monitors.indexOf(name);
    if (i < 0)
      return -1;
    if (hasBacklight && i == backlightMonitorIndex)
      return backlightBrightness;
    return brightnesses[i];
  }

  function validLevel(value) {
    return typeof value == "number" && Number.isFinite(value) && value >= 0 && value <= 100;
  }

  function validBus(value) {
    return Number.isInteger(value) && value >= 0 && value <= 65535;
  }

  function controlKey(kind, name, connector) {
    return JSON.stringify([kind, name, connector || ""]);
  }

  function controlVersion(key) {
    return valueVersions[key] || 0;
  }

  function bumpControlVersion(key) {
    const versions = Object.assign({}, valueVersions);
    versions[key] = controlVersion(key) + 1;
    valueVersions = versions;
  }

  function deviceName(value) {
    return /^[A-Za-z0-9_.:-]{1,128}$/.test(value);
  }

  function parseVcp(text) {
    const match = /^VCP\s+10\s+C\s+(\d+)\s+(\d+)\s*$/.exec(text.trim());
    if (!match)
      return null;
    const value = Number(match[1]), maximum = Number(match[2]);
    return validLevel(value) && Number.isInteger(maximum) && maximum > 0 && maximum <= 65535 && value <= maximum ? value : null;
  }

  function parseBacklight(text, device) {
    const fields = text.trim().split(",");
    if (fields.length != 5 || fields[0] != device || fields[1] != "backlight" || !/^\d+$/.test(fields[2]) || !/^\d+$/.test(fields[4]) || !/^\d+%$/.test(fields[3]))
      return null;
    const current = Number(fields[2]), maximum = Number(fields[4]);
    const percent = Number(fields[3].slice(0, -1));
    if (!Number.isSafeInteger(current) || !Number.isSafeInteger(maximum) || maximum <= 0 || current > maximum || !validLevel(percent))
      return null;
    const value = current * 100 / maximum;
    return validLevel(value) ? value : null;
  }

  function parseKernelBacklight(text) {
    if (text.trim() == "")
      return { device: "", connector: "" };
    const fields = text.trim().split(/\s+/);
    if (fields.length != 2 || !deviceName(fields[0]) || !/^card\d+-[A-Za-z0-9_.:-]+$/.test(fields[1]))
      return null;
    return { device: fields[0], connector: fields[1].replace(/^card\d+-/, "") };
  }

  function parseBacklightList(text) {
    if (text.trim() == "")
      return { device: "", connector: "" };
    const rows = text.trim().split(/\r?\n/);
    for (const row of rows) {
      const fields = row.split(",");
      if (fields.length != 5 || !deviceName(fields[0]) || !/^(backlight|leds)$/.test(fields[1]))
        return null;
      if (fields[1] == "backlight") {
        if (parseBacklight(row, fields[0]) === null)
          return null;
        return { device: fields[0], connector: "" };
      }
    }
    return { device: "", connector: "" };
  }

  function parseDetection(text, names) {
    // Bound parser input; never log EDID/serial fields. Empty output is valid absence.
    if (text.length > 65536)
      return null;
    const result = names.map(() => -1);
    if (text.trim() == "")
      return result;
    const blocks = text.split(/(?:^|\n)(?=(?:Display\s+\d+|Invalid display)\b)/);
    let records = 0;
    for (const block of blocks) {
      if (/^\s*Invalid display\b/.test(block)) {
        ++records;
        continue;
      }
      if (!/^\s*Display\s+\d+\b/.test(block)) {
        // Normal diagnostic preamble is allowed, never interpreted as a display.
        if (/DRM connector:|I2C bus:/.test(block))
          return null;
        continue;
      }
      ++records;
      const connector = /(?:^|\n)\s*DRM connector:\s*card\d+-([^\s]+)\s*(?:\n|$)/.exec(block);
      const bus = /(?:^|\n)\s*I2C bus:\s*\/dev\/i2c-(\d+)\s*(?:\n|$)/.exec(block);
      if (!connector || !bus || !validBus(Number(bus[1])))
        return null;
      const index = names.indexOf(connector[1]);
      if (index >= 0) {
        if (result[index] != -1 && result[index] != Number(bus[1]))
          return null;
        result[index] = Number(bus[1]);
      }
    }
    return records > 0 ? result : null;
  }

  function scheduleRead() {
    if (readsReady && readQueue.length > 0 && !readProc.request && !readProc.running)
      readNextTimer.restart();
  }

  function queueRead(job) {
    job.generation = readGeneration;
    readQueue = readQueue.concat([job]);
    scheduleRead();
  }

  function cancelOwnedRead() {
    if (!readProc.request)
      return;
    readProc.cancelled = true;
    // Process.signal has no internal PID-zero guard; never signal a starting process.
    if (readProc.running && Number(readProc.processId) > 0)
      readProc.signal(9);
    // If still starting, onStarted kills this owned child; wait for its actual exit.
  }

  function resetTopology() {
    if (!readsReady)
      return;
    const oldNames = knownMonitors.slice(), oldValues = brightnesses.slice();
    ++readGeneration;
    valueVersions = ({});
    readNextTimer.stop();
    readQueue = [];
    cancelOwnedRead();
    brightnesses = monitors.map(name => {
      const i = oldNames.indexOf(name);
      return i >= 0 && validLevel(oldValues[i]) ? oldValues[i] : -1;
    });
    knownMonitors = monitors.slice();
    monitorsDdcBuses = monitors.map(() => -1);
    needUpdate = monitors.map(() => false);
    backlightNeedUpdate = false;
    if (backlightConnector != "" && monitors.indexOf(backlightConnector) < 0)
      hasBacklight = false;
    queueRead({ kind: "detect", names: monitors.slice(), command: ["ddcutil", "detect", "--brief"], timeout: 30000 });
    queueRead({ kind: "kernel", command: ["sh", "-c", `
      for d in /sys/class/backlight/*; do
        [ -e "$d" ] || continue
        c=$(readlink -f "$d/device") || continue
        case "$c" in
          */card*-*) printf '%s %s\\n' "$(basename "$d")" "$(basename "$c")"; exit 0 ;;
        esac
      done
    `], timeout: 4000 });
  }

  function startNextRead() {
    if (readProc.request || readProc.running || ddcUpdateProc.running || backlightUpdateProc.running || updateTimer.running)
      return;
    let queue = readQueue.slice(), job = null;
    while (queue.length > 0) {
      const candidate = queue.shift();
      if (candidate.generation == readGeneration) {
        job = candidate;
        break;
      }
    }
    readQueue = queue;
    if (!job)
      return;
    job.valueKey = job.kind == "vcp" ? controlKey("vcp", job.name, "") : job.kind == "backlight" ? controlKey("backlight", job.device, job.connector) : "";
    job.valueVersion = controlVersion(job.valueKey);
    readProc.request = job;
    readProc.didStart = false;
    readProc.cancelled = false;
    readProc.outputSeen = false;
    readProc.completedOutput = "";
    readProc.command = job.command;
    readDeadline.interval = job.timeout;
    readDeadline.restart();
    readProc.running = true;
  }

  function discoverBacklight(info) {
    if (info === null)
      return;
    const changed = backlightDevice != info.device || backlightConnector != info.connector;
    if (changed) {
      bumpControlVersion(controlKey("backlight", backlightDevice, backlightConnector));
      backlightNeedUpdate = false;
      if (info.device != "")
        backlightBrightness = -1; // A different device is unknown, not a transient failure.
    }
    backlightDevice = info.device;
    backlightConnector = info.connector;
    hasBacklight = info.device != "";
    if (hasBacklight)
      queueRead({ kind: "backlight", device: info.device, connector: info.connector, command: ["brightnessctl", "-d", info.device, "-m"], timeout: 4000 });
  }

  function acceptRead(job, text) {
    if (job.generation != readGeneration || text.length > 65536)
      return;
    if (job.kind == "detect") {
      const buses = parseDetection(text, job.names);
      if (buses === null)
        return;
      const values = brightnesses.slice(), identities = {};
      for (let i = 0; i < job.names.length; ++i) {
        const name = job.names[i];
        if (!validBus(buses[i]) || (knownBuses[name] !== undefined && knownBuses[name] != buses[i])) {
          values[i] = -1; // Confirmed absence/new identity, not a transient read error.
          needUpdate[i] = false;
          bumpControlVersion(controlKey("vcp", name, ""));
        }
        identities[name] = buses[i];
      }
      knownBuses = identities;
      brightnesses = values;
      monitorsDdcBuses = buses;
      gatherBegin();
    } else if (job.kind == "kernel") {
      const info = parseKernelBacklight(text);
      if (info === null)
        return;
      if (info.device == "")
        queueRead({ kind: "backlight-list", command: ["brightnessctl", "-lm"], timeout: 4000 });
      else
        discoverBacklight(info);
    } else if (job.kind == "backlight-list") {
      discoverBacklight(parseBacklightList(text));
    } else if (job.kind == "vcp") {
      const index = monitors.indexOf(job.name), value = parseVcp(text);
      if (index >= 0 && monitorsDdcBuses[index] == job.bus && value !== null && job.valueVersion == controlVersion(job.valueKey) && !needUpdate[index]) {
        const values = brightnesses.slice();
        values[index] = value;
        brightnesses = values;
        overallBrightness = value;
      }
    } else if (job.kind == "backlight") {
      const value = parseBacklight(text, job.device);
      if (hasBacklight && job.device == backlightDevice && job.connector == backlightConnector && value !== null && job.valueVersion == controlVersion(job.valueKey) && !backlightNeedUpdate)
        backlightBrightness = value;
    }
  }

  function finishRead(text, exitCode, exitStatus) {
    const job = readProc.request;
    if (!job)
      return;
    readDeadline.stop();
    if (!readProc.cancelled && exitCode == 0 && exitStatus == 0)
      acceptRead(job, text);
    readProc.request = null;
    readProc.didStart = false;
    readProc.cancelled = false;
    scheduleRead();
  }

  function gatherBegin() {
    for (let i = 0; i < monitors.length; ++i) {
      if (validBus(monitorsDdcBuses[i]))
        queueRead({ kind: "vcp", name: monitors[i], bus: monitorsDdcBuses[i], command: ["ddcutil", "getvcp", "10", "--bus", String(monitorsDdcBuses[i]), "--brief"], timeout: 15000 });
    }
  }

  onMonitorsChanged: resetTopology()
  Component.onCompleted: {
    readsReady = true;
    resetTopology();
  }

  Process {
    id: readProc
    property var request: null
    property bool didStart: false
    property bool cancelled: false
    property bool outputSeen: false
    property string completedOutput: ""
    running: false
    stdout: StdioCollector {
      id: readOutput
      // Observe only the size while collecting; never parse/apply partial output.
      waitForEnd: false
      onDataChanged: {
        if (readProc.request) {
          readProc.outputSeen = true;
          if (text.length > 65536)
            root.cancelOwnedRead();
        }
      }
      // Empty EOF does not update the default collector's previous text in0.3.1.
      onStreamFinished: readProc.completedOutput = readProc.outputSeen ? text : ""
    }
    onStarted: {
      didStart = true;
      if (cancelled || !request || request.generation != root.readGeneration) {
        cancelled = true;
        if (Number(processId) > 0)
          signal(9);
      }
    }
    // 0.3.1 flushes the collector before exited; failed startup emits only runningChanged.
    onExited: (exitCode, exitStatus) => root.finishRead(completedOutput, exitCode, exitStatus)
    onRunningChanged: {
      if (!running && request && !didStart)
        root.finishRead("", -1, 1);
    }
  }

  Timer {
    id: readDeadline
    interval: 15000
    repeat: false
    onTriggered: root.cancelOwnedRead()
  }

  Timer {
    id: readNextTimer
    interval: 1
    repeat: false
    onTriggered: root.startNextRead()
  }

  function setBrightness(monitorId, brightness) {
    if (!Number.isInteger(monitorId) || monitorId < 0 || monitorId >= monitors.length || !validBus(monitorsDdcBuses[monitorId]) || !validLevel(brightnesses[monitorId]) || !validLevel(brightness))
      return;
    bumpControlVersion(controlKey("vcp", monitors[monitorId], ""));
    needUpdate[monitorId] = true;
    brightnesses[monitorId] = brightness;
    updateTimer.running = true;
  }

  function setOverall(brightness) {
    if (!validLevel(brightness))
      return;
    setBacklight(brightness);
    for (let i = 0; i < monitors.length; ++i)
      setBrightness(i, brightness);
    overallBrightness = brightness;
  }

  function setBacklight(brightness) {
    if (!hasBacklight || !deviceName(backlightDevice) || !validLevel(backlightBrightness) || !validLevel(brightness))
      return;
    bumpControlVersion(controlKey("backlight", backlightDevice, backlightConnector));
    backlightNeedUpdate = true;
    backlightBrightness = brightness;
    updateTimer.restart();
  }

  function incrementActive(delta) {
    const focusedMonitorId = monitors.indexOf(Hyprland.focusedMonitor.name);
    if (focusedMonitorId < 0)
      return;
    if (hasBacklight && focusedMonitorId == backlightMonitorIndex) {
      if (validLevel(backlightBrightness))
        setBacklight(Math.max(1, Math.min(100, backlightBrightness + delta)));
      return;
    }
    if (validLevel(brightnesses[focusedMonitorId]))
      setBrightness(focusedMonitorId, Math.max(1, Math.min(100, brightnesses[focusedMonitorId] + delta)));
  }

  Process {
    id: ddcUpdateProc
    running: false
    onRunningChanged: { if (!running) root.scheduleRead(); }
  }

  Process {
    id: backlightUpdateProc
    running: false
    onRunningChanged: { if (!running) root.scheduleRead(); }
  }

  Timer {
    id: updateTimer
    interval: 10
    repeat: true
    running: false
    onTriggered: () => {
      if (readProc.request || readProc.running || ddcUpdateProc.running || backlightUpdateProc.running)
        return;
      if (backlightNeedUpdate) {
        if (hasBacklight && deviceName(backlightDevice) && validLevel(backlightBrightness)) {
          backlightUpdateProc.command = ["brightnessctl", "-d", root.backlightDevice, "s", `${Math.max(root.backlightBrightness, 1)}%`];
          backlightUpdateProc.running = true;
        }
        backlightNeedUpdate = false;
        return;
      }
      for (let i = 0; i < needUpdate.length; ++i) {
        if (!needUpdate[i])
          continue;
        if (validBus(monitorsDdcBuses[i]) && validLevel(brightnesses[i])) {
          ddcUpdateProc.command = ["ddcutil", "setvcp", "10", "" + parseInt(Math.round(brightnesses[i])), "--bus", "" + monitorsDdcBuses[i]];
          ddcUpdateProc.running = true;
        }
        needUpdate[i] = false;
        return;
      }
      updateTimer.running = false;
      scheduleRead();
    }
  }

  IpcHandler {
    target: "brightness"
    function increment() {
      if (C.Config.misc.brightnessSplit)
        root.incrementActive(5);
      else
        root.setOverall(Math.min(100, root.overallBrightness + 5));
    }
    function decrement() {
      if (C.Config.misc.brightnessSplit)
        root.incrementActive(-5);
      else
        root.setOverall(Math.max(1, root.overallBrightness - 5));
    }
  }
}
