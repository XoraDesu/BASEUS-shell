# CHECKPOINT.md

**Project:** BASEUS  
**Document role:** Known-good checkpoint record  
**Authority:** Records verified project snapshots; does not redefine product intent.

---

# 1. Purpose

`CHECKPOINT.md` records known-good save points in the BASEUS project.

A checkpoint answers:

> **What exact project state was known to work, and what evidence supports that claim?**

A checkpoint is not:

- a roadmap;
- a task list;
- a design specification;
- a decision ledger;
- a replacement for `STATE.md`;
- permission to skip validation;
- proof that all future functionality works.

---

# 2. Checkpoint Philosophy

A checkpoint should make recovery and reasoning easier.

Each meaningful checkpoint should establish:

1. what was completed;
2. what was actually verified;
3. what environment was used;
4. what remains incomplete;
5. what limitations were known;
6. how the state can be recognized or reproduced.

The goal is to avoid vague claims such as:

- "it worked before";
- "the previous version was stable";
- "everything should still be fine."

A checkpoint must be evidence-oriented.

---

# 3. Relationship to Other Documents

| Document | Responsibility |
|---|---|
| `MASTER.md` | Product truth |
| `DESIGN.md` | Visual and interaction truth |
| `ANTI-SLOP.md` | Quality enforcement |
| `DECISIONS.md` | Accepted decisions |
| `ROADMAP.md` | Long-term sequencing |
| `TASKS.md` | Current executable scope |
| `STATE.md` | Current reality |
| `CHECKPOINT.md` | Known-good snapshots |
| `AGENTS.md` | Agent operating protocol |
| `MASTER-PROMPT.md` | Thin agent launcher |

`CHECKPOINT.md` records evidence about reality.

It must never be used to override a newer source-of-truth decision.

---

# 4. Checkpoint Status

A checkpoint may be:

### CANDIDATE

A potential checkpoint has been identified but required validation is incomplete.

### VERIFIED

Required validation has passed and the checkpoint is considered known-good for its stated scope.

### SUPERSEDED

A newer verified checkpoint replaces it as the preferred recovery/reference point.

### INVALIDATED

A later discovery proves that the checkpoint's stated condition was incorrect or no longer reproducible.

Do not call a checkpoint "known-good" without verification.

---

# 5. Required Checkpoint Record

Every checkpoint should record:

- checkpoint ID;
- date/time;
- phase;
- scope;
- repository revision;
- environment;
- implementation status;
- validation performed;
- known limitations;
- recovery/reference information;
- status.

The record should contain enough information to distinguish the checkpoint from nearby states.

---

# 6. Repository Identity

Where available, record:

- Git commit hash;
- branch;
- repository status;
- relevant tags;
- relevant configuration revision.

A checkpoint without repository identity is weaker because its exact source state may be ambiguous.

If Git is not yet established, explicitly record that fact rather than inventing a revision.

---

# 7. Environment Identity

For runtime checkpoints, record the relevant environment.

At minimum where applicable:

- operating system/distribution;
- kernel;
- Hyprland version;
- Quickshell version;
- relevant runtime/dependency versions;
- display/monitor arrangement if it materially affects behavior;
- relevant configuration state.

Do not record guessed versions.

Use actual inspection output.

---

# 8. Validation Evidence

Validation should be categorized.

## Static Validation

Examples:

- syntax checks;
- source inspection;
- configuration parsing;
- dependency resolution;
- repository checks.

## Runtime Validation

Examples:

- application starts;
- shell initializes;
- events are received;
- surfaces appear;
- restart works;
- failure paths behave correctly.

## Interaction Validation

Examples:

- keyboard shortcuts;
- gestures;
- workspace changes;
- window operations;
- surface transitions.

## Visual Validation

Examples:

- hierarchy;
- spacing;
- motion;
- palette;
- anti-slop review;
- multi-monitor presentation.

## Performance Validation

Examples:

- startup;
- memory;
- event responsiveness;
- animation behavior;
- long-session stability.

A checkpoint should only claim the categories that were actually tested.

---

# 9. Evidence Strength

Use precise evidence language.

### OBSERVED

Directly observed in the actual environment.

### REPRODUCED

Observed successfully more than once using a defined procedure.

### VERIFIED

Tested against an explicit acceptance criterion.

### STATICALLY VERIFIED

Confirmed from source/configuration without runtime execution.

### UNVERIFIED

Not tested.

### NOT APPLICABLE

Does not apply to the checkpoint scope.

Avoid treating code inspection as runtime proof.

---

# 10. Checkpoint Creation Rule

Create a checkpoint when a meaningful, validated state is reached.

Typical triggers:

- foundation phase completion;
- major phase gate passed;
- major architecture milestone;
- recovery after a risky migration;
- release candidate;
- final release;
- owner-requested known-good state.

Do not create checkpoints for every tiny edit.

---

# 11. Checkpoint Boundary

A checkpoint should represent a coherent state.

Do not create a checkpoint in the middle of a partially applied architectural migration unless the checkpoint explicitly records that it is a candidate or recovery-only state.

A verified checkpoint should be internally consistent.

---

# 12. Current Baseline

The current BASEUS documentation foundation is established.

The following product/project documents are locked:

- `MASTER.md`
- `DESIGN.md`
- `ANTI-SLOP.md`
- `DECISIONS.md`
- `ROADMAP.md`
- `AGENTS.md`
- `TASKS.md`
- `STATE.md`

This documentation state is a project baseline.

It is **not** a runtime checkpoint.

No runtime checkpoint should be implied until actual implementation and validation evidence exists.

---

# 13. Initial Checkpoint

## CP-000 — Documentation Baseline

**Status:** VERIFIED AS DOCUMENTATION BASELINE

### Scope

The current product and execution foundation has been established through the locked source-of-truth documents.

### Included

- product definition;
- visual/interaction design;
- anti-slop quality system;
- accepted decisions;
- roadmap;
- agent protocol;
- current M0 task boundary;
- current state model.

### Excluded

This checkpoint does not assert:

- Quickshell runtime success;
- Hyprland integration success;
- implementation completion;
- UI completion;
- performance readiness;
- installer readiness;
- release readiness.

### Evidence

The checkpoint is based on the existence and locked status of the project documentation baseline.

### Runtime Status

**NOT VERIFIED**

### Recovery Meaning

This checkpoint represents the conceptual/documentation baseline from which the clean M0 implementation begins.

---

# 14. M0 Foundation Checkpoint

## CP-M0-001 — Foundation Architecture Implementation

**Status:** VERIFIED (Static Validation, Quickshell 0.3.2 Runtime, and Live Hyprland 0.57.0 Compositor IPC Verified on WSL2 Arch Linux)  
**Date:** 2026-10-30  
**Phase:** M0 — Foundation  
**Scope:** Core Quickshell runtime bootstrap, shell lifecycle, centralized state, decoupled event bus, Hyprland bridge boundary + offline simulation bridge, design token foundation, configuration manager, diagnostic logger + IPC target, validation tooling, and baseline documentation.

### Repository

- **Commit:** `9a37a1420dd702ed8fe4d1ed036016d1732f60ea` (`feat(m0): complete verified M0 foundation baseline (CP-M0-001)`, anchored on top of `e3218a5e5f09792583b79873299ff71ca5925d16`)
- **Branch:** `main`
- **Working tree:** Implementation files present (`shell.qml`, `src/`, `config/`, `docs/`, `scripts/`)
- **Repository structure:** Matches `MASTER.md` §59 and `TASKS.md` §7

### Environment

- **Host OS:** Windows with WSL2 Linux runtime (`/mnt/d/Linux/BASEUS`)
- **Linux Distribution & Kernel:** `Arch Linux` on WSL2 (`Linux 6.18.54.1-microsoft-standard-WSL2`)
- **Display Connection:** WSLg Wayland (`WAYLAND_DISPLAY=wayland-0`) and nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` → live Hyprland child `WAYLAND_DISPLAY=wayland-1`)
- **Shell Runtime:** `Quickshell 0.3.2` (`quickshell-git`, rev `9b0f339b19057f4731bf3b48293307d7ef241671`)
- **Qt / QML Tooling:** Qt 6 (`qmllint 6.12.0` at `/usr/lib/qt6/bin/qmllint`)
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`, Lua config manager `Hyprland.usingLua == true`, headless output `VIRTUAL-1`)

### Implementation

