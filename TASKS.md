# TASKS.md

**Project:** BASEUS  
**Document role:** Current executable work tracker  
**Rule:** This document describes only the active phase. Future roadmap work does not belong here.

---

# 1. Purpose

`TASKS.md` converts the current `ROADMAP.md` phase into executable work.

It answers:

> **What are we actually doing right now?**

It is intentionally narrower than `ROADMAP.md`.

The roadmap describes the project sequence.

This file describes the current execution boundary.

---

# 2. Current Execution Model

The active development flow is:

```text
ROADMAP
   ↓
Current Phase (M1 — Desktop Core / Desktop Foundation)
   ↓
TASKS.md
   ↓
Implementation (Capability → Surface)
   ↓
Validation (Static + Live Runtime + Anti-Slop)
   ↓
STATE.md
   ↓
CHECKPOINT.md
```

Only tasks inside the active phase are normally executable.

M0 Foundation architecture is now protected under **Foundation Freeze** (`DEC-043`). M1 work must extend M0 subsystems (`Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, domain models, and `HyprlandBridge` / `MockHyprlandBridge`) rather than recreating parallel state or event systems.

---

# 3. Current Phase

## Milestone

**M1 — Desktop Core** (*`ROADMAP.md` §8: `M1 — Desktop Foundation`*)

## Phase

**M1 — Desktop Core**

## Phase Goal

Establish the core desktop, workspace, freeform window-management, navigation, and minimal foundational surface capabilities that all later BASEUS surfaces depend on, preserving a quiet Wabi-sabi idle desktop (`MASTER.md` §9), solid palette-derived surfaces (`DESIGN.md` §8), contextual motion (*"Focus grows. Context recedes."*), and freeform-first window agency (`DEC-008`).

---

# 4. Phase Scope

### IN SCOPE

- **Workspace capability (`MASTER.md` §7, §39; `DEC-010`):**
  - Fixed 10-workspace model (`1..10`); workspace count cannot be changed.
  - Per-monitor workspace state (`activeWorkspaces` and `previousWorkspaces` per monitor index, monitor-hotplug reconciliation, and workspace occupancy derived from `WindowModel`).
  - User-defined optional workspace labels and tags (`labels`, `tags`).
  - Direct workspace navigation (`1..10`, `Super+1` through `Super+0`) and bounded relative navigation (`nextWorkspace` / `previousWorkspace`, `4-finger swipe left/right` where platform input hardware permits).
  - BASEUS Hyprland desktop core configuration presets (`config/hypr/baseus-desktop.lua` for Hyprland `0.57+` Lua config manager and `config/hypr/baseus-desktop.conf` for legacy Hyprlang `< 0.57`).
- **Freeform window capability (`MASTER.md` §6, §35, §36, §38; `DESIGN.md` §34; `DEC-008`, `DEC-009`, `DEC-023`, `DEC-038`):**
  - Freeform floating windows by default, centered new-window placement, and overlap as a valid desktop state (no forced tiling).
  - Window geometry (`x`, `y`, `width`, `height`) and per-monitor state tracking.
  - Explicit distinction between **maximize** (literal workspace/screen occupation, Hyprland fullscreen mode `1`) and **native application fullscreen** (Hyprland fullscreen mode `0`, causing shell chrome on that monitor to recede per `DESIGN.md` §14).
  - **Minimize & centered restore** without exposing a scratchpad mental model (`DEC-038`, `MASTER.md` §36).
  - Window movement between workspaces (`1..10`) and normalized POP-style workspace-move transition event hooks (`MASTER.md` §35).
- **Navigation capability (`MASTER.md` §8, §34; `DEC-024`, `DEC-028`):**
  - Action identity decoupled from keyboard/gesture/UI triggers (`ActionRegistry` foundation: `Discover → Customize → Execute`).
  - Desktop context and `Back` / `Home` / `Overview` mental-model primitives (`NavigationController`).
- **Core layout scaffolding & minimal foundational desktop surfaces (`MASTER.md` §9, §11, §12, §39; `DESIGN.md` §5–14, §26–28; `ANTI-SLOP.md`; `DEC-002`, `DEC-004`, `DEC-006`, `DEC-029`):**
  - Per-monitor Quickshell Wayland Layer-Shell desktop overlay host (`src/surfaces/DesktopHost.qml`) with zero-cost click-through idle behavior and per-monitor native fullscreen recession (`DESIGN.md` §14).
  - **Contextual Workspace Indicator** (`src/surfaces/WorkspaceIndicator.qml`): completely hidden at idle, appearing transiently (~2 seconds) on the affected monitor when switching workspaces, using solid Wabi-sabi palette surfaces, hierarchical scaling (`previous` shrinks/recedes, `current` grows/focuses), optional compact pill morph (`2 — WEB`) when a workspace label exists, and in-place morphing on rapid switches (`AGENTS.md` §20).
  - **Minimal Top Island Idle Anchor Foundation** (`src/surfaces/TopIslandAnchor.qml`): quiet top-center edge-integrated solid Wabi-sabi anchor with organic `InverseCorner` (`ICR`) fillets showing only calm typographic time at idle (`MASTER.md` §9) and receding during native fullscreen (`DESIGN.md` §14).

---

# 5. Phase Non-Goals

### OUT OF SCOPE

The following belong to future milestones in `ROADMAP.md` and must **not** be implemented in M1:

- Dock surface, 1–2 px bottom-edge cursor trigger, and pixel/curtain reveal (`M2`);
- Full Top Island hover expansion, active status expansion, and quick controls (`M2`);
- Command Center and prefix routing (`M2`);
- App Drawer and category/app grid (`M2`);
- Notifications, OSD, and Media / Bongo Cat surfaces (`M3`);
- Wallpaper runtime, Matugen extraction pipeline, Theme presets, Widgets, and Headquarter (`M4`);
- Full Helicopter View / Overview UI, Alt+Tab switcher UI, and smart snap/grid arrangement (`M5`);
- Power Menu constellation, sleeping chibi, and personality choreography (`M6`);
- Multi-distro installer, updater, uninstaller, and doctor CLI (`M7`);
- Performance benchmarking and release freeze (`M8`–`M9`).

---

# 6. Dependencies

M1 depends on:

- **Verified M0 Foundation (`CP-M0-001` `VERIFIED`, commit `9a37a1420dd702ed8fe4d1ed036016d1732f60ea`):** `Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, `MonitorModel`, `WorkspaceModel`, `WindowModel`, `HyprlandBridge`, `MockHyprlandBridge`, and `src/theme/*` design tokens;
- **Locked Source of Truth:** `MASTER.md`, `DESIGN.md`, `ANTI-SLOP.md`, `DECISIONS.md`, `ROADMAP.md`, and `AGENTS.md`;
- **Runtime & Tooling:** `Quickshell 0.3.2`, Qt 6 (`qmllint 6.12.0`), and live `Hyprland 0.57.0` (`Aquamarine 0.15.1`) in WSL2 Arch Linux.

---

# 7. Implementation Order & Atomic Task Breakdown

Per `DEC-045` (*Capability-to-Surface Implementation*) and `AGENTS.md` §11 (*Smallest coherent change*), M1 executes in six atomic tasks:

```text
M1-T1 (Workspace Capability & Hyprland Preset)
  ↓
M1-T2 (Freeform Window Capability: Maximize/Fullscreen, Minimize/Centered-Restore)
  ↓
M1-T3 (Action Registry & Back/Home/Overview Navigation Primitives)
  ↓
M1-T4 (Per-Monitor Wayland Layer-Shell Desktop Host Scaffolding)
  ↓
M1-T5 (Contextual Workspace Indicator & Minimal Top Island Idle Anchor)
  ↓
M1-T6 (M1 Multi-Monitor E2E Validation, Anti-Slop Audit & Checkpoint CP-M1-001)
```

---

## Task M1-T1 — Workspace Capability, Per-Monitor Navigation & Hyprland Desktop Preset

**Goal:** Complete the fixed 10-workspace per-monitor capability layer, relative/direct navigation commands, workspace occupancy/history queries, and authoritative BASEUS Hyprland desktop core configuration presets.

### Sub-tasks

- [x] Extend `src/core/Config.qml` and `config/baseus.json` to support optional `workspaces.tags` (`workspaceTags`) alongside `workspaces.labels` (`MASTER.md` §7) while keeping `workspaceCount` locked at `10` (`DEC-010`).
- [x] Enhance `src/core/WorkspaceModel.qml` with per-monitor `previousWorkspaces` tracking, optional `tags` (`getTag` / `setTag`), bounded `1..10` relative stepping (`getRelativeWorkspace`, `canStepWorkspace`), `WindowModel`-derived occupancy queries (`getWindowCount`, `getSnapshot`), monitor-hotplug reconciliation, and normalized `{ source: "model", type: "changed", monitorIndex, previous, current, label, tag }` `EventBus` emission.
- [x] Enhance `src/core/HyprlandBridge.qml` with direct `.socket.sock` `j/monitors` synchronization (`Quickshell.Io.Socket` + `SplitParser`, zero child processes, compatible with `Hyprland 0.57+` monitor JSON), name-based monitor index resolution across `.socket2.sock` `focusedmon`/`focusedmonv2`/`moveworkspace`/`moveworkspacev2`/`monitoradded`/`monitorremoved` events, and monitor-targeted `focusMonitor`, `switchWorkspace(workspaceId, monitorIndex)`, `switchWorkspaceRelative(delta, monitorIndex)`, `nextWorkspace(monitorIndex)`, and `previousWorkspace(monitorIndex)` supporting both `Hyprland.usingLua` (`0.57+`) and legacy Hyprlang (`< 0.57`).
- [x] Upgrade `src/core/MockHyprlandBridge.qml` for multi-monitor simulation parity (`activeWorkspaces` per monitor, `setMockMonitorCount`, `focusMonitor`, `switchWorkspaceRelative`, `nextWorkspace`, `previousWorkspace`, `moveWindowToWorkspace`) without injecting unconfigured fake workspace labels.
- [x] Wire new model/bridge references and diagnostic IPC methods (`nextWorkspace`, `previousWorkspace`, `switchMonitorWorkspace`, `workspaces`) in `src/Shell.qml`.
- [x] Create `config/hypr/baseus-desktop.lua` (`Hyprland 0.57+` Lua) and `config/hypr/baseus-desktop.conf` (`< 0.57` Hyprlang reference) encoding `Super+1..0`, `Super+Shift+1..0`, 4-finger horizontal workspace swipe, non-wrapping 10-workspace bounds, fade workspace context transition (`MASTER.md` §7), default freeform floating + centered new windows (`DEC-008`), subtle 1px solid Wabi-sabi window borders without neon glow (`DESIGN.md` §34), and no scratchpad bindings (`DEC-038`).
- [x] Register new configuration files in `scripts/validate.sh` and `scripts/validate.ps1`, pass 0-warning `qmllint 6.12.0`, and verify live against `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`) + `Quickshell 0.3.2`.

