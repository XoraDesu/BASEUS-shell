# AGENTS.md

**Project:** BASEUS  
**Document role:** Agent operating protocol  
**Authority:** Operational rules derived from the locked product, design, anti-slop, decisions, and roadmap documents.

---

# 1. Purpose

`AGENTS.md` defines how an AI agent or automated development agent must operate inside the BASEUS repository.

It answers:

> **How should an agent work on BASEUS without damaging its product identity, architecture, scope, or source of truth?**

This document governs execution behavior.

It does not redefine:

- what BASEUS is;
- how BASEUS should look;
- accepted product decisions;
- the roadmap itself.

Those responsibilities belong to the higher-level source-of-truth documents.

---

# 2. Source-of-Truth Hierarchy

Before making changes, agents must understand the authority hierarchy.

```text
MASTER.md
    │
    ├── DESIGN.md
    └── DECISIONS.md
          │
       ROADMAP.md
          │
       TASKS.md
          │
    implementation
          │
    STATE.md / CHECKPOINT.md
```

Cross-cutting quality and execution rules:

```text
ANTI-SLOP.md
AGENTS.md
```

`MASTER-PROMPT.md` is only a launcher/context-loading mechanism. It is not an additional source of product truth.

## Authority rules

### MASTER.md

Defines the highest-level product truth.

### DESIGN.md

Defines visual and interaction truth.

### ANTI-SLOP.md

Defines the quality system used to reject generic, accidental, or unnecessary design.

### DECISIONS.md

Records accepted decisions and their rationale.

### ROADMAP.md

Defines intended development sequence.

### TASKS.md

Defines current executable scope.

### STATE.md

Records current implementation reality.

### CHECKPOINT.md

Records known-good project states.

### Implementation

Implements the source of truth.

Implementation does not override the source of truth.

---

# 3. Core Agent Principle

The agent is an implementation executor, not the owner of product direction.

The agent may:

- inspect;
- reason;
- implement;
- refactor within scope;
- validate;
- diagnose;
- document reality;
- update execution state.

The agent may not silently redefine:

- product identity;
- visual language;
- interaction philosophy;
- accepted architectural decisions;
- roadmap direction;
- scope boundaries.

If implementation reveals that an existing decision is problematic, the agent must surface the conflict rather than silently rewriting the decision.

---

# 4. Required Lifecycle

Every meaningful implementation task follows:

```text
ORIENT
  ↓
READ SOURCE OF TRUTH
  ↓
CHECK CURRENT STATE
  ↓
UNDERSTAND CURRENT PHASE
  ↓
PLAN
  ↓
IMPLEMENT
  ↓
VALIDATE
  ↓
UI/UX REVIEW
  ↓
UPDATE STATE
  ↓
CHECKPOINT
  ↓
REPORT
  ↓
STOP
```

The agent must not skip directly from request to implementation.

---

# 5. ORIENT

Before changing anything, determine:

- repository location;
- current branch/worktree context;
- project structure;
- current phase;
- current task;
- current state;
- relevant source-of-truth documents;
- relevant implementation files;
- known blockers.

Do not assume that an old implementation state is still valid.

Do not treat stale generated files, old task lists, or previous project versions as current truth unless the current source of truth explicitly says so.

---

# 6. READ SOURCE OF TRUTH

The minimum context for normal implementation is:

- `MASTER.md`;
- `AGENTS.md`;
- `TASKS.md`;
- `STATE.md`.

For UI/UX work, additionally read:

- `DESIGN.md`;
- `ANTI-SLOP.md`.

For architecture or behavior governed by an accepted decision, additionally read:

- `DECISIONS.md`;
- relevant architecture documentation.

For roadmap/phase questions, read:

- `ROADMAP.md`.

Read only as much implementation-specific material as necessary to execute the current task, but never skip the governing documents.

---

# 7. CURRENT PHASE IS THE DEFAULT BOUNDARY

The current phase determines what the agent is allowed to work on.

The agent must know:

- current milestone;
- current phase;
- phase goal;
- phase scope;
- phase non-goals;
- dependencies;
- acceptance criteria;
- validation;
- exit criteria.

A feature appearing in `ROADMAP.md` is not automatically executable.

Future roadmap work remains future work.

---

# 8. TASK SCOPE

Before implementation, the agent should be able to state:

```text
Goal:
Scope:
Non-goals:
Dependencies:
Files/components expected to change:
Validation:
Exit condition:
```

