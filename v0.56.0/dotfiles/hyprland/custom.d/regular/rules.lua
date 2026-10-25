local centerOnMonitor = { "(monitor_w - window_w) / 2", "(monitor_h - window_h) / 2" }
local steamClass = "^([Ss]team|steamwebhelper)$"

local function lowLatencyRule(options)
    local rule = { no_anim = true, opaque = true, immediate = true }
    for key, value in pairs(options) do
        rule[key] = value
    end
    hl.window_rule(rule)
end

local function steamRule(options)
    local rule = { no_initial_focus = true, focus_on_activate = false }
    for key, value in pairs(options) do
        rule[key] = value
    end
    hl.window_rule(rule)
end

lowLatencyRule({
    name = "minecraft-low-latency",
    match = { class = "^(com\\.mojang\\.minecraft)$" },
})

hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    float = false,
    suppress_event = "maximize",
})

for _, entry in ipairs({
    { name = "smart-gaps-w-tv1", workspace = "w[tv1]" },
    { name = "smart-gaps-f-1", workspace = "f[1]" },
}) do
    hl.window_rule({
        name = entry.name,
        match = { float = false, workspace = entry.workspace },
        border_size = 0,
        rounding = 0,
    })
end

-- Static placement: center new floating windows without floating tiled apps.
hl.window_rule({
    name = "center-new-floating-windows",
    match = { class = ".*" },
    center = true,
})

hl.window_rule({
    name = "global-floating-off",
    match = { float = true },
    border_size = 0,
})

hl.window_rule({
    name = "xwayland-video-bridge",
    match = { class = "^(xwaylandvideobridge)$" },
    opacity = "0.0 override",
    no_anim = true,
    max_size = { 1, 1 },
    no_blur = true,
})

hl.window_rule({
    name = "xwayland-window-fix",
    match = { xwayland = true },
    float = true,
    no_blur = true,
})

-- Proton games are XWayland clients. Keep Steam games tiled despite the
-- generic XWayland rule above; this must stay after it because custom.d
-- files load in directory order and would otherwise race the per-game rules.
hl.window_rule({
    name = "steam-games-tiled",
    match = { class = "^steam_app_[0-9]+$" },
    float = false,
})

for _, entry in ipairs({
    {
        name = "float-center-large",
        match = {
            class = "^(Alacritty|file_progress|confirm|dialog|download|notification|error|splash|confirmreset|Lxappearance|viewnior|feh|com\\.mitchellh\\.ghostty|pavucontrol-qt|pavucontrol|file-roller|quickshell|io\\.gitlab\\.theevilskeleton\\.Upscaler)$",
        },
    },
    {
        name = "float-center-titles",
        match = {
            title = "^(Open File|branchdialog|Media viewer|Mission Center|wlogout|Volume Control)$",
        },
    },
}) do
    hl.window_rule({
        name = entry.name,
        match = entry.match,
        float = true,
        move = centerOnMonitor,
        size = { 1200, 700 },
    })
end

hl.window_rule({
    name = "float-clipse",
    match = { class = "^(clipse)$" },
    float = true,
    size = { 622, 652 },
})

lowLatencyRule({
    name = "cs2-noanim-opaque",
    match = { class = "^(cs2)$" },
})

lowLatencyRule({
    name = "ascension-launcher",
    match = { title = "^(Ascension Launcher)$" },
    float = true,
    size = { 1280, 720 },
})

lowLatencyRule({
    name = "ascension-window",
    match = { title = "^(Ascension)$" },
    float = false,
    size = { 2560, 1440 },
})

hl.window_rule({
    name = "discord-floating-policy",
    match = { class = "^(discord)$" },
    float = false,
    opaque = true,
    no_initial_focus = true,
    focus_on_activate = false,
})

hl.window_rule({
    name = "chatgpt-tiled",
    match = { class = "^(Chatgpt)$" },
    tile = true,
    float = false,
})

