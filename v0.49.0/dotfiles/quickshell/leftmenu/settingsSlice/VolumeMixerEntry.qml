import "../../commonwidgets" as CW
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
  id: root

  property string overrideIcon: ""

  required property PwNode node
  PwObjectTracker {
    objects: [node]
  }

  implicitHeight: contentLayout.implicitHeight
  RowLayout {
    id: contentLayout
    anchors.fill: parent

    Image {
      property real size: columnLayout.implicitHeight
      visible: source != "image-missing"
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      sourceSize.width: size
      sourceSize.height: size
      source: {
        let icon;
        if (root.overrideIcon != "")
          return Quickshell.iconPath(root.overrideIcon, "image-missing");

        icon = root.node.properties["application.icon-name"];
        if (Quickshell.iconPath(icon, "image-missing") !== "image-missing")
          return Quickshell.iconPath(icon, "image-missing");
        icon = root.node.properties["node.name"];
        return Quickshell.iconPath(icon, "image-missing");
      }
    }

    ColumnLayout {
      id: columnLayout
      RowLayout {
        Layout.fillWidth: true
        CW.StyledText {
          Layout.fillWidth: true
          elide: Text.ElideRight
          text: {
            const app = root.node.properties["application.name"] ?? (root.node.description != "" ? root.node.description : root.node.name);
            const media = root.node.properties["media.name"];
            return media != undefined ? `${app} • ${media}` : app;
          }
        }
        CW.StyledText {
          text: `${Math.round((root.node.audio?.volume ?? 0) * 100)}%`
        }
      }
      RowLayout {
        CW.StyledSlider {
          id: slider
          Layout.fillWidth: true
          value: root.node.audio?.volume ?? 0
          onValueChanged: root.node.audio.volume = value
        }
      }
    }
  }
}