---

## Task M1-T2 — Freeform Window Capability (Geometry, Maximize vs Native Fullscreen, Minimize & Centered Restore)

**Goal:** Deliver BASEUS's freeform floating window model with explicit shell maximize vs native fullscreen separation, scratchpad-free minimize with centered restore, and POP-transition workspace movement hooks.

### Sub-tasks

- [x] Extend `src/core/WindowModel.qml` to track window geometry (`x`, `y`, `width`, `height`), `originWorkspace` and `savedGeometry` for minimized/maximized windows, MRU `focusHistory`, explicit `maximized` vs `fullscreen` booleans (`DEC-023`), per-monitor fullscreen/maximize queries (`hasFullscreenWindow(monitorIndex)`, `hasMaximizedWindow(monitorIndex)`), and workspace/monitor window filtering (`getVisibleWindowsByWorkspace`, `getMinimizedWindows`, `getNextFocusableWindow`, `getSnapshot`).
- [x] Extend `src/core/ShellState.qml` so `hasFullscreenApp`, `fullscreenMonitors`, and `isMonitorFullscreen(monitorIndex)` track native application fullscreen per monitor accurately (`"desktop"` <-> `"fullscreen"`, ignoring geometric maximized windows per `DEC-023`).
- [x] Extend `src/core/HyprlandBridge.qml` (with direct zero-process `.socket.sock` `j/clients` sync + FIFO `[[BATCH]]dispatch` socket pipeline and `DEC-008` newly-mapped floating/center enforcement), `config/hypr/baseus-desktop.{lua,conf}` (`baseus-minimized-hidden` rule), and `src/core/MockHyprlandBridge.qml` with dual Lua/Hyprlang window operations: `focusWindow`, `closeWindow`, `moveWindow`, `resizeWindow`, `centerWindow`, `setFloating` / `toggleFloating`, `setMaximized` / `toggleMaximize` (geometric maximize preserving `16px` layout boundaries), `setFullscreen` / `toggleFullscreen` (native compositor fullscreen), scratchpad-free `minimizeWindow` + `restoreWindow` (restoring centered onto the target monitor & workspace per `MASTER.md` §36 and `DEC-038`), and `moveWindowToWorkspace` / `moveWindowToMonitor` emitting normalized POP-transition metadata (`MASTER.md` §35).
- [x] Expose window capability commands on `baseus` diagnostic IPC in `src/Shell.qml` and verify live with real Wayland client windows inside dual-monitor `Hyprland 0.57.0`.

