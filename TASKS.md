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
Current Phase
   ↓
TASKS.md
   ↓
Implementation
   ↓
Validation
   ↓
STATE.md
   ↓
CHECKPOINT.md
```

Only tasks inside the active phase are normally executable.

---

# 3. Current Phase

## Milestone

**M0 — Foundation**

## Phase

**M0 — Foundation**

## Phase Goal

Establish the coherent technical and repository foundation required for BASEUS to exist as a Quickshell-based Linux + Hyprland desktop shell.

The foundation must support later capabilities without forcing each future surface to rebuild its own state, event, lifecycle, or runtime assumptions.

---

# 4. Phase Scope

This phase establishes:

- repository/source-of-truth structure;
- Quickshell runtime/bootstrap;
- BASEUS shell lifecycle;
- core state architecture;
- core event architecture;
- baseline Hyprland integration;
- configuration/state boundaries;
- diagnostics/logging;
- development validation workflow.

---

# 5. Phase Non-Goals

The following are **not** current M0 tasks:

- Dock;
- App Drawer;
- Command Center;
- Top Island;
- complete notification surface;
- complete OSD system;
- complete media UI;
- theme editor;
- wallpaper UX;
- widget system;
- Headquarter;
- advanced Overview;
- advanced window intelligence;
- Power Menu personality layer;
- Bongo Cat personality layer;
- installer;
- updater;
- release hardening.

Future capabilities remain in `ROADMAP.md`.

---

# 6. Dependencies

M0 depends on:

- Linux;
- Hyprland;
- Quickshell;
- the repository environment;
- the locked product/design/governance documents.

Where a live Hyprland/Wayland environment is unavailable, static validation may be performed, but runtime behavior must remain explicitly unverified.

---

# 7. Workstream A — Repository Foundation

## Goal

Ensure the repository structure reflects the current BASEUS source-of-truth architecture.

## Tasks

- [x] Confirm required root documentation files exist.
- [x] Confirm source-of-truth responsibilities are clear.
- [x] Confirm `docs/` structure exists for future public/development documentation.
- [x] Confirm `.github/` structure can support contribution and CI workflows.
- [x] Confirm `LICENSE` reflects MIT licensing.
- [x] Confirm repository does not rely on obsolete source-of-truth files.
- [x] Confirm generated/local files are excluded appropriately.
- [x] Confirm secret-sensitive files are excluded appropriately.

## Acceptance Criteria

- Repository structure matches the current project architecture.
- Locked documents are present and treated as authoritative.
- No legacy document silently overrides current truth.
- Repository foundation does not introduce unrelated implementation scope.

## Validation

- repository tree inspection;
- Git status;
- documentation presence checks;
- ignore-file inspection.

---

# 8. Workstream B — Quickshell Runtime Bootstrap

## Goal

Create the minimal functioning BASEUS Quickshell runtime.

## Tasks

- [x] Establish the Quickshell project entrypoint.
- [x] Establish the shell startup lifecycle.
- [x] Establish the minimal root shell surface.
- [x] Establish runtime configuration loading boundaries.
- [x] Establish a predictable development/restart workflow.
- [x] Ensure startup failure is diagnosable.
- [x] Avoid implementing polished surfaces as part of bootstrap.

## Acceptance Criteria

- BASEUS can launch as a Quickshell shell in the supported runtime environment.
- Startup and shutdown behavior are understandable.
- Runtime configuration has a clear ownership boundary.
- Bootstrap does not contain future surface-specific logic unnecessarily.
- Failure produces useful diagnostics.

## Validation

- static source inspection;
- Quickshell syntax/configuration validation where available;
- live launch on Linux + Hyprland when available;
- shell restart;
- startup failure inspection.

---

# 9. Workstream C — Shell Lifecycle

## Goal

Define predictable lifecycle behavior for BASEUS.

## Tasks

- [x] Define initialization sequence.
- [x] Define teardown behavior.
- [x] Define restart behavior.
- [x] Define state initialization timing.
- [x] Define event subscription initialization timing.
- [x] Define cleanup/unsubscription behavior.
- [x] Ensure repeated restart does not accumulate duplicate runtime subscriptions.

## Acceptance Criteria

- Startup has a deterministic sequence.
- Shutdown does not leave known persistent runtime state behind unintentionally.
- Restart does not duplicate listeners or handlers.
- State is initialized before dependent surfaces consume it.
- Failure during initialization is diagnosable.

## Validation

- repeated start/stop;
- repeated restart;
- event subscription inspection;
- state initialization checks;
- failure-path testing.

---

# 10. Workstream D — Core State Architecture

## Goal

Establish the state model required by later BASEUS capabilities.

## Tasks

- [x] Identify core state domains.
- [x] Define ownership for each core state domain.
- [x] Define read/update boundaries.
- [x] Define transient versus persistent state.
- [x] Define derived state versus source state.
- [x] Define initialization/default behavior.
- [x] Define state reset/recovery behavior.
- [x] Prevent UI surfaces from becoming uncontrolled state owners.

## Initial State Domains

The foundation should be capable of representing the concepts later required by the product, without implementing their full UI.

Potential foundation-level domains include:

- shell lifecycle;
- monitor context;
- workspace context;
- window context;
- input/navigation context;
- application context;
- transient feedback context;
- media context where required by architecture;
- theme/configuration context where required by architecture.

The foundation should not prematurely implement the complete future feature set.

## Acceptance Criteria

- Core state ownership is understandable.
- State can be consumed by multiple future surfaces without duplication.
- Persistent and transient state are distinguishable.
- Derived state does not become a second source of truth.
- Initialization is deterministic.
- Recovery behavior is defined.

## Validation

- state initialization;
- state update;
- state read;
- restart;
- duplicate update;
- invalid/missing state;
- recovery.

---

# 11. Workstream E — Core Event Architecture

## Goal

Establish a predictable event flow for BASEUS.

## Tasks

- [x] Define core event categories.
- [x] Define event producers.
- [x] Define event consumers.
- [x] Define subscription/unsubscription behavior.
- [x] Define event ordering where relevant.
- [x] Define duplicate-event handling.
- [x] Define failure behavior for event handlers.
- [x] Avoid hidden side effects in generic event pathways.

## Foundation Event Categories

The architecture should be capable of supporting events related to:

- shell lifecycle;
- monitor changes;
- workspace changes;
- window changes;
- input/actions;
- application state;
- system feedback;
- media;
- theme/palette;
- configuration.

These are architectural categories, not permission to implement all associated surfaces in M0.

## Acceptance Criteria

- Event flow is understandable.
- Consumers can subscribe without creating uncontrolled coupling.
- Duplicate subscriptions are prevented.
- Event failures are diagnosable.
- Future surfaces can consume events without inventing separate parallel event systems.

## Validation

- event emission;
- event subscription;
- event delivery;
- unsubscribe;
- repeated restart;
- duplicate event detection;
- handler failure.

---

# 12. Workstream F — Hyprland Integration Baseline

## Goal

Establish the minimal Hyprland integration required by the BASEUS runtime and future desktop capabilities.

## Tasks

- [x] Establish Hyprland IPC integration boundary.
- [x] Establish workspace state observation.
- [x] Establish window state observation.
- [x] Establish monitor state observation.
- [x] Establish relevant event subscription.
- [x] Define Hyprland-to-BASEUS state translation.
- [x] Keep Hyprland-specific details isolated from generic shell state where practical.
- [x] Document runtime assumptions.

## Acceptance Criteria

- BASEUS can observe required Hyprland desktop context.
- Hyprland events reach the BASEUS event/state layer.
- Hyprland-specific behavior does not leak unnecessarily through every UI surface.
- Runtime assumptions are documented.
- Unsupported/unavailable Hyprland runtime is reported honestly.

## Validation

When live Linux + Hyprland is available:

- workspace event;
- window event;
- monitor event;
- shell restart;
- repeated event handling.

When it is not available:

- static configuration/source validation only;
- clearly record runtime limitation in `STATE.md`.

---

# 13. Workstream G — Configuration Boundaries

## Goal

Prevent configuration, persistent state, runtime state, and visual theme state from becoming one uncontrolled system.

## Tasks

- [x] Define static configuration boundary.
- [x] Define runtime state boundary.
- [x] Define persistent user state boundary.
- [x] Define theme visual-state boundary.
- [x] Define defaults.
- [x] Define configuration loading order.
- [x] Define invalid-configuration behavior.
- [x] Define safe fallback behavior.

## Acceptance Criteria

- Configuration has a clear source.
- Runtime state is not accidentally persisted.
- Theme does not silently control behavior.
- Invalid configuration has a predictable failure path.
- Defaults remain usable.

## Validation

- valid configuration;
- missing configuration;
- malformed configuration;
- restart;
- fallback;
- persistence boundaries.

---

# 14. Workstream H — Diagnostics and Logging

## Goal

Make foundational failures diagnosable without requiring users or agents to guess.

## Tasks

- [x] Establish logging conventions.
- [x] Establish useful log levels.
- [x] Include enough context for lifecycle/state/event failures.
- [x] Avoid noisy logging during normal idle operation.
- [x] Ensure startup failure can be diagnosed.
- [x] Ensure event/state failures can be traced.
- [x] Ensure sensitive values are not logged unnecessarily.

## Acceptance Criteria

- Important failures produce useful diagnostics.
- Normal idle behavior does not generate excessive noise.
- Logs identify the relevant subsystem.
- Secrets or sensitive values are not exposed.
- Diagnostics can support future `doctor` tooling without coupling M0 to the installer milestone.

## Validation

- startup failure;
- invalid configuration;
- event handler failure;
- state initialization failure;
- log inspection.

---

# 15. Workstream I — Development and Validation Workflow

## Goal

Create a repeatable way to validate foundation changes.

## Tasks

- [x] Define basic syntax/static validation.
- [x] Define project structure validation.
- [x] Define Quickshell validation where available.
- [x] Define Hyprland validation where available.
- [x] Define runtime validation procedure.
- [x] Document environment limitations.
- [x] Ensure validation commands are reproducible.
- [x] Distinguish static from runtime validation.

## Acceptance Criteria

- A new agent can understand how to validate M0.
- Validation results are reproducible.
- Runtime limitations are explicit.
- Validation does not rely on invented success conditions.

---

# 16. Workstream J — Baseline Documentation

## Goal

Document only the foundation knowledge needed to maintain the project correctly.

## Tasks

- [x] Document foundation architecture.
- [x] Document state ownership.
- [x] Document event flow.
- [x] Document runtime lifecycle.
- [x] Document Hyprland integration boundary.
- [x] Document development validation.
- [x] Keep documentation aligned with implementation.

## Non-goal

Do not attempt to complete every public user guide in M0.

---

# 17. Workstream K — Source-of-Truth Integration

## Goal

Ensure the implementation process is governed by the locked product documents.

## Tasks

- [x] Verify implementation decisions against `MASTER.md`.
- [x] Verify UI-related foundation decisions against `DESIGN.md`.
- [x] Verify quality-sensitive decisions against `ANTI-SLOP.md`.
- [x] Verify accepted behavior against `DECISIONS.md`.
- [x] Verify sequencing against `ROADMAP.md`.
- [x] Ensure no implementation detail silently becomes a new product decision.

## Acceptance Criteria

- Foundation implementation does not contradict locked product truth.
- Architectural choices remain compatible with the roadmap.
- Conflicts are surfaced instead of silently resolved through document changes.

---

# 18. Cross-Cutting Technical Rules

During M0:

- Prefer event-driven behavior.
- Avoid unnecessary polling.
- Avoid premature abstraction.
- Keep state ownership explicit.
- Keep event ownership explicit.
- Keep Hyprland-specific behavior isolated.
- Keep configuration boundaries explicit.
- Keep failure handling observable.
- Avoid UI polish that belongs to later phases.
- Avoid implementing future surfaces merely to demonstrate architecture.

---

# 19. Cross-Cutting UX Rules

Even though M0 is foundational, technical choices must not make future BASEUS design harder.

Avoid architecture that assumes:

- permanent panels;
- traditional taskbars;
- forced tiling;
- generic card dashboards;
- unrestricted theme editors;
- always-visible status bars;
- global behavior changes caused by theme selection.

Foundation should enable the locked product model rather than constrain it toward generic desktop-shell patterns.

---

# 20. Explicitly Deferred

The following are acknowledged but intentionally deferred:

### M1

- full workspace capability;
- full window capability;
- desktop navigation.

### M2

- Dock;
- Top Island;
- Command Center;
- App Drawer.

### M3

- notifications;
- OSD;
- media;
- system feedback surfaces.

### M4

- wallpaper UX;
- Matugen;
- theme system;
- widgets;
- Headquarter.

### M5

- Overview;
- advanced window intelligence;
- Alt+Tab refinement;
- snap;
- multi-monitor refinement.

### M6

- personality surfaces;
- Bongo Cat;
- Power Menu constellation;
- Chibi;
- special choreography.

### M7+

- distribution;
- hardening;
- release readiness.

These items are not M0 tasks.

---

# 21. M0 Acceptance Checklist

M0 should not be marked complete until all applicable criteria are satisfied.

## Repository

- [x] Source-of-truth structure exists.
- [x] Locked documents are recognized as authoritative.
- [x] Legacy files do not silently override current truth.
- [x] Repository hygiene is acceptable.

## Runtime

- [x] Quickshell bootstrap exists.
- [x] Lifecycle is defined.
- [x] Startup failure is diagnosable.
- [x] Restart behavior is understood.

## State

- [x] Core state ownership exists.
- [x] Persistent/transient boundaries are defined.
- [x] Initialization is deterministic.
- [x] Recovery behavior is defined.

## Events

- [x] Core event model exists.
- [x] Subscription lifecycle is defined.
- [x] Duplicate subscriptions are prevented.
- [x] Event failures are diagnosable.

## Hyprland

- [x] Integration boundary exists.
- [x] Required desktop context can be observed.
- [x] Runtime assumptions are documented.
- [x] Runtime validation is performed when environment permits. (VERIFIED on WSL2 Arch Linux against live `Hyprland 0.57.0` + `Quickshell 0.3.2` — `.socket.sock` and `.socket2.sock` IPC, `bridgeConnected: true`, `hyprctl` → `socket2` → `HyprlandBridge` → `WorkspaceModel`/`WindowModel`/`ShellState` event flow, bidirectional `Hyprland.usingLua` `hl.dsp.focus` dispatch, live Wayland window open/fullscreen/close, live restart state resync, and unavailable-Hyprland graceful fallback all verified)

## Configuration

- [x] Configuration boundaries are defined.
- [x] Defaults exist.
- [x] Invalid configuration behavior is defined.
- [x] Theme state is not mixed with behavior.

## Diagnostics

- [x] Logging exists.
- [x] Important failures are visible.
- [x] Idle logging remains controlled.
- [x] Sensitive values are protected.

## Validation

- [x] Static validation works.
- [x] Runtime validation procedure is documented.
- [x] Environment limitations are recorded honestly.

## Documentation

- [x] Foundation architecture is documented.
- [x] State/event boundaries are documented.
- [x] Development validation is documented.

---

# 22. Validation Matrix

| Area | Static | Runtime | Required before M0 exit |
|---|---|---|---|
| Repository structure | Yes | No | Yes |
| Source-of-truth structure | Yes | No | Yes |
| Quickshell syntax/config | Yes where tooling exists | Yes | Yes when runtime available |
| Shell lifecycle | Partial | Yes | Yes |
| State initialization | Partial | Yes | Yes |
| Event flow | Partial | Yes | Yes |
| Hyprland IPC | Partial | Yes | Yes when runtime available |
| Configuration fallback | Yes | Yes | Yes |
| Logging | Yes | Yes | Yes |
| Performance baseline | Partial | Yes | Baseline required |
| UI polish | Not a M0 gate | Not a M0 gate | No |

If runtime validation cannot be performed, the relevant items remain explicitly unverified rather than being marked complete.

---

# 23. Definition of Done for Individual Tasks

A task is complete when:

- implementation exists;
- scope is respected;
- acceptance criteria are met;
- validation was performed;
- failures are understood;
- relevant documentation is updated;
- no source-of-truth conflict remains;
- state can accurately describe the result.

---

# 24. Definition of Done for M0

M0 is complete when:

1. BASEUS has a functioning Quickshell foundation.
2. Shell lifecycle is predictable.
3. Core state architecture exists.
4. Core event architecture exists.
5. Hyprland integration boundary exists.
6. Configuration boundaries are clear.
7. Diagnostics exist.
8. Validation workflow exists.
9. Foundation documentation exists.
10. Locked product truth remains intact.
11. Relevant design/technical gates pass.
12. `STATE.md` accurately records the result.
13. A known-good checkpoint is created when appropriate.

---

# 25. Out-of-Scope Parking Lot

Ideas discovered during M0 that do not belong in the current phase should be recorded separately rather than inserted into this task list.

Examples:

- future UI improvements;
- future widgets;
- new animations;
- future distribution support;
- optional integrations;
- personality ideas;
- convenience features.

The parking lot is not a commitment to implement those ideas.

---

# 26. Agent Execution Rule

The agent should execute M0 in coherent slices.

Recommended order:

```text
Repository Foundation
        ↓
