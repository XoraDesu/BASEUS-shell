# STATE.md

**Project:** BASEUS  
**Document role:** Current project state  
**Authority:** Records reality; does not redefine product intent.

---

# 1. Purpose

`STATE.md` records the actual condition of the BASEUS project at a given point in time.

It answers:

> **Where is the project right now?**

It must remain factual.

It must not become:

- a second roadmap;
- a design document;
- a decision ledger;
- a wishlist;
- a replacement for `TASKS.md`;
- a justification for changing locked product truth.

If reality changes, `STATE.md` changes.

If product intent changes, the appropriate source-of-truth document must change through the established governance process.

---

# 2. Current Baseline

BASEUS is being rebuilt from a clean project baseline.

The current authoritative product foundation consists of the locked:

- `MASTER.md`
- `DESIGN.md`
- `ANTI-SLOP.md`
- `DECISIONS.md`
- `ROADMAP.md`
- `AGENTS.md`
- `TASKS.md`

These documents define product intent, design language, quality rules, accepted decisions, roadmap sequencing, agent behavior, and current executable scope.

---

# 3. Legacy State Boundary

Previous implementation trackers are not part of the current baseline.

Historical implementation details must not be interpreted as current project state merely because they existed in an earlier project version.

In particular:

- old implementation phases are not current phases;
- old shell components are not assumed to exist;
- old Waybar/Fuzzel/Mako-style architecture is not assumed to exist;
- old installer progress is not current installer progress;
- old task completion is not current task completion;
- old blockers are not automatically current blockers.

The current execution baseline starts from the new roadmap at **M0 — Foundation**.

---

# 4. Current Roadmap Position

## Milestone

**M1 — Desktop Core** (*`ROADMAP.md` §8: `M1 — Desktop Foundation`*)

## Phase

**M1 — Desktop Core**

## Execution Status

**IN PROGRESS — Task `M1-T1` COMPLETE and VERIFIED; Tasks `M1-T2` through `M1-T6` NOT STARTED.**

The **M0 — Foundation** baseline is complete, approved, and anchored at verified checkpoint `CP-M0-001` (commit `9a37a1420dd702ed8fe4d1ed036016d1732f60ea`) under **Foundation Freeze** (`DEC-043`).

Active execution has formally transitioned to **M1 — Desktop Core**. Task `M1-T1` (*Workspace Capability, Per-Monitor Navigation & Hyprland Desktop Preset*) is implemented, statically verified (`qmllint 6.12.0` — 0 errors, 0 warnings), and runtime-verified under both offline multi-monitor simulation (`MockHyprlandBridge`) and a live dual-monitor `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`) + `Quickshell 0.3.2` session on WSL2 Arch Linux.

---

# 5. Current Task Tracker Position

`TASKS.md` defines the executable **M1 — Desktop Core** scope across six atomic tasks (`Capability → Surface` per `DEC-045`):

1. **`M1-T1` — Workspace Capability, Per-Monitor Navigation & Hyprland Desktop Preset:** `COMPLETE / VERIFIED`
2. **`M1-T2` — Freeform Window Capability (Geometry, Maximize vs Native Fullscreen, Minimize & Centered Restore):** `NOT STARTED`
3. **`M1-T3` — Action Registry & Desktop Navigation Primitives (`Back` / `Home` / `Overview`):** `NOT STARTED`
4. **`M1-T4` — Per-Monitor Layer-Shell Desktop Scaffolding (`DesktopHost`):** `NOT STARTED`
5. **`M1-T5` — Contextual Workspace Indicator & Minimal Top Island Idle Anchor:** `NOT STARTED`
6. **`M1-T6` — M1 End-to-End Multi-Monitor Validation, Anti-Slop Audit & Checkpoint `CP-M1-001`:** `NOT STARTED`

No M1 task should be considered complete merely because it has been designed or documented.

---

# 6. Implementation Reality

Current factual implementation status:

