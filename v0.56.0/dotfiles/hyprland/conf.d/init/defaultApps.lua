HLDE = HLDE or {}

HLDE.apps = HLDE.apps or {}
HLDE.colors = HLDE.colors or {}

local apps = HLDE.apps

apps.terminal = apps.terminal or "kitty"
apps.fileManager = apps.fileManager or "dolphin"
apps.menu = apps.menu or "hyprlauncher"
apps.clipboard = apps.clipboard or "cliphist list | hyprlauncher --dmenu | cliphist decode | wl-copy"
apps.lockscreen = apps.lockscreen or "hyprlock"
apps.screenshot = apps.screenshot or "grimblast --freeze --notify copysave area"

HLDE.mainMod = HLDE.mainMod or "SUPER"

function HLDE.env_set(name)
    local value = os.getenv(name)
    return value ~= nil and value ~= ""
end

function HLDE.color(name, fallback)
    return HLDE.colors[name] or fallback
end

function HLDE.raw_color(name, fallback)
    return HLDE.colors[name .. "_raw"] or fallback
end
