pragma Singleton
import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import "../state" as S

Singleton {
  property var anim_CURVE_SMOOTH_SLIDE: [0.23, 1, 0.32, 1, 1, 1]
  property var anim_CURVE_ALMOST_LINEAR: [0.5, 0.5, 0.75, 1, 1, 1]

  // Minimal motion: keep nonzero completion ticks for popup/notification lifecycle.
  property var anim_FAST: 16
  property var anim_MEDIUM: 32
  property var anim_SLOW: 54 // Existing 1.1× stagger remains below the 60 ms ceiling.
  property var anim_NORMAL: anim_MEDIUM

  property bool isFedora: S.SystemState.osString == "Fedora Linux" || S.SystemState.osString == "Nobara Linux"
}