If these cannot be determined, the agent should inspect the relevant source-of-truth files before coding.

---

# 9. Scope Expansion

The agent must not expand scope merely because:

- a related feature would be convenient;
- a cleaner architecture could include it;
- a future feature is nearby;
- the agent notices an unrelated bug;
- the implementation would look more complete with additional UI;
- the agent wants to "finish the whole area."

Scope may expand only when:

1. a dependency blocks the current task;
2. a critical bug prevents correct operation;
3. the owner explicitly requests the expansion.

When scope expansion is necessary, document:

- why it is necessary;
- what changed;
- why it cannot reasonably wait;
- what remains outside scope.

---

# 10. Plan Before Implementation

For non-trivial changes, make a compact implementation plan.

The plan should identify:

1. affected components;
2. state/data flow;
3. event flow;
4. UI surfaces if applicable;
5. configuration impact;
6. compatibility concerns;
7. validation strategy;
8. files expected to change.

Prefer the smallest coherent implementation.

Avoid speculative abstraction.

Avoid creating infrastructure solely because a future feature might need it.

---

# 11. Implementation Principles

## 11.1 Smallest coherent change

Prefer:

```text
one capability
→ one coherent implementation
→ validation
```

over:

```text
rewrite multiple subsystems
→ add several future abstractions
→ hope everything still works
```

## 11.2 Preserve existing behavior

Unless the current task explicitly changes behavior, existing working behavior should remain intact.

## 11.3 Avoid accidental redesign

A technical task is not permission to redesign unrelated UI.

## 11.4 Prefer explicit behavior

BASEUS should be understandable in code as well as in UI.

## 11.5 Keep state ownership clear

Each piece of state should have an understandable owner and update path.

## 11.6 Keep event flow predictable

Events should not produce hidden side effects that make the system difficult to reason about.

---

# 12. UI/UX Work

When touching UI, the agent must read:

- `MASTER.md`;
- `DESIGN.md`;
- `ANTI-SLOP.md`;
- relevant `DECISIONS.md` entries.

The agent must evaluate:

- hierarchy;
- whitespace;
- typography;
- surfaces;
- motion;
- interaction;
- icon semantics;
- palette;
- context;
- accessibility;
- performance.

---

# 13. BASEUS Visual Identity

Agents must preserve the established identity:

- wabi-sabi as static foundation;
- cyberpunk primarily through motion/effects;
- editorial/archival influence structurally;
- solid surfaces;
- intentional whitespace;
- contextual motion;
- freeform-first interaction;
- palette-driven visual state;
- restrained personality.

Do not introduce generic "modern UI" patterns merely because they are easy to implement.

---

# 14. Anti-Slop Enforcement

Every new visual element should answer:

1. What does it do?
2. Why is it here?
3. Why is it this size?
4. Why does it have this visual treatment?
5. Why does it behave this way?
6. Why does it feel like BASEUS?
7. What becomes worse if it is removed?

If these questions cannot be answered, the element should be reconsidered.

Apply the removal test:

> If removing the element does not make the interface meaningfully worse, the element may not need to exist.

Do not add:

- decorative cards;
- arbitrary gradients;
- glass effects;
- permanent glows;
- fake telemetry;
- random decorative data;
- unnecessary containers;
- excessive rounded surfaces;
- animation without purpose;
- icons where typography communicates better;
- personalization controls without meaningful purpose.

---

# 15. Interaction Rules

BASEUS follows:

```text
Discover
   ↓
Customize
   ↓
Execute
```

The agent should favor discoverability over memorization.

One action should be representable by multiple appropriate triggers where the product design calls for it.

Conflict handling should be explicit.

Do not introduce hidden gestures or shortcuts that users must memorize without a discoverable path.

---

# 16. Window Philosophy

Agents must preserve:

- freeform floating windows;
- smart assistance only where necessary;
- no forced tiling;
- no scratchpad;
- centered new windows;
- centered restore;
- overlap as a valid state;
- native fullscreen distinct from maximize.

A technical opportunity to implement tiling does not justify changing BASEUS's window philosophy.

---

# 17. Workspace Rules

The workspace model is:

- exactly 10 workspaces;
- per-monitor;
- Super+1 through Super+0;
- 4-finger left/right navigation where supported.

Do not silently change the workspace count or semantics.

---

# 18. Theme Rules

Theme is visual state, not behavior.

Theme may include:

