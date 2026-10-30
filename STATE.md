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

**M0 — Foundation**

## Phase

**M0 — Foundation**

## Execution Status

**M0 Foundation implementation COMPLETE and VERIFIED — statically verified (`qmllint 6.12.0`) and runtime-verified under `Quickshell 0.3.2` + live `Hyprland 0.57.0` (`Aquamarine 0.15.1`) on WSL2 Arch Linux (`CP-M0-001` VERIFIED).**

Quickshell entrypoint (`shell.qml`), shell composition (`src/Shell.qml`), core architecture (`Lifecycle`, `ShellState`, `EventBus`, `HyprlandBridge`, `MockHyprlandBridge`, `WorkspaceModel`, `WindowModel`, `MonitorModel`, `Config`, `Logger`), design token foundation (`src/theme/*`), visual preview stage (`src/dev/DesignStage.qml`), configuration defaults (`config/baseus.json`), diagnostic Quickshell IPC target (`baseus`), validation tooling (`scripts/validate.sh`, `scripts/validate.ps1`), and baseline documentation (`docs/architecture.md`, `docs/development.md`, `docs/configuration.md`) have been implemented and runtime-verified in WSL2 Arch Linux against both offline simulation (`MockHyprlandBridge`) and a live `Hyprland 0.57.0` compositor session (`.socket.sock`, `.socket2.sock`, `Quickshell.Hyprland` event observation, and `Hyprland.dispatch`).

---

# 5. Current Task Tracker Position

`TASKS.md` defines the executable M0 scope.

The current task tracker covers:

1. Repository Foundation
2. Quickshell Runtime Bootstrap
3. Shell Lifecycle
4. Core State Architecture
5. Core Event Architecture
6. Hyprland Integration Baseline
7. Configuration Boundaries
8. Diagnostics and Logging
9. Development and Validation Workflow
10. Baseline Documentation
11. Source-of-Truth Integration

No M0 task should be considered complete merely because it has been designed or documented.

---

# 6. Implementation Reality

Current factual implementation status:

- M0 Foundation source files exist and have been inspected and runtime-tested under `Quickshell 0.3.2` on WSL2 Arch Linux;
- Repository structure matches `MASTER.md` §59;
- Quickshell entrypoint `shell.qml` loads root `Shell` from `src/Shell.qml` and exposes diagnostic `Quickshell.Io` `IpcHandler` target `baseus` (`status`, `restart`, `switchWorkspace`);
- Core singletons (`Logger`, `EventBus`, `Config`, `Lifecycle`, `ShellState`, `Theme`, `MonitorModel`, `WorkspaceModel`, `WindowModel`, `HyprlandBridge` / `MockHyprlandBridge`) initialize and tear down in deterministic dependency order without late `Component.onCompleted` state clobbering or `[id-shadows-member]` alias issues;
- `Config.qml` loads layered JSON synchronously via `Quickshell.Io` `FileView` (`blockLoading: true`, `blockAllReads: true`, `waitForJob()`), rejects stray `"theme"` blocks per `DEC-012`, sanitizes out-of-range values, and falls back safely on missing or malformed JSON without failing startup;
- `HyprlandBridge.qml` honestly detects `HYPRLAND_INSTANCE_SIGNATURE` and `Hyprland.eventSocketPath`, reporting `connected = false` with an explicit `WARN` log when live Hyprland is absent, and when connected handles live `Quickshell.Hyprland` state synchronization, raw `.socket2.sock` workspace/monitor/window/fullscreen events, and `Hyprland.usingLua`-aware `Hyprland.dispatch(...)` calls (`hl.dsp.focus` / `hl.dsp.window.move` on Hyprland 0.57+ Lua config manager, with legacy Hyprlang fallback);
- Static validation via `scripts/validate.sh --all` (including `/usr/lib/qt6/bin/qmllint` `6.12.0` across all 20 QML files) and `scripts/validate.ps1` succeeds with 0 errors and 0 warnings;
- Quickshell runtime startup, deterministic teardown, 6 consecutive clean restarts, `EventBus` delivery and deduplication, domain model state updates, and malformed/invalid config fallback are `VERIFIED` on WSL2 Arch Linux;
- Live `Hyprland 0.57.0` compositor IPC (`HYPRLAND_INSTANCE_SIGNATURE`, `.socket.sock`, `.socket2.sock`, `bridgeConnected: true`, `hyprctl` → `socket2` → `WorkspaceModel`/`WindowModel`/`ShellState` event propagation, bidirectional `baseus switchWorkspace` → `Hyprland.dispatch`, live Wayland client window open/fullscreen/close tracking, and live restart state resynchronization) is `VERIFIED` on WSL2 Arch Linux;
- No performance baseline is claimed;
- Release readiness is NOT APPLICABLE.