- **Repository foundation:** All locked documents present; `LICENSE`, `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.gitignore`, `.github/` templates established.
- **Quickshell bootstrap & diagnostic IPC:** `shell.qml` root entrypoint; `src/Shell.qml` composition root with clean subsystem aliases and `Quickshell.Io` `IpcHandler` target `baseus` (`status`, `restart`, `switchWorkspace`).
- **Lifecycle:** `src/core/Lifecycle.qml` deterministic state machine (`uninitialized` → `initializing` → `running` → `tearing_down` → `terminated`) with subsystem init/teardown orchestration and consecutive-failure loop protection (`maxInitAttempts: 5`) decoupled from clean `restartCount`.
- **State architecture:** `src/core/ShellState.qml` central singleton; domain models `WorkspaceModel.qml` (fixed 10 workspaces per `DEC-010`), `WindowModel.qml` (freeform/floating), `MonitorModel.qml` (multi-monitor) subscribed to `EventBus` without late `Component.onCompleted` clobbering.
- **Event architecture:** `src/core/EventBus.qml` category subscription, `source`-guarded non-circular updates, duplicate prevention, isolated handler error recovery, and `unsubscribeAll` teardown cleanup.
- **Hyprland integration:** `src/core/HyprlandBridge.qml` honest `HYPRLAND_INSTANCE_SIGNATURE` + `Hyprland.eventSocketPath` detection, gated `Quickshell.Hyprland` (`Hyprland`) initial sync + raw `.socket2.sock` parsing (`workspace`/`workspacev2`, `focusedmon`/`focusedmonv2`, `openwindow`, `closewindow`, `activewindowv2`, `movewindow`/`movewindowv2`, `fullscreen`, `monitoradded`/`monitorremoved`) + `Hyprland.usingLua`-aware `Hyprland.dispatch(...)` (`hl.dsp.focus` / `hl.dsp.window.move` on Hyprland `0.57+` Lua config manager, with legacy Hyprlang fallback), paired with `src/core/MockHyprlandBridge.qml` (`BASEUS_SIMULATION=1`).
- **Design token foundation:** `src/theme/*` (`Theme.qml`, `Colors.qml` 4-color palette per `DEC-011`, `Typography.qml`, `Spacing.qml`, `Geometry.qml`, `Motion.qml`, `InverseCorner.qml`, `qmldir`) and `src/dev/DesignStage.qml`.
- **Configuration boundaries:** `src/core/Config.qml` synchronous layered loading via `Quickshell.Io` `FileView` (`blockLoading: true`, `blockAllReads: true`, `waitForJob()`), `config/baseus.json` behavioral defaults (`simulation.enabled: false`, no `"theme"` tokens per `DEC-012`), range sanitization, and safe fallback on missing/malformed JSON.
- **Diagnostics/logging:** `src/core/Logger.qml` structured multi-level logging (`debug`, `info`, `warn`, `error`) dynamically synced with `config.logLevel`.
- **Development workflow & docs:** `scripts/validate.sh` (auto-detecting `/usr/lib/qt6/bin/qmllint` with `-I` paths) and `scripts/validate.ps1`; `docs/architecture.md`, `docs/configuration.md`, `docs/development.md`.

### Validation

| Area | Status | Evidence |
|---|---|---|
| Repository structure | VERIFIED | `scripts/validate.sh --all` (WSL2) and `scripts/validate.ps1` (Windows) passed with 0 errors |
| JSON configuration | VERIFIED | `config/baseus.json` validated via `python3` and PowerShell JSON parsers |
| QML static & type linting | VERIFIED | `/usr/lib/qt6/bin/qmllint` (`6.12.0`) passed all 20 `.qml` files with 0 errors and 0 warnings |
| Quickshell startup | VERIFIED | `quickshell -p . -d -n` (`0.3.2`) compiled and launched `shell.qml` cleanly on both WSLg (`wayland-0`) and live Hyprland (`wayland-1`) |
| Lifecycle & repeated restart | VERIFIED | Deterministic init/teardown verified across 6 consecutive standalone restarts (`restartCount: 6`) and live Hyprland restart (`restartCount: 1`, `bridgeConnected: true`, `activeWorkspace: 4` re-synced) |
| State initialization & updates | VERIFIED | Verified under both `BASEUS_SIMULATION=1` and live `Hyprland 0.57.0` (`WorkspaceModel` 1–10 boundary, `WindowModel` floating/focus tracking, `ShellState` fullscreen/desktop mode transitions) |
| Events delivery & deduplication | VERIFIED | Subscription counts stayed constant (`{"monitor":2,"workspace":1,"window":2,"theme":1}`) across initial startup, live Hyprland restart, and 6 standalone restarts |
| Configuration fallback & reload | VERIFIED | Missing explicit config, malformed JSON, out-of-range values, `DEC-012` `"theme"` block warning, and live disk reload on `restart()` verified via `BASEUS_CONFIG_PATH` |
| Unavailable-Hyprland reporting | VERIFIED | Without `HYPRLAND_INSTANCE_SIGNATURE`, `HyprlandBridge` logs explicit `WARN`, reports `bridgeConnected: false`, and safely rejects live dispatch |
| Live Hyprland compositor IPC | VERIFIED | Live `Hyprland 0.57.0` (`HYPRLAND_INSTANCE_SIGNATURE=0aa6745f705f2c4b0a5004eb019ef76e5bbdb426_1793321236_1855700926`, `.socket.sock` + `.socket2.sock`, `VIRTUAL-1`) + `Quickshell 0.3.2` verified `bridgeType: "hyprland"`, `bridgeConnected: true`, `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'` → `.socket2.sock` `workspacev2>>2,2` → `activeWorkspace: 2`, bidirectional `baseus switchWorkspace 4` → `hyprctl activeworkspace` == `4`, and live Wayland window `openwindow` (`floating: true`, `windowCount: 1`) / `fullscreen` (`ShellState.mode: "fullscreen"` → `"desktop"`) / `closewindow` (`windowCount: 0`, `focusedWindow: ""`) |

### Known Limitations

