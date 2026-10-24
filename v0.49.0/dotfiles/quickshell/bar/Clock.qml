import QtQuick
import Quickshell

import "../commonwidgets" as CW

CW.StyledText {
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  text: Qt.formatDateTime(clock.date, "d MMM yyyy hh:mm")
}
