pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
  id: root

  property MprisPlayer player: null
  property MprisPlayer lastChangedPlayer: null
  property var changedPlayers: new Set()

  function updatePlayer() {
    let leader = null;
    let backup = lastChangedPlayer;
    for (let p of Mpris.players.values) {
      if (p.isPlaying) {
        backup = p;
        if (p.trackArtist != "")
          leader = p;
      }
    }

    player = leader != null ? leader : backup;
  }

  function handlePlayerChanged(player: MprisPlayer) {
    if (!player.isPlaying)
      return;

    changedPlayers.delete(player);
    changedPlayers.add(player);
    lastChangedPlayer = player ?? null;

    updatePlayer();
  }

  function playerDestroyed(player: MprisPlayer) {
    changedPlayers.delete(player);
    lastChangedPlayer = changedPlayers[changedPlayers.size] ?? null;

    updatePlayer();
  }

  Instantiator {
    model: Mpris.players

    Connections {
      required property MprisPlayer modelData
      target: modelData

      Component.onCompleted: root.handlePlayerChanged(modelData)
      Component.onDestruction: root.playerDestroyed(modelData)

      function onPlaybackStateChanged() {
        root.handlePlayerChanged(modelData);
      }
    }
  }

  IpcHandler {
    target: "mpris"

    function pauseAll() {
      for (const player of Mpris.players.values) {
        if (player.canPause)
          player.pause();
      }
    }

    function togglePlaying() {
      const player = root.player;
      if (player && player.canTogglePlaying)
        player.togglePlaying();
    }

    function previous() {
      const player = root.player;
      if (player && player.canGoPrevious)
        player.previous();
    }

    function next() {
      const player = root.player;
      if (player && player.canGoNext)
        player.next();
    }
  }
}