- **WSL2 virtual/headless output vs physical DRM hardware:** Live `Hyprland 0.57.0` IPC in WSL2 runs over a nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` + `MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`) with headless virtual output `VIRTUAL-1`. Physical multi-head DRM scanout and hardware GPU performance baselines remain to be measured on native Linux hardware in later milestones.
- **WSL2 `quickshell-git` daemon teardown quirk:** Under WSL2, `quickshell kill` runs QML `Component.onDestruction` to completion (`BASEUS shell terminated.`), after which upstream `quickshell 0.3.2` can remain parked in `futex_do_wait`; `LIBGL_ALWAYS_SOFTWARE=1` suppresses WSL2 Mesa `d3d12`/Zink warnings.

### Recovery / Resume Meaning

`CP-M0-001` is the verified M0 Foundation baseline from which **M1 — Desktop Core** may safely begin upon deliberate phase transition.

---

# 15. M1 Desktop Core Checkpoint

## CP-M1-001 — Desktop Core Baseline

**Status:** VERIFIED (Static `qmllint 6.12.0` across 25 QML files, zero ANTI-SLOP violations, Quickshell 0.3.2 Runtime, and Live Hyprland 0.57.0 Dual-Monitor Compositor E2E Verified on WSL2 Arch Linux)  
**Date:** 2026-10-30  
**Phase:** M1 — Desktop Core  
**Scope:** Fixed 10-workspace per-monitor capability (`DEC-010`), freeform floating/centering window lifecycle (`DEC-008`), geometric maximize vs native fullscreen recession (`DEC-023`), scratchpad-free minimization offscreen parking and centered cross-monitor restore (`DEC-038`), POP workspace/monitor hooks (`MASTER.md` §35), Action Registry (`DEC-028`) with 22 core actions, universal navigation primitives (`Back`, `Home`, `Overview` per `DEC-024`), multi-monitor `DesktopHost` layer-shell scaffolding, edge-integrated `TopIslandAnchor` with `InverseCorner` organic fillets and minute-aligned idle clock (`DESIGN.md` §9, §10, §14), transient contextual `WorkspaceIndicator` HUD with hierarchical scaling and labeled pill morphing (`DEC-029`), zero-process `.socket.sock` FIFO request pipeline, and authoritative `config/hypr/baseus-desktop.lua` preset.

### Repository

- **Commit:** `dd85f4b8b9f3870e80748626d30bb9e30ff9dcc5` (`feat(m1): complete M1-T6 e2e validation, anti-slop audit, and checkpoint CP-M1-001`)
- **Branch:** `main`
- **Working tree:** Implementation files present (`shell.qml`, `src/`, `config/`, `docs/`, `scripts/`)
- **Repository structure:** Matches `MASTER.md` §59 and `TASKS.md` §7

### Environment

- **Host OS:** Windows with WSL2 Linux runtime (`/mnt/d/Linux/BASEUS`)
- **Linux Distribution & Kernel:** `Arch Linux` on WSL2 (`Linux 6.18.54.1-microsoft-standard-WSL2`)
- **Display Connection:** WSLg Wayland (`WAYLAND_DISPLAY=wayland-0`) and nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` → live Hyprland child `WAYLAND_DISPLAY=wayland-1`)
- **Shell Runtime:** `Quickshell 0.3.2` (`quickshell-git`, rev `9b0f339b19057f4731bf3b48293307d7ef241671`)
- **Qt / QML Tooling:** Qt 6 (`qmllint 6.12.0` at `/usr/lib/qt6/bin/qmllint`)
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`, Lua config manager `Hyprland.usingLua == true`, dual headless outputs `VIRTUAL-1` and `VIRTUAL-2`)

### Implementation

- **Workspace Capability (`WorkspaceModel.qml` & `HyprlandBridge.qml`)**:
  - Exactly 10 workspaces enforced (`DEC-010`); out-of-range bounds clamped; `workspaces.count` overrides in config rejected.
  - Per-monitor independent active and previous workspaces (`activeWorkspaces`, `previousWorkspaces`).
  - Optional user-defined workspace `labels` and `tags` loaded from config or set via IPC.
  - Hotplug removal of monitors cleanly reconciles active/previous workspace tracking.
- **Freeform Window Capability (`WindowModel.qml` & `HyprlandBridge.qml`)**:
  - Newly mapped Wayland client windows open floating and centered by default (`DEC-008`).
  - Live window geometry tracking (`x`, `y`, `width`, `height`) and MRU `focusHistory`.
  - Geometric maximize preserves `16px` layout margins (`+baseus_maximized`) while keeping shell mode `"desktop"` (`DEC-023`).
  - Native compositor fullscreen toggles shell mode to `"fullscreen"` and scopes fullscreen state per monitor (`DEC-023`).
  - Scratchpad-free minimize parks windows offscreen (`[-16000, -16000]`) on normal workspaces tagged `+baseus_minimized`, handoffs focus to MRU visible window, and survives shell restart (`DEC-038`).
  - Centered restore repositions windows to the exact geometric center of the target monitor (`MASTER.md` §36).
  - POP workspace/monitor moves (`moveWindowToWorkspace`, `moveWindowToMonitor`) preserve focus semantics (`MASTER.md` §35).
- **Action Registry & Navigation Primitives (`ActionRegistry.qml` & `NavigationController.qml`)**:
  - Declarative action schema (`id`, `category`, `title`, `description`, `defaultShortcut`, `isEnabled`, `callback`).
  - 22 core actions registered across `navigation` (3), `workspace` (12), and `window` (7).
  - Navigation primitives: `Home` (navigates active monitor to Workspace 1), `Back` (dismisses overlay, or navigates to previous workspace, or toggles previous window focus via MRU history), `Overview` (toggles overview mode, mutually exclusive with native fullscreen).
- **DesktopHost Layer Scaffolding (`DesktopHost.qml`)**:
  - Multi-monitor Quickshell `Variants` over `Quickshell.screens` with `WlrLayershell.layer: Top`.
  - Layer-shell input region strictly constrained to interactive surface bodies (`mask: Region { item: topIsland.anchorItem }`), keeping idle desktop space 100% click-through.
  - Per-monitor native application fullscreen recession (`visible: false` on fullscreen monitor, remaining visible on non-fullscreen monitor).
- **Contextual Surfaces (`TopIslandAnchor.qml` & `WorkspaceIndicator.qml`)**:
  - `TopIslandAnchor`: Edge-integrated solid Wabi-sabi anchor with `InverseCorner` (`ICR`) organic fillets, displaying minute-aligned typographic clock without high-frequency polling.
  - `WorkspaceIndicator`: Transient workspace HUD (~2000ms auto-hide), hierarchical scaling (*"Focus grows. Context recedes."*), morphs to compact labeled pill (`2 — WEB`), resets in place during rapid switches without animation stacking.
- **Design Token Discipline & Anti-Slop**:
  - All 25 QML files enforce `pragma ComponentBehavior: Bound`.
  - Strict 4-color palette tokens (`dominant`, `secondary`, `accent`, `neutral`) per `DEC-011`.
  - Zero hardcoded hex colors, zero glassmorphism, zero blur filters, zero glow/neon drop shadows.
- **Compositor Presets**:
  - `config/hypr/baseus-desktop.lua` loaded with 0 config errors; 25 keybinds; default floating window rules; 4-finger gestures.

### Validation

| Area | Status | Evidence |
|---|---|---|
| Anti-Slop & Visual Architecture | VERIFIED | `scratch/audit_m1_anti_slop.py` scanned all 25 QML files: 0 violations, zero hardcoded hex colors, zero blur/glass/shadows, 100% `pragma ComponentBehavior: Bound` |
| QML Static & Type Linting | VERIFIED | `scripts/validate.sh --all` (`/usr/lib/qt6/bin/qmllint` 6.12.0) and `scripts/validate.ps1 -All` passed with 0 errors and 0 warnings across all 25 QML files |
| Configuration Validation | VERIFIED | `config/baseus.json` validated JSON; layered loading, labels/tags, `DEC-010` rejection verified |
| Hyprland Configuration Preset | VERIFIED | `Hyprland 0.57.0 -c config/hypr/baseus-desktop.lua` booted with 0 config errors (`hyprctl -j configerrors` == `[""]`) |
| Offline Simulation Suite | VERIFIED | `verify_m1_t1.py` through `verify_m1_t5.py` Phase A tests passed 100% with `BASEUS_SIMULATION=1` |
| Multi-Monitor Workspace Navigation | VERIFIED | Live dual-monitor (`VIRTUAL-1`, `VIRTUAL-2`) independent switching, boundary clamping (1..10), HUD containment verified |
| Freeform Window Lifecycle | VERIFIED | Live Wayland client windows verified centered floating spawn (760, 390, 400, 300), geometric maximize boundary (16, 16, 1888, 1048), unmaximize restore |
| Per-Monitor Fullscreen Recession | VERIFIED | Live native fullscreen on Mon 1 causes only Mon 1 surface to recede (`visible: false`), while Mon 0 remains visible (`visible: true`), and vice-versa |
| Minimize & Centered Restore | VERIFIED | Scratchpad-free minimize offscreen parking on normal workspaces (`DEC-038`) and cross-monitor centered restore onto Mon 1 ws 6 verified live |
| Navigation Primitives | VERIFIED | Live execution of `navigation.home`, `navigation.back`, and `navigation.overview` verified |
| Contextual Surfaces & Auto-Hide | VERIFIED | `TopIslandAnchor` minute clock and `WorkspaceIndicator` 2000ms auto-hide and labeled pill morph verified live |
| Lifecycle & Restart Stability | VERIFIED | `quickshell ipc call baseus restart` cleanly recovers 2 surfaces and preserves stable subscriptions (`monitor: 3, workspace: 2, window: 2, theme: 1`) |
| Comprehensive E2E Test Suite | VERIFIED | `scratch/verify_m1_e2e.py` executed all Steps A through G against live dual-monitor Hyprland 0.57.0 with 100% PASS |

### Known Limitations

- **WSL2 virtual scanout:** Physical multi-monitor DRM master hardware scanout, physical 4-finger touchpad gestures, and hardware GPU performance benchmarks require bare-metal Linux.
- **WSL2 `quickshell-git` daemon teardown quirk:** Daemon termination under WSL2 can park in `futex_do_wait` after clean destruction; handled cleanly by test harnesses.

### Recovery / Resume Meaning

`CP-M1-001` is the authoritative, verified **M1 — Desktop Core** baseline. From this checkpoint, the repository safely transitions to **M2 — Primary Surfaces** (Dock, App Drawer, Top Island interactive menus).

---

# 16. M2 Interaction Baseline Checkpoint

## CP-M2-001 — Interaction Baseline

**Status:** VERIFIED (Static `qmllint 6.12.0` across 33 QML files, zero ANTI-SLOP violations, Quickshell 0.3.2 Runtime, and Live Hyprland 0.57.0 Dual-Monitor Compositor E2E Integration Verified on WSL2 Arch Linux)  
**Date:** 2026-10-31  
**Phase:** M2 — Interaction  
**Scope:** Bottom-edge cursor trigger and edge-integrated Dock scaffolding (`DEC-015`), global pinned applications vs workspace-isolated client windows, multi-window instance MRU cycling, Top Island hover expansion into contextual header with unified InverseCorner silhouette (`DEC-016`), 2px fullscreen notch summon surface during native fullscreen (`DESIGN.md` §14), universal Command Center with `>` ActionRegistry routing engine (`DEC-017`), fullscreen App Drawer with landing state recents, upward search collapse transition, continuous dynamic catalog grid in fixed `A–Z–0–9–#` order without cardified headers (`DEC-018`), right-edge 1px-to-3px alphabet fast scroller (`DEC-022`), dynamic layer-shell hitmasking ensuring 100% click-through idle desktop space, and overlay mutual exclusivity.

### Repository

- **Commit:** `e58eac3180cb8b0d3b4e7f7642348e02e31db2ad` (`feat(m2): complete M2-T6 e2e validation, anti-slop audit, and checkpoint CP-M2-001`)
- **Branch:** `main`
- **Working tree:** Implementation files present (`shell.qml`, `src/`, `config/`, `docs/`, `scripts/`)
- **Repository structure:** Matches `MASTER.md` §59 and `TASKS.md` §7

### Environment

- **Host OS:** Windows with WSL2 Linux runtime (`/mnt/d/Linux/BASEUS`)
- **Linux Distribution & Kernel:** `Arch Linux` on WSL2 (`Linux 6.18.54.1-microsoft-standard-WSL2`)
- **Display Connection:** WSLg Wayland (`WAYLAND_DISPLAY=wayland-0`) and nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` → live Hyprland child `WAYLAND_DISPLAY=wayland-1`)
- **Shell Runtime:** `Quickshell 0.3.2` (`quickshell-git`, rev `9b0f339b19057f4731bf3b48293307d7ef241671`)
- **Qt / QML Tooling:** Qt 6 (`qmllint 6.12.0` at `/usr/lib/qt6/bin/qmllint`)
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`, Lua config manager `Hyprland.usingLua == true`, dual headless outputs `VIRTUAL-1` and `VIRTUAL-2`)

### Implementation

- **Dock Surface & Application State (`DockAnchor.qml`, `DockModel.qml`, `DockItem.qml`)**:
  - Edge-integrated bottom dock flush with bottom screen edge (`dockRadiusBottom: 0`, `dockRadiusTop: 12`) flanked by `InverseCorner` (`ICR`) fillets.
  - 1–2px bottom cursor trigger region (`triggerHeight: 2`) revealing the solid Wabi-sabi dock surface upon hover; auto-recedes cleanly after 400ms delay.
  - Strict separation: global pinned applications (`dock.pinnedApps` in `config/baseus.json`) persist across all workspaces; unpinned running windows appear exclusively on the workspace where they are active.
  - Multi-window instance MRU cycling and window focus/raising dispatch via `WindowModel` and `HyprlandBridge`.
  - Recedes cleanly during per-monitor native application fullscreen (`DESIGN.md` §14). Strictly contains NO search bar (`DEC-015`).