---

# 7. Repository Reality

Based on direct inspection:

- Git repository initialized on branch `main`;
- Working tree contains untracked implementation files for M0;
- Root Quickshell entrypoint `shell.qml` is present;
- Source directory `src/` and core subsystem `src/core/` are present;
- Configuration directory `config/` and `config/baseus.json` are present;
- Documentation directory `docs/` with architecture, development, and configuration guides are present;
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
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, Lua config manager `Hyprland.usingLua == true`, headless output `VIRTUAL-1`)

Runtime conditions **VERIFIED** on WSL2 Arch Linux (`Quickshell 0.3.2` + live `Hyprland 0.57.0`):

- Quickshell launches BASEUS (`quickshell -p . -d -n`) both standalone on WSLg (`wayland-0`) and directly inside a live `Hyprland 0.57.0` Wayland session (`wayland-1`);
- live `Hyprland 0.57.0` IPC sockets (`.socket.sock` and `.socket2.sock` under `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/`) connect cleanly with `bridgeType: "hyprland"` and `bridgeConnected: true`;
- live `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'` emits `workspace>>2` / `workspacev2>>2,2` on `.socket2.sock`, captured by `HyprlandBridge.qml` to update `WorkspaceModel` (`activeWorkspace: 2`) and `ShellState`;
- bidirectional `quickshell ipc -p . call baseus switchWorkspace 4` dispatches `hl.dsp.focus({ workspace = 4 })` via `Hyprland.dispatch(...)` (`usingLua == true`), switching live Hyprland to workspace `4` (`hyprctl activeworkspace` == `4`) and updating `activeWorkspace: 4`;
- live Wayland client window lifecycle inside Hyprland (`openwindow` with `floating: true`, `fullscreen>>1` → `ShellState.mode: "fullscreen"`, `fullscreen>>0` → `ShellState.mode: "desktop"`, `closewindow` + `activewindowv2>>` → `windowCount: 0, focusedWindow: ""`) is observed accurately;
- shell lifecycle (`uninitialized` → `initializing` → `running` → `tearing_down` → `terminated`) behaves deterministically, including live restart while connected to Hyprland (`restartCount: 1`, `bridgeConnected: true`, `activeWorkspace: 4` re-synced) and 6 consecutive standalone restarts without duplicate `EventBus` subscriptions;
- configuration loads synchronously via `FileView`, reloads updated disk files on restart, ignores `"theme"` keys in behavioral config (`DEC-012`), and falls back safely on missing, malformed, or out-of-range JSON;
- `EventBus` routes workspace, window, monitor, and theme events to domain models under both live `HyprlandBridge` and `MockHyprlandBridge` (`BASEUS_SIMULATION=1`) and enforces the fixed 10-workspace boundary (`DEC-010`);
- `HyprlandBridge` detects missing `HYPRLAND_INSTANCE_SIGNATURE`, logs a clear `WARN` diagnostic, reports `bridgeConnected: false`, and safely rejects live workspace dispatch without crashing;
- failure diagnostics and structured log levels (`debug`, `info`, `warn`, `error`) work as configured.

Runtime conditions remaining **NOT YET VERIFIED** (deferred to interactive/hardware milestones beyond M0):

