import QtQuick
import QtQuick.Layouts
import "../config" as C
import "../commonwidgets" as CW

Item {
  id: root

  implicitWidth: 8

  Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

  CW.CutRectangle {
    property alias size: root.implicitWidth
    visible: C.Config.settings.bar.separatorCustom == false

    anchors.centerIn: parent

    color: C.Config.theme.outline
    
    implicitHeight: size
    implicitWidth: size
    radius: size / 2
  }

  CW.StyledText {
    visible: C.Config.settings.bar.separatorCustom == true

    anchors.centerIn: parent

    text: C.Config.settings.bar.separatorCustomText
    color: C.Config.theme.outline
  }
}
