import "../state" as S
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick // for Text
import QtQuick.Layouts
import QtQuick.Layouts
import Quickshell // for ShellRoot and PanelWindow
import Quickshell.Wayland
import Quickshell.Services.Notifications

WlrLayershell {
  id: root

  visible: S.NotificationState.notifOverlayOpen
  color: "transparent"
  namespace: "hyprland-shell:notifs"
  layer: WlrLayer.Top
  implicitHeight: notifs.height
  implicitWidth: notifs.width + 10

  anchors {
    top: true
    right: true
  }

  ColumnLayout {
    id: notifs

    Item {
      implicitHeight: 10
    }

    // FIXME: fox make this animated
    Repeater {
      model: S.NotificationState.popupNotifs

      NotificationBox {
        required property int index
        app: S.NotificationState.popupNotifs[index].appName
        content: S.NotificationState.popupNotifs[index].summary
        icon: S.NotificationState.popupNotifs[index].appIcon
        indexPopup: index
      }
    }
  }
}