for _, entry in ipairs({
    { name = "discord-workspace-4", class = "^(discord)$" },
    { name = "legcord-workspace-4", class = "^(legcord)$" },
}) do
    hl.window_rule({
        name = entry.name,
        match = { class = entry.class },
        workspace = "4 silent",
    })
end

hl.window_rule({
    name = "tidal-workspace-3",
    match = { class = "^(tidal-hifi|[Ss]potify)$" },
    workspace = "3 silent",
    no_initial_focus = true,
    focus_on_activate = false,
})

hl.window_rule({
    name = "bitwarden-screen-share",
    match = { class = "^(Bitwarden)$" },
    no_screen_share = true,
})

hl.window_rule({
    name = "mpv-idle-inhibit",
    match = { class = "^(mpv)$" },
    idle_inhibit = "focus",
})

hl.window_rule({
    name = "fullscreen-browser-idle",
    match = {
        class = "^(firefox|vivaldi|zen|zen-browser)$",
        fullscreen = true,
    },
    idle_inhibit = "focus",
})

hl.window_rule({
    name = "afk-overlay-pin",
    match = { title = "^(AFK Overlay)$" },
    float = true,
    pin = true,
})

hl.window_rule({
    name = "rust-timer-no-focus",
    match = { class = "^(rust-timer)$" },
    monitor = "DP-2",
})

hl.window_rule({
    name = "volume-control-size",
    match = { title = "^(Volume Control)$" },
    size = { 800, 600 },
    move = centerOnMonitor,
})

steamRule({
    name = "steam-floating-baseline",
    match = { class = steamClass },
    float = false,
    no_anim = true,
    opaque = true,
    workspace = "5 silent",
})
hl.permission({ binary = "/usr/bin/sunshine", type = "screencopy", mode = "allow" })

steamRule({
    name = "steam-move-workspace-5",
    match = {
        class = steamClass,
        title = "^([Ss]team)$",
    },
    tile = true,
    float = false,
    workspace = "5 silent",
})

steamRule({
    name = "steam-friends-list",
    match = {
        class = steamClass,
        title = "Friends List",
    },
    float = true,
    workspace = "5 silent",
    size = { 400, 800 },
    move = centerOnMonitor,
})

steamRule({
    name = "steam-empty-title",
    match = {
        class = steamClass,
        title = "^()$",
    },
    float = true,
    min_size = { 1, 1 },
})

hl.window_rule({
    name = "runelite-baseline",
    match = { class = "^(net-runelite-client-RuneLite)$" },
    no_anim = true,
    opaque = true,
})

hl.window_rule({
    name = "runelite-empty-title",
    match = {
        class = "^(net-runelite-client-RuneLite)$",
        title = "^()$",
    },
    stay_focused = true,
})

hl.window_rule({
    name = "runelite-popup-nofocus",
    match = {
        initial_class = "^(net-runelite-client-RuneLite)$",
        initial_title = "win\\d+",
    },
    float = true,
})

hl.window_rule({
    name = "picture-in-picture",
    match = {
        class = "^(zen|zen-browser)$",
        title = "^(Picture-in-Picture|Picture in Picture)$",
    },
    float = true,
    pin = true,
    no_anim = true,
    no_initial_focus = true,
    focus_on_activate = false,
    size = { 600, 340 },
    move = { 1960, 1100 },
})

hl.window_rule({
    name = "bambustudio-baseline",
    match = { class = "^(BambuStudio)$" },
    float = false,
    opacity = "1.0 override",
    opaque = true,
})

hl.window_rule({
    name = "bambustudio-empty-title",
    match = {
        class = "^(BambuStudio)$",
        title = "^()$",
    },
    min_size = { 1, 1 },
})

-- Genuine dialogs override app-wide tiling policies; keep their requested size.
hl.window_rule({
    name = "center-modal-dialogs",
    match = { modal = true },
    float = true,
    center = true,
})