- M0 Foundation (`CP-M0-001`, commit `9a37a1420dd702ed8fe4d1ed036016d1732f60ea`) and `M1-T1` workspace capability source/configuration files exist and have been runtime-tested under `Quickshell 0.3.2` and live `Hyprland 0.57.0` on WSL2 Arch Linux;
- Repository structure matches `MASTER.md` §59, augmented with `config/hypr/baseus-desktop.lua` (`Hyprland 0.57+` Lua preset) and `config/hypr/baseus-desktop.conf` (`< 0.57` Hyprlang reference preset);
- Quickshell entrypoint `shell.qml` loads root `Shell` from `src/Shell.qml` and exposes diagnostic `Quickshell.Io` `IpcHandler` target `baseus` (`status`, `restart`, `switchWorkspace`, `switchMonitorWorkspace`, `nextWorkspace`, `previousWorkspace`, `workspaces`);
- Core singletons (`Logger`, `EventBus`, `Config`, `Lifecycle`, `ShellState`, `Theme`, `MonitorModel`, `WorkspaceModel`, `WindowModel`, `HyprlandBridge` / `MockHyprlandBridge`) initialize and tear down in deterministic dependency order with stable `EventBus` subscription counts (`monitor: 3, workspace: 1, window: 2, theme: 1`);
- `Config.qml` loads layered JSON synchronously via `Quickshell.Io` `FileView`, supports optional `workspaces.labels` and `workspaces.tags` (`1..10`), explicitly rejects and logs `WARN` on `workspaces.count` override attempts (`DEC-010`) and stray `"theme"` blocks (`DEC-012`), and falls back safely on missing or malformed JSON;
- `WorkspaceModel.qml` enforces the fixed 10-workspace model (`DEC-010`), tracks per-monitor `activeWorkspaces` and `previousWorkspaces`, manages optional workspace `labels` and `tags`, provides bounded `1..10` relative stepping (`getRelativeWorkspace`, `canStepWorkspace`), computes workspace occupancy and full 10-workspace snapshots from `WindowModel`, reconciles monitor hotplug changes via `"monitor"` events, and emits normalized `{ source: "model", type: "changed", monitorIndex, previous, current, label, tag }` transitions;
- `HyprlandBridge.qml` synchronizes multi-monitor topology and per-monitor active workspaces directly over `Hyprland.requestSocketPath` (`.socket.sock` `j/monitors` via `Quickshell.Io` `Socket` + `SplitParser`, zero child processes spawned, compatible with `Hyprland 0.57.0`'s updated `specialWorkspace` JSON schema), resolves monitor ownership by output name across `focusedmon`/`focusedmonv2`/`workspace`/`workspacev2`/`moveworkspace`/`moveworkspacev2`/`monitoradded`/`monitorremoved`, and dispatches monitor-targeted direct and relative `1..10` workspace navigation in both Lua (`0.57+`) and legacy Hyprlang (`< 0.57`) modes;
- `MockHyprlandBridge.qml` provides multi-monitor per-monitor workspace simulation parity without injecting unconfigured fake workspace labels;
- `config/hypr/baseus-desktop.lua` loads cleanly in live `Hyprland 0.57.0` with zero configuration errors (`hyprctl -j configerrors` == `[""]`), configuring 22 keybinds (`Super+1..0`, `Super+Shift+1..0`, freeform pointer drag/resize), 4-finger horizontal workspace swipe (`hl.gesture`), non-wrapping workspace transitions with `fade` context animation (`MASTER.md` §7), default freeform floating + centered window rules (`DEC-008`), 1px solid tonal borders without blur/glow (`DESIGN.md` §34), and zero scratchpad bindings (`DEC-038`);
- Static validation via `scripts/validate.sh --all` (`/usr/lib/qt6/bin/qmllint` `6.12.0` across all 20 QML files) and `scripts/validate.ps1` succeeds with 0 errors and 0 warnings;
- M1 tasks `M1-T2` (window maximize vs native fullscreen, minimize + centered restore), `M1-T3` (`ActionRegistry` & `NavigationController`), `M1-T4` (`DesktopHost`), and `M1-T5` (`WorkspaceIndicator` & `TopIslandAnchor`) are not yet implemented;
- No performance baseline is claimed;
- Release readiness is NOT APPLICABLE.

---

# 7. Repository Reality

Based on direct inspection:

- Git repository initialized on branch `main` with verified M0 baseline commit `9a37a1420dd702ed8fe4d1ed036016d1732f60ea` (`CP-M0-001`);
- Root Quickshell entrypoint `shell.qml` is present;
- Source directory `src/` and core/theme/dev subsystems (`src/core/`, `src/theme/`, `src/dev/`) are present;
- Configuration directory `config/` contains `config/baseus.json`, `config/hypr/baseus-desktop.lua`, and `config/hypr/baseus-desktop.conf`;
- Documentation directory `docs/` with architecture, development, and configuration guides is present;
- Validation scripts `scripts/validate.sh` and `scripts/validate.ps1` are present;
- GitHub issue templates and PR template are present in `.github/`;
- Root repository files (`LICENSE`, `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.gitignore`) are present.

---

# 8. Runtime Reality

The runtime environment targets:

- Linux;
- Hyprland;
- Quickshell.

Current verified Linux runtime environment (WSL2):

- **Distribution / Kernel:** `Arch Linux` on WSL2 (`Linux 6.18.54.1-microsoft-standard-WSL2`)
- **Wayland Display:** WSLg (`WAYLAND_DISPLAY=wayland-0`) and nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` → live `Hyprland` child `WAYLAND_DISPLAY=wayland-1`)
- **Shell Runtime:** `Quickshell 0.3.2` (`quickshell-git`, rev `9b0f339b19057f4731bf3b48293307d7ef241671`), Qt / `qmllint 6.12.0`
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, Lua config manager `Hyprland.usingLua == true`, single and dual headless outputs `VIRTUAL-1`, `VIRTUAL-2` loaded with `config/hypr/baseus-desktop.lua`)

Runtime conditions **VERIFIED** on WSL2 Arch Linux (`Quickshell 0.3.2` + live `Hyprland 0.57.0`):

- Quickshell launches BASEUS (`quickshell -p . -d -n`) both standalone on WSLg (`wayland-0`) and directly inside a live `Hyprland 0.57.0` Wayland session (`wayland-1`);
- live `Hyprland 0.57.0 -c config/hypr/baseus-desktop.lua` boots cleanly with zero config errors (`hyprctl -j configerrors` == `[""]`), 22 keybinds (`Super+1..0`, `Super+Shift+1..0`, freeform drag/resize), 4-finger horizontal workspace swipe (`hl.gesture`), default floating window rule, and zero scratchpad bindings (`DEC-038`);
- live `Hyprland 0.57.0` IPC sockets (`.socket.sock` and `.socket2.sock` under `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/`) connect cleanly with `bridgeType: "hyprland"` and `bridgeConnected: true`;
- direct `.socket.sock` `j/monitors` query via `Quickshell.Io` `Socket` + `SplitParser` synchronizes dual headless monitors (`VIRTUAL-1` `id=0`, `VIRTUAL-2` `id=1`, `monitorCount: 2`) without spawning child processes;
- live multi-monitor per-monitor workspace navigation (`switchMonitorWorkspace 1 7`, `switchMonitorWorkspace 0 3`, `nextWorkspace` → `4`, `previousWorkspace` → `3`, `1..10` boundary clamping at `1` and `10`, and cross-monitor focus `switchWorkspace 7` returning focus to `VIRTUAL-2` without altering `VIRTUAL-1`'s workspace `3`) updates `WorkspaceModel` (`activeWorkspaces`, `previousWorkspaces`) and `ShellState` deterministically;
- live `workspaces` snapshot reflects user-configured `labels` and `tags`, `visibleOnMonitor`, and `WindowModel`-derived `windowCount` for live Wayland client windows (`floating: true`);
- live monitor hotplug removal (`hyprctl output remove VIRTUAL-2`) reconciles `MonitorModel` (`monitorCount: 2 → 1`), `WorkspaceModel` (`activeWorkspaces`, `previousWorkspaces`), and `ShellState`;
- live Wayland client window lifecycle inside Hyprland (`openwindow` with `floating: true`, `fullscreen>>1` → `ShellState.mode: "fullscreen"`, `fullscreen>>0` → `ShellState.mode: "desktop"`, `closewindow` + `activewindowv2>>` → `windowCount: 0, focusedWindow: ""`) is observed accurately;
- shell lifecycle (`uninitialized` → `initializing` → `running` → `tearing_down` → `terminated`) behaves deterministically, including live restart while connected to Hyprland (`restartCount: 1`, `bridgeConnected: true`, `subscriptions: { monitor: 3, workspace: 1, window: 2, theme: 1 }`) and 6 consecutive standalone restarts without duplicate `EventBus` subscriptions;
- configuration loads synchronously via `FileView`, reloads updated disk files on restart, rejects `workspaces.count` overrides (`DEC-010`) and stray `"theme"` keys (`DEC-012`) with `WARN` diagnostics, and falls back safely on missing, malformed, or out-of-range JSON;
- `EventBus` routes workspace, window, monitor, and theme events to domain models under both live `HyprlandBridge` and `MockHyprlandBridge` (`BASEUS_SIMULATION=1`) and enforces the fixed 10-workspace boundary (`DEC-010`);
- `HyprlandBridge` detects missing `HYPRLAND_INSTANCE_SIGNATURE`, logs a clear `WARN` diagnostic, reports `bridgeConnected: false`, and safely rejects live workspace dispatch without crashing;
- failure diagnostics and structured log levels (`debug`, `info`, `warn`, `error`) work as configured.

Runtime conditions remaining **NOT YET VERIFIED** (scheduled for upcoming M1 tasks or physical hardware milestones):

- maximize vs native fullscreen mode distinction and scratchpad-free minimize + centered restore (`M1-T2`);
- `ActionRegistry` and `Back` / `Home` / `Overview` navigation primitives (`M1-T3`);
- per-monitor Layer-Shell `DesktopHost`, contextual `WorkspaceIndicator`, and minimal `TopIslandAnchor` surfaces (`M1-T4`–`M1-T5`);
- physical multi-monitor DRM hardware scanout, physical 4-finger touchpad hardware input, and hardware GPU desktop performance baseline;
- interactive surface accessibility validation (`M1-T5`+).

---

# 9. Product Truth Status

The product/design foundation is locked.

Current authoritative product state:

| Source | Status |
|---|---|
| `MASTER.md` | LOCKED |
| `DESIGN.md` | LOCKED |
| `ANTI-SLOP.md` | LOCKED |
| `DECISIONS.md` | LOCKED |
| `ROADMAP.md` | LOCKED |
| `AGENTS.md` | LOCKED |
| `TASKS.md` | LOCKED |

These documents are not implementation status reports.

---

# 10. Design Baseline

The implementation must preserve the established BASEUS design language.

The current design baseline includes:

- wabi-sabi as the static visual foundation;
- cyberpunk primarily through motion and effects;
- solid surfaces as the preferred surface language;
- intentional whitespace;
- contextual hierarchy;
- freeform-first window mental model;
- centered/edge-integrated interaction surfaces;
- controlled motion;
- semantic/iconographic restraint;
- exactly four main palette colors;
- Matugen-based palette behavior;
- theme as visual state rather than behavior.

No implementation claim should be interpreted as permission to redesign these foundations.

---

# 11. Architectural Baseline

The foundation architecture is expected to support:

- Quickshell runtime;
- explicit shell lifecycle;
- centralized state ownership;
- explicit event flow;
- Hyprland integration boundary;
- configuration/state separation;
- diagnostics;
- reproducible validation.

The exact implementation details remain implementation concerns unless they conflict with locked product decisions.

---

# 12. Current Feature Reality

The following future surfaces are **not currently claimed as implemented**:

## Desktop interaction

- Dock;
- Top Island;
- Command Center;
- App Drawer;
- Overview;
- advanced window arrangement.

## System feedback

- notifications;
- OSD;
- media surface;
- system feedback choreography.

## Personalization

- wallpaper system;
- Matugen integration;
- theme runtime;
- widget system;
- Headquarter.

## Personality

- Power Menu constellation;
- Bongo Cat;
- Chibi;
- personality transitions.

## Distribution

- installer;
- updater;
- uninstaller;
- doctor/recovery;
- packaging.

Their intended scope is defined by `ROADMAP.md`, not by this file.

---

# 13. Current Validation Status

Current validation status based on direct verification:

| Validation Area | Status | Evidence |
|---|---|---|
| Repository validation | VERIFIED | `scripts/validate.sh --all` (WSL2 Arch Linux) and `scripts/validate.ps1` (Windows) passed with 0 errors including `config/hypr/baseus-desktop.{lua,conf}` |
| Quickshell syntax / config | VERIFIED | `/usr/lib/qt6/bin/qmllint` (`6.12.0`) passed all 20 `.qml` files with 0 errors and 0 warnings; `config/baseus.json` validated JSON; `Hyprland 0.57.0 -c config/hypr/baseus-desktop.lua` passed with 0 `configerrors` |
| Quickshell runtime startup & IPC | VERIFIED | `quickshell -p /mnt/d/Linux/BASEUS` (`0.3.2`) launched cleanly on WSL2 `wayland-0` and inside live Hyprland (`wayland-1`); `baseus` IPC methods (`status`, `restart`, `switchWorkspace`, `switchMonitorWorkspace`, `nextWorkspace`, `previousWorkspace`, `workspaces`) verified |
| Hyprland runtime validation | VERIFIED | Live `Hyprland 0.57.0` (`config/hypr/baseus-desktop.lua`, `.socket.sock` + `.socket2.sock`, `VIRTUAL-1` + `VIRTUAL-2`) + `Quickshell 0.3.2` verified direct `j/monitors` sync, per-monitor workspace switching (`1..10`), relative stepping, cross-monitor focus, floating Wayland window occupancy, monitor hotplug removal, and live restart resync |
| Lifecycle validation | VERIFIED | Deterministic init/teardown, 6 consecutive standalone restarts, and live dual-monitor Hyprland restart verified with stable `EventBus` subscriptions |
| State architecture validation | VERIFIED | `ShellState`, `MonitorModel`, `WorkspaceModel` (fixed 1–10 per-monitor `activeWorkspaces`, `previousWorkspaces`, `labels`, `tags`, `WindowModel` occupancy, hotplug reconciliation), and `WindowModel` verified under both `BASEUS_SIMULATION=1` and live Hyprland |
| Event architecture validation | VERIFIED | `EventBus` routing, non-circular `source` filtering, and stable subscription counts (`monitor: 3, workspace: 1, window: 2, theme: 1`) across restarts verified at runtime |
| Configuration validation | VERIFIED | Layered `FileView` loading, `workspaces.labels` & `workspaces.tags`, `DEC-010` `workspaces.count` override warning/rejection, `DEC-012` `"theme"` block rejection, missing/malformed JSON fallback, and live disk reload on restart verified at runtime |
| Logging validation | VERIFIED | Structured `[LEVEL] [Subsystem]` diagnostics verified via `quickshell log` across `info`, `debug`, `warn`, and `error` paths |
| Performance baseline | NOT YET VERIFIED | Requires live native Linux + Hyprland desktop session |
| Multi-monitor validation | PARTIALLY VERIFIED | Dual virtual headless outputs (`VIRTUAL-1` + `VIRTUAL-2`) per-monitor workspace state, cross-monitor focus, and hotplug removal `VERIFIED` live in `Hyprland 0.57.0`; Layer-Shell UI surface placement (`M1-T4`–`M1-T5`) and physical DRM multi-head hardware `NOT YET VERIFIED` |
| Accessibility validation | NOT YET VERIFIED | Requires interactive desktop surfaces (`M1-T5`+) |
| Release validation | NOT APPLICABLE | Desktop Core phase |

This table must be updated from evidence, not assumptions.

---

# 14. Current Blockers

- **None for M1 — Desktop Core (`M1-T1` complete; `M1-T2` unblocked).** Live `Hyprland 0.57.0` (`Aquamarine 0.15.1`) multi-output execution in WSL2 runs deterministically via the user-space nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128`, `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`) with headless outputs `VIRTUAL-1` and `VIRTUAL-2`, and `HyprlandBridge.qml` queries `j/monitors` directly over `.socket.sock` (`Quickshell.Io.Socket` + `SplitParser`) to stay compatible with `Hyprland 0.57.0`'s monitor JSON schema. (Physical multi-monitor DRM hardware scanout, physical 4-finger touchpad hardware gestures, and hardware GPU performance measurement still require a native Linux desktop machine.)

