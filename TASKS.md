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
Current Phase (M5 — Session, Lock & Polish)
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

M0 Foundation, M1 Desktop Core, M2 Primary Surfaces, M3 System Feedback, and M4 Personalization are protected under **Foundation Freeze** (`DEC-043`). M5 work extends existing subsystems (`Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, `MonitorModel`, `WorkspaceModel`, `WindowModel`, `NavigationController`, `ActionRegistry`, `DesktopHost`, `TopIslandAnchor`, `DockAnchor`, `CommandCenter`, `AppDrawer`, `NotificationModel`, `AudioService`, `MediaService`, `StatusService`, `PaletteService`, `WallpaperService`, `ThemeService`, `WallpaperPicker`, `Headquarter`, and `Theme`) rather than creating parallel architectures.

---

# 3. Current Phase

## Milestone

**M5 — Session, Lock & Polish** (*`ROADMAP.md` §12, `MASTER.md` §34–36, `DESIGN.md` §34–36, `DEC-025`, `DEC-027`, `DEC-045`*)

## Phase

**M5 — Session, Lock & Polish**

## Phase Goal

Implement secure, resilient session, power, idle, and lock management, refine hardware shortcut and multi-finger gestures, and optimize cold-start performance while preserving BASEUS's restrained visual identity and freeform desktop philosophy.

---

# 4. Phase Scope

### IN SCOPE

- **Session & Power Management (`PowerService.qml`, `SessionOverlay.qml`, `DEC-027`):**
  - Event-driven power backend supporting `lock()`, `suspend()`, `logout()`, `reboot()`, and `poweroff()`.
  - Clean execution via `systemctl`, `loginctl`, and Hyprland dispatch with mock fallback for headless WSL2 / `BASEUS_SIMULATION=1`.
  - Constellation-inspired modal session overlay (`WlrLayer.Overlay`, `DEC-027`, `MASTER.md` §32, `DESIGN.md` §31): quiet dark space, palette-aware stars, sparse layout, subtle movement, and no sci-fi neon overload.
  - Accidental trigger prevention: hold-to-confirm (progress fill) or two-step execution for destructive actions (`reboot`, `poweroff`).
  - Full keyboard navigation (Arrows/Tab selection, Enter execute, Escape / `navigation.back` dismiss) and 0x0 idle hitmasking.
- **Idle & Inhibitor Service (`IdleService.qml`):**
  - Wayland `ext-idle-notify-v1` integration tracking user activity and idle timeouts.
  - Presentation mode inhibitor toggle suppressing screen dimming and lock during media playback or presentation.
- **Lock Screen Surface & Authentication Architecture (`LockScreen.qml`):**
  - Wayland `ext-session-lock-v1` integration guaranteeing secure lock screen coverage across all outputs.
  - PAM bridge authentication model with responsive typographic pin/password entry and feedback.
  - Solid Wabi-sabi lock surface with minute-aligned typographic clock, subtle battery/status indicator, and zero blur.
- **Hardware Bindings & Gesture Scaffolding:**
  - Hyprland shortcut alignment and 3/4-finger touchpad gesture bindings (`hl.gesture`).
  - Media key, brightness, and volume hardware key event routing through core services.
- **Shell Cold-Start Optimization & Performance Profiling:**
  - Initialization pipeline audit and deferred component instantiation.
  - Zero redundant process spawns, zero background polling, and verified idle-state 0% CPU consumption.
- **Multi-Monitor E2E Validation & Anti-Slop Audit (`CP-M5-001`):**
  - Full dual-monitor verification across `VIRTUAL-1` and `VIRTUAL-2`.
  - 100% `pragma ComponentBehavior: Bound` and 0-warning `qmllint 6.12.0` compliance across all QML files.

---

# 5. Phase Non-Goals

### OUT OF SCOPE

The following belong to future milestones in `ROADMAP.md` and must **not** be implemented in M5:

- **Personality Expansion (M6):** Advanced Bongo Cat personas, retro audio effects, easter eggs.
- **Distribution & Packaging (M7):** Pacman packaging, AUR PKGBUILD, installer wizard.
- **Hardening & System Integration (M8):** Polkit agent, Bluetooth daemon, VPN management.
- **Biometric Hardware Scanners:** Fingerprint / facial recognition PAM modules outside standard Linux PAM.

---

# 6. Dependencies

M5 depends upon:

- **M0 Foundation (`CP-M0-001`):** `Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, and `Theme`.
- **M1 Desktop Core (`CP-M1-001`):** Fixed 10 workspaces, `DesktopHost` layer-shell scaffolding, `HyprlandBridge`.
- **M2 Interaction (`CP-M2-001`):** `DockAnchor`, `TopIslandAnchor`, `CommandCenter`, `AppDrawer`, `ActionRegistry`.
- **M3 System Feedback (`CP-M3-001`):** `NotificationModel`, `AudioService`, `MediaService`, `StatusService`.
- **M4 Personalization (`CP-M4-001`):** `PaletteService`, `WallpaperService`, `ThemeService`, `WallpaperPicker`, `Headquarter`.

---

# 7. Milestone M5 Tasks

## Task M5-T1 — Session & Power Management Overlay

**Goal:** Implement `src/core/PowerService.qml` and `src/desktop/SessionOverlay.qml` providing session and power action dispatch (`lock`, `suspend`, `logout`, `reboot`, `poweroff`) with constellation visual composition, hold-to-confirm destructive protection, and layer-shell overlay exclusivity (`DEC-027`, `MASTER.md` §32).

### Sub-tasks

- [x] Implement `PowerService.qml` event-driven backend supporting `lock()`, `suspend()`, `logout()`, `reboot()`, and `poweroff()` with simulation fallback.
- [x] Implement `SessionOverlay.qml` fullscreen constellation overlay on `WlrLayer.Overlay` with hold-to-confirm destructive safety.
- [x] Wire keyboard navigation (Arrows/Tab, Enter, Escape) and dynamic 0x0 layer-shell input masking.
- [x] Expose diagnostic IPC endpoints in `Shell.qml`: `openSessionMenu(monitorIndex)`, `closeSessionMenu()`, `sessionMenuState(monitorIndex)`, `executePowerAction(action)`.
- [x] Validate static qmllint, offline simulation, and live dual-monitor Hyprland execution.

---

## Task M5-T2 — Idle & Inhibitor Service

**Goal:** Implement `src/core/IdleService.qml` integrating Wayland `ext-idle-notify-v1`, managing idle state transitions, and providing a presentation mode inhibitor toggle.

### Sub-tasks

- [ ] Implement `IdleService.qml` monitoring user activity and idle timeouts.
- [ ] Implement presentation mode idle inhibitor toggle suppressing sleep and lock during active presentations or media playback.
- [ ] Expose diagnostic IPC endpoints on `Shell.qml`.

---

## Task M5-T3 — Lock Screen Surface & Authentication Architecture

**Goal:** Implement `src/desktop/LockScreen.qml` utilizing Wayland `ext-session-lock-v1` with PAM authentication model and solid Wabi-sabi aesthetics.

### Sub-tasks

- [ ] Implement PAM authentication bridge and credential handling.
- [ ] Implement `LockScreen.qml` surface securing all outputs with typographic time and battery status.
- [ ] Expose diagnostic IPC endpoints on `Shell.qml`.

---

## Task M5-T4 — Hardware Bindings & Gesture Scaffolding

**Goal:** Integrate hardware keys and multi-finger touchpad gestures in Hyprland presets and shell event routes.

### Sub-tasks

- [ ] Align Hyprland keybinds for session, lock, and power triggers.
- [ ] Implement 3-finger and 4-finger gesture mappings.

---

## Task M5-T5 — Shell Cold-Start Optimization & Performance Profiling

**Goal:** Profile shell startup latency and memory footprint, optimizing component instantiation and ensuring 0% idle CPU utilization.

### Sub-tasks

- [ ] Audit startup timeline and optimize component loading.
- [ ] Verify zero CPU consumption during desktop idle state.

---

## Task M5-T6 — M5 End-to-End Multi-Monitor Validation, Full Anti-Slop Audit & Checkpoint `CP-M5-001`

**Goal:** Run integrated multi-monitor E2E validation, perform complete anti-slop audit across all surfaces, update baseline documentation, promote `CP-M5-001`, and stop at M5 → M6 milestone gate.

### Sub-tasks

- [ ] Run integrated E2E test suite across dual outputs (`VIRTUAL-1`, `VIRTUAL-2`).
- [ ] Perform comprehensive anti-slop audit across all QML surfaces.
- [ ] Update `docs/architecture.md` and `docs/configuration.md`.
- [ ] Update `STATE.md`, record `CP-M5-001` in `CHECKPOINT.md`, and **STOP**.

---

# 8. Acceptance Criteria

M5 is acceptable only when all of the following hold:

1. **Constellation Power Menu (`DEC-027`, `MASTER.md` §32):** Fullscreen constellation composition with quiet dark space, palette-aware stars, and sparse layout; zero neon sci-fi overload.
2. **Accidental Trigger Protection:** Destructive actions (`reboot`, `poweroff`) strictly require hold-to-confirm progress fill or explicit confirmation.
3. **Session Lock Security:** Lock screen securely binds all outputs via `ext-session-lock-v1` with PAM authentication.
4. **Zero-cost idle desktop:** Overlays maintain 0x0 hitmask when closed; idle state utilizes 0% CPU with no background polling loops.
5. **Zero-warning static & runtime stability:** `qmllint 6.12.0` passes with 0 errors and 0 warnings; live `Hyprland 0.57.0` + `Quickshell 0.3.2` execution passes without memory leaks or unhandled errors.

---

# 9. Validation Matrix

| Area | Validation Method | Required Evidence |
|---|---|---|
| Structure & QML Lint | `scripts/validate.sh --all` & `scripts/validate.ps1` | Exit code 0; `qmllint 6.12.0` passes with 0 errors and 0 warnings |
| PowerService & Actions | Quickshell IPC + simulation | `lock`, `suspend`, `logout`, `reboot`, and `poweroff` dispatch validated |
| SessionOverlay Surface | Simulated trigger & keyboard navigation | Constellation layout, arrow key selection, hold-to-confirm for destructive actions |
| Overlay Mutual Exclusivity | IPC overlay transitions | Opening SessionOverlay dismisses active overlays without leaked grab |
| Multi-Monitor & Fullscreen | Dual-monitor (`VIRTUAL-1`, `VIRTUAL-2`) test harness | SessionOverlay maps per-monitor on Overlay layer; keyboard focus exclusively on active monitor |

---

# 10. Exit Criteria & Stop Conditions

M5 exits only when `M5-T1` through `M5-T6` are complete, validated with live evidence, audited against `ANTI-SLOP.md`, documented in `STATE.md`, and recorded in `CP-M5-001` (`CHECKPOINT.md`).

The agent must **STOP**:

- after completing and auditing each requested atomic task (`M5-T1`);
- immediately if a source-of-truth conflict requiring owner governance (`DEC-043`) is discovered;
- immediately if a repeated runtime blocker prevents honest validation;
- unconditionally upon completing M5 (`CP-M5-001`), without auto-starting M6 (`AGENTS.md` §46, §48).

---

# 11. Current Status

- **Active Phase:** `M5 — Session, Lock & Polish` (*`ROADMAP.md` §12: `M5 — Session, Lock & Polish`*)
- **Completed Milestones:**
  - `M0 — Foundation` (`CP-M0-001` `VERIFIED`)
  - `M1 — Desktop Core` (`CP-M1-001` `VERIFIED`)
  - `M2 — Interaction` (`CP-M2-001` `VERIFIED`)
  - `M3 — System Feedback` (`CP-M3-001` `VERIFIED`)
  - `M4 — Personalization` (`CP-M4-001` `VERIFIED`)
- **Completed Tasks in Phase:**
  - (None yet)
- **Active Task:** `M5-T1` (Session & Power Management Overlay — in progress).
- **Next Executable Task:** `M5-T2` (Idle & Inhibitor Service — awaiting M5-T1 completion).