- **Top Island Hover Expansion & Fullscreen Summon (`TopIslandAnchor.qml`, `TopIslandHeader.qml`)**:
  - Edge-integrated top-center solid Wabi-sabi anchor with unified C1 continuous `InverseCorner` fillets (`DEC-016`, `DEC-029`).
  - Minute-aligned typographic clock at idle without polling.
  - Hover expansion downward into contextual header displaying formatted date, active session metrics (workspace number, user label, running window count), and action trigger shortcuts.
  - Dedicated Overlay fullscreen summon surface providing a 2px top-edge notch trigger during native fullscreen applications, summoning compact clock on hover and expanding the header on click (`DEC-016`).
- **Command Center Surface & Prefix Routing Engine (`CommandCenter.qml`)**:
  - Universal search and action launcher positioned horizontally centered and slightly above vertical center (`DEC-017`).
  - Top-to-bottom curtain reveal, dynamic fit-content height up to 520px with internal scrolling, instant input focus.
  - Prefix routing engine: `>` routes to `ActionRegistry` (22 core actions); `?help` lists quick reference; plain text searches applications with MRU tracking.
- **Fullscreen App Drawer & Fast Scroller (`AppDrawer.qml`, `AppDrawerItem.qml`, `AlphabetScroller.qml`)**:
  - Fullscreen application discovery surface (`DEC-018`) with rounded top corners (`floatingRadius: 12`) and flush bottom edge. Smooth bottom-to-top curtain reveal.
  - Persistent top search bar, initial landing state with recent/suggested applications (max 3 columns) that smoothly collapses upward upon typing.
  - Continuous dynamic catalog grid in strict fixed `A–Z–0–9–#` order without cardified headers.
  - Zero running state indicators (`DEC-018`).
  - Right-edge 1px-to-3px alphabet fast scroller (`DEC-022`) with pointer and touch scrub jumping.
- **Overlay Mutual Exclusivity & Dynamic Hitmasking**:
  - Governed by `ShellState.mode` (`desktop`, `overview`, `command-center`, `app-drawer`).
  - Opening an overlay cleanly supersedes any existing overlay without collision or leaked focus.
  - Clean Layer-Shell input mask release upon dismissal via `navigation.back`, `Escape`, or clicking outside.
- **Design Token Discipline & Anti-Slop**:
  - All 33 QML files enforce `pragma ComponentBehavior: Bound`.
  - Strict 4-color palette tokens (`dominant`, `secondary`, `accent`, `neutral`) per `DEC-011`.
  - Zero hardcoded hex colors, zero glassmorphism, zero blur filters, zero glow/neon drop shadows.

### Validation

| Area | Status | Evidence |
|---|---|---|
| Anti-Slop & Design Audit | VERIFIED | Automated audit across all 33 QML files: 0 violations, zero hardcoded hex colors, zero blur/glass/shadows, 100% `pragma ComponentBehavior: Bound` |
| QML Static & Type Linting | VERIFIED | `scripts/validate.sh --all` (`/usr/lib/qt6/bin/qmllint` 6.12.0) and `scripts/validate.ps1 -All` passed with 0 errors and 0 warnings across all 33 QML files |
| Configuration Validation | VERIFIED | `config/baseus.json` validated JSON; `dock.pinnedApps` and `commandCenter.actionPrefix` verified |
| Dock Scaffolding & Reveal | VERIFIED | `verify_m2_t1.py` live dual-monitor Hyprland 0.57.0: 2px trigger reveal, input region containment, clean 400ms hide, and per-monitor fullscreen recession verified |
| Dock Application State & Pinning | VERIFIED | `verify_m2_t2.py` live dual-monitor Hyprland 0.57.0: global pins persist across workspaces, active Wayland window isolated to Monitor 0 dock, click-to-focus dispatched |
| Top Island Hover & Fullscreen Summon | VERIFIED | `verify_m2_t3.py` live dual-monitor Hyprland 0.57.0: unified ICR silhouette, hover expansion, header action dispatch, and 2px fullscreen notch summon verified |
| Command Center & Prefix Routing | VERIFIED | `verify_m2_t4.py` live dual-monitor Hyprland 0.57.0: centered reveal, `>` prefix routes to 22 core actions, `?help`, keyboard navigation, and execution dismissal verified |
| App Drawer & Alphabet Scroller | VERIFIED | `verify_m2_t5.py` live dual-monitor Hyprland 0.57.0: fullscreen curtain reveal, search collapse, alphabet fast scroller scrubbing across A–Z–0–9–#, launch dispatch, and Back dismissal verified |
| Comprehensive Multi-Monitor E2E | VERIFIED | `verify_m2_e2e.py` executed Phase A (static audit), Phase B (offline simulation), and Phase C (live dual-monitor Hyprland C1–C7) with 100% PASS |
| Overlay Mutual Exclusivity | VERIFIED | Switching between Command Center and App Drawer cleanly supersedes active overlay without animation collision or leaked keyboard focus |
| Lifecycle & Shell Restart Recovery | VERIFIED | `quickshell ipc call baseus restart` cleanly recovers 2 monitors, 2 desktop host surfaces, docks, islands, and zero leaked input grab regions |

### Known Limitations

- **WSL2 virtual scanout:** Physical multi-monitor DRM master hardware scanout, physical 4-finger touchpad gestures, and hardware GPU performance benchmarks require bare-metal Linux.
- **WSL2 `quickshell-git` daemon teardown quirk:** Daemon termination under WSL2 can park in `futex_do_wait` after clean destruction; handled cleanly by test harnesses.

### Recovery / Resume Meaning

`CP-M2-001` is the authoritative, verified **M2 — Interaction** baseline. From this checkpoint, the repository safely transitions to **M3 — Status, Notification & Audio/Brightness Overlays** (Notification daemon, OSD, Media controls, and Personality surfaces).

---

# 17. M3 System Feedback Baseline Checkpoint

## CP-M3-001 — System Feedback Baseline

**Status:** VERIFIED (Static `qmllint 6.12.0` across 44 QML files, zero ANTI-SLOP violations, Quickshell 0.3.2 Runtime, and Live Hyprland 0.57.0 Dual-Monitor Compositor E2E Integration Verified on WSL2 Arch Linux)  
**Date:** 2026-10-31  
**Phase:** M3 — System Feedback  
**Scope:** Floating top-left notification daemon with 70% icon backdrop, solid Wabi-sabi tonal surface, zero nested cardification (`DEC-020`, `ANTI-SLOP.md` §20), hold-to-silence feedback (`DESIGN.md` §18), and dynamic 0x0 click-through layer-shell input masking; PipeWire / WirePlumber volume and display brightness OSD subsystem geometrically emerging from the bottom notch of Top Island with bubble-drop transition, rapid-event in-place morphing without animation stacking (`DEC-021`, `AGENTS.md` §20), and 100% click-through passthrough hitmask; centralized Linux MPRIS media player architecture (`MediaService.qml`) tracking playback state, multi-session switching, position seek, and deterministic mock fallback (`DEC-026`); strict enforcement of `DEC-039` (track changes strictly NEVER spawn generic desktop notification noise); compact media integration in `TopIslandHeader.qml` (`TopIslandMedia.qml`) with fixed 328x38px layout eliminating resizing jitter; modular desktop media widget (`MediaWidget.qml`) with compact state (108px), auto-expansion during playback (254px), interactive seek slider, session selector, and structural lyrics slot (`LyricsContainer.qml`); Bongo Cat companion (`BongoCatCompanion.qml`) providing personality without noise (`ANTI-SLOP.md` §37) with active alternating paw rhythm during playback and strict zero-CPU idle timer halt on pause/idle; system status and diagnostic architecture (`StatusService.qml`) monitoring battery/power, network connectivity, and subsystem health without permanent cockpit dashboards (`ANTI-SLOP.md` §6.7–6.8); auto-dispatches non-intrusive low-battery alerts ($\le 20\%$) with state deduplication and charging suppression; per-monitor native application fullscreen recession across Monitor 0 while Monitor 1 remains active (`DESIGN.md` §14); shell restart recovery (`quickshell ipc call baseus restart`) with clean state resynchronization across dual monitors and zero leaked input grab regions or orphaned subscriptions.

### Repository

- **Commit:** `0e6711bab3b1beee70bde6563a884d10872386bf` (`feat(m3): complete M3-T6 e2e validation, anti-slop audit, and checkpoint CP-M3-001`)
- **Branch:** `main`
- **Working tree:** Implementation files present (`shell.qml`, `src/`, `config/`, `docs/`, `scripts/`)
- **Repository structure:** Matches `MASTER.md` §59 and `TASKS.md` §7

### Environment

- **Host OS:** Windows with WSL2 Linux runtime (`/mnt/d/Linux/BASEUS`)
- **Linux Distribution & Kernel:** `Arch Linux` on WSL2 (`Linux 6.18.54.1-microsoft-standard-WSL2`)
- **Display Connection:** WSLg Wayland (`WAYLAND_DISPLAY=wayland-0`) and nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` → live Hyprland child `WAYLAND_DISPLAY=wayland-1`)
- **Shell Runtime:** `Quickshell 0.3.2` (`quickshell-git`, rev `9b0f339b19057f4731bf3b48293307d7ef241671`)
- **Qt / QML Tooling:** Qt 6 (`qmllint 6.12.0` at `/usr/lib/qt6/bin/qmllint`)
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`, Lua config manager `Hyprland.usingLua == true`, dual headless outputs `VIRTUAL-1` and `VIRTUAL-2`)

