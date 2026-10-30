# BASEUS — Architecture

## Overview

BASEUS is a Quickshell-based desktop shell for Linux + Hyprland. The architecture follows a **Foundation → Capability → Surface** development model.

---

## Runtime Stack

```text
┌─────────────────────────────────────┐
│           BASEUS Shell              │
│  ┌──────────────────────────────┐   │
│  │        Surfaces              │   │
│  │  (Dock, Top Island, etc.)    │   │
│  ├──────────────────────────────┤   │
│  │     State / Events           │   │
│  │  ShellState · EventBus       │   │
│  ├──────────────────────────────┤   │
│  │   Domain Models              │   │
│  │  Workspace · Window · Monitor│   │
│  ├──────────────────────────────┤   │
│  │   Integration Boundary       │   │
│  │     HyprlandBridge           │   │
│  ├──────────────────────────────┤   │
│  │   Foundation                 │   │
│  │  Lifecycle · Config · Logger │   │
│  └──────────────────────────────┘   │
├─────────────────────────────────────┤
│         Quickshell Runtime          │
├─────────────────────────────────────┤
│      Hyprland (Wayland Compositor)  │
├─────────────────────────────────────┤
│              Linux                  │
└─────────────────────────────────────┘
```

---

## Core Components

### shell.qml

Quickshell entrypoint. Loads the root `Shell` component.

### src/Shell.qml

Root composition. Instantiates all foundation singletons in dependency order:

1. **Logger** — diagnostics (no dependencies)
2. **Config** — configuration loading (no dependencies)
3. **Lifecycle** — init/teardown/restart (depends on Logger, Config)
4. **ShellState** — central state (depends on Logger)
5. **EventBus** — event architecture (depends on Logger)
6. **HyprlandBridge / MockHyprlandBridge** — Hyprland integration boundary with offline simulation support (depends on Logger, EventBus, ShellState)
7. **MonitorModel** — monitor tracking (depends on Logger, EventBus)
8. **WorkspaceModel** — workspace tracking (depends on Logger, EventBus)
9. **WindowModel** — freeform window tracking (depends on Logger, EventBus)
10. **ActionRegistry** (`src/core/ActionRegistry.qml`) — Discover → Customize → Execute action boundary (`DEC-028`)
11. **NavigationController** (`src/core/NavigationController.qml`) — `Back` / `Home` / `Overview` navigation primitives (`DEC-024`)
12. **Theme** — unified design tokens (Colors, Typography, Spacing, Geometry, Motion)
13. **DesktopHost** (`src/desktop/DesktopHost.qml`) — per-monitor layer-shell scaffolding hosting `TopIslandAnchor` and `WorkspaceIndicator`
14. **Diagnostic IPC (`IpcHandler`)** — Quickshell IPC target `baseus` exposing diagnostic and automation endpoints (`status`, `restart`, `switchWorkspace`, `switchMonitorWorkspace`, `nextWorkspace`, `previousWorkspace`, `workspaces`, `windows`, `focusWindow`, `closeWindow`, `centerWindow`, `moveWindow`, `resizeWindow`, `toggleFloating`, `toggleMaximize`, `toggleFullscreen`, `minimizeWindow`, `restoreWindow`, `moveWindowToWorkspace`, `moveWindowToMonitor`, `listActions`, `getAction`, `shortcutOwners`, `executeAction`, `executeActionWithPayload`, `desktopSurfaces`, `triggerWorkspaceIndicator`, `setWorkspaceLabel`)

---

## Desktop Surfaces Architecture (`src/desktop/`)

BASEUS introduces desktop visual surfaces following the **Capability → Surface** pattern (`DEC-045`):

- **DesktopHost (`DesktopHost.qml`)**: Multi-monitor Wayland layer-shell host scaffolding using Quickshell `Variants` over `Quickshell.screens` and `WlrLayershell.layer: Top`. It anchors across screen bounds, maintains transparent background geometry, and constrains the layer-shell input region strictly to interactive surface bodies (`mask: Region { item: topIsland.anchorItem }`), guaranteeing 100% click-through for idle desktop space.
- **TopIslandAnchor (`TopIslandAnchor.qml`)**: Edge-integrated top-center solid Wabi-sabi idle anchor (`islandRadiusTop: 0`, `islandRadiusBottom: 12`) flanked by `InverseCorner` (`ICR`) organic fillets. Displays a quiet typographic clock updated on minute boundaries without polling, and recedes (`visible: false`) during per-monitor native application fullscreen (`DESIGN.md` §14).
- **WorkspaceIndicator (`WorkspaceIndicator.qml`)**: Contextual workspace HUD triggered on workspace switch events, auto-hiding after ~2000ms (`DEC-029`). Employs hierarchical scaling (*"Focus grows. Context recedes."*), morphs into a compact labeled pill (`2 — WEB`) when user labels exist, updates/resets in place without animation stacking during rapid switches, and suppresses initial compositor startup discovery bursts.