---

# 15. Current Risks

The current primary risks are process risks rather than claimed runtime failures.

### Risk: Legacy resurrection

Old implementation details may accidentally be treated as current truth.

**Control:** Use the current locked source-of-truth hierarchy and this state document.

### Risk: Documentation drift

Implementation may diverge from locked documents.

**Control:** Agents validate against `MASTER.md`, `DESIGN.md`, `ANTI-SLOP.md`, and `DECISIONS.md`.

### Risk: False completion

A task may be marked complete because code exists without runtime validation.

**Control:** Completion requires evidence and validation.

### Risk: Scope creep into M2+

Interactive M2 surfaces (Dock, full Top Island hover expansion/quick controls, Command Center, App Drawer) or M5 Overview UI may accidentally creep into M1's minimal foundational scope.

**Control:** `TASKS.md` strictly limits M1 to workspace/window/navigation capabilities plus minimal `DesktopHost`, transient `WorkspaceIndicator`, and idle `TopIslandAnchor`.

### Risk: Architecture violating Foundation Freeze

M1 tasks could bypass M0 `ShellState` / `EventBus` / `HyprlandBridge` boundaries (`DEC-043`).

**Control:** All M1 capabilities and surfaces must consume and extend M0 state/event infrastructure cleanly.

---

# 16. Current Working Assumptions