### Implementation

- **Notification Daemon & Floating Surface (`NotificationModel.qml`, `NotificationHost.qml`, `NotificationItem.qml`)**:
  - Floating top-left placement with left-to-right reveal, 70% icon backdrop, solid Wabi-sabi tonal surface, and zero nested cardification (`ANTI-SLOP.md` §20, `DEC-020`).
  - Hold-to-silence feedback with tonal progress fill, dismissing pending items and calming future alerts (`DESIGN.md` §18).
  - Dynamic Layer-Shell input masking contracting to 0x0 at idle for 100% click-through desktop transparency.
- **Top Island OSD Integration (`AudioService.qml`, `TopIslandOsd.qml`)**:
  - Originates geometrically from the bottom notch of `TopIslandAnchor.qml` (`DEC-021`).
  - Downward bubble-drop transition; rapid consecutive adjustments update and morph in place without animation pile-up or stacking (`AGENTS.md` §20).
  - 100% non-blocking click-through passthrough hitmask (`mask: Region {}`).
  - PipeWire / WirePlumber audio/volume and brightness integration with deterministic mock fallback.
- **Media Player Architecture & Top Island Integration (`MediaService.qml`, `TopIslandMedia.qml`)**:
  - Centralized MPRIS integration tracking playback status, metadata, seek, and multi-session switching.
  - Strict enforcement of `DEC-039`: track and playback changes NEVER spawn generic desktop notifications.
  - Compact Top Island header surface with fixed 328x38px footprint eliminating resizing jitter.
- **Dedicated Media Widget & Bongo Cat Companion (`MediaWidget.qml`, `BongoCatCompanion.qml`, `LyricsContainer.qml`)**:
  - Modular desktop widget transitioning between compact idle/paused state (108px) and expanded playback state (254px).
  - Bongo Cat companion tapping paws in rhythm during playback and completely halting internal animation timers when paused/idle (zero CPU consumption at idle, `ANTI-SLOP.md` §37).
  - Structural lyrics slot with live stream support and clean editorial fallback.
- **System Status & Diagnostic Architecture (`StatusService.qml`)**:
  - Event-driven monitoring for power/battery, network connectivity, and subsystem health.
  - Contextual status presentation inside expanded Top Island header; zero permanent cockpit dashboards (`ANTI-SLOP.md` §6.7–6.8).
  - Non-intrusive low-battery notification alerts when battery <= 20% while discharging, with state deduplication and charging recovery.

### Validation

| Area | Status | Evidence |
|---|---|---|
| Anti-Slop & Design Audit | VERIFIED | Automated audit across all 44 QML files: 0 violations, zero hardcoded hex colors outside `Colors.qml`, zero blur/glass/shadows, zero M4 scope leaks, 100% `pragma ComponentBehavior: Bound` |
| QML Static & Type Linting | VERIFIED | `scripts/validate.sh --all` (`/usr/lib/qt6/bin/qmllint` 6.12.0) and `scripts/validate.ps1 -All` passed with 0 errors and 0 warnings across all 44 QML files |
| Configuration Validation | VERIFIED | `config/baseus.json` validated JSON; notification, audio, media, and status configuration schemas verified |
| Offline Simulation Suite | VERIFIED | `verify_m3_e2e.py` Phase B: All M3 foundation services, notification posting, hold-to-silence, OSD morphing, media controls, DEC-039 suppression, MediaWidget morphing, Bongo Cat 0-CPU halt, and StatusService alert recovery passed 100% |
| Notifications Live Delivery | VERIFIED | `verify_m3_e2e.py` Step C2: Live notification delivery on Monitor 0 with 360x77 dynamic hitmask and 0x0 clean dismissal verified |
| Top Island OSD Live Feedback | VERIFIED | `verify_m3_e2e.py` Step C3: Live bubble-drop feedback, rapid in-place morphing (78% -> 84%), and 100% non-blocking click-through verified |
| Top Island Header Integration | VERIFIED | `verify_m3_e2e.py` Step C4: Contextual status row and fixed 328x38px compact media surface verified inside expanded header |
| Strict DEC-039 Suppression | VERIFIED | `verify_m3_e2e.py` Step C5: Live media track changes produced 0 desktop notification count increase |
| Media Widget & Bongo Cat Live | VERIFIED | `verify_m3_e2e.py` Step C6: Media Widget compact (108px) to expanded (254px) playback morphing, active paw rhythm, and immediate 0-CPU timer halt on pause verified |
| System Status Live Low-Power | VERIFIED | `verify_m3_e2e.py` Step C7: Low-power alert (13%) delivered non-intrusively and charging status cleanly suppressed alert |
| Per-Monitor Fullscreen Recession | VERIFIED | `verify_m3_e2e.py` Step C8: Native fullscreen on Monitor 0 causes Monitor 0 surfaces to recede while Monitor 1 remains active; restores cleanly upon exit |
| Lifecycle & Shell Restart Recovery | VERIFIED | `verify_m3_e2e.py` Step C9: `quickshell ipc call baseus restart` cleanly recovers 2 monitors, layer surfaces, and all feedback subsystems |
| Comprehensive Multi-Monitor E2E | VERIFIED | `verify_m3_e2e.py` executed Phase A, Phase B, and Phase C Steps C1–C9 with 100% PASS |

### Known Limitations

- **WSL2 virtual scanout:** Physical multi-monitor DRM master hardware scanout, physical 4-finger touchpad gestures, physical backlight controllers, and physical audio DACs require bare-metal Linux.
- **WSL2 `quickshell-git` daemon teardown quirk:** Daemon termination under WSL2 can park in `futex_do_wait` after clean destruction; handled cleanly by test harnesses.

### Recovery / Resume Meaning

`CP-M3-001` is the authoritative, verified **M3 — System Feedback** baseline. From this checkpoint, the repository safely transitions to **M4 — Personalization** (Wallpaper engine, extraction pipeline, and settings).


---

# 18. M4 Personalization Baseline Checkpoint

## CP-M4-001 — Personalization Baseline

**Status:** VERIFIED (Static `qmllint 6.12.0` across 49 QML files, zero ANTI-SLOP violations, Quickshell 0.3.2 Runtime, and Live Hyprland 0.57.0 Dual-Monitor Compositor E2E Integration Verified on WSL2 Arch Linux)  
**Date:** 2026-11-01  
**Phase:** M4 — Personalization  
**Scope:** Palette pipeline architecture (`PaletteService.qml`, `scripts/palette_extract.py`) enforcing the four-color model (`DEC-011`: `dominant`, `secondary`, `accent`, `neutral`) with derived tonal roles (`surfaceSolid`, `surfaceHighlight`, `surfaceRecessed`, `borderSubtle`, `textPrimary`, `textSecondary`), WCAG AA contrast validation ($\ge 4.5:1$), and caching; wallpaper engine (`WallpaperService.qml`, `DesktopHost.qml`) enforcing `DEC-013` (independent per-workspace static wallpapers across `1..10` vs global live wallpaper) and `DEC-014` (single-sample extraction for live wallpaper, zero continuous background extraction loops); background layer-shell surface with `exclusiveZone: -1` and `mask: Region {}` for 100% click-through desktop transparency; dynamic theme system & visual transitions (`ThemeService.qml`) with complete visual state serialization, daily theme snapshot persistence (`MASTER.md` §26), transition mask shader tokens (`fade`, `circle_wipe`, `wavy_wipe`, `bubble_ripple`), built-in presets (`wabi-sabi-indigo`, `tokyo-slate`, `cyber-sand`, `obsidian-ember`), and strict preservation of interaction invariants (`DEC-012`, `DEC-037`: theme switching changes visual styling ONLY and never alters gestures, shortcuts, window behavior, or timeouts); floating wallpaper picker overlay (`WallpaperPicker.qml`, `WlrLayer.Overlay`) with categorized tabs (`Library`, `Favorites`, `Recent`), responsive 196x118px cards with live preview, favorite toggle, apply to active workspace, apply to all workspaces, live wallpaper activation, keyboard navigation, and dynamic 0x0 hitmask recovery; Headquarter settings application (`Headquarter.qml`, `WlrLayer.Overlay`, `DEC-019`, `DESIGN.md` §24–25) featuring a literally fullscreen overlay per-monitor, persistent 240px right sidebar flanked by organic `InverseCorner` (`ICR`) fillets connecting to top/bottom screen perimeter (strictly never icon-only mode), 6 categorized settings views (`Home`, `Appearance`, `Workspaces`, `Shortcuts`, `Feedback`, `About`) adhering strictly to editorial minimalism without spaceship KPI telemetry dashboards (`ANTI-SLOP.md` §6.8), live apply principle (`MASTER.md` §22: mutating backend state immediately without modal dialogs), real-time settings search filtering across categories with hierarchical breadcrumbs, contextual help bubble system anchored cleanly to the right of settings controls without layout shift, universal dismissal via `Escape` / `navigation.back`, and dynamic Layer-Shell input mask with exclusive keyboard focus when open and 0x0 click-through when closed; overlay mutual exclusivity across Headquarter, WallpaperPicker, CommandCenter, AppDrawer, and Overview without animation collisions or leaked keyboard grabs; and shell restart recovery (`quickshell ipc call baseus restart`) with clean state resynchronization across dual monitors and zero orphaned subscriptions.

