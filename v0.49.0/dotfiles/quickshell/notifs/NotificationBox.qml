import "../bar" as B
import "../commonwidgets" as CW
import "../config" as C
import "../state" as S
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Rectangle {
  id: root

  property string app: "Test App"
  property string content: "Test Content\nTest Line 2\nTest Line 3"
  property string icon: ""
  property int indexPopup: -1
  property int indexAll: -1
  property bool hasDismiss: true
  property real iconSize: 46

  implicitWidth: 360
  implicitHeight: mainLayout.implicitHeight
  radius: 16
  color: C.Config.theme.background

  RowLayout {
    id: mainLayout

    implicitHeight: contentLayout.implicitHeight
    spacing: 5

    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }

    Item {
      id: coverItem

      Layout.alignment: Qt.AlignTop
      implicitWidth: root.iconSize
      implicitHeight: root.iconSize
      Layout.leftMargin: 15
      Layout.topMargin: 15

      ClippingWrapperRectangle {
        visible: icon != ""
        anchors.centerIn: parent
        radius: 15
        color: "transparent"

        IconImage {
          implicitSize: coverItem.height
          source: Quickshell.iconPath(root.icon)
        }
      }

      Rectangle {
        visible: icon == ""
        anchors.fill: parent
        radius: 15
        color: Qt.lighter(C.Config.theme.background)

        CW.FontIcon {
          text: ""
          anchors.centerIn: parent
          font.pointSize: 22
        }
      }
    }

    ColumnLayout {
      id: contentLayout

      Layout.fillWidth: true
      Layout.rightMargin: 15
      Layout.leftMargin: 15
      Layout.topMargin: 15
      Layout.bottomMargin: 15
      spacing: 5

      CW.StyledText {
        Layout.maximumWidth: contentLayout.width - buttonLayout.width
        text: app
        elide: Text.ElideRight
        font.pointSize: C.Config.fontSize.large
      }

      CW.HorizontalLine {
        Layout.leftMargin: 0
        Layout.fillWidth: false
        implicitWidth: 130
        Layout.bottomMargin: 0
      }

      CW.StyledText {
        Layout.fillWidth: true
        Layout.fillHeight: true
        font.pointSize: C.Config.fontSize.normal
        elide: Text.ElideRight
        text: content
      }
    }
  }

  RowLayout {
    id: buttonLayout
    implicitHeight: 22

    anchors {
      top: parent.top
      right: parent.right
      topMargin: 13
      rightMargin: 12
    }

    WrapperMouseArea {
      id: closeButtonMa

      hoverEnabled: true
      Layout.fillHeight: true
      implicitWidth: 22

      onPressed: () => {
        if (indexAll != -1)
          S.NotificationState.notifCloseByAll(indexAll);
        else if (indexPopup != -1)
          S.NotificationState.notifCloseByPopup(indexPopup);
      }

      Rectangle {
        radius: 16
        color: closeButtonMa.containsMouse ? Qt.lighter(Qt.lighter(Qt.lighter(C.Config.theme.background))) : Qt.lighter(Qt.lighter(C.Config.theme.background))
        implicitWidth: 22
        implicitHeight: 22

        CW.FontIcon {
          text: "close"
          anchors.centerIn: parent
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
      id: dismissButtonMa

      visible: hasDismiss

      hoverEnabled: true
      Layout.fillHeight: true
      implicitWidth: 22

      onPressed: () => {
        if (indexAll != -1)
          S.NotificationState.notifDismissByAll(indexAll);
        else if (indexPopup != -1)
          S.NotificationState.notifDismissByPopup(indexPopup);
      }

      Rectangle {
        radius: 16
        color: dismissButtonMa.containsMouse ? Qt.lighter(Qt.lighter(Qt.lighter(C.Config.theme.background))) : Qt.lighter(Qt.lighter(C.Config.theme.background))
        implicitWidth: 22
        implicitHeight: 22

        CW.FontIcon {
          text: "chevron_right"
          anchors.centerIn: parent
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