- wallpaper;
- palette;
- extraction characteristic;
- widget arrangement;
- Home/Dock/Top Island/notification visual configuration;
- app icon appearance.

Theme must not silently redefine:

- gestures;
- shortcuts;
- window behavior;
- notification timeout;
- Dock trigger;
- interaction semantics.

A theme switch must not unexpectedly alter how BASEUS works.

---

# 19. Wallpaper and Palette Rules

Static wallpaper:

- per workspace.

Live wallpaper:

- global.

Live-wallpaper palette extraction must be bounded.

Agents should favor:

- brief sampling;
- multiple-frame sampling where needed;
- abnormal-frame filtering;
- one palette extraction;
- caching.

Do not create continuous expensive palette extraction unless explicitly justified and accepted.

---

# 20. Motion Rules

Motion must communicate:

- focus;
- context;
- transition;
- causality;
- state.

Motion must not exist merely to demonstrate animation capability.

Use:

> Focus grows. Context recedes.

Avoid stacking independent animations when a state can morph or update in place.

Repeated events should generally update or morph an existing transient surface rather than producing an animation pile-up.

---

# 21. Performance Rules

BASEUS should be event-driven and cache expensive work.

Agents should avoid:

- unnecessary polling;
- continuous expensive computation;
- repeated palette extraction;
- needless filesystem scans;
- redundant process spawning;
- unnecessary animation loops;
- persistent work during idle state.

When adding background work, ask:

- Can it be event-driven?
- Can it be cached?
- Can it happen only on demand?
- Can it stop while idle?
- Can it be batched?

---

# 22. Failure Handling

When an implementation fails:

```text
Attempt
  ↓
Diagnose
  ↓
Small correction
  ↓
Validate
```

If the same approach repeatedly fails:

```text
Stop
  ↓
Report blocker
  ↓
Explain evidence
  ↓
Propose next action
```

Do not conceal failure by:

- weakening validation;
- deleting the failing test;
- changing the acceptance criterion;
- marking incomplete behavior as complete;
- silently changing scope.

---

# 23. Validation

Validation should match the change.

Examples:

### Script change

- syntax;
- behavior;
- error paths.

### State change

- persistence;
- restart;
- recovery;
- conflicting updates.

### UI change

- visual review;
- interaction review;
- accessibility;
- anti-slop;
- performance.

### Window/workspace change

- workspace behavior;
- monitor behavior;
- fullscreen/maximize distinction;
- navigation;
- regression.

### Distribution change

- clean install;
- update;
- uninstall;
- recovery;
- dependency failure.

Validation must test actual acceptance criteria, not merely whether code executes.

---

# 24. Validation Integrity

The validation method must remain meaningful.

Do not change validation simply because implementation fails it.

If a validation is genuinely wrong, that is a separate issue requiring explicit reasoning and, where necessary, a documented decision change.

A passing test is not useful if the test was weakened to make the implementation pass.

---

# 25. UI/UX Review Before Completion

A UI task is not complete merely because it renders.

Review:

- Does the hierarchy make sense?
- Is empty space intentional?
- Are surfaces necessary?
- Is the visual weight appropriate?
- Does motion communicate something?
- Is the interaction discoverable?
- Is the result unmistakably BASEUS?
- Could the result belong to a generic Linux shell without anyone noticing?
- Does it remain useful without a screenshot or demo context?
- Does it respect performance and accessibility?

---

# 26. Accessibility

Accessibility is part of implementation quality.

Agents should consider:

- keyboard access;
- focus;
- readable typography;
- contrast;
- state communication;
- motion sensitivity;
- alternatives to gestures;
- clear interaction feedback.

Do not use "minimal" as justification for inaccessible interaction.

---

# 27. Multi-Monitor Behavior

Any surface affected by monitor context must be considered in multi-monitor environments.

Agents should explicitly validate when applicable:

- workspace ownership;
- surface placement;
- fullscreen behavior;
- pointer-triggered UI;
- notifications;
- Dock;
- Top Island;
- App Drawer;
- Command Center;
- Overview.

Do not assume a single-monitor environment represents the whole product.

---

# 28. Dependency Discipline

When a task depends on another capability:

1. identify the dependency;
2. determine whether it already exists;
3. if missing, decide whether it is a blocking dependency;
4. implement only the smallest dependency necessary;
5. validate it;
6. continue the current task.

Do not build an entire future subsystem just because one small dependency is missing.

---

# 29. Architecture Changes

Architecture changes require extra caution.

Before changing foundational architecture, determine:

