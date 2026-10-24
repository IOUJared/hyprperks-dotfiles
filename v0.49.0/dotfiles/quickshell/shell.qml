import "./config" as C
import "./intro" as I
import "./shortcuts" as SH
import "./versionMismatch" as V
import "./state" as S
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "config"

Scope {
  Component.onCompleted: {
    console.log("Shell initialized");
    S.BrightnessState.load();
  }

  Variants {
    model: {
      S.UpdateState.init();

      let mons = Quickshell.screens.filter(m => {
        if (Config.settings.panels.monitorChoiceMode == 0)
          return !Config.settings.panels.excludedMonitors.includes(m.name);
        else
          return (Config.settings.panels.includedMonitors.includes(m.name) || Config.settings.panels.includedMonitors.includes("" + Quickshell.screens.indexOf(m)));
      });

      if (mons.length == 0) {
        S.ErrorState.monitorError = true;
        return [Quickshell.screens[0]]; // prevent a softlock
      }
      S.ErrorState.monitorError = false;
      return mons;
    }

    ScreenState {
      required property ShellScreen modelData

      screen: modelData
    }
  }

  SH.ShortcutsPanel {
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  }

  I.IntroMenu {
    visible: !C.Config.misc.introductionDone
    screen: Quickshell.screens[0]
  }

  V.VersionMismatch {
    screen: Quickshell.screens[0]
  }

  IpcHandler {
    target: "update"

    function updated(): void {
      S.UpdateState.setUpdated();
    }
  }
}