---

## Task M1-T3 — Action Registry & Desktop Navigation Primitives (`Back` / `Home` / `Overview`)

**Goal:** Establish the `Discover → Customize → Execute` action boundary (`DEC-028`) and the `Back` / `Home` / `Overview` desktop navigation mental model (`DEC-024`, `MASTER.md` §8).

### Sub-tasks

- [ ] Implement `src/core/ActionRegistry.qml` registering core M1 desktop, workspace, window, and navigation actions with human-readable metadata, categories (`Navigation`, `Workspaces`, `Windows`), default trigger descriptors, conflict detection helpers, and `execute(actionId, payload)`.
- [ ] Implement `src/core/NavigationController.qml` managing desktop context history and `Back` (exit active overlay mode → `"desktop"`, or return to monitor's `previousWorkspace` when in `"desktop"`), `Home` (return cleanly to `"desktop"` context), and `Overview` (toggle `"overview"` mode state foundation for M5).
- [ ] Wire `ActionRegistry` and `NavigationController` into `src/Shell.qml` lifecycle and diagnostic IPC, maintaining stable `EventBus` subscription counts across restarts.
- [ ] Validate statically (`qmllint 6.12.0`) and at runtime under both `MockHyprlandBridge` and live `Hyprland 0.57.0`.

---

## Task M1-T4 — Per-Monitor Layer-Shell Desktop Scaffolding (`DesktopHost`)

**Goal:** Create the multi-monitor Quickshell Wayland Layer-Shell host scaffolding that anchors foundational desktop overlays per screen while remaining invisible and zero-cost at idle and receding automatically during native fullscreen.

### Sub-tasks

- [ ] Implement `src/surfaces/DesktopHost.qml` using Quickshell `Variants` over `Quickshell.screens` and `Quickshell.Wayland` `PanelWindow` (`WlrLayershell`), mapping each `ShellScreen` (`name`) to `MonitorModel` monitor index.
- [ ] Enforce non-intrusive idle behavior (transparent background, pass-through input mask for empty regions, zero polling/timers when idle per `AGENTS.md` §21) and per-monitor native fullscreen recession (`DESIGN.md` §14).
- [ ] Integrate `DesktopHost` cleanly into `src/Shell.qml` with headful/headless gating and deterministic lifecycle cleanup.
- [ ] Validate `qmllint 6.12.0` (0 warnings) and live multi-output Layer-Shell mapping inside `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`).

