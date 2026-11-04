-- Hyprland 0.57+ config (Lua). Ported from the legacy hyprland.conf.
-- API reference: /usr/share/hypr/stubs/hl.meta.lua, https://wiki.hypr.land/configuring/

---------------
-- Variables --
---------------

-- Keep the Sway muscle memory: Alt plus Vim direction keys.
local mod  = "ALT"
local term = "ghostty"
local menu = "vicinae toggle"

local function key(...)
    return table.concat({ ... }, " + ")
end

-------------------------------
-- Monitors and environment --
-------------------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-----------
-- Input --
-----------

hl.config({
    input = {
        kb_model     = "mac",
        kb_layout    = "us",
        kb_variant   = "intl",
        kb_options   = "numlock:enable",
        follow_mouse = 0,

        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            disable_while_typing = false,
        },
    },
})

-------------------
-- Look and feel --
-------------------

hl.config({
    general = {
        gaps_in          = 3,
        gaps_out         = 6,
        border_size      = 2,
        col = {
            active_border   = { colors = { "rgba(CF577Cee)", "rgba(8A2350ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        layout           = "dwindle",
    },

    decoration = {
        rounding           = 8,
        rounding_power     = 6,
        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,
        dim_special        = 0.25,

        blur = {
            enabled           = true,
            size              = 1,
            passes            = 2,
            new_optimizations = true,
            ignore_opacity    = true,
            vibrancy          = 0.16,
        },

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
    },

    group = {
        col = {
            border_active   = "rgba(CF577Cee)",
            border_inactive = "rgba(595959aa)",
        },

        groupbar = {
            enabled     = true,
            font_family = "JetBrains Mono Nerd Font",
            font_size   = 10,
            gradients   = true,
            height      = 22,
            col = {
                active   = "rgba(CF577Cff)",
                inactive = "rgba(2B2B2Bff)",
            },
            text_color  = "rgba(ffffffff)",
        },
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0 }, { 0.35, 1 } } })
hl.curve("workspaceSlide", { type = "bezier", points = { { 0.76, 0 }, { 0.24, 1 } } })

hl.animation({ leaf = "windows",          enabled = true,  speed = 2.5, bezier = "easeOutQuint",   style = "popin 92%" })
hl.animation({ leaf = "windowsOut",       enabled = true,  speed = 2,   bezier = "easeInOutCubic", style = "popin 92%" })
hl.animation({ leaf = "border",           enabled = true,  speed = 3,   bezier = "easeOutQuint" })
hl.animation({ leaf = "fade",             enabled = false })
hl.animation({ leaf = "workspaces",       enabled = true,  speed = 3,   bezier = "workspaceSlide", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true,  speed = 2.5, bezier = "easeOutQuint",   style = "slidevert" })

-------------
-- Startup --
-------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    -- Hokum notification daemon (graphical-session.target never starts under plain Hyprland).
    hl.exec_cmd("systemctl --user start hokum.service")
    hl.exec_cmd("ibus-daemon --xim --daemonize -r")
    hl.exec_cmd("~/bin/bgchange_wayland --default")
    hl.exec_cmd("systemctl --user start bgchange.timer")
    hl.exec_cmd("wlsunset -l 10.5 -L -66.8 -T 5351 -t 2000 -g 0.95")
    hl.exec_cmd("vicinae server")
    hl.exec_cmd("~/bin/desktop-shell-start")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("~/bin/battery-monitor-launcher")
    -- The IdeaPad EC's hotkey interrupt never arrives; poll it so Fn keys are delivered.
    hl.exec_cmd("~/bin/laptop-hotkey ec-poll")
end)

------------------
-- Key bindings --
------------------

local locked        = { locked = true }
local locked_repeat = { locked = true, repeating = true }

-- Basics
hl.bind(key(mod, "Return"),         hl.dsp.exec_cmd(term))
hl.bind(key(mod, "SHIFT", "Q"),     hl.dsp.window.close())
hl.bind(key(mod, "D"),              hl.dsp.exec_cmd(menu))
hl.bind(key(mod, "SHIFT", "R"),     hl.dsp.exec_cmd("hyprctl reload && ~/bin/desktop-shell-start"))
hl.bind(key(mod, "SHIFT", "E"),     hl.dsp.exit())
hl.bind(key(mod, "End"),            hl.dsp.exec_cmd("systemctl poweroff"))

-- Focus and move with Vim directions
local directions = { H = "left", J = "down", K = "up", L = "right" }
for k, dir in pairs(directions) do
    hl.bind(key(mod, k),            hl.dsp.focus({ direction = dir }))
    hl.bind(key(mod, "SHIFT", k),   hl.dsp.window.move({ direction = dir }))
end

-- Workspaces
for i = 1, 10 do
    local k = tostring(i % 10) -- 10 maps to key 0
    hl.bind(key(mod, k),            hl.dsp.focus({ workspace = i }))
    hl.bind(key(mod, "SHIFT", k),   hl.dsp.window.move({ workspace = i }))
end
hl.bind(key(mod, "Tab"),            hl.dsp.focus({ workspace = "previous" }))

-- Layout: preselect horizontal/vertical, tabbed groups, and split toggle.
hl.bind(key(mod, "B"),              hl.dsp.layout("preselect r"))
hl.bind(key(mod, "V"),              hl.dsp.layout("preselect d"))
hl.bind(key(mod, "S"),              hl.dsp.group.toggle())
hl.bind(key(mod, "E"),              hl.dsp.layout("togglesplit"))
hl.bind(key(mod, "F"),              hl.dsp.window.fullscreen())
hl.bind(key(mod, "SHIFT", "SPACE"), hl.dsp.window.float({ action = "toggle" }))
hl.bind(key(mod, "SPACE"),          hl.dsp.exec_cmd("~/bin/hypr-focus-mode-toggle"))
-- Hyprland has no nested parent containers; keep Alt+A as a tiled-window cycle.
hl.bind(key(mod, "A"),              hl.dsp.window.cycle_next({ tiled = true }))

-- Scratchpad
hl.bind(key(mod, "SHIFT", "MINUS"), hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
hl.bind(key(mod, "MINUS"),          hl.dsp.workspace.toggle_special("scratchpad"))

-- Resize mode
hl.bind(key(mod, "R"),              hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("H",      hl.dsp.window.resize({ x = -10, y = 0,   relative = true }), { repeating = true })
    hl.bind("J",      hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }), { repeating = true })
    hl.bind("K",      hl.dsp.window.resize({ x = 0,   y = -10, relative = true }), { repeating = true })
    hl.bind("L",      hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }), { repeating = true })
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Mouse move/resize, matching Sway's floating modifier.
hl.bind(key(mod, "mouse:272"),      hl.dsp.window.drag(),   { mouse = true })
hl.bind(key(mod, "mouse:273"),      hl.dsp.window.resize(), { mouse = true })