These are implementation assumptions, not new product decisions:

- **M1 — Desktop Core** (*`ROADMAP.md` §8: `M1 — Desktop Foundation`*) is the active phase.
- M0 Foundation (`CP-M0-001`) is frozen under Foundation Freeze (`DEC-043`) and extended cleanly rather than rewritten.
- Current implementation status must be discovered from actual files/runtime.
- Quickshell is the shell runtime.
- Hyprland is the required compositor environment (`Hyprland 0.57+` Lua primary preset with `< 0.57` Hyprlang compatibility).
- Future UI surfaces consume shared state/event infrastructure rather than recreating it independently.
- Validation must distinguish static evidence from live runtime evidence.

If an assumption becomes false, update the relevant state and, if necessary, the appropriate source-of-truth document.

---

# 17. State Update Rules

`STATE.md` should be updated when material project reality changes.

Examples:

- phase begins;
- task starts;
- task completes;
- task becomes blocked;
- validation succeeds;
- validation fails;
- runtime environment changes;
- architecture is actually implemented;
- known-good checkpoint is created;
- a previously unknown condition is verified.

Do not update state merely because an idea was discussed.

---

# 18. Status Vocabulary

Use precise status language.

### NOT STARTED

Work has not begun.

### IN PROGRESS

Implementation work is actively underway.

