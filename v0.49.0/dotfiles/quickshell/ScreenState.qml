import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar" as B
import "notifs" as N
import "osd" as O
import "keybinds" as K

Scope {
  id: root

  property ShellScreen screen
  property bool hasFullscreenWindow: Hyprland.monitorFor(screen).activeWorkspace.hasFullscreen

  B.Bar {
    screen: root.screen
    compact: root.hasFullscreenWindow
  }

  N.NotificationPanel {
    screen: root.screen
  }

  O.OnScreenDisplay {
    screen: root.screen
  }
}