---

## Task M1-T5 — Contextual Workspace Indicator & Minimal Top Island Idle Anchor

**Goal:** Implement the minimal foundational M1 visual surfaces strictly required to make desktop context legible without encroaching on M2 interactive panels.

### Sub-tasks

- [ ] Implement `src/surfaces/WorkspaceIndicator.qml` (`MASTER.md` §11, `DESIGN.md` §12, `DEC-029`):
  - Completely hidden at idle (never permanently showing workspace numbers).
  - Appears transiently (~2 seconds) on the switched monitor upon `WorkspaceModel` `"changed"` events.
  - Uses solid Wabi-sabi `Theme.colors.surfaceSolid` + `borderSubtle` (no glass/blur/gradients/neon glow), `Theme.typography.fontFamilyMono`, and hierarchical scaling (*"Focus grows. Context recedes."*: `previous` shrinks/dims, `current` grows/focuses).
  - Morphs cleanly into a compact pill (`2 — WEB`, `Theme.geometry.radiusPill`) when a user-defined workspace label is present, updates/resets in place during rapid consecutive switches without animation stacking (`AGENTS.md` §20), and respects `Theme.motion.reducedMotion`.
- [ ] Implement `src/surfaces/TopIslandAnchor.qml` (`MASTER.md` §9, §12; `DESIGN.md` §9, §10, §13, §14):
  - Edge-integrated top-center solid Wabi-sabi surface (`islandRadiusTop: 0`, `islandRadiusBottom: 12`) flanked by `InverseCorner` (`ICR`) organic fillets.
  - Displays only quiet typographic idle clock time (minute-aligned event/timer updates — no high-frequency polling), receding smoothly when a native fullscreen application occupies that monitor (`DESIGN.md` §14).
  - Keeps M2 hover-menu expansion, quick controls, and active-system drawers strictly out of M1 scope.
