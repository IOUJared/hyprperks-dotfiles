-- Warframe: Steam AppID 230410, Proton-GE Latest, runs MODE_BORDERLESS (EE.cfg).
-- Kept windowed/borderless on DP-1: no fullscreen promotion, so the game is
-- never pushed into its exclusive fullscreen mode. Consequence: the
-- fullscreen-gated features (VRR mode 2, tearing, direct scanout) stay
-- inactive. Borderless windows inherit conf.d's transparent-non-fullscreen
-- opacity 0.95, which the baseline rule overrides.
local warframe = "^steam_app_230410$" -- confirm with `hyprctl clients` while running

hl.window_rule({
    name = "warframe-game-content",
    match = { class = warframe },
    content = "game", -- identifies the game; prerequisite if VRR 3 is enabled later
})

hl.window_rule({
    name = "warframe-game-baseline",
    match = { class = warframe },
    float = false,            -- Proton runs through XWayland; keep it tiled
    no_anim = true,
    no_blur = true,
    opaque = true,
    opacity = "1.0 override", -- beat transparent-non-fullscreen (0.95)
    force_rgbx = true,        -- ignore Wine's own window transparency
    idle_inhibit = "focus",   -- hypridle must not lock mid-mission
})

hl.window_rule({
    name = "warframe-confine-pointer",
    match = { class = warframe, focus = true },
    confine_pointer = true, -- keep the cursor off the other monitor
})

hl.window_rule({
    name = "warframe-monitor-dp1", -- DP-1 = LG 540 Hz (10-bit), DP-2 = ASUS 240 Hz
    match = { class = warframe },
    monitor = "DP-1",
})