### Repository

- **Commit:** `ad5f93d64fb088e913b3cf333497f68432ad9594` (`feat(m4): implement headquarter settings application (M4-T5)`)
- **Branch:** `main`
- **Working tree:** Implementation files present (`shell.qml`, `src/`, `config/`, `docs/`, `scripts/`)
- **Repository structure:** Matches `MASTER.md` §59 and `TASKS.md` §7

### Environment

- **Host OS:** Windows with WSL2 Linux runtime (`/mnt/d/Linux/BASEUS`)
- **Linux Distribution & Kernel:** `Arch Linux` on WSL2 (`Linux 6.18.54.1-microsoft-standard-WSL2`)
- **Display Connection:** WSLg Wayland (`WAYLAND_DISPLAY=wayland-0`) and nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` → live Hyprland child `WAYLAND_DISPLAY=wayland-1`)
- **Shell Runtime:** `Quickshell 0.3.2` (`quickshell-git`, rev `9b0f339b19057f4731bf3b48293307d7ef241671`)
- **Qt / QML Tooling:** Qt 6 (`qmllint 6.12.0` at `/usr/lib/qt6/bin/qmllint`)
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`, Lua config manager `Hyprland.usingLua == true`, dual headless outputs `VIRTUAL-1` and `VIRTUAL-2`)

### Implementation

- **Palette & Matugen Pipeline Architecture (`PaletteService.qml`, `scripts/palette_extract.py`)**:
  - Enforces the four-color model (`DEC-011`: `dominant`, `secondary`, `accent`, `neutral`) with derived tonal roles.
  - WCAG AA contrast ratio validation ($\ge 4.5:1$ between text and solid surfaces) with automatic lightness adjustments.
  - Matugen CLI extraction bridge with deterministic fallback under `BASEUS_SIMULATION=1` or when Matugen is absent.
  - Wires updates into `EventBus.qml` under category `"theme"` (`palette_updated`).
- **Wallpaper Engine (`WallpaperService.qml`, `DesktopHost.qml`)**:
  - Enforces `DEC-013`: static wallpapers are independent per workspace (`1..10`), whereas live wallpaper is global across the desktop.
  - Enforces `DEC-014`: live wallpaper extraction is sampled once upon initialization and cached (zero continuous background extraction loops).
  - Background layer-shell surface with `exclusiveZone: -1` and `mask: Region {}` for 100% click-through desktop transparency.
- **Dynamic Theme System & Visual Transitions (`ThemeService.qml`)**:
  - Visual state serialization (wallpaper paths, 4-color palette, widget layout, icon theme) into JSON snapshots.
  - Preserves strict interaction invariance (`DEC-012`, `DEC-037`: theme switching changes visual tokens ONLY and never modifies gestures, keybinds, window rules, or timeouts).
  - Transition mask shader tokens (`fade`, `circle_wipe`, `wavy_wipe`, `bubble_ripple`).
  - Daily theme snapshot persistence (`MASTER.md` §26) and built-in aesthetic presets (`wabi-sabi-indigo`, `tokyo-slate`, `cyber-sand`, `obsidian-ember`).
- **Wallpaper Picker Floating Surface (`WallpaperPicker.qml`)**:
  - Floating centered overlay (`WlrLayer.Overlay`) with solid Wabi-sabi body (`surfaceSolid` + `borderSubtle`), zero blur, and zero drop shadows (`ANTI-SLOP.md`).
  - Categorized tabs (`Library`, `Favorites`, `Recent` ordered by timestamp), responsive 196x118px thumbnail cards with live preview, favorite toggle, apply to active workspace, apply to all workspaces, live wallpaper activation, and full keyboard navigation.
  - Contracts to `0x0` input mask immediately upon closure.
- **Headquarter Settings Application (`Headquarter.qml`)**:
  - Literally fullscreen surface overlay per-monitor with exclusive keyboard focus when active (`DEC-019`, `DESIGN.md` §24).
  - Persistent 240px right sidebar flanked by organic `InverseCorner` (`ICR`) fillets connecting to top/bottom screen perimeter; strictly never collapses into an icon-only mode.
  - 6 categorized settings views (`Home`, `Appearance`, `Workspaces`, `Shortcuts`, `Feedback`, `About`) adhering strictly to editorial minimalism without spaceship KPI telemetry dashboards (`ANTI-SLOP.md` §6.8).
  - Live apply principle (`MASTER.md` §22: mutating backend state immediately without modal dialogs).
  - Real-time search bar filtering across settings items with hierarchical breadcrumbs.
  - Non-modal contextual help bubble system anchored cleanly to the right of settings controls without layout shift (`DESIGN.md` §25).
  - Universal dismissal via `Escape` / `navigation.back`, releasing exclusive keyboard focus and contracting input mask to 0x0.

### Validation

| Area | Status | Evidence |
|---|---|---|
| Anti-Slop & Design Audit | VERIFIED | Automated audit across all 49 QML files: 0 violations, zero hardcoded hex colors outside definition tokens, zero blur/glass/shadows, zero M5 scope leaks, 100% `pragma ComponentBehavior: Bound` |
| QML Static & Type Linting | VERIFIED | `scripts/validate.sh --all` (`/usr/lib/qt6/bin/qmllint` 6.12.0) and `scripts/validate.ps1` passed with 0 errors and 0 warnings across all 49 QML files |
| Configuration Validation | VERIFIED | `config/baseus.json` validated JSON; theme, wallpaper, and headquarter configuration schemas verified |
| Offline Simulation Suite | VERIFIED | `verify_m4_e2e.py` Phase B: PaletteService 4-color model & contrast validation, WallpaperService per-workspace vs global live, ThemeService presets & interaction invariance, WallpaperPicker tabs & apply, Headquarter persistent sidebar & search, and overlay mutual exclusivity passed 100% |
| Background Wallpaper Surfaces | VERIFIED | `verify_m4_e2e.py` Step C1: Dual-monitor background layer-shell surfaces registered with 0x0 hitmask for 100% click-through desktop transparency |
| Wallpaper Picker Live Delivery | VERIFIED | `verify_m4_e2e.py` Step C2: Live open on Monitor 0, selection, workspace apply dispatch, and 0x0 hitmask recovery verified |
| Headquarter Live Delivery | VERIFIED | `verify_m4_e2e.py` Step C3: Live open on Monitor 0 with exclusive keyboard focus, persistent 240px right sidebar, category navigation, search with breadcrumbs, and universal back dismissal verified |
| Overlay Mutual Exclusivity Live | VERIFIED | `verify_m4_e2e.py` Step C4: CommandCenter <-> Headquarter <-> WallpaperPicker seamless transitions without leaked keyboard grabs verified |
| Lifecycle & Shell Restart Recovery | VERIFIED | `verify_m4_e2e.py` Step C5: `quickshell ipc call baseus restart` cleanly recovers 2 monitors, layer surfaces, and all personalization subsystems |
| Full Desktop Regressions M1–M4 | VERIFIED | `verify_m4_e2e.py` Step C6: Workspaces (10-ws async switching), Dock & Top Island, MediaService & StatusService, PaletteService, WallpaperService, and ThemeService operational |
| Comprehensive Multi-Monitor E2E | VERIFIED | `verify_m4_e2e.py` executed Phase A, Phase B, and Phase C with 100% PASS |

### Known Limitations

- **WSL2 virtual scanout:** Physical multi-monitor DRM master hardware scanout, physical 4-finger touchpad gestures, and hardware backlight controllers require bare-metal Linux.
- **Hardware video decoding for live wallpaper:** Headless WSL2 utilizes software decoding fallback for animated live wallpaper feeds.

### Recovery / Resume Meaning

`CP-M4-001` is the authoritative, verified **M4 — Personalization** baseline. From this checkpoint, the repository safely transitions to **M5 — Session, Lock & Polish** (Lock screen, Session/power management, Idle inhibitor, Native hardware gesture binding).


---

# 19. M5 Session, Lock & Polish Baseline Checkpoint

## CP-M5-001 — Session, Lock & Polish Baseline