- [ ] Add M1 surface preview harness toggle in `src/dev/DesignStage.qml` and perform full `ANTI-SLOP.md` §14 removal/identity review + `qmllint 6.12.0` + live `Hyprland 0.57.0` + `Quickshell 0.3.2` runtime validation.

---

## Task M1-T6 — M1 End-to-End Multi-Monitor Validation, Anti-Slop Audit & Checkpoint `CP-M1-001`

**Goal:** Verify all M1 acceptance and exit criteria across multi-monitor live Hyprland + Quickshell execution, update baseline docs, record `CP-M1-001`, and stop cleanly at the M1 → M2 phase gate.

### Sub-tasks

- [ ] Run comprehensive live `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`) + `Quickshell 0.3.2` end-to-end verification covering 10-workspace per-monitor switching, freeform window floating/centering, maximize vs native fullscreen recession, minimize + centered restore, `Back`/`Home`/`Overview` navigation primitives, `WorkspaceIndicator` & `TopIslandAnchor` behavior, and repeated shell restarts.
- [ ] Perform formal `DESIGN.md` §45 and `ANTI-SLOP.md` audit across all M1 surfaces and configurations.
- [ ] Update `docs/architecture.md` and `docs/configuration.md` to document M1 capabilities and `config/hypr/` presets accurately.
- [ ] Update `STATE.md`, record verified checkpoint `CP-M1-001` in `CHECKPOINT.md`, report concisely, and **STOP** before M2 (`DEC-042`, `AGENTS.md` §48).

---

# 8. Acceptance Criteria

M1 is acceptable only when all of the following hold:

