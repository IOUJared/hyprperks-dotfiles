import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../config" as C
import "../bar" as B
import "../state" as S

ColumnLayout {
  id: root

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Text {
    text: Qt.formatDateTime(clock.date, "hh:mm:ss")

    Layout.fillWidth: true

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.pointSize: 17
    color: C.Config.theme.on_surface
  }

  Text {
    text: Qt.formatDateTime(clock.date, "d MMM yyyy")

    Layout.fillWidth: true

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.pointSize: 10
    color: C.Config.theme.on_surface
  }
}