- what current behavior depends on it;
- what source-of-truth decisions govern it;
- what migration is required;
- what validation will prove safety;
- whether the change crosses Foundation Freeze.

If the change is fundamental and conflicts with an accepted decision, stop and surface the conflict.

---

# 30. Source-of-Truth Conflict Protocol

When implementation conflicts with source of truth:

```text
Detect conflict
    ↓
Stop affected work
    ↓
Identify exact conflict
    ↓
Explain implementation constraint
    ↓
Present possible resolution paths
    ↓
Wait for owner decision when required
```

Do not solve the conflict by silently editing the higher-level document.

Examples:

```text
DESIGN says A
implementation wants B
→ stop affected UI work
```

```text
DECISIONS says A
technical implementation requires B
→ report architectural conflict
```

```text
ROADMAP says future
current task wants future feature
→ keep future feature out of current scope
```

---

# 31. Design Proposals

A significant UI change should have a Design Proposal before implementation.

A proposal should describe:

- problem;
- current behavior;
- proposed behavior;
- affected surfaces;
- design rationale;
- interaction impact;
- performance impact;
- accessibility impact;
- migration impact;
- relationship to existing decisions.

Major identity changes require:

1. proposal;
2. impact analysis;
3. owner approval;
4. `DECISIONS.md` update;
5. migration plan where required.

---

# 32. Decision Discipline

Agents may discover useful information and recommend changes.

Agents may not turn recommendations into accepted product decisions without the required governance.

If a new implementation choice is clearly within existing decisions, implement it.

If it changes the meaning of an existing decision, stop and surface it.

---

# 33. State Updates

After meaningful work, update `STATE.md` so it reflects reality.

State should communicate:

- current phase;
- completed work;
- incomplete work;
- blockers;
- validation status;
- next relevant milestone.

Do not use STATE as a wishlist.

Do not claim completion merely because code exists.

---

# 34. Checkpoints

Create or update `CHECKPOINT.md` when an important known-good state is reached.

A useful checkpoint should identify:

- state;
- validation performed;
- known limitations;
- relevant version/commit;
- what can safely be resumed from.

Checkpoints are especially valuable after foundational work and major integration.

---

# 35. Reporting

At the end of a task, report concisely:

```text
Completed:
- ...

Changed:
- ...

Validated:
- ...

Known limitations:
- ...

State:
- ...

Next:
- ...
```

Do not bury blockers.

Do not claim tests passed if they were not run.

Do not claim runtime validation when only static validation was possible.

---

# 36. Runtime Environment Honesty

Agents must distinguish:

```text
static validation
```

from:

```text
runtime validation
```

For example:

- syntax validation is not runtime validation;
- configuration parsing is not interactive behavior validation;
- a successful build is not UX validation;
- a static Hyprland config check is not proof of behavior inside a live Hyprland session.

When the required runtime environment is unavailable, say so.

Do not invent runtime results.

---

# 37. Current Environment vs Historical State

The repository may contain artifacts from earlier development stages.

Agents must not automatically treat:

- old task trackers;
- old state files;
- previous architecture;
- previous shell implementations;
- abandoned components;
- historical roadmaps

as current truth.

Current locked source-of-truth documents take precedence.

Historical artifacts may be inspected for context only when useful and when they do not conflict with current truth.

---

# 38. No Legacy Resurrection

Do not revive an old implementation merely because it already exists.

If a previous implementation conflicts with current BASEUS design or architecture:

- identify it;
- determine whether it is reusable;
- reuse only compatible parts;
- replace incompatible parts where required by the current plan.

Existing code is not automatically sacred.

Likewise, existing code is not automatically disposable.

---

# 39. Reuse vs Rewrite

Prefer reuse when:

- behavior remains correct;
- architecture remains compatible;
- visual/interaction language remains correct;
- ownership and state flow remain understandable.

Prefer replacement when:

- implementation encodes obsolete product decisions;
- architecture fights the current model;
- reuse would create permanent compatibility debt;
- adapting it would be more complex than a coherent replacement.

Document the reasoning for significant replacement.

---

# 40. File Change Discipline

Before changing a file, understand:

- why it is relevant;
- what behavior it owns;
- what depends on it.

After changing it:

- validate the affected behavior;
- check for references;
- check for regressions.

Avoid broad unrelated formatting changes.

Avoid drive-by refactors during focused tasks.

---

# 41. Configuration Discipline

Configuration should be:

