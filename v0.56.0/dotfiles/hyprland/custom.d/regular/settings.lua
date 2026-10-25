hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        accel_profile = "flat",
        follow_mouse = 1,
        sensitivity = 0,
    },

    general = {
        allow_tearing = true,
        border_size = 2,
        float_gaps = 0,
        gaps_in = 2,
        gaps_out = 2,
        gaps_workspaces = 4,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        enable_swallow = true,
        swallow_regex = "^(alacritty)$",
        swallow_exception_regex = "^(nvim|vim|vi)\\b.*$",
        force_default_wallpaper = -1,
        font_family = "Fira Code",
        key_press_enables_dpms = true,
        always_follow_on_dnd = true,
        focus_on_activate = true,
        mouse_move_focuses_monitor = true,
        close_special_on_empty = true,
        middle_click_paste = false,
        allow_session_lock_restore = true,
        vrr = 0,
    },

    decoration = {
        rounding = 5,
        shadow = { enabled = false }, -- Shadows belong to the lock screen only.
        blur = { passes = 2, popups = false, input_methods = false },
    },

    animations = {
        enabled = false,
    },

    cursor = {
        enable_hyprcursor = true,
        no_warps = false,
        no_hardware_cursors = false,
        sync_gsettings_theme = true,
        default_monitor = "DP-1",
        hide_on_key_press = false,
        no_break_fs_vrr = 0,
    },

    render = {
        cm_auto_hdr = 1,
        direct_scanout = 2,
    },

    xwayland = {
        force_zero_scaling = true,
        enabled = true,
        use_nearest_neighbor = true,
    },

    binds = {
        allow_workspace_cycles = true,
        workspace_back_and_forth = true,
        workspace_center_on = 1,
    },

    ecosystem = {
        enforce_permissions = true,
    },

    debug = {
        disable_logs = true,
    },
})

hl.permission({
    binary = "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland",
    type = "screencopy",
    mode = "allow",
})

hl.permission({
    binary = "/usr/bin/hyprlock",
    type = "screencopy",
    mode = "allow",
})

-- Hyprshot captures through grim; hyprpicker freezes its region selection.
for _, binary in ipairs({ "/usr/bin/grim", "/usr/bin/hyprpicker" }) do
    hl.permission({ binary = binary, type = "screencopy", mode = "allow" })
end

hl.permission({
    binary = "/usr/(bin|local/bin)/hyprpm",
    type = "plugin",
    mode = "ask",
})

hl.permission({
    binary = ".*",
    type = "plugin",
    mode = "deny",
})

for _, name in ipairs({ "logitech-g915-x-ls-tkl-1", "logitech-x2-superstrike-1" }) do
    hl.device({ name = name, enabled = true, keybinds = true })
end
