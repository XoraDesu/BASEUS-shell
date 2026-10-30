# BASEUS — Development Guide

## Requirements

- Linux
- [Hyprland](https://hyprland.org/)
- [Quickshell](https://quickshell.outfoxxed.me/)
- Qt 6 (QML runtime)

---

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/XoraDesu/BASEUS-shell.git
cd BASEUS-shell
```

### Launch BASEUS

BASEUS runs as a Quickshell shell:

```bash
quickshell -p .
```

Or set it as your default shell in your Hyprland configuration:

```lua
-- ~/.config/hypr/hyprland.lua (Hyprland 0.57+)
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -p /path/to/BASEUS")
end)
```

```ini
# ~/.config/hypr/hyprland.conf (Hyprland < 0.57)
exec-once = quickshell -p /path/to/BASEUS
```

### Reload, Restart, and Diagnostics During Development

Quickshell automatically watches project QML files and hot-reloads changes. You can also control and inspect a running BASEUS instance via Quickshell IPC:

```bash
quickshell ipc -p . call baseus status              # Inspect runtime state JSON
quickshell ipc -p . call baseus restart             # Trigger deterministic Lifecycle restart
quickshell ipc -p . call baseus switchWorkspace 2   # Dispatch workspace switch (1-10)
quickshell log -p .                                 # Inspect shell logs
quickshell kill -p .                                # Stop running instance
```

To run with the offline simulation bridge (`MockHyprlandBridge`) when a live Hyprland compositor is unavailable:

```bash
BASEUS_SIMULATION=1 quickshell -p .
```

---

## Project Structure

```text
BASEUS/
├── shell.qml              # Quickshell entrypoint
├── src/
│   ├── Shell.qml           # Root shell component
│   └── core/               # Foundation architecture
│       ├── Lifecycle.qml    # Shell lifecycle
│       ├── ShellState.qml   # Central state
│       ├── EventBus.qml     # Event bus
│       ├── HyprlandBridge.qml     # Hyprland integration
│       ├── MockHyprlandBridge.qml # Offline simulation bridge
│       ├── WorkspaceModel.qml     # Workspace state
│       ├── WindowModel.qml        # Window state
│       ├── MonitorModel.qml       # Monitor state
│       ├── Config.qml             # Configuration
│       └── Logger.qml             # Diagnostics
│   ├── theme/                     # Design tokens (DESIGN.md)
│   │   ├── Theme.qml              # Unified theme root
│   │   ├── Colors.qml             # 4-color palette & tonal roles
│   │   ├── Typography.qml         # Font families & scale
│   │   ├── Spacing.qml            # Whitespace scale & padding
│   │   ├── Geometry.qml           # Radii & inverse corners (ICR)
│   │   ├── Motion.qml             # Durations & easing curves
│   │   └── InverseCorner.qml      # ICR concave corner component
│   └── dev/                       # Visual design & testbed tools
│       └── DesignStage.qml        # Visual testbed (Dock, Island, ICR)
├── config/
│   └── baseus.json                # Default configuration
├── docs/                          # Documentation
└── scripts/
    ├── validate.sh                # Validation script (Linux)
    └── validate.ps1               # Validation script (Windows)
```

---

## Validation

### Static Validation

Run the validation script:

```bash
./scripts/validate.sh
```

On Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate.ps1
```

Options (bash):

```bash
./scripts/validate.sh --structure  # Check project structure
./scripts/validate.sh --qml        # QML syntax (requires qmllint)
./scripts/validate.sh --config     # Configuration validity
./scripts/validate.sh --all        # All checks (default)
```

### Runtime Validation

Runtime validation requires a live Linux + Hyprland environment.

Key checks:
- Shell launches via `quickshell -p .`
- Shell lifecycle (start/stop/restart) works correctly
- Workspace switching produces events
- Window creation/destruction is tracked
- Monitor changes are observed
- Configuration loads correctly
- Logs are produced at expected levels

---

## Source of Truth

Before making changes, read the relevant documentation:

| Document | Purpose |
|---|---|
| `MASTER.md` | Product definition |
| `DESIGN.md` | Visual and interaction design |
| `ANTI-SLOP.md` | Design quality system |
| `DECISIONS.md` | Accepted decisions |
| `ROADMAP.md` | Development sequence |
| `TASKS.md` | Current executable scope |
| `STATE.md` | Current project state |
| `AGENTS.md` | Agent operating protocol |

---

## Environment Limitations

When developing on a system without a live Hyprland session:

- **Windows / macOS (non-Linux):**
  - Static validation (`scripts/validate.ps1` or `scripts/validate.sh`) and JSON configuration checks can run.
  - Runtime behavior cannot be validated; mark runtime items `UNVERIFIED` in `STATE.md`.
- **Linux / WSL2 Wayland:**
  - Static validation and Qt 6 `qmllint` checks can run.
  - Quickshell runtime startup, lifecycle (`start` / `restart` / `stop`), configuration loading/fallback, `EventBus` delivery, `baseus` IPC diagnostics, unavailable-Hyprland graceful reporting, and offline simulation (`BASEUS_SIMULATION=1`) run directly on WSLg (`wayland-0`).
  - Live `Hyprland 0.57+` (`Aquamarine`) compositor IPC can run in WSL2 without root privileges by hosting a minimal nested Wayland `zwp_linux_dmabuf_v1` display advertising `/dev/dri/renderD128` (`AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`) with a headless virtual output (`hyprctl output create headless VIRTUAL-1`). Physical multi-monitor DRM scanout and hardware GPU performance measurements still require a native Linux desktop session.
