local apps = HLDE.apps

local startupCommands = {
    { "uwsm app -- clipse -listen" },
    -- Portals activate through D-Bus; Hyprland handles native clipboard synchronization.
    { apps.browser, { workspace = "1 silent" } },
    { "uwsm app -- steam", { workspace = "5 silent" } },
    { "uwsm app -- gtk-launch discordx", { workspace = "4 silent" } },
    { "uwsm app -- sway-audio-idle-inhibit" },
    -- EasyEffects is owned by its XDG/UWSM autostart service.
    { "uwsm app -- tidal-hifi", { workspace = "3 silent" } },
}

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.focus({ workspace = 1 }))
    -- Preserve launch submission order; applications still start asynchronously.
    for _, command in ipairs(startupCommands) do
        hl.exec_cmd(command[1], command[2])
    end
    hl.dispatch(hl.dsp.focus({ workspace = 1 }))
end)
