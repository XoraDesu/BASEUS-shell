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

- **DesktopHost (`DesktopHost.qml`)**: Multi-monitor Wayland layer-shell host scaffolding using Quickshell `Variants` over `Quickshell.screens` (`WlrLayershell.layer: Top`). Anchors across screen bounds with transparent background geometry, dynamically adjusting `mask: Region` to encompass only interactive elements (`topIsland.anchorItem`, `dock.hitRegionItem`). Dedicated overlay variants (`commandCenterVariants`, `appDrawerVariants`, `summonVariants`) operate on `WlrLayershell.layer: Overlay` with on-demand input grab regions, ensuring 100% click-through for idle desktop space.
- **DockAnchor (`DockAnchor.qml`) & DockModel (`DockModel.qml`) & DockItem (`DockItem.qml`)**: Edge-integrated bottom dock (`DEC-015`) flush with the bottom screen edge (`dockRadiusBottom: 0`, `dockRadiusTop: 12`) flanked by `InverseCorner` (`ICR`) fillets. Features a 1–2px bottom-edge cursor trigger strip (`triggerHeight: 2`) revealing the solid Wabi-sabi dock surface upon hover. Enforces strict separation: global pinned applications (`dock.pinnedApps` in `config/baseus.json`) persist across all workspaces, whereas unpinned running client windows appear exclusively on the workspace where they are active. Supports multi-window instance MRU cycling and window focus/raising dispatch via `WindowModel` and `HyprlandBridge`. Recedes cleanly during per-monitor native application fullscreen (`DESIGN.md` §14). Strictly contains NO search bar (`DEC-015`).
- **TopIslandAnchor (`TopIslandAnchor.qml`) & TopIslandHeader (`TopIslandHeader.qml`)**: Edge-integrated top-center solid Wabi-sabi anchor with unified C1 continuous `InverseCorner` fillets (`DEC-016`, `DEC-029`). Displays a minute-aligned typographic clock at idle without polling. Expands smoothly downward on hover (or tap) into a contextual header displaying formatted date, active session metrics (workspace number, user label, running window count), and action trigger shortcuts. During native fullscreen, recedes into a dedicated 2px top-edge notch summon surface that summons the compact clock on hover and expands the header on click.
- **CommandCenter (`CommandCenter.qml`)**: Universal search and action launcher positioned horizontally centered and slightly above vertical center (`DEC-017`). Top-to-bottom curtain reveal, dynamic fit-content height up to 520px with internal scrolling, instant input focus, and prefix routing engine:
  - `>`: direct action execution routed to `ActionRegistry` (22 core actions);
  - `?help`: quick reference and prefix syntax guide;
  - Plain text: application search with MRU tracking and enter-key launch.
- **AppDrawer (`AppDrawer.qml`), AppDrawerItem (`AppDrawerItem.qml`), AlphabetScroller (`AlphabetScroller.qml`)**: Fullscreen application discovery surface (`DEC-018`) with rounded top corners (`floatingRadius: 12`) and flush bottom edge. Smooth bottom-to-top curtain reveal. Features a persistent top search bar, initial landing state with recent/suggested applications (max 3 columns) that smoothly collapses upward upon typing, continuous dynamic catalog grid in strict fixed `A–Z–0–9–#` order without cardified headers, zero running state indicators (`DEC-018`), and right-edge 1px-to-3px alphabet fast scroller (`DEC-022`) with pointer and touch scrub jumping.
- **WorkspaceIndicator (`WorkspaceIndicator.qml`)**: Contextual workspace HUD triggered on workspace switch events, auto-hiding after ~2000ms (`DEC-029`). Employs hierarchical scaling (*"Focus grows. Context recedes."*), morphs into a compact labeled pill (`2 — WEB`) when user labels exist, updates/resets in place without animation stacking during rapid switches, and suppresses initial compositor startup discovery bursts.

### Overlay Mode Transitions & Mutual Exclusivity

Overlay surfaces (`CommandCenter`, `AppDrawer`) are governed by `ShellState.mode`:

```text
Desktop Mode ("desktop")
       │
       ├─► Super+Space / Action  ──► CommandCenter ("command-center")
       │                                     │
       │                                     ├─► Super+A / Action ──► AppDrawer ("app-drawer")
       │                                     │
       ├─► Super+A / Action      ──► AppDrawer ("app-drawer")
       │                                     │
       │                                     ├─► Super+Space      ──► CommandCenter ("command-center")
       │                                     │
       └─► navigation.back / Esc ◄───────────┴──────────────────────── Dismiss Overlay
```

- **Mutual Exclusivity:** Opening any overlay immediately and cleanly dismisses any previously active overlay without animation collision or leaked keyboard focus.
- **Universal Dismissal:** `navigation.back` (`Super+Escape`), `Escape`, or clicking outside the active surface footprint dismisses the active overlay and returns shell mode to `"desktop"`.
- **Dynamic Layer-Shell Hitmasking:** Overlays grab keyboard focus and pointer events exclusively while active; upon dismissal, their layer-shell windows are fully unmapped, restoring zero-cost desktop transparency.

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
