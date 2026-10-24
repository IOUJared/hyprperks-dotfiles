import "../commonwidgets" as CW
import "../config" as C
import "../notifs" as N
import "../state" as S
import "../shortcuts" as SH
import "./settings" as ST
import "./updates" as UP
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

WrapperItem {
  property bool settingsOpen: false
  property bool updatesOpen: false

  implicitWidth: 360 // notifs are 360

  Item {
    anchors.fill: parent

    ColumnLayout {
      id: rightMenuLayout

      opacity: settingsOpen || updatesOpen ? 0 : 1
      visible: opacity != 0
      spacing: 15
      anchors.fill: parent
      z: settingsOpen || updatesOpen ? 1 : 2

      Clock {
        Layout.fillWidth: true
        implicitHeight: 120
      }

      WarningBar {
        text: "Your monitor configuration prevents the display of the bar by not matching any connected display."
        Layout.fillWidth: true
        visible: S.ErrorState.monitorError
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Notifications
        ScrollView {
          id: notifScroll
          anchors.fill: parent
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
          ScrollBar.vertical.policy: ScrollBar.AlwaysOff

          ColumnLayout {
            id: notifLayout

            implicitWidth: notifScroll.width

            Repeater {
              model: S.NotificationState.allNotifs

              N.NotificationBox {
                required property int index

                app: S.NotificationState.allNotifs[index].appName
                content: S.NotificationState.allNotifs[index].summary
                icon: S.NotificationState.allNotifs[index].appIcon
                hasDismiss: false
                indexAll: index
              }
            }
          }
        }

        // Empty placeholder
        ColumnLayout {
          anchors.centerIn: parent
          opacity: S.NotificationState.allNotifs.length === 0 ? 1 : 0
          visible: opacity > 0
          Behavior on opacity {
            NumberAnimation {
              duration: C.Globals.anim_FAST
              easing.type: Easing.Linear
            }
          }
          CW.FontIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "notifications_active"
            iconSize: 64
            color: C.Config.theme.outline
          }
          CW.StyledText {
            text: qsTr("No notifications")
            font.pointSize: C.Config.fontSize.large
            horizontalAlignment: Text.AlignHCenter
            color: C.Config.theme.outline
          }
        }
      }

      UpdateBar {
        visible: S.UpdateState.updatesAvailable && !S.UpdateState.updateRunning
        Layout.fillWidth: true
      }

      Stats {
        Layout.fillWidth: true
      }

      Behavior on opacity {
        NumberAnimation {
          duration: 250
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      transform: Translate {
        x: settingsOpen || updatesOpen ? -40 : 0

        Behavior on x {
          NumberAnimation {
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }
    }

    ST.Settings {
      visible: opacity != 0
      anchors.fill: parent
      opacity: settingsOpen ? 1 : 0
      z: settingsOpen ? 2 : 1

      Behavior on opacity {
        NumberAnimation {
          duration: 250
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      transform: Translate {
        x: settingsOpen ? 0 : 40

        Behavior on x {
          NumberAnimation {
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }
    }

    UP.Updates {
      visible: opacity != 0
      anchors.fill: parent
      opacity: updatesOpen ? 1 : 0
      z: updatesOpen ? 2 : 1

      Behavior on opacity {
        NumberAnimation {
          duration: 250
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      transform: Translate {
        x: updatesOpen ? 0 : 40

        Behavior on x {
          NumberAnimation {
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }
    }

    RowLayout {
      opacity: settingsOpen || updatesOpen ? 0 : 1

      Behavior on opacity {
        NumberAnimation {
          duration: 300
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      visible: opacity != 0
      z: settingsOpen || updatesOpen ? 1 : 2

      anchors {
        right: parent.right
        bottom: parent.bottom
        left: parent.left
        rightMargin: 0
        bottomMargin: 0
      }

      implicitHeight: 20

      WrapperMouseArea {
        id: shortcutsMa

        implicitHeight: 20
        implicitWidth: 20
        hoverEnabled: true
        onPressed: () => {
          S.MiscState.shortcutsOpen = true;
          S.MiscState.shortcutsOpenGrab = true;
        }

        Rectangle {
          anchors.fill: parent
          radius: 4
          color: C.Config.applySecondaryOpacity(shortcutsMa.containsMouse ? Qt.lighter(C.Config.theme.surface_container, 3) : C.Config.theme.surface_container)

          CW.FontIcon {
            anchors.centerIn: parent
            text: "keyboard"
          }

          Behavior on color {
            ColorAnimation {
              duration: 400
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }

      Item {
        Layout.fillWidth: true
      }

      WrapperMouseArea {
        id: updatesMa

        implicitHeight: 20
        implicitWidth: 20
        hoverEnabled: true
        onPressed: () => {
          updatesOpen = true;
        }

        Rectangle {
          anchors.fill: parent
          radius: 4
          color: C.Config.applySecondaryOpacity(updatesMa.containsMouse ? Qt.lighter(C.Config.theme.surface_container, 3) : C.Config.theme.surface_container)

          CW.FontIcon {
            anchors.centerIn: parent
            text: "arrow_upward"
          }

          Behavior on color {
            ColorAnimation {
              duration: 400
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }

      WrapperMouseArea {
        id: settingsMa

        implicitHeight: 20
        implicitWidth: 20
        hoverEnabled: true
        onPressed: () => {
          settingsOpen = true;
        }

        Rectangle {
          anchors.fill: parent
          radius: 4
          color: C.Config.applySecondaryOpacity(settingsMa.containsMouse ? Qt.lighter(C.Config.theme.surface_container, 3) : C.Config.theme.surface_container)

          CW.FontIcon {
            anchors.centerIn: parent
            text: "settings"
          }

          Behavior on color {
            ColorAnimation {
              duration: 400
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }
    }

    RowLayout {
      opacity: settingsOpen || updatesOpen ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: 300
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      visible: opacity != 0
      z: settingsOpen || updatesOpen ? 2 : 1

      anchors {
        right: parent.right
        bottom: parent.bottom
        rightMargin: 0
        bottomMargin: 0
      }

      implicitHeight: 20

      WrapperMouseArea {
        id: settingsBackMa

        implicitHeight: 20
        implicitWidth: 20
        hoverEnabled: true
        onPressed: () => {
          updatesOpen = false;
          settingsOpen = false;
        }

        Rectangle {
          anchors.fill: parent
          radius: 4
          color: C.Config.applySecondaryOpacity(settingsBackMa.containsMouse ? Qt.lighter(C.Config.theme.surface_container, 3) : C.Config.theme.surface_container)

          CW.FontIcon {
            anchors.centerIn: parent
            text: "arrow_back"
          }

          Behavior on color {
            ColorAnimation {
              duration: 400
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }
    }
  }
}
