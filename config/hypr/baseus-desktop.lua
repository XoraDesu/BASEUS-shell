-- BASEUS — Hyprland 0.57+ Desktop Core Configuration Preset (Lua)
-- Copyright (c) 2026 xoradesu — MIT License
--
-- Implements M1 Desktop Core compositor behavior per:
--   - MASTER.md §6, §7, §9, §36, §38, §39
--   - DESIGN.md §8, §34 (Wabi-sabi solid surfaces, hairline tonal focus, no neon glow)
--   - DECISIONS.md DEC-008, DEC-010, DEC-023, DEC-038
--
-- Usage:
--   Standalone: Hyprland -c /path/to/BASEUS/config/hypr/baseus-desktop.lua
--   Modular:    dofile("/path/to/BASEUS/config/hypr/baseus-desktop.lua")

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Explicit non-overlapping 1080p geometry for headless virtual outputs (VIRTUAL-*),
-- which do not advertise physical EDID preferred modes.
for idx = 1, 4 do
    hl.monitor({
        output   = "VIRTUAL-" .. tostring(idx),
        mode     = "1920x1080@60",
        position = tostring((idx - 1) * 1920) .. "x0",
        scale    = 1,
    })
end

hl.config({
    general = {
        border_size      = 1,
        gaps_in          = 8,
        gaps_out         = 16,
        resize_on_border = true,
        allow_tearing    = false,
        col = {
            active_border   = "rgba(7aa2f7ff)",
            inactive_border = "rgba(292e42ff)",
        },
    },

    decoration = {
        rounding         = 8,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        glow = {
            enabled = false,
        },
        blur = {
            enabled = false,
        },
        shadow = {
            enabled      = true,
            range        = 8,
            render_power = 3,
            color        = "rgba(13131acc)",
        },
    },

    animations = {
        enabled              = true,
        workspace_wraparound = false,
    },

    binds = {
        allow_workspace_cycles = false,
    },

    gestures = {
        workspace_swipe_create_new = false,
        workspace_swipe_forever    = false,
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = false,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = "0x16161e",
        mouse_move_focuses_monitor = true,
    },
})

-- Controlled motion curves ("Focus grows. Context recedes." — DESIGN.md §6)
hl.curve("baseusFocus",   { type = "bezier", points = { { 0.22, 1.0 }, { 0.36, 1.0 } } })
hl.curve("baseusContext", { type = "bezier", points = { { 0.40, 0.0 }, { 0.20, 1.0 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 2.4, bezier = "baseusFocus" })
hl.animation({ leaf = "border",        enabled = true, speed = 2.0, bezier = "baseusFocus" })
hl.animation({ leaf = "windows",       enabled = true, speed = 2.2, bezier = "baseusFocus",   style = "popin 92%" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 2.2, bezier = "baseusFocus",   style = "popin 92%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.6, bezier = "baseusContext", style = "popin 94%" })
hl.animation({ leaf = "fade",          enabled = true, speed = 2.0, bezier = "baseusContext" })
hl.animation({ leaf = "layers",        enabled = true, speed = 1.8, bezier = "baseusFocus",   style = "fade" })
-- MASTER.md §7: Workspace transitions represent a context change, not physical desktop sliding.
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.8, bezier = "baseusContext", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.6, bezier = "baseusContext", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.6, bezier = "baseusContext", style = "fade" })

-- Freeform floating & centered new windows by default (MASTER.md §6, §36; DEC-008)
hl.window_rule({
    name   = "baseus-freeform-default",
    match  = { class = ".*" },
    float  = true,
    center = true,
})

-- Scratchpad-free minimized window suppression (DEC-038):
-- Minimized windows remain associated with their normal 1..10 workspace without
-- ever entering a special workspace, while becoming non-interactive and invisible.
hl.window_rule({
    name        = "baseus-minimized-hidden",
    match       = { tag = "baseus_minimized" },
    opacity     = "0.0 override",
    no_focus    = true,
    no_anim     = true,
    no_shadow   = true,
    no_blur     = true,
    border_size = 0,
})

-- 4-finger horizontal workspace navigation (MASTER.md §7, DEC-010)
hl.gesture({
    fingers   = 4,
    direction = "horizontal",
    action    = "workspace",
})

local mainMod = "SUPER"

-- Fixed 10-workspace model: Super+1..0 focus, Super+Shift+1..0 move window (DEC-010)
-- Note: No scratchpad/special workspace bindings exist (DEC-038).
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Freeform pointer drag and resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- Navigation primitives — Back / Home / Overview (DEC-024, DEC-028).
-- Binds execute registered BASEUS actions through Quickshell IPC; the action registry owns
-- action identity, so the same action can later gain other triggers (gestures, UI).
-- The BASEUS root is derived from this file's location (config/hypr/) so the IPC call targets
-- the matching Quickshell instance; if it cannot be derived, the default Quickshell config is used.
local function baseusIpcPrefix()
    local source = debug and debug.getinfo and debug.getinfo(1, "S").source or ""
    if source:sub(1, 1) == "@" then
        local root = source:sub(2):match("^(.*)/config/hypr/[^/]+$")
        if root then
            return 'quickshell ipc -p "' .. root .. '" call baseus executeAction '
        end
    end
    return "quickshell ipc call baseus executeAction "
end

local baseusAction = baseusIpcPrefix()

-- Published (global) so diagnostics can inspect the resolved IPC command prefix:
--   hyprctl eval 'return BASEUS_ACTION_IPC'
BASEUS_ACTION_IPC = baseusAction

-- Primary Surfaces & Session (M2/M5, DEC-028)
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(baseusAction .. "surface.app_drawer"),      { description = "BASEUS App Drawer" })
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(baseusAction .. "surface.command_center"),  { description = "BASEUS Command Center" })
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(baseusAction .. "surface.session_menu"),    { description = "BASEUS Session Menu" })
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd(baseusAction .. "system.lock"),             { description = "BASEUS Lock Screen" })

-- Navigation primitives — Back / Home / Overview (DEC-024, DEC-028)
hl.bind("ALT + Left",           hl.dsp.exec_cmd(baseusAction .. "navigation.back"),         { description = "BASEUS Back" })
hl.bind(mainMod .. " + H",      hl.dsp.exec_cmd(baseusAction .. "navigation.home"),         { description = "BASEUS Home" })
hl.bind(mainMod .. " + Tab",    hl.dsp.exec_cmd(baseusAction .. "navigation.overview"),     { description = "BASEUS Overview" })

-- Hardware / Media / Volume / Brightness function keys (M3/M5)
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd(baseusAction .. "media.toggle"),        { description = "Media Play/Pause" })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd(baseusAction .. "media.next"),          { description = "Media Next" })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd(baseusAction .. "media.previous"),      { description = "Media Previous" })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(baseusAction .. "audio.volume_up"),    { description = "Volume Up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(baseusAction .. "audio.volume_down"),  { description = "Volume Down" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(baseusAction .. "audio.mute"),         { description = "Toggle Mute" })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(baseusAction .. "brightness.up"),      { description = "Brightness Up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(baseusAction .. "brightness.down"),    { description = "Brightness Down" })
