import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../config" as C

OffsetMouseWrapper {
  id: root

  property real padding: height / 4
  property real topInset: 0
  property real bottomInset: 0

  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(QsWindow.window?.screen)
  readonly property int activeWorkspace: monitor?.activeWorkspace?.id ?? 1
  property int shownWorkspaces: C.Config.settings.bar.workspaces.shown
  property int baseWorkspace: Math.floor((activeWorkspace - 1) / shownWorkspaces) * shownWorkspaces + 1

  // trackpads
  property int scrollAccumulator: 0

  acceptedButtons: Qt.NoButton
  onWheel: event => {
    event.accepted = true;
    let acc = scrollAccumulator - event.angleDelta.x - event.angleDelta.y;
    const sign = Math.sign(acc);
    acc = Math.abs(acc);

    const offset = sign * Math.floor(acc / 120);
    scrollAccumulator = sign * (acc % 120);

    if (offset != 0) {
      const currentWorkspace = root.activeWorkspace;
      const targetWorkspace = currentWorkspace + offset;
      const id = Math.max(baseWorkspace, Math.min(baseWorkspace + shownWorkspaces - 1, targetWorkspace));
      if (id != currentWorkspace)
        Hyprland.dispatch(`workspace ${id}`);
    }
  }

  Row {
    spacing: 1

    Repeater {
      model: ScriptModel {
        objectProp: "index"
        values: {
          const workspaces = Hyprland.workspaces.values;
          const base = root.baseWorkspace;
          return Array.from({
            length: root.shownWorkspaces
          }, (_, i) => ({
                index: base + i,
                workspace: workspaces.find(w => w.id == base + i)
              }));
        }
      }

      WrapperMouseArea {
        id: delegate
        required property var modelData

        implicitHeight: parent.height
        leftMargin: 1
        rightMargin: 1
        topMargin: root.topInset + root.padding
        bottomMargin: root.bottomInset + root.padding

        onPressed: Hyprland.dispatch(`workspace ${modelData.index}`)

        Rectangle {
          property real activeMul: delegate.modelData.workspace?.active ?? false ? (C.Config.settings.bar.workspaces.activeIndicatorWidthMultiplier) : 1
          Behavior on activeMul {
            NumberAnimation {
              duration: C.Globals.anim_SLOW
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }

          radius: height / 2
          implicitWidth: height * activeMul

          color: delegate.modelData.workspace?.active ? C.Config.theme.primary : delegate.modelData.workspace ? Qt.darker(C.Config.theme.primary) : C.Config.theme.surface_container_highest

          Behavior on color {
            ColorAnimation {
              duration: C.Globals.anim_SLOW
              easing.type: Easing.BezierSpline
              easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }
          }
        }
      }
    }
  }
}