### VERIFIED

The stated condition has been checked against evidence.

### COMPLETE

The task's implementation and required validation are complete.

### BLOCKED

A verified dependency or failure prevents continuation.

### UNVERIFIED

The condition may exist, but evidence has not been collected.

### DEFERRED

The work is intentionally outside the current execution boundary.

### NOT APPLICABLE

The validation or task does not apply to the current phase.

Avoid vague status such as:

- probably done;
- should work;
- seems fine;
- basically complete;
- production-ready.

---

# 19. Evidence Rules

Every meaningful state claim should be grounded in one of:

- repository inspection;
- source inspection;
- command output;
- runtime observation;
- reproducible test;
- explicit owner decision.

Documentation alone proves documentation exists.

Code alone proves code exists.

A runtime claim requires runtime evidence.

A performance claim requires performance evidence.

A release claim requires release validation.

---

# 20. State Versus Intent

The distinction is mandatory.

### Product intent

Defined by:

- `MASTER.md`
- `DESIGN.md`
- `DECISIONS.md`
- `ROADMAP.md`

### Quality enforcement

Defined by:

- `ANTI-SLOP.md`
- `AGENTS.md`

### Current executable scope

Defined by:

- `TASKS.md`

### Current reality

Defined by:

- `STATE.md`

### Known-good snapshots

