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
12. **NotificationModel** (`src/core/NotificationModel.qml`) — notification domain model and FreeDesktop DBus ingestion (`DEC-020`)
13. **AudioService** (`src/core/AudioService.qml`) — PipeWire / WirePlumber audio/volume and brightness feedback service (`DEC-021`)
14. **MediaService** (`src/core/MediaService.qml`) — Linux MPRIS media player session tracking and control service (`DEC-026`, `DEC-039`)
15. **StatusService** (`src/core/StatusService.qml`) — event-driven system status, power/battery, network, and subsystem health model (`MASTER.md` §9, `ANTI-SLOP.md` §6.7–6.8)
16. **Theme** — unified design tokens (Colors, Typography, Spacing, Geometry, Motion)
17. **DesktopHost** (`src/desktop/DesktopHost.qml`) — per-monitor layer-shell scaffolding hosting `TopIslandAnchor`, `WorkspaceIndicator`, `DockAnchor`, `NotificationHost`, `MediaWidget`, and overlay summon surfaces
18. **Diagnostic IPC (`IpcHandler`)** — Quickshell IPC target `baseus` exposing diagnostic and automation endpoints (`status`, `restart`, `switchWorkspace`, `switchMonitorWorkspace`, `nextWorkspace`, `previousWorkspace`, `workspaces`, `windows`, `focusWindow`, `closeWindow`, `centerWindow`, `moveWindow`, `resizeWindow`, `toggleFloating`, `toggleMaximize`, `toggleFullscreen`, `minimizeWindow`, `restoreWindow`, `moveWindowToWorkspace`, `moveWindowToMonitor`, `listActions`, `getAction`, `shortcutOwners`, `executeAction`, `executeActionWithPayload`, `desktopSurfaces`, `triggerWorkspaceIndicator`, `setWorkspaceLabel`, `dockItems`, `clickDockItem`, `revealDock`, `hideDock`, `topIslandState`, `setTopIslandHover`, `tapTopIsland`, `clickTopIslandTrigger`, `toggleCommandCenter`, `openCommandCenter`, `closeCommandCenter`, `commandCenterState`, `commandCenterInput`, `commandCenterExecute`, `toggleAppDrawer`, `openAppDrawer`, `closeAppDrawer`, `appDrawerState`, `appDrawerSearch`, `appDrawerScrub`, `appDrawerLaunch`, `postNotification`, `dismissNotification`, `silenceNotifications`, `notificationState`, `osdState`, `triggerVolumeOsd`, `triggerBrightnessOsd`, `mediaStatus`, `mediaPlay`, `mediaPause`, `mediaToggle`, `mediaNext`, `mediaPrevious`, `mediaSeek`, `mediaWidgetState`, `toggleMediaWidget`, `bongoCatState`, `systemStatus`, `setMockBattery`, `setMockNetwork`)

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

## System Feedback Architecture (Milestone M3)

Milestone M3 establishes calm, contextual, event-driven feedback across four primary domains (`DEC-045` Capability → Surface pattern):

### 1. Notifications Domain (`NotificationModel.qml`, `NotificationHost.qml`, `NotificationItem.qml`)
- **Placement & Visual Language (`DEC-020`):** Floating top-left placement (`anchors.top: true`, `anchors.left: true`) with left-to-right curtain reveal. Features a large 70% icon backdrop, solid Wabi-sabi tonal surface (`colors.surfaceSolid` + 1px `borderSubtle`), and zero nested cardification (`ANTI-SLOP.md` §20).
- **Hold-to-Silence Feedback (`DESIGN.md` §18):** Pointer long-press (~1200ms) initiates a smooth left-to-right tonal progress fill, silencing the notification subsystem, dismissing all pending items, and providing calm "Notifications silenced" feedback without alarming error styling.
- **Dynamic Hitmasking:** Precise Layer-Shell input mask contracts to `0x0` whenever no notifications are active, maintaining 100% click-through idle desktop transparency.
- **Interaction:** Hover pauses dismiss timer; double-click dismisses immediately; single-click on action buttons executes callback and dismisses.

### 2. Audio & Brightness OSD Subsystem (`AudioService.qml`, `TopIslandOsd.qml`)
- **Spatial Origin (`DEC-021`):** Audio volume and display brightness OSD drops geometrically from the bottom notch of `TopIslandAnchor.qml`.
- **Bubble-Drop & Morphing:** Smooth downward expansion communicating state (`Theme.motion.fast`), auto-hiding after ~1800ms. Rapid successive keypresses morph the value and progress bar in place without animation pile-up or stacking (`AGENTS.md` §20).
- **Zero-Block Hitmask:** Configured with `mask: Region {}` (empty hitmask), guaranteeing 100% non-blocking click-through passthrough so OSD reveals never intercept window interactions.
- **PipeWire / WirePlumber:** Integrated via `Quickshell.Services.Pipewire` with deterministic offline simulation fallback for headless / WSL2 environments.

### 3. Media Player Architecture (`MediaService.qml`, `TopIslandMedia.qml`, `MediaWidget.qml`, `BongoCatCompanion.qml`, `LyricsContainer.qml`)
- **MPRIS Integration:** Centralized playback tracking via `Quickshell.Services.Mpris` (title, artist, album, duration, position, playback status, seek, multi-session switching).
- **Strict Notification Suppression (`DEC-039`):** Track and playback changes strictly NEVER generate generic desktop notification spam.
- **Top Island Compact Integration (`TopIslandMedia.qml`):** Calm, compact surface integrated inside the expanded Top Island header with fixed 328x38px dimensions, eliminating dynamic layout resizing jitter.
- **Dedicated Desktop Media Widget (`MediaWidget.qml`):** Dual-state desktop widget:
  - **Compact State (`idle` / `paused`):** Minimal 108px footprint with essential track info, play/pause toggle, and compact progress bar.
  - **Expanded State (`playing`):** Auto-expands smoothly to 254px revealing track navigation (previous, seek -10, play/pause, seek +10, next), interactive seek slider, session selector, and structural lyrics slot (`LyricsContainer.qml`).
- **Bongo Cat Companion (`BongoCatCompanion.qml`):** Vector-shaped visual companion reacting contextually to playback tempo with alternating paw tapping while playing. Implements zero-CPU idle timer gating (`ANTI-SLOP.md` §37): when music is paused or idle, the internal animation timer is completely halted (`running: false`).

### 4. System Status & Diagnostic Architecture (`StatusService.qml`)
- **Quiet Telemetry (`ANTI-SLOP.md` §6.7–6.8):** Strictly NO permanent dashboard cockpit, NO decorative CPU/RAM graphs, NO sci-fi dials. Status remains calm and discoverable on hover inside `TopIslandHeader.qml`.
- **Battery & Power Monitoring:** Tracks percentage, charging status, low-battery threshold ($\le 20\%$), and critical threshold ($\le 10\%$). Dispatches a non-intrusive alert via `NotificationModel` when low while discharging, with automatic state deduplication and charging recovery.
- **Network Connectivity:** Tracks connection state, interface type (wifi, ethernet, offline), and SSID label.
- **Subsystem Health:** Monitors live status across HyprlandBridge, AudioService, and MediaService.

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