Quickshell Runtime
        ↓
Lifecycle
        ↓
State Architecture
        ↓
Event Architecture
        ↓
Hyprland Integration
        ↓
Configuration Boundaries
        ↓
Diagnostics
        ↓
Validation Workflow
        ↓
Documentation
        ↓
Foundation Gate
```

A later workstream may begin early when its dependencies are satisfied, but the agent must not bypass foundational dependencies simply to make visible progress.

---

# 27. Stop Conditions

Stop current execution when:

- the requested M0 task is complete;
- a blocking dependency is missing;
- a source-of-truth conflict is discovered;
- runtime validation is impossible and no honest substitute exists;
- repeated implementation attempts fail;
- M0 exit criteria are satisfied.

Do not automatically begin M1.

---

# 28. Current Status

**Phase:** M0 — Foundation  
**Execution status:** COMPLETE & VERIFIED — static validation (`qmllint 6.12.0`), Quickshell 0.3.2 runtime validation, and live `Hyprland 0.57.0` compositor IPC (`socket` + `socket2` + `Hyprland.dispatch`) VERIFIED on WSL2 Arch Linux (`CP-M0-001` VERIFIED)  
**Scope status:** All M0 Foundation tasks and acceptance criteria satisfied  
**Next execution focus:** M0 exit criteria satisfied; STOP at phase boundary awaiting deliberate transition to **M1 — Desktop Core**.

---

# 29. Final Principle

`TASKS.md` should remain boring, explicit, and executable.

It is not a showcase.

It is not a wishlist.

It is not a second roadmap.

It is the current boundary that tells the agent:

> **What are we doing now, what are we not doing now, how do we know it works, and when do we stop?**
