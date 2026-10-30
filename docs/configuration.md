# BASEUS — Configuration

## Overview

BASEUS uses a layered configuration system. Configuration defines **intended behavior and persistent preferences**. It does not store runtime state or visual theme state.

---

## Configuration File

User configuration: `~/.config/baseus/baseus.json`

Default configuration: `config/baseus.json` (in the project)

---

## Configuration Structure

```json
{
    "baseus": {
        "shell": {
            "logLevel": "info"
        },
        "dock": {
            "triggerHeight": 2,
            "revealDuration": 200,
            "showLauncher": true
        },
        "topIsland": {
            "idleTimeout": 2000
        },
        "notifications": {
            "timeout": 3000,
            "position": "top-left"
        },
        "commandCenter": {
            "defaultPrefix": "",
            "actionPrefix": ">"
        },
        "workspaces": {
            "labels": {
                "1": "HOME",
                "2": "DEV",
                "7": "MEDIA"
            },
            "tags": {
                "1": "01",
                "2": "CODE"
            }
        },
        "performance": {
            "reducedMotion": false,
            "animationDuration": 250
        },
        "simulation": {
            "enabled": false
        }
    }
}
```

---

## Loading Order

1. **Built-in defaults** — hardcoded in `Config.qml`
2. **Project/system config** — `config/baseus.json` if present
3. **User config** — `~/.config/baseus/baseus.json` (or explicit path in `$BASEUS_CONFIG_PATH`)
4. **Runtime environment overrides** — `$BASEUS_SIMULATION` (`1`/`true` or `0`/`false`) and `$BASEUS_LOG_LEVEL` (`debug`/`info`/`warn`/`error`), not persisted

Each layer overrides individual values from the previous layer. Missing values use the built-in default.

---

## Configuration Boundaries

### Configuration IS

- Static behavior preferences
- User-defined workspace labels
- Notification timeout
- Animation preferences
- Log level
- Dock trigger sensitivity

### Configuration IS NOT

- Runtime state (which workspace is active)
- Transient UI state (is OSD visible)
- Theme visual state (wallpaper, palette, widget arrangement)
- Window positions

---

## Invalid Configuration

If configuration is malformed:

1. The invalid file is reported in logs
2. Built-in defaults are used as fallback
3. The shell continues to operate normally

BASEUS should never fail to start due to a configuration error.

---

## Settings Reference

| Setting | Default | Range | Description |
|---|---|---|---|
| `shell.logLevel` | `"info"` | debug, info, warn, error | Logging verbosity |
| `dock.triggerHeight` | `2` | 1–10 px | Bottom-edge trigger region |
| `dock.revealDuration` | `200` | ms | Dock reveal animation duration |
| `dock.showLauncher` | `true` | bool | Show BASEUS launcher in Dock |
| `topIsland.idleTimeout` | `2000` | ms | Secondary info hide delay |
| `notifications.timeout` | `3000` | ms | Default notification display time |
| `notifications.position` | `"top-left"` | string | Notification placement |
| `performance.reducedMotion` | `false` | bool | Reduce animation for accessibility |
| `performance.animationDuration` | `250` | 0–2000 ms | Default animation duration |
| `workspaces.labels` | `{}` | key-value map (`1..10` → string) | User-defined workspace names (e.g. `{"1": "HOME", "2": "DEV"}`) |
| `workspaces.tags` | `{}` | key-value map (`1..10` → string) | Compact alphanumeric indicators (e.g. `{"1": "01", "2": "CODE"}`) |

> [!IMPORTANT]
> BASEUS strictly enforces a fixed 10-workspace model (`DEC-010`). Any attempt to set `workspaces.count` in configuration is rejected and logged with a warning.

---

## Hyprland Configuration Presets (`config/hypr/`)

BASEUS provides authoritative compositor presets matching the desktop core architecture:

- **`config/hypr/baseus-desktop.lua`**: Modern Lua configuration preset for Hyprland `0.57.0+`. Configures 25 keybinds (22 workspace/window binds + `Super+Escape` Back, `Super+D` Home, `Super+Tab` Overview via Quickshell IPC), 4-finger horizontal workspace gestures (`hl.gesture`), non-wrapping workspace transitions with `fade` context animation (`MASTER.md` §7), default freeform floating + centered window placement (`DEC-008`), `baseus-minimized-hidden` rule suppressing minimized windows without scratchpads (`DEC-038`), and 1px solid tonal borders without blur or neon glow (`DESIGN.md` §34).
- **`config/hypr/baseus-desktop.conf`**: Hyprlang reference preset maintained for compatibility and cross-version audit.
