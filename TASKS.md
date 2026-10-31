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
Current Phase (M3 — System Feedback)
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

M0 Foundation, M1 Desktop Core, and M2 Primary Surfaces are protected under **Foundation Freeze** (`DEC-043`). M3 work must extend M0/M1/M2 subsystems (`Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, `MonitorModel`, `WorkspaceModel`, `WindowModel`, `NavigationController`, `ActionRegistry`, `DesktopHost`, `DockAnchor`, `TopIslandAnchor`, `CommandCenter`, `AppDrawer`, and `HyprlandBridge` / `MockHyprlandBridge`) rather than creating parallel state or event systems.

---

# 3. Current Phase

## Milestone

**M3 — System Feedback** (*`ROADMAP.md` §10: `M3 — System Feedback`*)

## Phase

**M3 — System Feedback**

## Phase Goal

Build the system feedback layer that communicates transient state without turning BASEUS into a permanent dashboard. Notifications (floating top-left, 70% icon backdrop, solid surface, hold-to-silence feedback, zero cardification per `DEC-020`), Top Island OSD integration (volume/brightness feedback, bubble-drop transition, rapid-event in-place morphing per `DEC-021`), Media Player Architecture & Top Island Compact Integration (MPRIS bridge, session tracking, play/pause/seek controls, zero generic notifications on track change per `DEC-026`, `DEC-039`), Dedicated Media Widget & Bongo Cat companion integration, System Status & Diagnostic Feedback Architecture.

---

# 4. Phase Scope

### IN SCOPE

- **Notifications (`DEC-020`, `MASTER.md` §30, `DESIGN.md` §17–18):**
  - Floating top-left placement (`16px` margins from screen boundaries).
  - Left-to-right reveal animation.
  - Large background application icon with approximately 70% transparency.
  - Overlapping legible notification text (prominent title, smaller message).
  - Solid palette-derived surface (`theme.colors.surfaceSolid`, `borderSubtle`, zero glassmorphism, zero blur).
  - Interaction: click to launch/activate, double-click to dismiss, hold ~2s to silence all with solid tonal progress fill (`DESIGN.md` §18).
  - Hover pauses timeout for all pending notifications (~3000ms configurable timeout).
  - Strict Anti-Slop (`ANTI-SLOP.md` §20): strictly NO notification cards within cards, NO permanent notification clutter.
- **Top Island OSD Integration (`DEC-021`, `MASTER.md` §33, `DESIGN.md` §32):**
  - Spatial origin: all system volume & brightness feedback originates from Top Island.
  - Bubble-drop / gooey transition into the expanded OSD state.
  - Rapid-event in-place morphing without stacking animation queues.
- **Media Player Architecture (`DEC-026`, `DEC-039`, `MASTER.md` §31, `DESIGN.md` §33):**
  - MPRIS integration and multi-session playback management.
  - Fixed compact layout inside Top Island (zero unpredictable resizing).
  - Dedicated modular desktop Media Widget with compact, expanded, and lyrics states.
  - Strict Rule (`DEC-039`): Changing media tracks updates dedicated media surfaces and MUST NOT generate generic notifications.
- **Bongo Cat Companion:**
  - Integrated visual companion reacting dynamically to playback state and tempo.
- **System Status Feedback:**
  - Contextual status reporting (audio output sink, backlight brightness, battery/power) with quiet failure communication.

---

# 5. Phase Non-Goals

### OUT OF SCOPE

The following belong to future milestones in `ROADMAP.md` and must **not** be implemented in M3:

- Wallpaper runtime, Matugen palette extraction pipeline, Theme presets, Widgets, and Headquarter (`M4`);
- Full Helicopter View / Overview window layout, Alt+Tab switcher UI, and smart snap/grid arrangement (`M5`);
- Power Menu constellation, sleeping chibi, and personality choreography (`M6`);
- Multi-distro installer, updater, uninstaller, and doctor CLI (`M7`);
- Performance benchmarking and release freeze (`M8`–`M9`).

---

# 6. Dependencies

M3 depends on:

- **Verified M0 Foundation (`CP-M0-001` `VERIFIED`):** `Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, domain models, and bridges;
- **Verified M1 Desktop Core (`CP-M1-001` `VERIFIED`):** Fixed 10-workspace per-monitor model, freeform floating window tracking, `ActionRegistry` (`DEC-028`), `NavigationController` (`DEC-024`), `DesktopHost` multi-monitor Layer-Shell scaffolding (`DEC-045`), `TopIslandAnchor` (`DEC-029`), and `WorkspaceIndicator`;
- **Verified M2 Primary Surfaces (`CP-M2-001` `VERIFIED`):** `DockAnchor`, `DockModel`, `DockItem`, `TopIslandAnchor` hover expansion and fullscreen summon, `CommandCenter`, `AppDrawer`, `AlphabetScroller`, and overlay mutual exclusivity;
- **Locked Source of Truth:** `MASTER.md`, `DESIGN.md`, `ANTI-SLOP.md`, `DECISIONS.md`, `ROADMAP.md`, and `AGENTS.md`;
- **Runtime & Tooling:** `Quickshell 0.3.2` with `Quickshell.Services.Notifications` & `Quickshell.Services.Mpris`, Qt 6 (`qmllint 6.12.0`), and live `Hyprland 0.57.0` (`Aquamarine 0.15.1`) in WSL2 Arch Linux.

---

# 7. Implementation Order & Atomic Task Breakdown

Per `DEC-045` (*Capability-to-Surface Implementation*) and `AGENTS.md` §11 (*Smallest coherent change*), M3 executes in six atomic tasks:

```text
M3-T1 (Notification Daemon & Floating Surface)
  ↓
M3-T2 (Top Island OSD Integration)
  ↓
M3-T3 (Media Player Architecture & Top Island Compact Integration)
  ↓
M3-T4 (Dedicated Media Widget & Bongo Cat Companion Integration)
  ↓
M3-T5 (System Status & Diagnostic Feedback Architecture)
  ↓
M3-T6 (M3 End-to-End Multi-Monitor Validation, Anti-Slop Audit & Checkpoint CP-M3-001)
```

---

## Task M3-T1 — Notification Daemon & Floating Surface

**Goal:** Implement the desktop notification domain model (`src/core/NotificationModel.qml`), notification host surface (`src/desktop/NotificationHost.qml`), and item delegate (`src/desktop/NotificationItem.qml`). Comply with `DESIGN.md` §17–18 (top-left placement, left-to-right reveal, ~3s timeout with hover pause, 70% icon backdrop, hold-to-silence feedback, zero cardification), and wire into `DesktopHost.qml` with dynamic Layer-Shell input masking.

### Sub-tasks

- [x] Implement `src/core/NotificationModel.qml`:
  - Manage notifications queue, FreeDesktop DBus integration via `Quickshell.Services.Notifications.NotificationServer` with fallback simulation model.
  - Configurable ~3000ms timeout (`Config.qml` `notifications.timeout`).
  - Hover pause mechanic: hovering any notification pauses timeouts for all pending notifications.
  - Hold-to-silence mechanic: holding for ~2000ms silences/dismisses all notifications with quiet confirmation.
  - Programmatic diagnostic API (`postNotification`, `dismissNotification`, `silenceAll`, `getSnapshot`).
  - Wire into `EventBus` category `"notification"`.
- [x] Implement `src/desktop/NotificationHost.qml` and `src/desktop/NotificationItem.qml`:
  - Anchored top-left (`16px` margins).
  - Left-to-right curtain/slide reveal animation driven by `Theme.motion`.
  - Solid Wabi-sabi surface (`Theme.colors.surfaceSolid` + `borderSubtle`, zero glassmorphism, zero blur).
  - 70% transparent large background application icon (`opacity: 0.30`).
  - Overlapping typography (prominent title, legible body).
  - Action buttons as solid pills.
  - Hold-to-silence progress fill (solid tonal fill progressing left-to-right per `DESIGN.md` §18).
  - Click to activate/launch, double-click to dismiss, hover to pause timeout.
- [x] Wire `NotificationHost` into `src/desktop/DesktopHost.qml`:
  - Integrate with Layer-Shell input mask: `Region { width: 0, height: 0 }` when no notifications active (100% click-through idle desktop space); dynamically covers notification footprint when visible.
- [x] Expose diagnostic IPC hooks in `src/Shell.qml` (`postNotification`, `dismissNotification`, `silenceNotifications`, `notificationState`).
- [x] Validate statically (`qmllint 6.12.0` — 0 errors, 0 warnings across all QML files) and runtime under both offline simulation and live dual-monitor Hyprland in WSL2.

---

## Task M3-T2 — Top Island OSD Integration

**Goal:** Implement volume and brightness system OSD originating from Top Island (`DEC-021`), bubble-drop / gooey curtain transition into expanded feedback state, and rapid-event in-place morphing without animation stacking.

### Sub-tasks

- [ ] Implement system OSD model and feedback controller.
- [ ] Extend `TopIslandAnchor` with bubble-drop OSD drop-down surface.
- [ ] Implement rapid-event in-place value updates and timeout reset without animation queue pile-up.
- [ ] Validate OSD triggers, timing, and clean recession back to idle clock.

---

## Task M3-T3 — Media Player Architecture & Top Island Compact Integration

**Goal:** Implement MPRIS media bridge, multi-session tracking, play/pause/prev/next/seek controls, fixed compact layout inside Top Island, and enforce `DEC-039` (strictly zero generic notifications on media track change).

### Sub-tasks

- [ ] Implement `src/core/MediaModel.qml` consuming `Quickshell.Services.Mpris`.
- [ ] Integrate compact fixed media controller in `TopIslandHeader.qml`.
- [ ] Enforce `DEC-039`: track change updates media state and suppresses standard notification emission.
- [ ] Validate multi-session switching, playback control dispatch, and metadata formatting.

---

## Task M3-T4 — Dedicated Media Widget & Bongo Cat Companion Integration

**Goal:** Implement modular desktop Media Widget with compact, expanded, and lyrics states, synchronized with animated Bongo Cat companion reacting to playback state.

### Sub-tasks

- [ ] Implement desktop media widget component.
- [ ] Implement Bongo Cat visual companion with state-driven animation choreography.
- [ ] Wire synchronized playback tracking and lyrics presentation.
- [ ] Validate anti-slop compliance and performance.

---

## Task M3-T5 — System Status & Diagnostic Feedback Architecture

**Goal:** Implement system status monitors (audio sink, display brightness, battery/power) with quiet failure communication.

### Sub-tasks

- [ ] Implement system hardware monitoring models.
- [ ] Provide contextual feedback surfaces and failure alerts.
- [ ] Validate reporting across multi-monitor environments.

---

## Task M3-T6 — M3 End-to-End Multi-Monitor Validation, Anti-Slop Audit & Checkpoint `CP-M3-001`

**Goal:** Verify all M3 system feedback surfaces across dual-monitor live Hyprland + Quickshell execution, perform full anti-slop audit, update documentation, record `CP-M3-001`, and stop at M3 → M4 phase gate.

### Sub-tasks

- [ ] Run integrated E2E test suite combining Notifications, OSD, Media, and Bongo Cat across dual virtual outputs (`VIRTUAL-1`, `VIRTUAL-2`).
- [ ] Perform comprehensive anti-slop audit across all QML surfaces.
- [ ] Update `docs/architecture.md` and `docs/configuration.md`.
- [ ] Update `STATE.md`, record `CP-M3-001` in `CHECKPOINT.md`, report concisely, and **STOP**.

---

# 8. Acceptance Criteria

M3 is acceptable only when all of the following hold:

1. **Floating Top-Left Notifications (`DEC-020`):** Notifications appear floating in the top-left with left-to-right reveal, 70% icon backdrop, solid Wabi-sabi surface, and NO nested cardification (`ANTI-SLOP.md` §20).
2. **Hold-to-Silence Feedback (`DESIGN.md` §18):** Long-hold silence interaction fills with a solid tonal progress bar and calms notifications without alarming error styling.
3. **Top Island OSD Spatial Origin (`DEC-021`):** All volume/brightness feedback drops from Top Island; rapid events morph in place without animation stacks.
4. **Dedicated Media Context & No Notification Spam (`DEC-026`, `DEC-039`):** Media has fixed compact Top Island integration and desktop widget; track changes never produce generic notification noise.
5. **Bongo Cat Companion Integration:** Bongo Cat companion is integrated and responds dynamically to music playback state.
6. **Zero-cost idle desktop:** Empty desktop space remains completely click-through via precise Layer-Shell input masks when notifications/OSDs are idle.
7. **Zero-warning static & runtime stability:** `qmllint 6.12.0` passes with 0 errors and 0 warnings; live `Hyprland 0.57.0` + `Quickshell 0.3.2` execution passes without memory leaks or unhandled errors.

---

# 9. Validation Matrix

| Area | Validation Method | Required Evidence |
|---|---|---|
| Structure & QML Lint | `scripts/validate.sh --all` & `scripts/validate.ps1` | Exit code 0; `qmllint 6.12.0` passes with 0 errors and 0 warnings |
| Notification Reveal & Dismissal | Quickshell IPC + DBus / simulation | Top-left floating placement; left-to-right reveal; ~3s timeout; hover pause; double-click dismissal |
| Hold-to-Silence | Simulated pointer long-press | Tonal fill progresses left-to-right; silent state confirmed; all pending dismissed |
| OSD Bubble-Drop & Morph | Volume/brightness key simulation | OSD drops from Top Island; rapid changes update in-place without animation stacks |
| Media MPRIS & Suppression | MPRIS mock / player events | Compact Top Island controls; track change updates media UI with ZERO notification noise |
| Multi-Monitor & Fullscreen | Dual-monitor (`VIRTUAL-1`, `VIRTUAL-2`) test harness | Notifications and feedback respect monitor focus and native fullscreen rules |

---

# 10. Exit Criteria & Stop Conditions

M3 exits only when `M3-T1` through `M3-T6` are complete, validated with live evidence, audited against `ANTI-SLOP.md`, documented in `STATE.md`, and recorded in `CP-M3-001` (`CHECKPOINT.md`).

The agent must **STOP**:

- after completing and auditing each requested atomic task (`M3-T1`);
- immediately if a source-of-truth conflict requiring owner governance (`DEC-043`) is discovered;
- immediately if a repeated runtime blocker prevents honest validation;
- unconditionally upon completing M3 (`CP-M3-001`), without auto-starting M4 (`AGENTS.md` §46, §48).

---

# 11. Current Status

- **Active Phase:** `M3 — System Feedback` (*`ROADMAP.md` §10: `M3 — System Feedback`*)
- **Completed Milestones:**
  - `M0 — Foundation` (`CP-M0-001` `VERIFIED`)
  - `M1 — Desktop Core` (`CP-M1-001` `VERIFIED`)
  - `M2 — Interaction` (`CP-M2-001` `VERIFIED`)
- **Completed Tasks in Phase:**
  - `M3-T1` (Notification Daemon & Floating Surface — `COMPLETE / VERIFIED`)
- **Active Task:** `M3-T1` complete; stopped at task boundary per `AGENTS.md` §46.
- **Next Executable Task:** `M3-T2` (Top Island OSD Integration).