-- Volume and brightness
hl.bind("XF86AudioRaiseVolume",     hl.dsp.exec_cmd("~/bin/laptop-hotkey volume up"),         locked_repeat)
hl.bind("XF86AudioLowerVolume",     hl.dsp.exec_cmd("~/bin/laptop-hotkey volume down"),       locked_repeat)
hl.bind("XF86AudioMute",            hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), locked)
hl.bind("XF86MonBrightnessUp",      hl.dsp.exec_cmd("~/bin/laptop-hotkey brightness up"),     locked_repeat)
hl.bind("XF86MonBrightnessDown",    hl.dsp.exec_cmd("~/bin/laptop-hotkey brightness down"),   locked_repeat)

-- Laptop Fn row: mic mute, touchpad, airplane mode, camera, lock, display switch.
hl.bind("XF86AudioMicMute",         hl.dsp.exec_cmd("~/bin/laptop-hotkey mic-mute"),          locked)
hl.bind("XF86TouchpadToggle",       hl.dsp.exec_cmd("~/bin/laptop-hotkey touchpad toggle"),   locked)
hl.bind("XF86TouchpadOn",           hl.dsp.exec_cmd("~/bin/laptop-hotkey touchpad on"),       locked)
hl.bind("XF86TouchpadOff",          hl.dsp.exec_cmd("~/bin/laptop-hotkey touchpad off"),      locked)
hl.bind("XF86RFKill",               hl.dsp.exec_cmd("~/bin/laptop-hotkey airplane"),          locked)
hl.bind("XF86WLAN",                 hl.dsp.exec_cmd("~/bin/laptop-hotkey airplane"),          locked)
hl.bind("XF86WebCam",               hl.dsp.exec_cmd("~/bin/laptop-hotkey camera"))
hl.bind(key("SUPER", "L"),          hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("XF86ScreenSaver",          hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(key("SUPER", "P"),          hl.dsp.exec_cmd("~/bin/laptop-hotkey display"),           locked)
hl.bind("XF86Display",              hl.dsp.exec_cmd("~/bin/laptop-hotkey display"),           locked)

-- Screenshots
hl.bind("Print",                    hl.dsp.exec_cmd("~/.local/bin/nice-screenshots region"))  -- like Cmd+Shift+4 (Space: window)
hl.bind(key("CTRL", "Print"),       hl.dsp.exec_cmd("~/.local/bin/nice-screenshots"))         -- like Cmd+Shift+5 (toolbar)
hl.bind(key(mod, "Print"),          hl.dsp.exec_cmd("~/.local/bin/nice-screenshots screen"))  -- like Cmd+Shift+3
hl.bind(key(mod, "CTRL", "Escape"), hl.dsp.exec_cmd("~/.local/bin/nice-screenshots stop"))    -- like Cmd+Ctrl+Esc: stop recording
hl.bind(key(mod, "SHIFT", "C"),     hl.dsp.exec_cmd("~/bin/save-clipboard-picture"))
hl.bind(key(mod, "CTRL", "V"),      hl.dsp.exec_cmd("vicinae cmd launch clipboard:history"))

-- Utilities
hl.bind(key("CTRL", "SHIFT", "Escape"), hl.dsp.exec_cmd(term .. " --class htop-keybind -e htop"))
hl.bind(key(mod, "SHIFT", "B"),     hl.dsp.exec_cmd("~/bin/bgchange_wayland"))
hl.bind(key(mod, "SHIFT", "N"),     hl.dsp.exec_cmd("hokum"))

-- Close Quickshell popups when clicking outside; pass clicks to applications.
hl.bind("mouse:272",                hl.dsp.exec_cmd("qs ipc call shell checkClick"), { non_consuming = true })
hl.bind("mouse:273",                hl.dsp.exec_cmd("qs ipc call shell checkClick"), { non_consuming = true })

------------------
-- Window rules --
------------------

hl.window_rule({
    name   = "float-telegram",
    match  = { class = "^(org.telegram.desktop)$" },
    float  = true,
    center = true,
    size   = "380 504",
})

hl.window_rule({
    name   = "float-htop",
    match  = { class = "^(htop-keybind)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name    = "terminal-opacity",
    match   = { class = "^(kitty|com\\.mitchellh\\.ghostty)$" },
    opacity = "0.96 0.90",
})

hl.layer_rule({
    name         = "blur-waybar",
    match        = { namespace = "waybar" },
    blur         = true,
    ignore_alpha = 0.15,
})

hl.layer_rule({
    name         = "blur-notifications",
    match        = { namespace = "swaync.*" },
    blur         = true,
    ignore_alpha = 0.15,
})

hl.layer_rule({
    name         = "blur-vicinae",
    match        = { namespace = "vicinae" },
    blur         = true,
    ignore_alpha = 0.10,
})

-- nice-screenshots: no fade on the frozen overlay or the capture flash, blur behind its floating UI
hl.layer_rule({
    name    = "nice-screenshots-overlay",
    match   = { namespace = "^(nice-screenshots|nice-screenshots-flash)$" },
    no_anim = true,
})

hl.layer_rule({
    name         = "nice-screenshots-chrome",
    match        = { namespace = "^(nice-screenshots-(thumbnail|indicator|countdown))$" },
    blur         = true,
    ignore_alpha = 0.3,
})
