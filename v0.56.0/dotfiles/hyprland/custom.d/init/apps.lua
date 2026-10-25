HLDE = HLDE or {}
HLDE.apps = HLDE.apps or {}

HLDE.mainMod = HLDE.mainMod or "SUPER"

HLDE.apps.terminal = "uwsm app -- alacritty"
HLDE.apps.browser = "uwsm app -- zen-browser"
HLDE.apps.fileManager = "uwsm app -- thunar"
HLDE.apps.menu = "hyprlauncher --toggle"
HLDE.apps.lockscreen = "hyprlock --config /home/jared/.config/hypr/hyprlock-custom.conf"
HLDE.apps.hyprshot = "uwsm app -- hyprshot"
HLDE.apps.screenshot = HLDE.apps.hyprshot .. " -m region --freeze"
