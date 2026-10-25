import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../config" as C
import "../bar" as B
import "../state" as S

ColumnLayout {
  id: root
  property string statsConsumer: ""
  readonly property bool statsDemand: (QsWindow.window?.visible ?? false)
    && S.SystemState.itemVisible(root)
  onStatsDemandChanged: S.SystemState.setConsumer(statsConsumer, "stats", statsDemand)
  Component.onCompleted: {
    statsConsumer = S.SystemState.newConsumer();
    S.SystemState.setConsumer(statsConsumer, "stats", statsDemand);
  }
  Component.onDestruction: S.SystemState.setConsumer(statsConsumer, "stats", false)

  spacing: 10

  RowLayout {
    spacing: 10
    uniformCellSizes: true

    StatsBarElement {
      icon: ""
      percentage: S.SystemState.cpu
    }

    StatsBarElement {
      icon: ""
      percentage: S.SystemState.ram
    }
  }

  RowLayout {
    spacing: 10

    Item {
      Layout.fillWidth: true
    }

    StatsRawElement {
      icon: ""
      amount: S.SystemState.networkD
    }

    StatsRawElement {
      icon: ""
      amount: S.SystemState.networkU
    }

    StatsRawElement {
      visible: S.SystemState.temp != ""
      icon: ""
      amount: S.SystemState.temp + "°C"
    }

    Item {
      Layout.fillWidth: true
    }
  }
}