---

## Design Token Architecture (`src/theme/`)

The design system implements the visual language defined in `DESIGN.md` and `ANTI-SLOP.md`:

- **Colors (`Colors.qml`)**: Four main colors (`dominant`, `secondary`, `accent`, `neutral`) per `DEC-011`, with a strict tonal hierarchy for solid surfaces, legible text, and hairline boundaries.
- **Typography (`Typography.qml`)**: Editorial and archival influence. Functional scale (`display` through `micro`) with separate UI sans and monospaced telemetry font families.
- **Spacing (`Spacing.qml`)**: Mathematical whitespace scale (`xxs` through `giant`) prioritizing breathing room over nested containers.
- **Geometry (`Geometry.qml`)**: Controlled radii (`small`, `medium`, `large`, `pill`) and Inverse Corner Radius (`ICR`) for edge-integrated surfaces (Dock, Top Island).
- **Motion (`Motion.qml`)**: Restrained durations (`fast`, `normal`, `slow`, `theme`) with "Focus grows, context recedes" scale/opacity tokens and reduced motion support.

---

## State Architecture

### Principles

- Each state domain has a single owner
- Consumers read state; they do not maintain copies
- Transient state (OSD visible, notification visible) is runtime-only
- Persistent state (workspace labels, config) survives restart
- Derived state is computed, not duplicated

### State Flow

```text
Hyprland IPC Event
       ↓
HyprlandBridge (normalization)
       ↓
EventBus.emit("category", data)
       ↓
Domain Model (state update)
       ↓
QML Property Binding (UI update)
```

---

## Event Architecture

### Categories

| Category | Examples |
|---|---|
| lifecycle | shell start, stop, restart |
| monitor | added, removed, focused |
| workspace | switched, activated |
| window | created, destroyed, focused, fullscreen |
| input | action triggered |
| system | volume, brightness |
| media | track change, play/pause |
| theme | palette changed |
| config | configuration reloaded |

### Subscription Model

- Keyed by subscriber ID — prevents duplicates
- Per-subscriber unsubscribe-all for clean restart
- Handler failures are isolated — one failure doesn't block others
- Diagnostic introspection available

---

## Hyprland Integration

The `HyprlandBridge` isolates all Hyprland-specific communication:

```text
Hyprland IPC → HyprlandBridge → Normalized Events → EventBus → Consumers
```

Surfaces never communicate directly with Hyprland IPC. They consume state from domain models and receive events from EventBus.

### Runtime Assumptions

- Hyprland is running and accessible via IPC
- `hyprctl` is available for queries
- Hyprland event socket (socket2) is available
- Quickshell.Hyprland module provides built-in integration

---

## Configuration

### Loading Order

1. Built-in defaults (hardcoded in `Config.qml`)
2. Project/system config (`config/baseus.json` loaded synchronously via `Quickshell.Io` `FileView`)
3. User config (`~/.config/baseus/baseus.json`, or explicit override via `$BASEUS_CONFIG_PATH`)
4. Runtime environment overrides (`$BASEUS_SIMULATION`, `$BASEUS_LOG_LEVEL` — transient, not persisted)

### Boundaries

- **Static configuration**: intended behavior, persistent preferences
- **Runtime state**: current transient condition
- **Theme visual state**: visual appearance (never stores behavior)

---

## Diagnostics

Structured logging with levels:

| Level | Purpose |
|---|---|
| DEBUG | Detailed subsystem tracing |
| INFO | Normal operation milestones |
| WARN | Unexpected but recoverable conditions |
| ERROR | Failures requiring attention |

Format: `TIMESTAMP [LEVEL] [Subsystem] Message`

Default level: `INFO` — quiet during idle, informative during operation.