- physical multi-monitor DRM hardware scanout and pointer/surface placement across physical displays;
- hardware GPU desktop performance baseline under interactive surfaces;
- interactive surface accessibility validation (M1+ UI surfaces).

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
| Repository validation | VERIFIED | `scripts/validate.sh --all` (WSL2 Arch Linux) and `scripts/validate.ps1` (Windows) passed with 0 errors |
| Quickshell syntax / config | VERIFIED | `/usr/lib/qt6/bin/qmllint` (`6.12.0`) passed all 20 `.qml` files with 0 errors and 0 warnings; `config/baseus.json` validated JSON |
| Quickshell runtime startup & IPC | VERIFIED | `quickshell -p /mnt/d/Linux/BASEUS` (`0.3.2`) launched cleanly on WSL2 `wayland-0`; `quickshell ipc call baseus status` returned healthy runtime JSON |
| Hyprland runtime validation | VERIFIED | Live `Hyprland 0.57.0` (`HYPRLAND_INSTANCE_SIGNATURE=0aa6745f705f2c4b0a5004eb019ef76e5bbdb426_1793321236_1855700926`, `.socket.sock` + `.socket2.sock`, `VIRTUAL-1`) + `Quickshell 0.3.2` verified `bridgeConnected: true`, `hyprctl` workspace 2 `socket2` update, bidirectional `switchWorkspace 4` (`Hyprland.usingLua`), live Wayland window open/fullscreen/close events, live restart resync, and unavailable-Hyprland fallback |
| Lifecycle validation | VERIFIED | Deterministic init/teardown and 6 consecutive restarts (`quickshell ipc call baseus restart`) verified at runtime with `restartCount: 6` and `lifecycle: "running"` |
| State architecture validation | VERIFIED | `ShellState`, `MonitorModel`, `WorkspaceModel` (1–10 boundary enforced), and `WindowModel` state updates and clean restart resets verified at runtime under `BASEUS_SIMULATION=1` |
| Event architecture validation | VERIFIED | `EventBus` routing, non-circular `source` filtering, and stable subscription counts (`monitor: 2, workspace: 1, window: 2, theme: 1`) across 6 restarts verified at runtime |
| Configuration validation | VERIFIED | Layered `FileView` loading, missing/malformed JSON fallback, out-of-range field sanitization, `DEC-012` `"theme"` block rejection, and live disk reload on restart verified at runtime |
| Logging validation | VERIFIED | Structured `[LEVEL] [Subsystem]` diagnostics verified via `quickshell log` across `info`, `debug`, `warn`, and `error` paths |
| Performance baseline | NOT YET VERIFIED | Requires live native Linux + Hyprland desktop session |
| Multi-monitor validation | NOT YET VERIFIED | Requires live Linux + Hyprland session with multiple physical/virtual outputs |
| Accessibility validation | NOT YET VERIFIED | Requires live desktop session with interactive surfaces |
| Release validation | NOT APPLICABLE | Foundation phase |

This table must be updated from evidence, not assumptions.

---

# 14. Current Blockers

- **None for M0 — Foundation.** The previous WSL2 live `Hyprland 0.57.0` (`Aquamarine 0.15.1`) IPC verification blocker (`Cannot open backend: no allocator available`) was resolved in user space by running a minimal nested Wayland `zwp_linux_dmabuf_v1` host advertising `/dev/dri/renderD128` (`0666`) with `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast` and headless output `VIRTUAL-1`. (Note: physical multi-monitor DRM hardware scanout and hardware GPU performance measurement still require a native Linux desktop session in later milestones.)

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

### Risk: Scope creep

Future M1+ features may enter M0.

**Control:** `TASKS.md` is the active execution boundary.

### Risk: Architecture optimized for generic desktop-shell conventions

Foundation choices could accidentally make later BASEUS behavior awkward.

**Control:** Foundation implementation must remain compatible with locked design and interaction principles.

---

# 16. Current Working Assumptions

These are implementation assumptions, not new product decisions:

- M0 is the active phase.
- The repository should be treated as a clean rebuild.
- Current implementation status must be discovered from actual files/runtime.
- Quickshell is the shell runtime.
- Hyprland is the required compositor environment.
- Future UI should consume shared state/event infrastructure rather than recreate it independently.
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

> **M0 — Foundation** implementation, static validation, Quickshell runtime validation, and live `Hyprland 0.57.0` IPC runtime validation are **COMPLETE** and recorded in verified checkpoint `CP-M0-001`. Execution is stopped at the M0 → M1 phase boundary (`AGENTS.md` §46, §48; `DEC-042`), awaiting deliberate transition to **M1 — Desktop Core**.

The agent must inspect actual repository state before deciding which M0 foundation tasks are already satisfied.

---

# 22. Transition Conditions

M0 should transition toward M1 only after:

- M0 implementation is complete;
- M0 acceptance criteria are satisfied;
- required validation has been performed;
- unresolved blockers are understood;
- `STATE.md` accurately reflects reality;
- an appropriate checkpoint exists;
- the M0 phase gate passes.

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
├── Current tasks            LOCKED
│
├── Active phase             M0 — Foundation (COMPLETE — awaiting M1 transition)
├── Implementation           VERIFIED (qmllint 6.12.0 + Quickshell 0.3.2)
├── Quickshell runtime       VERIFIED (WSL2 Arch Linux / wayland-0 & wayland-1)
├── Hyprland live IPC        VERIFIED (Hyprland 0.57.0 + Quickshell 0.3.2)
├── Checkpoint               CP-M0-001 (VERIFIED)
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
