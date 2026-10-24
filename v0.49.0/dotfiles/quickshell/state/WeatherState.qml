pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as C

Singleton {
  id: root

  property string location: "?"
  property string icon: "sunny"
  property string temp: "26°"

  Process {
    id: weatherProc
    running: false
    command: ["sh", "-c", "curl -s \"wttr.in/$(curl -s ipinfo.io/city)?format=%c|%t|%C|%f|%m|%p|%l\""]

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        const RETS = data.split("|");
        console.log("got weather");

        location = "Unknown";

        if (RETS.length < 5)
          return;

        location = RETS[6];
        temp = RETS[1][0] == "+" ? RETS[1].substr(1) : RETS[1];

        if (RETS[2] == "Clear" || RETS[2] == "Sunny")
          icon = "sunny";
        else if (RETS[2] == "Partly cloudy")
          icon = "partly_cloudy_day";
        else if (RETS[2] == "Cloudy" || RETS[2] == "Overcast")
          icon = "cloud";
        else if (RETS[2] == "Mist" || RETS[2] == "Fog" || RETS[2] == "Freezing fog")
          icon = "Foggy";
        else if (RETS[2].indexOf("rain") != -1 || RETS[2].indexOf("drizzle") != -1)
          icon = "rainy";
        else if (RETS[2].indexOf("snow") != -1)
          icon = "weather_snowy";
        else if (RETS[2].indexOf("hunder") != -1)
          icon = "thunderstorm";
        else if (RETS[2] == "Ice pellets")
          icon = "weather_hail";
        else
          icon = "question_mark";
      }
    }
  }

  Timer {
    running: C.Config.settings.bar.weather && location == "?"
    interval: 100
    repeat: true
    onTriggered: {
      if (!weatherProc.running)
        weatherProc.running = true;
    }
  }

  Timer {
    repeat: true
    running: C.Config.settings.bar.weather
    interval: 1000 * 60 * 10 // 10 mins

    onTriggered: {
      weatherProc.running = true;
    }
  }
}