Defined by:

- `CHECKPOINT.md`

Implementation must not modify product intent simply because current reality differs from the intended state.

---

# 21. Current Next Action

The immediate execution target is:

> **Task `M1-T2` — Freeform Window Capability (Geometry, Maximize vs Native Fullscreen, Minimize & Centered Restore)** inside active phase **M1 — Desktop Core**. Task `M1-T1` is complete, verified against `qmllint 6.12.0` and live dual-monitor `Hyprland 0.57.0` + `Quickshell 0.3.2`, committed atomically, and stopped cleanly per the `ORIENT → PLAN → ATOMIC COMMIT → AUDIT → STOP` loop.

The agent must inspect actual repository state and `TASKS.md` before beginning `M1-T2`.

---

# 22. Transition Conditions

M1 should transition toward M2 only after:

- all M1 tasks (`M1-T1` through `M1-T6`) are complete;
- M1 acceptance criteria (`TASKS.md` §8) are satisfied;
- required static, live multi-monitor runtime, and `ANTI-SLOP.md` / `DESIGN.md` reviews have been performed;
- unresolved blockers are understood;
- `STATE.md` accurately reflects reality;
- verified checkpoint `CP-M1-001` exists in `CHECKPOINT.md`;
- the M1 phase gate passes (`DEC-042`).