- explicit;
- predictable;
- documented when user-facing;
- compatible with the established mental model.

Do not create hidden configuration that users cannot discover.

Do not expose every internal implementation detail as a setting.

Personalization should remain intentional.

---

# 42. Security and Secret Hygiene

Agents must not:

- commit credentials;
- expose tokens;
- hardcode secrets;
- print sensitive values unnecessarily;
- add unsafe privilege escalation;
- run destructive commands without explicit scope.

When a command can modify user state, prefer:

- dry-run;
- confirmation where appropriate;
- backup;
- rollback;
- ownership tracking.

---

# 43. Destructive Operations

Destructive operations require explicit care.

Examples:

- deleting configuration;
- uninstalling packages;
- replacing user files;
- resetting state;
- modifying system configuration.

Prefer:

```text
detect
→ backup
→ apply
→ validate
→ recover if needed
```

Never claim rollback exists unless rollback has actually been implemented and validated.

---

# 44. Git Discipline

When Git is available:

- inspect status before substantial work;
- avoid overwriting unrelated user changes;
- keep changes coherent;
- use meaningful commits/checkpoints when requested;
- do not rewrite history unnecessarily;
- do not commit generated secrets or local machine state.

An agent should not discard unrelated user work simply to produce a clean diff.

---

# 45. Parallel Work

Parallel implementation is acceptable only when workstreams are genuinely independent.

Before parallelizing, verify:

- no shared mutable state conflict;
- no source-of-truth conflict;
- no dependency ordering problem;
- validation can remain meaningful.

When uncertain, prefer sequential work.

---

# 46. Stopping Rules

An agent must stop when:

- the current task is complete;
- the current phase exit criteria are satisfied;
- the requested change is complete;
- a required owner decision is missing;
- a blocker cannot be safely resolved;
- validation cannot be honestly completed.

Do not automatically continue into the next phase.

Do not interpret "next" as permission to implement all remaining roadmap work.

---

# 47. Completion Definition

A task is Done when:

- intended implementation exists;
- behavior is correct;
- regressions were considered;
- validation was performed;
- UI follows DESIGN where relevant;
- ANTI-SLOP review passes where relevant;
- performance is acceptable;
- accessibility is considered;
- state is updated;
- blockers are documented;
- scope remained controlled.

A task is not Done merely because:

- files were created;
- code compiles;
- a screenshot looks good;
- a demo works once;
- a test was skipped.

---

# 48. Phase Completion Definition

A phase is Done when:

- phase scope is implemented;
- phase acceptance criteria are satisfied;
- validation is complete;
- non-goals remain respected;
- relevant design review passes;
- relevant technical review passes;
- state is accurate;
- required checkpoint exists;
- no unresolved blocker prevents the phase exit criteria.

After that:

> **STOP.**

The next phase should begin as a deliberate transition.

---

# 49. Agent Decision Matrix

| Situation | Agent action |
|---|---|
| Clearly within current task | Implement |
| Small implementation detail not explicitly decided | Choose the simplest coherent option consistent with source of truth |
| Future roadmap feature | Do not implement |
| Blocking dependency | Implement minimum necessary dependency |
| Critical bug | Fix if required for current work |
| Unrelated bug | Record it; do not expand scope unless blocking |
| UI conflicts with DESIGN | Stop affected work and resolve conflict |
| Implementation conflicts with DECISIONS | Stop affected work and report |
| Major identity change | Design Proposal + owner approval |
| Fundamental architecture change | Evaluate against Foundation Freeze and governance |
| Runtime unavailable | Perform static validation and report limitation |
| Repeated failed approach | Stop and report blocker |
| Phase complete | Update state/checkpoint and stop |

---

# 50. Recommended Working Loop

For every meaningful task:

```text
1. Read
2. Orient
3. Scope
4. Plan
5. Implement
6. Test
7. Review
8. Update
9. Checkpoint
10. Report
11. Stop
```

The loop should be boring.

Boring process is desirable because it reduces accidental drift.

---

# 51. Final Agent Principle

The agent's job is not to make BASEUS bigger as quickly as possible.

The agent's job is to make BASEUS:

- more complete;
- more coherent;
- more reliable;
- more usable;
- more intentional;

without losing what makes it BASEUS.

The highest-level rule is:

> **Never sacrifice product coherence merely to make implementation progress appear faster.**

And the operational rule is:

> **Implement the current truth, validate it honestly, record reality, and stop when the work is done.**
