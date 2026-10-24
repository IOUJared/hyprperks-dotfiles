import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import QtQuick.Controls

import "../../config" as C
import "../../state" as S
import "../../commonwidgets" as CW
import "./wifi" as W

Rectangle {
  id: root
  required property Item header
  property alias model: view.model
  property alias delegate: view.delegate
  property string footerIcon: ""
  property bool footerActive
  signal footerClicked

  color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
  radius: 8
  implicitHeight: 300

  ColumnLayout {
    id: contentLayout
    anchors.fill: parent
    spacing: 0
    anchors.topMargin: 10
    anchors.leftMargin: 10
    anchors.rightMargin: 10

    CW.HorizontalLine {
      id: sep
      Layout.leftMargin: -contentLayout.anchors.leftMargin
      Layout.rightMargin: -contentLayout.anchors.rightMargin
      Layout.topMargin: 10
      Layout.bottomMargin: 0
    }

    ListView {
      id: view
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 5
      clip: true
      topMargin: 10
      bottomMargin: (footerBox.visible ? footerBox.height : 0) + topMargin
    }

    children: [root.header, sep, view, root.footer,]
  }

  WrapperMouseArea {
    id: footerBox
    visible: root.footerIcon != ""
    hoverEnabled: true
    onClicked: root.footerClicked()

    anchors {
      right: parent.right
      bottom: parent.bottom
    }

    Rectangle {
      color: {
        const base = root.footerActive ? C.Config.theme.surface_variant : C.Config.theme.surface_container;
        return footerBox.containsMouse ? Qt.lighter(base) : base;
      }

      Behavior on color {
        ColorAnimation {
          duration: C.Globals.anim_NORMAL
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      topLeftRadius: bottomRightRadius
      bottomRightRadius: root.bottomRightRadius

      implicitWidth: 25
      implicitHeight: 25

      CW.FontIcon {
        anchors.centerIn: parent
        text: root.footerIcon
      }
    }
  }
}