**Status:** VERIFIED (Static `qmllint 6.12.0` across 55 QML files, zero ANTI-SLOP violations, Quickshell 0.3.2 Runtime, and Live Hyprland 0.57.0 Dual-Monitor Compositor E2E Integration Verified on WSL2 Arch Linux)  
**Date:** 2026-11-03  
**Phase:** M5 — Session, Lock & Polish  
**Scope:** Session and power management subsystem (`PowerService.qml`, `SessionOverlay.qml`) delivering a modal constellation power menu (`WlrLayer.Overlay`, `DEC-027`, `MASTER.md` §32) with quiet dark space, palette-aware stars, sparse layout, 1000ms hold-to-confirm progress timer protecting destructive actions (`reboot`, `poweroff`), direct keyboard mnemonics (`L`, `S`, `O`, `R`, `P`), quiet sleeping chibi companion with zero-CPU idle timer gating (`ANTI-SLOP.md` §37), and dynamic Layer-Shell input mask (exclusive keyboard focus on target monitor, 0x0 click-through at idle); idle and inhibitor service (`IdleService.qml`, `MASTER.md` §34) supporting Wayland `ext-idle-notify-v1` tiered progression (`dimTimeout: 300s`, `lockTimeout: 600s`, `suspendTimeout: 900s`), presentation mode inhibitor toggle completely halting auto-lock/sleep while active, contextual Top Island awake pip indicator, and user activity simulation; airtight session lock surface (`LockScreen.qml`, `AuthService.qml`, `DEC-025`, `DESIGN.md` §35) binding 100% of connected displays via `ext-session-lock-v1` with exclusive overlay fallback, 100% opaque solid body (`surfaceSolid`, zero background window bleed-through, zero blur shaders per `ANTI-SLOP.md`), minute-aligned typographic clock gated to visible-only running state, monospace bullet password buffer, Linux PAM authentication state machine with failure counting, Escape buffer clearing, and error tinting; hardware keybinding alignment (`config/hyprland-baseus.conf`, `config/hypr/baseus-desktop.lua`) and touchpad gesture scaffolding (`GestureService.qml`) across all 35 canonical core actions registered in `ActionRegistry.qml` with 3-finger horizontal workspace switching, 4-finger vertical overview/drawer gestures, and 350ms cooldown gating; shell cold-start latency optimization (mean: ~133ms < 300ms ceiling); zero-cost idle state (0.00% CPU utilization, 0 ticks/s at idle); bounded memory footprint across repeated overlay reveal cycles; overlay mutual exclusivity across SessionOverlay, LockScreen, Headquarter, WallpaperPicker, CommandCenter, and AppDrawer; and shell restart recovery (`quickshell ipc call baseus restart`) with clean multi-monitor state resynchronization and zero orphaned subscriptions.

### Repository

- **Commit:** `da05c109c1328578ff046e2267befc3732efdffb` (`feat(m5): implement shell cold-start optimization and performance profiling (M5-T5)`)
- **Branch:** `main`
- **Working tree:** Implementation files present (`shell.qml`, `src/`, `config/`, `docs/`, `scripts/`)
- **Repository structure:** Matches `MASTER.md` §59 and `TASKS.md` §7

### Environment

- **Host OS:** Windows with WSL2 Linux runtime (`/mnt/d/Linux/BASEUS`)
- **Linux Distribution & Kernel:** `Arch Linux` on WSL2 (`Linux 6.18.54.1-microsoft-standard-WSL2`)
- **Display Connection:** WSLg Wayland (`WAYLAND_DISPLAY=wayland-0`) and nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` → live Hyprland child `WAYLAND_DISPLAY=wayland-1`)
- **Shell Runtime:** `Quickshell 0.3.2` (`quickshell-git`, rev `9b0f339b19057f4731bf3b48293307d7ef241671`)
- **Qt / QML Tooling:** Qt 6 (`qmllint 6.12.0` at `/usr/lib/qt6/bin/qmllint`)
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`, Lua config manager `Hyprland.usingLua == true`, dual headless outputs `VIRTUAL-1` and `VIRTUAL-2`)

### Implementation

- **Session & Power Management Subsystem (`PowerService.qml`, `SessionOverlay.qml`)**:
  - Modal constellation power menu (`WlrLayer.Overlay`, `DEC-027`, `MASTER.md` §32) with quiet dark space, palette-aware stars, and sparse radial layout.
  - 1000ms radial sweep hold-to-confirm progress timer protecting destructive actions (`reboot`, `poweroff`).
  - Direct keyboard mnemonics (`L`, `S`, `O`, `R`, `P`) and arrow key navigation.
  - Quiet sleeping chibi companion with zero-CPU idle timer gating (`ANTI-SLOP.md` §37).
  - Dynamic Layer-Shell input mask (exclusive keyboard focus on target monitor, 0x0 click-through at idle).
- **Idle Management & Inhibitor Subsystem (`IdleService.qml`)**:
  - Event-driven idle management backend supporting Wayland `ext-idle-notify-v1` (`IdleMonitor`) with tiered progression (`dimTimeout: 300s`, `lockTimeout: 600s`, `suspendTimeout: 900s`).
  - Presentation Mode / Awake Mode inhibitor toggle completely halting idle timers and suppressing auto-lock/sleep actions while active.
  - Contextual Top Island awake pip indicator rendered with `Theme.colors.accent` in `TopIslandAnchor.qml` and interactive toggle in `TopIslandHeader.qml`.
  - Normalized `EventBus` category `"idle"` (`inhibitor_changed`, `tier_reached`, `activity_detected`).
- **Session Lock Surface & Authentication Architecture (`LockScreen.qml`, `AuthService.qml`)**:
  - Wayland `ext-session-lock-v1` protocol surface via `WlSessionLock` + `WlSessionLockSurface` with exclusive overlay fallback, securing 100% of connected display outputs (`DEC-025`, `DESIGN.md` §35).
  - 100% opaque solid body (`Theme.colors.surfaceSolid`, zero background window bleed-through, zero blur shaders per `ANTI-SLOP.md`).
  - Linux PAM authentication state machine via `Quickshell.Services.Pam.PamContext` with deterministic simulation parity under `BASEUS_SIMULATION=1`.
  - Minute-aligned typographic clock with timer gated to visible-only running state.
  - Monospace bullet password buffer, Enter submission, and Escape buffer reset (strictly non-dismissible via Escape).
- **Hardware Bindings & Gesture Scaffolding (`GestureService.qml`, `config/hyprland-baseus.conf`)**:
  - Synchronized canonical keybinding config mapping all 35 core actions registered in `ActionRegistry.qml` to native Hyprland keybinds.
  - Touchpad gesture processor: 3-finger horizontal swipe (`workspace.next`, `workspace.previous`), 4-finger vertical swipe (`surface.app_drawer`, `navigation.overview`).
  - 350ms cooldown latching preventing rapid duplicate gesture firing.
- **Performance Profiling & Optimization (`Lifecycle.qml`, `scripts/profile_performance.py`)**:
  - Cold-start latency optimized to ~133ms (sub-300ms ceiling).
  - Zero-cost idle desktop verified at 0.00% CPU utilization (0.0 ticks/s).
  - Bounded steady-state memory (~204MB RSS under WSL2 Mesa llvmpipe with ~34MB BASEUS shell footprint; +27.8MB across 25 overlay stress cycles).

### Validation

| Area | Status | Evidence |
|---|---|---|
| Anti-Slop & Design Audit | VERIFIED | Automated audit across all 55 QML files: 0 violations, zero hardcoded hex colors outside definition tokens, zero blur/glass/shadows, 100% `pragma ComponentBehavior: Bound` |
| QML Static & Type Linting | VERIFIED | `scripts/validate.sh --all` (`/usr/lib/qt6/bin/qmllint` 6.12.0) and `scripts/validate.ps1` passed with 0 errors and 0 warnings across all 55 QML files |
| Configuration Validation | VERIFIED | `config/baseus.json` validated JSON; idle configuration schema (`dimTimeout: 300`, `lockTimeout: 600`, `suspendTimeout: 900`, `autoLock: true`, `autoSuspend: false`) verified |
| Offline Simulation Suite | VERIFIED | `verify_m5_e2e.py` Phase B: SessionOverlay constellation menu & destructive hold gating, IdleService tiers & inhibitor toggle, LockScreen airtight occlusion & mock auth, ActionRegistry 35 core actions & multi-finger gestures with 350ms cooldown passed 100% |
| Dual-Monitor Idle State | VERIFIED | `verify_m5_e2e.py` Step C1: Dual-monitor idle state verified with 0x0 hitmask across all overlays (100% click-through desktop, 0 cockpit slop) |
| Session Menu Live Delivery | VERIFIED | `verify_m5_e2e.py` Step C2: Live open on Monitor 0, constellation composition, action selection, and 0x0 hitmask recovery verified |
| Presentation Mode Live Delivery | VERIFIED | `verify_m5_e2e.py` Step C3: Live inhibitor toggle and Top Island awake pip indicator verified |
| Lock Screen Live Delivery | VERIFIED | `verify_m5_e2e.py` Step C4: Live lockSession dispatch, ext-session-lock-v1 protocol occlusion, and clean unlock verified |
| Overlay Mutual Exclusivity Live | VERIFIED | `verify_m5_e2e.py` Step C5: CommandCenter <-> SessionOverlay <-> WallpaperPicker <-> Headquarter seamless transitions verified |
| Lifecycle & Shell Restart Recovery | VERIFIED | `verify_m5_e2e.py` Step C6: `quickshell ipc call baseus restart` cleanly recovers 2 monitors, layer surfaces, and session subsystems |
| Performance Benchmark Suite | VERIFIED | `verify_m5_e2e.py` Phase D / `scripts/profile_performance.py`: Cold start 133.7ms (<300ms ceiling), steady-state RSS 204.3 MB, memory delta +27.8 MB across 25 overlay cycles, 0.00% idle CPU utilization (0.0 ticks/s) |
| Comprehensive Multi-Monitor E2E | VERIFIED | `verify_m5_e2e.py` executed Phase A, Phase B, Phase C, and Phase D with 100% PASS |

### Known Limitations

- **WSL2 virtual scanout:** Physical multi-monitor DRM master hardware scanout, physical 4-finger touchpad gestures, and hardware backlight controllers require bare-metal Linux.
- **Hardware video decoding for live wallpaper:** Headless WSL2 utilizes software decoding fallback for animated live wallpaper feeds.

### Recovery / Resume Meaning

`CP-M5-001` is the authoritative, verified **M5 — Session, Lock & Polish** baseline. All 55 QML components and core subsystems across Milestones M0 through M5 are 100% complete, verified, and anchored.


