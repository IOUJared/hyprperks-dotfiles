local apps = HLDE.apps
local mainMod = HLDE.mainMod

local cursorZoomStep = 0.5
local cursorZoomMin = 1
local cursorZoomMax = 3
local function zoomCursor(delta)
    local current = tonumber(hl.get_config("cursor.zoom_factor")) or cursorZoomMin
    local nextZoom = math.max(cursorZoomMin,
        math.min(cursorZoomMax, current + (delta or 0)))

    hl.config({ cursor = { zoom_factor = nextZoom } })
end

for _, key in ipairs({ "Q", "M", "mouse_down", "mouse_up" }) do
    hl.unbind(mainMod .. " + " .. key)
end

for i = 1, 10 do
    hl.unbind(mainMod .. " + " .. (i % 10))
end

-- Let UWSM shut down clients and the graphical session in order.
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("uwsm stop"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(apps.terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(apps.browser))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(apps.terminal .. ' --class "rust-timer" -e ~/code/rust/cs2_timer/target/release/cs2_timer'))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(apps.terminal .. " --class clipse -e 'clipse'"))

hl.bind("PAUSE", hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "M", window = "class:^(discord)$" }))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(apps.hyprshot .. " -m output"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(apps.hyprshot .. " -m window"))
hl.bind(mainMod .. " + Z", function()
    zoomCursor(cursorZoomStep)
end)
hl.bind(mainMod .. " + SHIFT + Z", function()
    hl.config({ cursor = { zoom_factor = cursorZoomMin } })
end)

hl.bind(mainMod .. " + SHIFT + O", hl.dsp.workspace.swap_monitors({
    monitor1 = "1",
    monitor2 = "current",
}))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

for i = 1, 10 do
    local key = tostring(i % 10)
    local workspace = tostring(i)
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace, on_current_monitor = true }))
    hl.bind(mainMod .. " + SHIFT + F" .. i, hl.dsp.window.move({ workspace = workspace, follow = false }))
end

-- Move the active window to workspace 1-12 and follow it with Win + F1-F12.
for i = 1, 12 do
    hl.bind(mainMod .. " + F" .. i, hl.dsp.window.move({ workspace = tostring(i), follow = true }))
end
