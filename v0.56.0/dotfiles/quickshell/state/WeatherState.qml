pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

import "../config" as C

Singleton {
  id: root

  property alias location: weatherCache.location
  property alias icon: weatherCache.icon
  property alias temp: weatherCache.temp
  property alias weatherStr: weatherCache.weatherStr
  property alias lastLocation: weatherCache.lastLocation
  property bool ready: false
  readonly property string configuredLocation: C.Config.settings.bar.weatherLocation
  readonly property bool fetchEnabled: C.Config.settings.bar.weather &&
    [C.Config.settings.bar.modulesLeft, C.Config.settings.bar.moduleCenter, C.Config.settings.bar.modulesRight]
      .join(",").split(",").some(module => module.trim() === "weather")

  PersistentProperties {
    id: weatherCache
    reloadableId: "weather-cache"
    property string location: "?"
    property string icon: "sunny"
    property string temp: "--°"
    property string weatherStr: "Unknown"
    property string lastLocation: ""
    property string lastAttemptLocation: ""
    property double nextRefreshAt: 0
    property int retryDelay: 60000
    onLoaded: {
      root.ready = true;
      root.scheduleWeather(lastAttemptLocation !== root.configuredLocation);
    }
  }

  function getTemp() {
    const value = parseFloat(root.temp);
    if (!Number.isFinite(value))
      return root.temp;
    const fahrenheit = root.temp.endsWith("F");
    if (C.Config.settings.bar.weatherTempInCelcius)
      return fahrenheit ? Math.round((value - 32) * 5 / 9) + "°C" : root.temp;
    return fahrenheit ? root.temp : Math.round(value * 9 / 5 + 32) + "°F";
  }

  function scheduleWeather(locationChanged) {
    if (!root.ready)
      return;
    if (!root.fetchEnabled) {
      refreshTimer.stop();
      return;
    }
    if (locationChanged) {
      weatherCache.nextRefreshAt = 0;
      weatherCache.retryDelay = 60000;
    }
    if (weatherProc.running)
      return;
    // Single-shot: immediate needs settle once, not a repeating startup/retry poll.
    refreshTimer.interval = Math.max(1000, Math.min(600000, weatherCache.nextRefreshAt - Date.now()));
    refreshTimer.restart();
  }

  function requestWeather() {
    if (!root.ready || !root.fetchEnabled || weatherProc.running)
      return;
    weatherProc.requestedLocation = root.configuredLocation;
    weatherCache.lastAttemptLocation = root.configuredLocation;
    weatherProc.pending = true;
    weatherProc.didStart = false;
    weatherProc.running = true;
  }

  function weatherIcon(description) {
    const condition = description.toLowerCase();
    if (condition === "clear" || condition === "sunny") return "sunny";
    if (condition === "partly cloudy") return "partly_cloudy_day";
    if (condition === "cloudy" || condition === "overcast") return "cloud";
    if (condition === "mist" || condition === "fog" || condition === "freezing fog") return "Foggy";
    if (condition.includes("rain") || condition.includes("drizzle")) return "rainy";
    if (condition.includes("snow")) return "weather_snowy";
    if (condition.includes("hunder")) return "thunderstorm";
    if (condition === "ice pellets") return "weather_hail";
    return "question_mark";
  }

  function finishWeather(output, exitCode, exitStatus, requestedLocation) {
    if (!root.fetchEnabled) {
      refreshTimer.stop();
      return false;
    }
    if (requestedLocation !== root.configuredLocation) {
      root.scheduleWeather(true); // Discard a response for the previous location.
      return false;
    }
    const fields = output.trim().split("|");
    const valid = exitCode === 0 && exitStatus === 0 && fields.length >= 7 &&
      /^[+-]?\d+(?:\.\d+)?°[CF]$/.test(fields[1]) && fields[2].trim() !== "" && fields[6].trim() !== "";
    if (valid) {
      root.location = fields[6];
      root.temp = fields[1].startsWith("+") ? fields[1].slice(1) : fields[1];
      root.weatherStr = fields[2];
      root.icon = root.weatherIcon(fields[2]);
      root.lastLocation = requestedLocation;
      weatherCache.retryDelay = 60000;
      weatherCache.nextRefreshAt = Date.now() + 600000; // Normal ten-minute refresh.
    } else {
      // Retain the last valid display, and exponentially back off to ten minutes.
      weatherCache.nextRefreshAt = Date.now() + weatherCache.retryDelay;
      weatherCache.retryDelay = Math.min(600000, weatherCache.retryDelay * 2);
      console.warn("Weather fetch failed; retaining cached data and backing off.");
    }
    root.scheduleWeather(false);
    return valid;
  }

  onFetchEnabledChanged: root.scheduleWeather(weatherCache.lastAttemptLocation !== root.configuredLocation)
  onConfiguredLocationChanged: root.scheduleWeather(true)

  Timer {
    id: refreshTimer
    repeat: false
    onTriggered: root.requestWeather()
  }

  Process {
    id: weatherProc
    property string requestedLocation: ""
    property bool pending: false
    property bool didStart: false
    running: false
    command: [
      "bash",
      (StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/state/weather.sh").replace("file://", ""),
      requestedLocation !== "None" && requestedLocation !== "" ? requestedLocation : ""
    ]
    stdout: StdioCollector { id: weatherOutput }
    onStarted: didStart = true
    onExited: (exitCode, exitStatus) => {
      pending = false;
      root.finishWeather(weatherOutput.text, exitCode, exitStatus, requestedLocation);
    }
    onRunningChanged: {
      if (!running && pending && !didStart) {
        pending = false;
        root.finishWeather("", -1, 1, requestedLocation);
      }
    }
  }
}
