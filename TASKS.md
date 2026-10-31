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
Current Phase (M2 — Interaction / Primary Surfaces)
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

M0 Foundation and M1 Desktop Core architectures are now protected under **Foundation Freeze** (`DEC-043`). M2 work must extend M0/M1 subsystems (`Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, `MonitorModel`, `WorkspaceModel`, `WindowModel`, `NavigationController`, `ActionRegistry`, `DesktopHost`, and `HyprlandBridge` / `MockHyprlandBridge`) rather than creating parallel state or event systems.

---

# 3. Current Phase

## Milestone

**M2 — Interaction** (*`ROADMAP.md` §9: `M2 — Interaction`*)

## Phase

**M2 — Interaction**

## Phase Goal

Build the primary interaction surfaces that define how users access and control BASEUS: the edge-integrated bottom Dock (`MASTER.md` §10; `DESIGN.md` §11; `DEC-015`), hover-expandable Top Island (`MASTER.md` §12; `DESIGN.md` §13, §14; `DEC-016`), universal action Command Center (`MASTER.md` §13; `DESIGN.md` §15, §16; `DEC-017`, `DEC-028`), and fullscreen search-first App Drawer (`MASTER.md` §14; `DESIGN.md` §17; `DEC-018`), adhering to Wabi-sabi solid surfaces (`DEC-011`, `ANTI-SLOP.md`), edge integration with Inverse Corner Radius (`DEC-015`, `DEC-016`), and non-permanent contextual desktop presence (`MASTER.md` §9).

---

# 4. Phase Scope

### IN SCOPE

- **Dock (`MASTER.md` §10; `DESIGN.md` §11; `DEC-015`):**
  - Bottom-centered, edge-integrated (flush bottom edge, rounded top corners, ICR fillets flaring into the bottom screen edge).
  - Recessed/hidden by default at idle; 1–2px bottom-edge cursor trigger strip; contextual reveal.
  - Input region containment: empty/trigger-only mask at idle (100% click-through desktop), expanding to dock body on reveal.
  - Global pinned applications vs workspace-specific active applications (`WindowModel`).
  - Clean separation: strictly NO search in Dock (`DEC-015`, `MASTER.md` §10).
  - Fullscreen recession on the active monitor (`DESIGN.md` §14, `DEC-023`).
- **Top Island Hover Expansion & Contextual Header (`MASTER.md` §12; `DESIGN.md` §13, §14; `DEC-016`):**
  - Hover expansion from the quiet idle clock anchor (`TopIslandAnchor`).
  - Contextual system header and quick controls foundation (volume/network/power entrypoint).
  - Fullscreen compact clock summon behavior (`DESIGN.md` §14).
- **Command Center (`MASTER.md` §13; `DESIGN.md` §15, §16; `DEC-017`, `DEC-028`):**
  - Universal action and navigation search interface slightly above center.
  - Search-first layout with dynamic bounded height and transient curtain reveal.
  - Action prefix routing (`>` prefix queries and invokes actions registered in `ActionRegistry`).
- **App Drawer (`MASTER.md` §14; `DESIGN.md` §17; `DEC-018`):**
  - Fullscreen composition with persistent search and continuous app grid.
  - Fixed A–Z–0–9–# fast scroller / category navigation.
  - Recent/suggested applications, right-click actions, and global discovery.
  - Running state is not represented as persistent task indicators in the drawer (`DEC-018`).

---

# 5. Phase Non-Goals

### OUT OF SCOPE

The following belong to future milestones in `ROADMAP.md` and must **not** be implemented in M2:

- Notification popups, notification center history, OSD, and Media / Bongo Cat surfaces (`M3`);
- Wallpaper runtime, Matugen palette extraction pipeline, Theme presets, Widgets, and Headquarter (`M4`);
- Full Helicopter View / Overview window layout, Alt+Tab switcher UI, and smart snap/grid arrangement (`M5`);
- Power Menu constellation, sleeping chibi, and personality choreography (`M6`);
- Multi-distro installer, updater, uninstaller, and doctor CLI (`M7`);
- Performance benchmarking and release freeze (`M8`–`M9`).

---

# 6. Dependencies

M2 depends on:

- **Verified M0 Foundation (`CP-M0-001` `VERIFIED`):** `Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, domain models, and bridges;
- **Verified M1 Desktop Core (`CP-M1-001` `VERIFIED`):** Fixed 10-workspace per-monitor model, freeform floating window tracking, `ActionRegistry` (`DEC-028`), `NavigationController` (`DEC-024`), `DesktopHost` multi-monitor Layer-Shell scaffolding (`DEC-045`), `TopIslandAnchor` (`DEC-029`), and `WorkspaceIndicator`;
- **Locked Source of Truth:** `MASTER.md`, `DESIGN.md`, `ANTI-SLOP.md`, `DECISIONS.md`, `ROADMAP.md`, and `AGENTS.md`;
- **Runtime & Tooling:** `Quickshell 0.3.2`, Qt 6 (`qmllint 6.12.0`), and live `Hyprland 0.57.0` (`Aquamarine 0.15.1`) in WSL2 Arch Linux.

---

# 7. Implementation Order & Atomic Task Breakdown

Per `DEC-045` (*Capability-to-Surface Implementation*) and `AGENTS.md` §11 (*Smallest coherent change*), M2 executes in six atomic tasks:

```text
M2-T1 (Bottom-Edge Cursor Trigger & Dock Scaffolding)
  ↓
M2-T2 (Dock Application State & Pinning)
  ↓
M2-T3 (Top Island Hover Expansion & Contextual Header)
  ↓
M2-T4 (Command Center Surface & Action Prefix Routing)
  ↓
M2-T5 (Fullscreen App Drawer & Alphabet Fast Scroller)
  ↓
M2-T6 (M2 Integration, Anti-Slop Audit & Checkpoint CP-M2-001)
```

---

## Task M2-T1 — Bottom-Edge Cursor Trigger & Dock Scaffolding

**Goal:** Implement the edge-integrated bottom Dock scaffolding (`src/desktop/DockAnchor.qml`), 1–2px bottom-edge cursor trigger, curtain reveal/recess state machine, input region containment, and per-monitor fullscreen recession.

### Sub-tasks

- [x] Implement `src/desktop/DockAnchor.qml` (`MASTER.md` §10; `DESIGN.md` §11; `DEC-015`):
  - Bottom-centered edge-integrated geometry: flush with bottom screen edge (`dockRadiusBottom: 0`), rounded top corners (`dockRadiusTop: 12`).
  - Organic `InverseCorner` (`ICR`) fillets flaring into the bottom screen edge (`position: "bottom-left"`, `position: "bottom-right"`).
  - Solid Wabi-sabi background (`theme.colors.surfaceSolid`, `borderSubtle`, strictly no glassmorphism, blur, or neon glow).
  - Recessed/hidden by default at idle with a bottom 1–2px invisible cursor trigger strip (`triggerHeight: 2`).
  - Reveal state machine: cursor entering trigger raises/reveals the dock body from the edge; cursor exiting dock bounds recedes the dock after a clean delay (~400ms).
  - Fullscreen recession: cleanly recedes when monitor enters native application fullscreen (`DESIGN.md` §14, `DEC-023`).
  - Reduced motion compliance: instant transitions when `theme.motion.reducedMotion` is true.
  - Expose items for layer-shell mask management (`triggerItem`, `hitRegionItem`).
- [x] Wire `DockAnchor` into `src/desktop/DesktopHost.qml`:
  - Multi-monitor variant integration with per-screen screen binding.
  - Update `mask: Region` to include `topIsland.anchorItem` and `dockAnchor.hitRegionItem` so screen remains 100% click-through at idle.
  - Expose dock telemetry (`revealed`, `visible`) in `getSurfaceSnapshot()`.
  - Add `revealDock(monitorIndex)` / `hideDock(monitorIndex)` methods.
- [x] Expose diagnostic IPC hooks in `src/Shell.qml` (`revealDock`, `hideDock`, `dockRevealed`).
- [x] Integrate production `DockAnchor` preview in `src/dev/DesignStage.qml`.
- [x] Register `src/desktop/DockAnchor.qml` in `scripts/validate.sh` and `scripts/validate.ps1`.
- [x] Validate statically (`qmllint 6.12.0` — 0 errors, 0 warnings) and runtime in WSL2 Arch Linux (`BASEUS_SIMULATION=1` and live dual-monitor `Hyprland 0.57.0`).

---

## Task M2-T2 — Dock Application State & Pinning

**Goal:** Implement dock item data models (`DockModel.qml` / `DockItem.qml`), distinguishing global pinned applications from workspace-specific active applications (`WindowModel`), launch dispatch, and focus switching.

### Sub-tasks

- [x] Implement `src/desktop/DockModel.qml` managing global pinned application definitions and workspace-specific active clients derived from `WindowModel`.
- [x] Implement `src/desktop/DockItem.qml` rendering solid Wabi-sabi application tiles, running indicator pips, active workspace window count badges, and click/launch dispatch.
- [x] Support pin management (persistent pinned apps from `config/baseus.json` via `Config.qml`, global pin matching, dynamic aggregation).
- [x] Validate multi-monitor and multi-workspace window association (zero leakage across monitors/workspaces in dual-monitor Hyprland 0.57.0 runtime).

---

## Task M2-T3 — Top Island Hover Expansion & Contextual Header

**Goal:** Extend `TopIslandAnchor` with interactive downward expansion, revealing quiet contextual header controls (date, active session workspace/window context, ActionRegistry navigation triggers) without breaking idle simplicity, respecting Anti-Slop (no permanent telemetry dashboards, no volume/media OSDs reserved for M3) and fullscreen notch summon (`DESIGN.md` §14, `DEC-016`).

### Sub-tasks

- [x] Extend `src/desktop/TopIslandAnchor.qml` with downward curtain expansion driven by `Theme.motion` tokens, 120ms hover intent, 350ms exit grace period, and InverseCorner (ICR) organic fillets.
- [x] Implement `src/desktop/TopIslandHeader.qml` showing full formatted date, active session context (workspace, label, window counts), and ActionRegistry navigation triggers (`navigation.back`, `navigation.home`, `navigation.overview`) with discoverable keyboard shortcuts.
- [x] Implement native fullscreen notch summon in `src/desktop/DesktopHost.qml` (`summonVariants` on Overlay layer with 2px top edge trigger, hover summoning compact clock, click expanding contextual header, and clean auto-recess).
- [x] Validate click-through and input mask dynamic resizing across idle (clock footprint / 2px trigger in fullscreen) and expanded header states.

---

## Task M2-T4 — Command Center Surface & Action Prefix Routing

**Goal:** Build the universal action and search surface (`src/surfaces/CommandCenter.qml`) with dynamic bounded height, transient curtain reveal, and `>` action prefix routing to `ActionRegistry`.

### Sub-tasks

- [ ] Implement `src/surfaces/CommandCenter.qml` appearing slightly above center.
- [ ] Implement search input with keyboard focus grab and ESC dismissal.
- [ ] Wire `>` prefix routing to query and execute `ActionRegistry` actions (`DEC-028`).
- [ ] Implement dynamic height sizing capped at maximum threshold.
- [ ] Validate keyboard navigation (Up/Down/Enter/Escape).

---

## Task M2-T5 — Fullscreen App Drawer & Alphabet Fast Scroller

**Goal:** Implement the fullscreen application discovery drawer (`src/surfaces/AppDrawer.qml`) with persistent search, A–Z–0–9–# fast scroller, and continuous app grid.

### Sub-tasks

- [ ] Implement `src/surfaces/AppDrawer.qml` fullscreen surface with flush bottom edge and rounded top corners (`drawerRadiusTop: 12`).
- [ ] Implement desktop entry discovery and parsing.
- [ ] Implement A–Z–0–9–# alphabet fast scroller and section headers.
- [ ] Implement recent/suggested applications header row.
- [ ] Wire launcher dispatch hooks.

---

## Task M2-T6 — M2 Integration, Anti-Slop Audit & Checkpoint `CP-M2-001`

**Goal:** Verify all M2 primary interaction surfaces across dual-monitor live Hyprland + Quickshell execution, perform full anti-slop audit, update documentation, record `CP-M2-001`, and stop at M2 → M3 phase gate.

### Sub-tasks

- [ ] Run integrated E2E test suite combining Dock, Top Island, Command Center, and App Drawer across dual virtual outputs (`VIRTUAL-1`, `VIRTUAL-2`).
- [ ] Perform comprehensive anti-slop audit across all QML surfaces.
- [ ] Update `docs/architecture.md` and `docs/configuration.md`.
- [ ] Update `STATE.md`, record `CP-M2-001` in `CHECKPOINT.md`, report concisely, and **STOP**.

---

# 8. Acceptance Criteria

M2 is acceptable only when all of the following hold:

1. **Edge-integrated Dock (`DEC-015`):** Dock is bottom-centered, edge-integrated with ICR fillets, recessed at idle with a 1–2px bottom trigger, reveals from the trigger, distinguishes global pins from workspace clients, and contains NO search.
2. **Contextual Top Island (`DEC-016`):** Idle clock expands on hover to provide contextual controls; fullscreen mode cleanly recedes while keeping compact clock summon available.
3. **Universal Command Center (`DEC-017`, `DEC-028`):** Universal action surface appears slightly above center, supports search, executes `>` prefixed actions via `ActionRegistry`, and dynamically resizes.
4. **Fast App Drawer (`DEC-018`):** Fullscreen search-first launcher provides continuous app grid with fixed A–Z–0–9–# fast scroller without turning into a task manager.
5. **Solid Wabi-sabi & Anti-Slop (`ANTI-SLOP.md`):** Zero glassmorphism, zero blur filters, zero neon glows, strict tokenized typography/colors/spacing, and 100% `pragma ComponentBehavior: Bound`.
6. **Zero-cost idle desktop:** Empty desktop space remains completely click-through via precise Layer-Shell input masks.
7. **Zero-warning static & runtime stability:** `qmllint 6.12.0` passes with 0 errors and 0 warnings; live `Hyprland 0.57.0` + `Quickshell 0.3.2` execution passes without memory leaks or unhandled errors.

---

# 9. Validation Matrix

| Area | Validation Method | Required Evidence |
|---|---|---|
| Structure & QML Lint | `scripts/validate.sh --all` & `scripts/validate.ps1` | Exit code 0; `qmllint 6.12.0` passes with 0 errors and 0 warnings |
| Dock Trigger & Reveal | Live Hyprland 0.57.0 + Quickshell IPC | 1–2px trigger activates reveal; input mask covers dock; auto-recedes on exit; fullscreen recedes |
| Dock Application State | Quickshell IPC + Wayland client windows | Global pins persist across workspaces; active client icons track workspace occupancy |
| Top Island Expansion | Live Quickshell hover interaction | Idle clock expands smoothly; quick controls accessible; fullscreen compact clock works |
| Command Center | Quickshell IPC + keyboard input | `>` prefix matches `ActionRegistry` actions; Up/Down/Enter navigates and executes |
| App Drawer | Live Quickshell fullscreen launcher | Search filters grid; A–Z scroller jumps accurately; clicking app launches client |
| Multi-Monitor & Fullscreen | Dual-monitor (`VIRTUAL-1`, `VIRTUAL-2`) test harness | Independent surface states per monitor; native fullscreen causes only affected monitor to recede |

---

# 10. Exit Criteria & Stop Conditions

M2 exits only when `M2-T1` through `M2-T6` are complete, validated with live evidence, audited against `ANTI-SLOP.md`, documented in `STATE.md`, and recorded in `CP-M2-001` (`CHECKPOINT.md`).

The agent must **STOP**:

- after completing and auditing the requested atomic task (`M2-T1`);
- immediately if a source-of-truth conflict requiring owner governance (`DEC-043`) is discovered;
- immediately if a repeated runtime blocker prevents honest validation;
- unconditionally upon completing M2 (`CP-M2-001`), without auto-starting M3 (`AGENTS.md` §46, §48).

---

# 11. Current Status

- **Active Phase:** `M2 — Interaction` (*`ROADMAP.md` §9: `M2 — Interaction`*)
- **Completed Milestones:**
  - `M0 — Foundation` (`CP-M0-001` `VERIFIED`)
  - `M1 — Desktop Core` (`CP-M1-001` `VERIFIED`)
- **Completed Tasks in Phase:**
  - `M2-T1` (Bottom-Edge Cursor Trigger & Dock Scaffolding — `COMPLETE / VERIFIED`)
  - `M2-T2` (Dock Application State & Pinning — `COMPLETE / VERIFIED`)
  - `M2-T3` (Top Island Hover Expansion & Contextual Header — `COMPLETE / VERIFIED`)
- **Active Task:** `M2-T3` complete; stopped at task boundary per `AGENTS.md` §46.
- **Next Executable Task:** `M2-T4` (Command Center Surface & Action Prefix Routing — awaiting user prompt).