1. **Fixed 10-workspace discipline (`DEC-010`):** Workspaces `1..10` work deterministically per monitor; out-of-range workspace IDs (`< 1` or `> 10`) are rejected; workspace creation beyond `10` is prevented in both shell logic and Hyprland gesture/bind presets.
2. **Per-monitor independence (`MASTER.md` §39):** Switching workspaces on Monitor B preserves Monitor A's active workspace and independent `previousWorkspace` history.
3. **Freeform-first window behavior (`DEC-008`, `DEC-023`, `DEC-038`):** Windows open floating and centered by default, can overlap freely, distinguish workspace-filling maximize from shell-receding native fullscreen, and support minimize + centered restore without exposing a scratchpad mental model.
4. **Navigation foundation (`DEC-024`, `DEC-028`):** `Back`, `Home`, and `Overview` primitives operate through explicit actions decoupled from triggers.
5. **Contextual quiet desktop (`MASTER.md` §9, §11; `DESIGN.md` §8, §12–14; `ANTI-SLOP.md`):** Idle desktop shows no permanent workspace numbers, taskbars, cards, glass blur, gradients, or neon glows; `WorkspaceIndicator` appears only on workspace transitions and auto-hides cleanly; `TopIslandAnchor` and `DesktopHost` recede during native fullscreen.
6. **Zero-warning static & live runtime stability:** `scripts/validate.sh --all` (`qmllint 6.12.0`) passes with 0 errors and 0 warnings; live `Hyprland 0.57.0` + `Quickshell 0.3.2` execution and repeated `Lifecycle.restart()` runs maintain stable `EventBus` subscription counts and zero uncaught QML errors.

---

# 9. Validation Matrix

| Area | Validation Method | Required Evidence |
|---|---|---|
| Structure & JSON | `scripts/validate.sh --structure --config` & `scripts/validate.ps1` | Exit code 0; all M0 + M1 files and JSON configs valid |
| QML Static & Types | `scripts/validate.sh --qml` (`qmllint 6.12.0`) | 0 errors and 0 warnings across every `.qml` file |
| Hyprland Preset | Live `Hyprland 0.57.0 -c config/hypr/baseus-desktop.lua` + `hyprctl configerrors` | Zero config errors; floating/centered rules, `Super+1..0`, and 4-finger gesture loaded |
| Multi-Monitor Workspaces | Live `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`) + `Quickshell 0.3.2` IPC | Independent per-monitor active/previous workspaces, `1..10` clamping, label/tag & occupancy snapshot |
| Window Lifecycle | Live Wayland test clients inside `Hyprland 0.57.0` + `Quickshell 0.3.2` | Centered floating spawn, maximize vs native fullscreen mode distinction, minimize & centered restore, workspace move |
| Navigation & Surfaces | Live `Quickshell 0.3.2` on `Hyprland 0.57.0` + `DesignStage` / `ANTI-SLOP.md` review | `Back`/`Home`/`Overview` transitions, transient `WorkspaceIndicator` morph & ~2s hide, `TopIslandAnchor` ICR + fullscreen recession |
| Restart & Recovery | `quickshell ipc call baseus restart` under live Hyprland & `BASEUS_SIMULATION=1` | Constant `EventBus` subscription counts and accurate live state resynchronization |

---

# 10. Exit Criteria & Stop Conditions

M1 exits only when `M1-T1` through `M1-T6` are complete, validated with live evidence, audited against `DESIGN.md` and `ANTI-SLOP.md`, documented in `STATE.md`, and recorded in `CP-M1-001` (`CHECKPOINT.md`).

The agent must **STOP**:

- after completing and auditing the requested atomic task when operating in single-task kickoff/step mode;
- immediately if a source-of-truth conflict requiring owner governance (`DEC-043`) is discovered;
- immediately if a repeated runtime blocker prevents honest validation;
- unconditionally upon completing M1 (`CP-M1-001`), without auto-starting M2 (`AGENTS.md` §46, §48; `DEC-042`).

---

# 11. Current Status

- **Active Phase:** `M1 — Desktop Core` (*`ROADMAP.md` §8: `M1 — Desktop Foundation`*)
- **Completed Tasks:**
  - `M1-T1` (Workspace Capability, Per-Monitor Navigation & Hyprland Desktop Preset — `VERIFIED`)
  - `M1-T2` (Freeform Window Capability: Geometry, Maximize vs Native Fullscreen, Minimize & Centered Restore — `VERIFIED`)
- **Next Executable Task:** `M1-T3` (Action Registry & Desktop Navigation Primitives: `Back` / `Home` / `Overview`)