Completion of documentation alone does not transition the phase.

---

# 23. State Integrity Rule

The most important rule of this file is:

> **STATE.md records what is true, not what we wish were true.**

If uncertain:

- mark it `UNVERIFIED`;
- investigate;
- then update.

Never upgrade uncertainty into completion for convenience.

---

# 24. Current State Summary

```text
BASEUS
│
├── Product definition       LOCKED
├── Visual design            LOCKED
├── Anti-slop system         LOCKED
├── Decision ledger          LOCKED
├── Roadmap                  LOCKED
├── Agent protocol           LOCKED
├── Current tasks            ACTIVE (M1 — Desktop Core: M1-T1..M1-T6)
│
├── Active phase             M1 — Desktop Core (IN PROGRESS: M1-T1 VERIFIED, M1-T2 next)
├── Foundation baseline      CP-M0-001 (VERIFIED — commit 9a37a142)
├── Static validation        VERIFIED (qmllint 6.12.0: 0 errors, 0 warnings)
├── Quickshell runtime       VERIFIED (Quickshell 0.3.2 / WSL2 Arch Linux)
├── Hyprland live IPC        VERIFIED (Hyprland 0.57.0 + VIRTUAL-1 & VIRTUAL-2)
├── Multi-monitor state      PARTIALLY VERIFIED (dual virtual outputs VERIFIED; UI/DRM pending)
├── Performance              NOT YET VERIFIED
└── Release readiness        NOT APPLICABLE
```

---

# 25. Final Principle

`STATE.md` is a reality mirror.

It must stay smaller in authority than the product source of truth and stronger in factual discipline than a progress narrative.

When reality changes, record it.

When reality is unknown, say so.

When a phase is complete, prove it.

When implementation conflicts with product truth, do not rewrite reality or truth to make the conflict disappear.