---

# 15. Recovery Principle

A checkpoint is useful only if it can be returned to or reconstructed.

For Git-backed states, the preferred recovery identity is the commit hash.

For non-Git or environment-dependent states, record the exact available recovery mechanism.

Never claim a recovery path that has not been tested or established.

---

# 16. Checkpoint and STATE.md

The documents have different roles.

`STATE.md` answers:

> What is true now?

`CHECKPOINT.md` answers:

> Which previously verified states can we reliably reference or recover to?

Therefore:

- current state may move forward without creating a checkpoint;
- a checkpoint remains historical even after `STATE.md` changes;
- superseded checkpoints remain useful as historical recovery points;
- invalidated checkpoints must not be presented as known-good.

---

# 17. Checkpoint and TASKS.md

`TASKS.md` defines what the agent should currently execute.

A checkpoint does not mark a task complete by itself.

A task becomes complete when:

1. implementation satisfies the task;
2. required acceptance criteria are satisfied;
3. required validation is performed;
4. the result is recorded accurately;
5. the phase exit conditions are satisfied where applicable.

A checkpoint can then preserve that known-good state.

---

# 18. Checkpoint and Phase Gates

A phase gate should normally produce a verified checkpoint when the phase establishes a meaningful stable state.

For example:

```text
TASKS
  ↓
Implementation
  ↓
Validation
  ↓
Phase Gate
  ↓
Verified Checkpoint
  ↓
STATE update
  ↓
Next Phase
```

The exact order may vary when recovery or documentation requires otherwise, but the checkpoint must not be used to bypass validation.

---

# 19. No False Stability

A project can be:

- partially implemented;
- visually impressive;
- locally working;
- passing one test;
- failing another;
- unstable under restart;
- untested on another monitor.

A checkpoint must describe the tested scope rather than turning partial success into a broad stability claim.

For example:

> "Quickshell launches successfully in the tested Hyprland session"

is valid if observed.

> "BASEUS is stable"

is too broad unless stability has actually been defined and validated.

---

# 20. Runtime Honesty

If an agent cannot perform a required runtime validation, it must record:

**UNVERIFIED**

rather than:

- assumed passing;
- probably passing;
- should work;
- verified by code inspection.

Runtime limitations must remain visible.

---

# 21. Visual Checkpoints

Visual checkpoints may include screenshots or recordings when useful.

However, visual evidence does not replace interaction or runtime validation.

A screenshot can establish:

- a surface was rendered;
- a visual arrangement existed;
- a particular state was visible.

It cannot by itself establish:

- correct keyboard behavior;
- correct gesture behavior;
- correct event handling;
- performance;
- recovery;
- accessibility.

Visual evidence should therefore be treated as one validation category.

---

# 22. Performance Checkpoints

Performance claims require measured evidence.

Where performance is relevant, record:

- what was measured;
- measurement method;
- environment;
- workload;
- result;
- acceptable threshold if one exists.

Avoid vague claims such as "lightweight" or "fast" without evidence.

---

# 23. Multi-Monitor Checkpoints

When a checkpoint covers multi-monitor behavior, record:

- monitor count;
- relevant monitor arrangement;
- workspace assignment if relevant;
- tested interactions;
- observed result.

A single-monitor success must not automatically be represented as multi-monitor validation.

---

# 24. Configuration Checkpoints

Configuration changes can affect runtime behavior.

A checkpoint that depends on configuration should record the relevant configuration identity or revision.

Do not silently omit configuration changes that materially affect reproducibility.

---

# 25. Dependency Checkpoints

When dependencies materially affect the tested state, record their relevant versions.

If dependency versions are intentionally flexible, record the supported range or actual tested versions where defined.

Do not claim reproducibility without acknowledging materially relevant dependencies.

---

# 26. Invalidating a Checkpoint

A checkpoint should be invalidated when:

- the claimed behavior is proven false;
- a required dependency is unavailable;
- recovery no longer works;
- the source revision is corrupted or unavailable;
- later investigation reveals the original validation was insufficient;
- the checkpoint's stated scope was materially misleading.

Invalidation should explain why.

Do not silently delete historical evidence.

---

# 27. Superseding a Checkpoint

A newer verified checkpoint may supersede an older one when it becomes the preferred reference state.

The older checkpoint remains useful unless it is invalidated.

The record should make the relationship explicit.

---

# 28. Checkpoint IDs

Use stable IDs.

Recommended format:

- `CP-000` — initial/documentation baseline;
- `CP-M0-001` — M0 checkpoint;
- `CP-M1-001` — M1 checkpoint;
- `CP-RC-001` — release candidate;
- `CP-REL-001` — release.

If a phase produces multiple meaningful checkpoints, increment the sequence rather than overwriting history.

---

# 29. Agent Rules

Agents may:

- create candidate checkpoints;
- update verified checkpoint evidence;
- record repository/runtime facts;
- mark checkpoints superseded or invalidated when evidence supports it.

Agents must not:

- invent validation;
- mark untested behavior verified;
- erase inconvenient failures;
- redefine product intent;
- use a checkpoint to bypass source-of-truth conflicts;
- call a checkpoint release-ready without the appropriate release validation.

---

# 30. Owner Review

A checkpoint that represents a major product milestone should be clearly reported to the project owner.

The report should state:

- checkpoint ID;
- what changed;
- what was validated;
- what remains unverified;
- known limitations;
- whether the next phase can begin.

The report should be concise; the evidence belongs in the checkpoint record.

---

# 31. Checkpoint Quality Gate

Before marking a checkpoint `VERIFIED`, ask:

### Identity

- Is the source state identifiable?
- Is the environment identifiable where necessary?

### Scope

- Is the checkpoint's scope explicit?
- Are excluded areas explicit?

### Evidence

- Was the claimed behavior actually tested?
- Is each major claim supported by evidence?

### Reproducibility

- Can the state be recovered or reconstructed?
- Are relevant dependencies/configuration known?

### Honesty

- Are limitations visible?
- Are unverified areas marked unverified?

### Governance

- Does the checkpoint respect the locked source of truth?
- Does it avoid turning implementation reality into product intent?

If any critical answer is no, keep the checkpoint as `CANDIDATE` or fix the record.

---

# 32. Current Checkpoint Index

| ID | State | Scope |
|---|---|---|
| `CP-000` | VERIFIED | Documentation baseline |
| `CP-M0-001` | VERIFIED | M0 Foundation (static `qmllint 6.12.0`, `Quickshell 0.3.2` runtime, and live `Hyprland 0.57.0` compositor IPC verified on WSL2 Arch Linux) |
| `CP-M1-001` | VERIFIED | M1 Desktop Core (fixed 10 workspaces, per-monitor navigation, freeform floating/centering, maximize vs native fullscreen, scratchpad-free minimize & restore, Action Registry, navigation primitives, DesktopHost layer scaffolding, TopIslandAnchor with ICR, contextual WorkspaceIndicator HUD, zero anti-slop violations, zero-warning `qmllint 6.12.0`, live dual-monitor Hyprland 0.57.0 E2E verified) |
| `CP-M2-001` | VERIFIED | M2 Interaction (Dock 2px trigger & scaffolding, global pins vs workspace clients, Top Island hover expansion & fullscreen notch summon, Command Center `>` prefix routing, App Drawer with search collapse & alphabet fast scroller, overlay mutual exclusivity, dynamic layer-shell hitmasking, zero anti-slop violations, zero-warning `qmllint 6.12.0`, live dual-monitor Hyprland 0.57.0 E2E verified) |
| `CP-M3-001` | VERIFIED | M3 System Feedback (top-left notifications with 70% backdrop & hold-to-silence, Top Island OSD with bubble-drop & rapid in-place morphing, centralized MPRIS media service with strict DEC-039 notification suppression, compact 328x38px header media controls, dedicated Media Widget with Bongo Cat 0-CPU idle timer gating, calm contextual System Status with non-intrusive low-power alerts, zero anti-slop violations, zero-warning `qmllint 6.12.0`, live dual-monitor Hyprland 0.57.0 E2E verified) |
| `CP-M4-001` | VERIFIED | M4 Personalization (PaletteService 4-color model & WCAG AA contrast validation, WallpaperService per-workspace static vs global live engine, ThemeService presets & strict DEC-037 interaction invariance, WallpaperPicker floating overlay & multi-workspace apply, Headquarter fullscreen settings with persistent 240px right sidebar & ICR fillets, real-time search with breadcrumbs, overlay mutual exclusivity, zero anti-slop violations, zero-warning `qmllint 6.12.0`, live dual-monitor Hyprland 0.57.0 E2E verified) |
| `CP-M5-001` | VERIFIED | M5 Session, Lock & Polish (Constellation SessionOverlay with 1000ms hold-to-confirm, IdleService with ext-idle-notify-v1 and presentation mode awake pip, LockScreen with ext-session-lock-v1 airtight opaque occlusion and PAM auth, GestureService with 35 core actions and 350ms cooldown gating, <150ms cold-start, 0.00% idle CPU utilization, zero anti-slop violations, zero-warning `qmllint 6.12.0`, live dual-monitor Hyprland 0.57.0 E2E verified) |

This index should grow as verified states are created.

---

# 33. Final Principle

> **A checkpoint is a promise about evidence, not a celebration of progress.**

Only record what was actually established.

Only call a state known-good when its stated scope has been validated.

And never let a checkpoint become a shortcut around the truth recorded by the project.
