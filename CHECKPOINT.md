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

This index should grow as verified states are created.

---

# 33. Final Principle

> **A checkpoint is a promise about evidence, not a celebration of progress.**

Only record what was actually established.

Only call a state known-good when its stated scope has been validated.

And never let a checkpoint become a shortcut around the truth recorded by the project.
