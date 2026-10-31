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
Current Phase (M4 — Personalization)
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

M0 Foundation, M1 Desktop Core, M2 Primary Surfaces, and M3 System Feedback are protected under **Foundation Freeze** (`DEC-043`). M4 work must extend existing subsystems (`Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, `MonitorModel`, `WorkspaceModel`, `WindowModel`, `NavigationController`, `ActionRegistry`, `DesktopHost`, `TopIslandAnchor`, `DockAnchor`, `CommandCenter`, `AppDrawer`, `NotificationModel`, `AudioService`, `MediaService`, `StatusService`, and `Theme`) rather than creating parallel state or event architectures.

---

# 3. Current Phase

## Milestone

**M4 — Personalization** (*`ROADMAP.md` §11: `M4 — Personalization`*)

## Phase

**M4 — Personalization**

## Phase Goal

Make BASEUS meaningfully personal while preserving the visual system and keeping theme state strictly separate from interaction behavior (`DEC-011`, `DEC-012`, `DEC-013`, `DEC-014`, `DEC-019`, `DEC-037`). Implement the four-color palette extraction pipeline with Matugen integration, wallpaper engine (per-workspace static vs global live wallpaper), dynamic Theme model with daily snapshot, floating Wallpaper Picker surface, and fullscreen Headquarter settings application with persistent right sidebar and contextual help.

---

# 4. Phase Scope

### IN SCOPE

- **Palette & Matugen Pipeline (`DEC-011`, `DEC-014`, `DESIGN.md` §27–28):**
  - Exactly four primary colors (`dominant`, `secondary`, `accent`, `neutral`) with derived tonal roles (`surfaceSolid`, `surfaceHighlight`, `surfaceRecessed`, `borderSubtle`, `textPrimary`, `textSecondary`).
  - Matugen image color extraction bridge with caching and contrast validation.
  - Deterministic fallback to calm Wabi-sabi palette (`Colors.qml`) when Matugen is absent or in simulation.
  - EventBus category `"theme"` emission (`palette_updated`).
- **Wallpaper Engine (`DEC-013`, `MASTER.md` §27):**
  - Static per-workspace wallpaper mapping (`1..10`).
  - Live global wallpaper support with bounded, sampled palette extraction (`DEC-014`).
  - Multi-monitor wallpaper layout adaptation (multi-monitor span vs per-monitor fit).
  - Quickshell layer-shell wallpaper surface (`WlrLayershell.layer: Background`).
- **Dynamic Theme System (`DEC-012`, `DEC-037`, `MASTER.md` §23–26):**
  - Visual state model: wallpaper, palette, widget layout, surface styling.
  - Daily auto-saved theme snapshot representing current visual state.
  - Theme transitions with transition masks (circle wipe, wavy wipe, bubble ripple) without scaling UI.
  - Strict separation: themes alter visual appearance and NEVER change gestures, shortcuts, or window behavior (`DEC-012`, `DEC-037`).
- **Wallpaper Picker Floating Surface (`MASTER.md` §27):**
  - Transient floating surface with library, favorites, and recent tabs.
  - Live thumbnail preview and instant application.
  - Triggerable via Command Center, shortcut, or Headquarter.
  - Dynamic Layer-Shell input masking with 0x0 idle footprint.
- **Headquarter Settings Application (`DEC-019`, `DESIGN.md` §24–25):**
  - Fullscreen settings application with persistent right sidebar and ICR organic fillets.
  - Contextual help bubble system anchored to the right of settings without shifting layout.
  - Progressive disclosure, live apply, and user-facing terminology.
  - Universal dismissal (`navigation.back` / Escape).

---

# 5. Phase Non-Goals

### OUT OF SCOPE

The following belong to future milestones in `ROADMAP.md` and must **not** be implemented in M4:

- **Desktop Experience (M5):** Helicopter overview window layout, dynamic freeform widget canvas snapping, smart window arrangement.
- **Personality (M6):** Advanced Bongo Cat personas, retro sound design, easter eggs.
- **Distribution (M7):** Pacman packaging, AUR PKGBUILD, installation wizard.
- **Uncontrolled Theming:** Arbitrary per-element CSS overrides, random theme-mixing, or unconstrained color palettes (`DEC-011`).
- **Wallpaper Slideshows:** Continuous random wallpaper shuffling (`MASTER.md` §27).

---

# 6. Dependencies

M4 depends upon:

- **M0 Foundation (`CP-M0-001`):** `Lifecycle`, `ShellState`, `EventBus`, `Config`, `Logger`, and `Theme`.
- **M1 Desktop Core (`CP-M1-001`):** Fixed 10 workspaces, `DesktopHost` layer-shell scaffolding, `HyprlandBridge`.
- **M2 Interaction (`CP-M2-001`):** `DockAnchor`, `TopIslandAnchor`, `CommandCenter`, `AppDrawer`, `ActionRegistry`.
- **M3 System Feedback (`CP-M3-001`):** `NotificationModel`, `AudioService`, `MediaService`, `StatusService`.

---

# 7. Milestone M4 Tasks

## Task M4-T1 — Palette & Matugen Pipeline Architecture

**Goal:** Implement `src/core/PaletteService.qml` managing color palette state, integrating Matugen color extraction with caching and deterministic fallback to default Wabi-sabi palette (`DEC-011`, `DEC-014`).

### Sub-tasks

- [x] Implement `PaletteService.qml` managing 4-color palette state (`dominant`, `secondary`, `accent`, `neutral`) and derived tonal roles.
- [x] Implement Matugen integration bridge, contrast ratio validation, and extraction caching (`DEC-014`).
- [x] Wire palette updates into `EventBus.qml` under `"theme"` category and expose diagnostic IPC endpoints on `Shell.qml`.
- [x] Validate static qmllint, offline simulation, and live Hyprland execution.

---

## Task M4-T2 — Wallpaper Engine (Static Per-Workspace vs Global Live Wallpaper)

**Goal:** Implement wallpaper rendering service and layer-shell wallpaper surface supporting per-workspace static vs global live wallpaper (`DEC-013`, `MASTER.md` §27).

### Sub-tasks

- [x] Implement `WallpaperService.qml` managing per-workspace static wallpaper and global live wallpaper state.
- [x] Implement `wallpaperVariants` layer-shell background surface under `DesktopHost.qml` (`WlrLayershell.layer: Background`, 0x0 hitmask).
- [x] Multi-monitor wallpaper layout adaptation (multi-monitor span vs per-monitor fit).
- [x] Validate wallpaper workspace switching and resource consumption.

---

## Task M4-T3 — Dynamic Theme System & Visual Transitions

**Goal:** Implement `ThemeService.qml` managing visual state snapshots, daily auto-saved snapshot, and cinematic transition masks (`MASTER.md` §23–26, `DEC-012`, `DEC-037`).

### Sub-tasks

- [x] Implement `ThemeService.qml` managing saved themes, daily snapshot, and active visual state.
- [x] Implement transition mask coordinator (circle wipe, wavy wipe, bubble ripple, fade) without scaling UI.
- [x] Enforce DEC-037: Theme changes strictly alter visual state without modifying behavior/shortcuts.
- [x] Validate theme serialization, persistence, and transition choreography.

---

## Task M4-T4 — Wallpaper Picker Floating Surface

**Goal:** Implement transient floating wallpaper picker surface (`MASTER.md` §27).

### Sub-tasks

- [x] Implement `WallpaperPicker.qml` floating transient surface with library, favorites, and recent tabs.
- [x] Implement live wallpaper thumbnail preview and keyboard navigation.
- [x] Wire triggers from Command Center and keybinds.
- [x] Validate dynamic layer-shell hitmask and clean dismissal.

---

## Task M4-T5 — Headquarter Settings Application

**Goal:** Implement fullscreen Headquarter settings application with persistent right sidebar and contextual help (`DEC-019`, `DESIGN.md` §24–25).

### Sub-tasks

- [ ] Implement `Headquarter.qml` fullscreen settings application with persistent right sidebar and organic ICR fillets.
- [ ] Implement categorized settings views (General, Display, Audio, Workspaces, Theme, About).
- [ ] Implement contextual help bubble system anchored to the right of settings controls (`DESIGN.md` §25).
- [ ] Wire universal dismissal (`navigation.back` / Escape) and mutual exclusivity with overlays.

---

## Task M4-T6 — M4 End-to-End Multi-Monitor Validation, Anti-Slop Audit & Checkpoint `CP-M4-001`

**Goal:** Verify all M4 personalization surfaces across dual-monitor live Hyprland + Quickshell execution, perform full anti-slop audit, update documentation, record `CP-M4-001`, and stop at M4 → M5 phase gate.

### Sub-tasks

- [ ] Run integrated E2E test suite combining Palette, Wallpaper, Theme transitions, Wallpaper Picker, and Headquarter across dual virtual outputs (`VIRTUAL-1`, `VIRTUAL-2`).
- [ ] Perform comprehensive anti-slop audit across all QML surfaces.
- [ ] Update `docs/architecture.md` and `docs/configuration.md`.
- [ ] Update `STATE.md`, record `CP-M4-001` in `CHECKPOINT.md`, report concisely, and **STOP**.

---

# 8. Acceptance Criteria

M4 is acceptable only when all of the following hold:

1. **Four-Color Palette Integrity (`DEC-011`):** Every theme and extracted palette consists of exactly four primary colors with derived tonal roles; zero component-level color invention.
2. **Bounded Matugen Extraction (`DEC-014`):** Palette extraction from wallpapers runs once, validates contrast, and is cached; live wallpaper does not continuously churn colors.
3. **Per-Workspace Static vs Global Live Wallpaper (`DEC-013`):** Static wallpapers map per-workspace (`1..10`); live wallpaper spans globally without duplicated rendering overhead.
4. **Theme / Behavior Separation (`DEC-012`, `DEC-037`):** Theme switching changes visual appearance (palette, wallpaper, widget layout, surface styles) and NEVER alters shortcuts, gestures, window management, or timeouts.
5. **Headquarter Fullscreen Architecture (`DEC-019`):** Headquarter presents a fullscreen configuration environment with persistent right sidebar and non-disruptive contextual help bubbles to the right (`DESIGN.md` §25).
6. **Zero-cost idle desktop:** Wallpaper surface stays on background layer with zero input grab; floating picker and Headquarter maintain 0x0 hitmask when idle.
7. **Zero-warning static & runtime stability:** `qmllint 6.12.0` passes with 0 errors and 0 warnings; live `Hyprland 0.57.0` + `Quickshell 0.3.2` execution passes without memory leaks or unhandled errors.

---

# 9. Validation Matrix

| Area | Validation Method | Required Evidence |
|---|---|---|
| Structure & QML Lint | `scripts/validate.sh --all` & `scripts/validate.ps1` | Exit code 0; `qmllint 6.12.0` passes with 0 errors and 0 warnings |
| Palette Extraction & Caching | Quickshell IPC + simulation / Matugen | 4-color palette generated, cached, and applied to `Theme.colors` with contrast validation |
| Wallpaper Layer Surface | Layer-shell query | Background layer placement (`WlrLayershell.layer: Background`), per-workspace static vs global live |
| Theme State Separation | IPC theme switch | Visual state changes; gestures, shortcuts, and window rules remain completely unchanged |
| Wallpaper Picker | Simulated click / trigger | Floating surface reveals, previews, applies wallpaper, and dismisses cleanly to 0x0 hitmask |
| Headquarter Settings | Open / navigate / dismiss | Fullscreen right-sidebar layout, contextual help displays on right without layout shift |
| Multi-Monitor & Fullscreen | Dual-monitor (`VIRTUAL-1`, `VIRTUAL-2`) test harness | Wallpaper spans or adapts per-monitor; Headquarter respects monitor focus |

---

# 10. Exit Criteria & Stop Conditions

M4 exits only when `M4-T1` through `M4-T6` are complete, validated with live evidence, audited against `ANTI-SLOP.md`, documented in `STATE.md`, and recorded in `CP-M4-001` (`CHECKPOINT.md`).

The agent must **STOP**:

- after completing and auditing each requested atomic task (`M4-T1`);
- immediately if a source-of-truth conflict requiring owner governance (`DEC-043`) is discovered;
- immediately if a repeated runtime blocker prevents honest validation;
- unconditionally upon completing M4 (`CP-M4-001`), without auto-starting M5 (`AGENTS.md` §46, §48).

---

# 11. Current Status

- **Active Phase:** `M4 — Personalization` (*`ROADMAP.md` §11: `M4 — Personalization`*)
- **Completed Milestones:**
  - `M0 — Foundation` (`CP-M0-001` `VERIFIED`)
  - `M1 — Desktop Core` (`CP-M1-001` `VERIFIED`)
  - `M2 — Interaction` (`CP-M2-001` `VERIFIED`)
  - `M3 — System Feedback` (`CP-M3-001` `VERIFIED`)
- **Completed Tasks in Phase:**
  - `M4-T1` (Palette & Matugen Pipeline Architecture — `COMPLETE / VERIFIED`)
  - `M4-T2` (Wallpaper Engine: Static Per-Workspace vs Global Live Wallpaper — `COMPLETE / VERIFIED`)
  - `M4-T3` (Dynamic Theme System & Visual Transitions — `COMPLETE / VERIFIED`)
  - `M4-T4` (Wallpaper Picker Floating Surface — `COMPLETE / VERIFIED`)
- **Active Task:** `M4-T4` complete and verified across offline simulation, live dual-monitor Hyprland 0.57.0 runtime, and full M1-M4 regressions. Stopped at the M4-T4 -> M4-T5 boundary per user directive and `AGENTS.md` §46.
- **Next Executable Task:** `M4-T5` (Headquarter Settings Application — awaiting user authorization).
