# ROADMAP.md

**Project:** BASEUS  
**Document role:** Product development roadmap  
**Planning model:** Milestone → Phase → Task  
**Development direction:** Foundation → Capability → Surface

---

# 1. Purpose

`ROADMAP.md` defines the intended development sequence for BASEUS.

It answers:

> **What should be built, and in what broad order?**

It does not replace:

- `MASTER.md` — product truth;
- `DESIGN.md` — visual and interaction truth;
- `ANTI-SLOP.md` — design quality system;
- `DECISIONS.md` — accepted decisions;
- `TASKS.md` — current executable scope;
- `STATE.md` — actual current project condition.

The roadmap intentionally remains above individual implementation details.

---

# 2. Planning Philosophy

BASEUS is developed through:

```text
Foundation
    ↓
Capability
    ↓
Surface
```

This means the project should not primarily be built as a collection of isolated visual components.

A surface should be built when the capabilities beneath it are sufficiently stable.

For example:

```text
event/state architecture
        ↓
interaction capability
        ↓
Dock / Top Island / Command Center
```

rather than:

```text
build pretty Dock
→ discover missing state architecture
→ rewrite Dock
→ discover missing event system
→ rewrite Dock again
```

The roadmap therefore prioritizes coherent foundations before dependent surfaces.

---

# 3. Roadmap Structure

The hierarchy is:

```text
Milestone
    ↓
Phase
    ↓
Task
```

## Milestone

A broad product-development stage.

A milestone may contain several phases.

## Phase

A coherent body of work with:

- Goal;
- Scope;
- Non-goals;
- Dependencies;
- Tasks;
- Acceptance Criteria;
- Validation;
- Exit Criteria;
- IN SCOPE;
- OUT OF SCOPE.

## Task

A concrete implementation unit inside the current phase.

Detailed execution tasks belong in `TASKS.md`, not here.

---

# 4. Scope Discipline

The roadmap is not permission to implement everything mentioned inside it immediately.

Only the **current phase** is executable by default.

Agents must not jump ahead because a future feature is visible in the roadmap.

Scope may expand only when:

1. a blocking dependency requires it;
2. a critical bug requires it;
3. the owner explicitly requests it.

Otherwise, discovered future work should remain future work.

---

# 5. Quality Gates

BASEUS uses three broad quality gates.

## Design Gate

Checks:

- visual identity;
- interaction language;
- hierarchy;
- motion;
- anti-slop;
- accessibility;
- coherence with locked design.

## Technical Gate

Checks:

- correctness;
- architecture;
- performance;
- reliability;
- failure recovery;
- compatibility;
- maintainability;
- validation coverage.

## Release Gate

Checks:

- end-to-end usability;
- clean installation;
- documentation;
- regression safety;
- performance;
- accessibility;
- design consistency;
- release readiness.

A phase can be technically complete without being ready for release.

---

# 6. Milestone Map

The intended roadmap is:

```text
M0 Foundation
    ↓
M1 Desktop Foundation
    ↓
M2 Interaction
    ↓
M3 System Feedback
    ↓
M4 Personalization
    ↓
M5 Desktop Experience
    ↓
M6 Personality
    ↓
M7 Distribution
    ↓
M8 Hardening
    ↓
M9 Release Readiness
```

The order is intentional but not immutable.

A dependency discovered during implementation may require sequencing changes, but such changes should be recorded rather than silently drifting the roadmap.

---

# 7. M0 — Foundation

## Goal

Establish the project foundation required for BASEUS to exist as a coherent Quickshell desktop shell.

This milestone establishes:

- repository structure;
- governance;
- Quickshell runtime;
- core state architecture;
- core event architecture;
- baseline development workflow.

## Scope

### Project foundation

- repository structure;
- source-of-truth documents;
- license;
- contribution/governance structure;
- development documentation foundation.

### Runtime foundation

- Quickshell project boot;
- Hyprland integration baseline;
- shell lifecycle;
- process/runtime assumptions.

### State foundation

- central state concepts;
- state ownership;
- state update flow;
- event/state boundaries.

### Event foundation

- event propagation;
- subscription/update model;
- shell-level event handling;
- predictable lifecycle.

### Development foundation

- reproducible development setup;
- validation commands;
- baseline diagnostics;
- logging/debugging approach.

## Non-goals

M0 does not attempt to complete:

- Dock;
- App Drawer;
- Command Center;
- Top Island;
- notifications;
- media UI;
- Headquarter;
- themes;
- wallpaper UX;
- personality surfaces;
- installer.

## Dependencies

- Quickshell;
- Hyprland;
- Linux environment.

## Acceptance Criteria

- BASEUS launches as a Quickshell shell.
- The project has a coherent runtime lifecycle.
- Core state architecture exists.
- Core event architecture exists.
- Hyprland integration baseline is functional.
- Development/validation workflow is documented.
- Repository governance foundation exists.
- No major surface is required to fake missing foundational state.

## Validation

- clean runtime launch;
- shell restart validation;
- state update validation;
- event propagation validation;
- basic Hyprland integration validation;
- failure/logging inspection.

## Exit Criteria

M0 is complete when the project has a stable enough foundation that desktop capabilities can be built without repeatedly rebuilding the underlying runtime/state/event architecture.

## IN SCOPE

- repository;
- governance;
- runtime;
- state;
- events;
- development foundation.

## OUT OF SCOPE

- polished UI surfaces;
- personalization system;
- release installer;
- personality features.

---

# 8. M1 — Desktop Foundation

## Goal

Establish the core desktop and window-management capabilities that BASEUS surfaces depend on.

## Scope

### Workspace capability

- fixed 10-workspace model;
- per-monitor workspace state;
- workspace navigation;
- Super+1 through Super+0;
- 4-finger left/right integration where platform support permits.

### Window capability

- freeform floating windows;
- centered new-window behavior;
- overlap;
- minimize;
- centered restore;
- maximize;
- native fullscreen distinction;
- workspace movement;
- POP-style workspace transition foundation.

### Navigation capability

- desktop context;
- shell navigation primitives;
- Back/Home/Overview mental-model foundation.

### Core desktop surfaces

Only the minimal foundational surfaces required to make desktop context usable should be introduced.

## Non-goals

- polished Dock;
- full App Drawer;
- full Command Center;
- complete Overview;
- advanced smart arrangement;
- personality effects.

## Dependencies

- M0.

## Acceptance Criteria

- Ten workspaces are represented consistently.
- Workspace state is coherent per monitor.
- Window operations preserve freeform behavior.
- Workspace switching is predictable.
- Window movement between workspaces works.
- Native fullscreen remains distinct from shell maximize.
- Core navigation state is available to later surfaces.

## Validation

- workspace switching;
- multi-monitor workspace checks;
- window creation;
- minimize/restore;
- maximize/fullscreen distinction;
- move-to-workspace behavior;
- repeated navigation;
- failure/recovery checks.

## Exit Criteria

M1 is complete when BASEUS can reliably represent and navigate the desktop context without requiring the later polished shell surfaces.

## IN SCOPE

- workspaces;
- windows;
- navigation foundation;
- desktop context.

## OUT OF SCOPE

- advanced shell surfaces;
- personalization;
- personality;
- distribution.

---

# 9. M2 — Interaction

## Goal

Build the primary interaction surfaces that define how users access and control BASEUS.

## Scope

### Dock

- bottom-centered;
- edge-integrated;
- hidden/recessed idle state;
- 1–2px bottom trigger;
- contextual reveal;
- global pinned applications;
- workspace-specific active applications.

### Top Island

- top-centered;
- clock idle state;
- hover expansion;
- shell integration;
- fullscreen compact-clock behavior.

### Command Center

- universal action/search;
- search-first layout;
- result display;
- dynamic bounded height;
- transient curtain reveal.

### App Drawer

- fullscreen composition;
- persistent search;
- A–Z–0–9–# navigation;
- recent/suggested applications;
- continuous grid;
- fast scroller;
- right-click actions;
- global application discovery.

## Non-goals

- final personality layer;
- complete media experience;
- full notification system;
- advanced theme editor;
- installer.

## Dependencies

- M0;
- M1.

## Acceptance Criteria

- Dock works without behaving like a permanent taskbar.
- Top Island provides contextual system access.
- Command Center provides a universal action/search path.
- App Drawer provides scalable application discovery.
- Surfaces share coherent state.
- Monitor behavior is predictable.
- Interaction does not require unnecessary memorization.

## Validation

- keyboard navigation;
- mouse interaction;
- hover/reveal behavior;
- repeated open/close cycles;
- application discovery;
- workspace context;
- monitor context;
- fullscreen behavior;
- animation/reduced-motion checks;
- anti-slop review.

## Exit Criteria

M2 is complete when users have a coherent way to:

- see what they are using;
- see what they can open;
- invoke actions;
- access contextual shell controls.

## IN SCOPE

- Dock;
- Top Island;
- Command Center;
- App Drawer.

## OUT OF SCOPE

- full personalization;
- advanced desktop intelligence;
- final personality surfaces.

---

# 10. M3 — System Feedback

## Goal

Build the system feedback layer that communicates transient state without turning BASEUS into a permanent dashboard.

## Scope

### Notifications

- top-left placement;
- source/application recognition;
- solid surfaces;
- controlled animation;
- actions;
- dismissal;
- notification state.

### OSD

- Top Island origin;
- bubble-drop/gooey transition;
- expanded state;
- rapid-event morph/update behavior.

### Media

- Top Island integration;
- media widget;
- compact/expanded states;
- lyrics;
- conventional controls;
- media switching;
- Bongo Cat integration;
- no generic media-change notification.

### Status feedback

- system status needed by later surfaces;
- contextual feedback;
- failure communication.

## Non-goals

- permanent monitoring dashboard;
- decorative telemetry;
- fake data;
- final personality polish.

## Dependencies

- M0;
- M1;
- M2.

## Acceptance Criteria

- Notifications are useful without becoming permanent clutter.
- OSD events have a coherent spatial origin.
- Repeated system events do not create animation stacks.
- Media state is coherent across its surfaces.
- Media changes do not create generic notification noise.
- Feedback remains readable and contextual.

## Validation

- repeated notification events;
- rapid OSD changes;
- media switching;
- volume/brightness changes;
- fullscreen behavior;
- multi-monitor behavior;
- accessibility checks;
- performance checks.

## Exit Criteria

M3 is complete when BASEUS can communicate important transient desktop state without requiring a traditional status panel.

## IN SCOPE

- notifications;
- OSD;
- media;
- system feedback.

## OUT OF SCOPE

- full personalization;
- installer;
- advanced smart arrangement.

---

# 11. M4 — Personalization

## Goal

Make BASEUS meaningfully personal while preserving the visual system and keeping theme state separate from interaction behavior.

## Scope

### Wallpaper

- static per-workspace wallpaper;
- live global wallpaper;
- wallpaper picker;
- library;
- recent;
- favorites;
- preview;
- no slideshow.

### Palette

- Matugen integration;
- exactly four main colors;
- wallpaper-derived palette;
- live-wallpaper bounded sampling;
- abnormal-frame filtering;
- single extraction;
- caching.

### Theme

- visual-state model;
- wallpaper;
- palette;
- extraction characteristic;
- widget arrangement;
- Home/Dock/Top Island/notification visual configuration;
- app icon appearance;
- visual transition.

### Widgets

- dynamic widgets;
- grid snapping aid;
- freeform positioning;
- modular sizing;
- global widget state;
- no automatic packing.

### Headquarter

- fullscreen settings headquarters;
- right sidebar;
- memorable greeting;
- contextual help;
- progressive disclosure.

## Non-goals

- unrestricted theme editor;
- arbitrary component styling;
- per-element behavior configuration;
- uncontrolled personalization.

## Dependencies

- M0;
- M1;
- M2;
- M3.

## Acceptance Criteria

- Themes change visual state without changing interaction semantics.
- Static wallpaper supports workspace identity.
- Live wallpaper remains global.
- Palette extraction is bounded and cached.
- Matugen produces the four-color system.
- Widgets can be positioned without forcing automatic packing.
- Headquarter provides one coherent configuration home.

## Validation

- theme switching;
- palette stability;
- live wallpaper resource use;
- workspace wallpaper changes;
- widget repositioning;
- widget resizing;
- Headquarter navigation;
- theme/state persistence;
- clean restart recovery.

## Exit Criteria

M4 is complete when users can meaningfully personalize the desktop without turning BASEUS into an unrestricted visual editor.

## IN SCOPE

- wallpaper;
- palette;
- themes;
- widgets;
- Headquarter.

## OUT OF SCOPE

- advanced window intelligence;
- installer;
- release hardening.

---

# 12. M5 — Desktop Experience

## Goal

Refine the desktop itself with advanced but restrained interaction capabilities.

## Scope

### Window chrome

- minimal familiar chrome;
- appropriate native affordances;
- consistency with freeform philosophy.

### Smart arrangement

- slight intelligent shifts;
- assistive placement;
- no forced tiling.

### Snap

- useful snap behavior;
- freeform preservation.

### Alt+Tab

- hierarchy;
- coherent application/window switching;
- keyboard-first usability.

### Overview

- Helicopter View;
- spatial desktop context;
- integration with window/workspace state.

### Multi-monitor refinement

- per-monitor behavior;
- contextual surfaces;
- consistent workspace model;
- monitor-aware interaction.

## Non-goals

- replacing freeform behavior with tiling;
- scratchpad;
- arbitrary automation;
- permanent dashboard.

## Dependencies

- M1;
- M2;
- M3.

## Acceptance Criteria

- Window intelligence assists without fighting the user.
- Snap remains compatible with freeform interaction.
- Alt+Tab is understandable and fast.
- Overview provides useful spatial context.
- Multi-monitor behavior remains coherent.
- Native fullscreen remains distinct.

## Validation

- multi-window scenarios;
- rapid switching;
- multiple monitors;
- snap/unsnap;
- maximize/fullscreen;
- Overview entry/exit;
- keyboard and pointer interaction;
- failure/recovery.

## Exit Criteria

M5 is complete when the desktop experience feels mature without abandoning BASEUS's freeform-first model.

## IN SCOPE

- window chrome;
- smart arrangement;
- snap;
- Alt+Tab;
- Overview;
- multi-monitor refinement.

## OUT OF SCOPE

- installer;
- final release hardening;
- broad personality expansion.

---

# 13. M6 — Personality

## Goal

Add the distinctive personality elements that make BASEUS memorable without turning personality into visual noise.

## Scope

### Bongo Cat

- meaningful media interaction;
- responsive personality behavior;
- restrained integration.

### Power Menu constellation

- fullscreen constellation;
- quiet dark space;
- palette-derived visuals;
- pixel text;
- chibi elements;
- sparse composition.

### Chibi

- intentional personality cues;
- contextual appearance;
- no constant clutter.

### Special transitions

- established pixel-like reveals;
- contextual effects;
- coherent choreography.

### Editorial details

- typography;
- numbering;
- dividers;
- controlled asymmetry;
- archival influence.

## Non-goals

- permanent animation everywhere;
- neon overload;
- decorative character spam;
- fake telemetry;
- screenshot-only spectacle.

## Dependencies

- M2;
- M3;
- M4;
- M5.

## Acceptance Criteria

- Personality elements feel native to BASEUS.
- Effects remain contextual.
- Motion follows established language.
- Power Menu remains sparse.
- Chibi/Bongo Cat elements do not clutter normal desktop use.
- Editorial details reinforce hierarchy rather than becoming ornament.

## Validation

- idle-state review;
- interaction review;
- motion review;
- anti-slop review;
- accessibility review;
- performance review;
- screenshot-independent usability review.

## Exit Criteria

M6 is complete when BASEUS has its distinctive personality while remaining restrained and usable.

## IN SCOPE

- Bongo Cat;
- Power Menu;
- Chibi;
- special transitions;
- editorial details.

## OUT OF SCOPE

- installer;
- release freeze;
- unrestricted visual effects.

---

# 14. M7 — Distribution

## Goal

Make BASEUS installable, diagnosable, recoverable, and maintainable across its supported Linux environments.

## Scope

### Installer

- environment detection;
- Hyprland detection;
- distribution detection;
- dependency detection;
- adaptive installation;
- Arch path;
- Nix path;
- other supported Linux environments where practical.

### Updater

- controlled update flow;
- compatibility checks;
- safe update behavior.

### Uninstaller

- clean removal;
- user-data handling;
- configuration preservation/removal decisions.

### Doctor

- environment diagnosis;
- dependency diagnosis;
- configuration checks;
- runtime checks;
- common failure reporting.

### Recovery

- safe fallback;
- broken configuration handling;
- useful diagnostic output.

### Packaging

- supported packaging approaches;
- dependency metadata;
- versioning.

### Documentation

- installation;
- getting started;
- configuration;
- theming;
- keybindings;
- gestures;
- troubleshooting.

## Non-goals

- pretending all Linux distributions are identical;
- requiring Arch;
- hiding Hyprland requirements;
- destructive uninstall behavior.

## Dependencies

- M0 through the capabilities required for the packaged release.

## Acceptance Criteria

- Installer correctly identifies environment.
- BASEUS communicates that Hyprland is required.
- Arch and Nix have first-class paths.
- Dependency failures are understandable.
- Doctor can diagnose common setup failures.
- Recovery path exists for common configuration/runtime failures.
- Documentation matches actual installation behavior.

## Validation

- clean install;
- repeat install;
- update;
- uninstall;
- reinstall;
- dependency failure;
- unsupported environment;
- broken configuration;
- Hyprland absence;
- Arch;
- Nix;
- documentation walkthrough.

## Exit Criteria

M7 is complete when a new user can move from a supported Linux + Hyprland environment to a functioning BASEUS installation through a reproducible documented path.

## IN SCOPE

- installer;
- updater;
- uninstaller;
- doctor;
- recovery;
- packaging;
- installation documentation.

## OUT OF SCOPE

- new major UI capabilities.

---

# 15. M8 — Hardening

## Goal

Stabilize BASEUS for real-world daily use.

## Scope

### Performance

- startup;
- CPU;
- GPU;
- memory;
- idle cost;
- animation cost;
- wallpaper cost;
- widget cost.

### Reliability

- shell restart;
- surface recovery;
- state recovery;
- process failure handling;
- configuration failure handling.

### Accessibility

- contrast;
- legibility;
- keyboard access;
- focus;
- gesture alternatives;
- motion considerations;
- state communication.

### Multi-monitor

- regression checks;
- monitor addition/removal;
- workspace consistency;
- contextual surface placement.

### Regression

- core workflow tests;
- surface integration tests;
- install/update/recovery tests.

### Design hardening

- anti-slop review;
- visual consistency;
- motion consistency;
- hierarchy review.

## Non-goals

- major new features;
- redesigning locked product identity;
- adding features to fill perceived gaps.

## Dependencies

- M0 through M7.

## Acceptance Criteria

- Startup is acceptable.
- Idle resource usage is understood and controlled.
- Common shell failures recover predictably.
- Accessibility issues are addressed.
- Multi-monitor behavior is stable.
- Major regressions are caught.
- Anti-slop review passes.
- Design remains consistent with locked sources of truth.

## Validation

- clean boot;
- long-running session;
- repeated shell restart;
- multi-monitor;
- rapid interaction;
- idle performance;
- animation-heavy scenarios;
- live wallpaper;
- widget-heavy scenarios;
- failure injection where appropriate;
- accessibility review;
- regression suite.

## Exit Criteria

M8 is complete when the implementation is stable enough to enter release readiness without relying on major architectural or product changes.

## IN SCOPE

- performance;
- reliability;
- accessibility;
- multi-monitor hardening;
- regression;
- design hardening.

## OUT OF SCOPE

- new major product direction.

---

# 16. M9 — Release Readiness

## Goal

Prepare a coherent, validated BASEUS release.

## Scope

### Feature freeze

- freeze major feature scope;
- identify known issues;
- resolve release blockers.

### UX review

- complete real-use review;
- navigation review;
- interaction review;
- onboarding review.

### Design review

- MASTER alignment;
- DESIGN alignment;
- ANTI-SLOP review;
- identity review.

### Performance review

- startup;
- idle;
- active use;
- memory;
- GPU;
- live wallpaper;
- widgets.

### Documentation

- README;
- installation;
- getting started;
- configuration;
- theming;
- keybindings;
- gestures;
- troubleshooting;
- architecture/development documentation as appropriate.

### Release review

- versioning;
- license;
- repository hygiene;
- security;
- contribution documentation;
- known limitations;
- release notes.

## Non-goals

- large new feature development;
- major identity changes;
- experimental redesign.

## Dependencies

- M8.

## Acceptance Criteria

- Feature scope is frozen.
- Critical bugs are resolved or explicitly documented.
- Design passes review.
- Anti-slop review passes.
- Technical validation passes.
- Release documentation matches reality.
- Installation is reproducible.
- Known limitations are documented.
- Repository is ready for public release.

## Validation

- clean install;
- clean upgrade;
- full core workflow;
- full UI review;
- accessibility review;
- performance review;
- multi-monitor review;
- regression review;
- documentation walkthrough;
- release artifact verification.

## Exit Criteria

M9 is complete when BASEUS can be released without relying on undocumented assumptions or known critical blockers.

## IN SCOPE

- freeze;
- final validation;
- documentation;
- release preparation.

## OUT OF SCOPE

- new major feature work.

---

# 17. Foundation Freeze

Foundation Freeze occurs after the relevant foundation phase passes its quality gate.

After the freeze:

Fundamental changes require:

1. proposal;
2. impact analysis;
3. owner approval;
4. DECISIONS.md update;
5. migration plan when required.

Examples of changes that may qualify as fundamental:

- replacing core runtime architecture;
- changing the workspace model;
- replacing the freeform-first window model;
- changing the central event/state model;
- changing the core visual identity;
- changing the platform requirement;
- changing the product's primary interaction mental models.

Foundation Freeze does not prohibit normal implementation improvements.

It protects foundational intent from casual late-stage redesign.

---

# 18. Phase Transition Rules

A phase should not advance solely because its code exists.

Before moving forward, verify:

### Design

- Does the implementation follow DESIGN.md?
- Does it pass ANTI-SLOP review?
- Does it preserve identity?

### Technical

- Does it work?
- Are regressions checked?
- Are dependencies understood?
- Is performance acceptable?

### State

- Is STATE.md accurate?
- Are known limitations documented?

### Scope

- Did implementation stay within the phase?
- Were unrelated discoveries kept out?

### Checkpoint

- Is there a known-good checkpoint when appropriate?

Only then should the phase be considered complete.

---

# 19. What the Roadmap Does Not Do

The roadmap does not:

- specify every component;
- replace implementation planning;
- guarantee exact dates;
- guarantee exact task counts;
- authorize future scope;
- override locked design;
- override accepted decisions;
- define current implementation state;
- serve as a giant backlog.

Those responsibilities belong elsewhere.

---

# 20. Relationship to TASKS.md

`ROADMAP.md` describes the development direction.

`TASKS.md` describes the current executable phase.

When entering a phase:

1. read the roadmap phase;
2. establish the phase goal;
3. define scope;
4. define non-goals;
5. identify dependencies;
6. create executable tasks;
7. define acceptance criteria;
8. define validation;
9. define exit criteria;
10. explicitly state IN SCOPE / OUT OF SCOPE.

When the phase ends:

- validate;
- update state;
- create checkpoint if appropriate;
- stop.

The roadmap itself should not become a task checklist.

---

# 21. Relationship to STATE.md

ROADMAP describes intended direction.

STATE describes reality.

For example:

```text
ROADMAP:
M2 includes App Drawer.

STATE:
App Drawer is 60% implemented, search works, fast scroller is incomplete.
```

The roadmap must not be rewritten merely because implementation is incomplete.

Likewise, STATE must not claim completion merely because the roadmap says a phase should be complete.

---

# 22. Relationship to CHECKPOINT.md

A checkpoint records a known-good project state.

A roadmap phase may produce one or more checkpoints where useful.

A checkpoint should identify:

- what was working;
- what was validated;
- what remains known;
- what commit/version/state represents the checkpoint.

Checkpointing is especially valuable after:

- foundation completion;
- major architectural stabilization;
- major surface integration;
- distribution milestones;
- release readiness.

---

# 23. Agent Roadmap Rules

Agents must:

- understand the current milestone;
- understand the current phase;
- read the phase scope;
- respect phase non-goals;
- respect dependencies;
- avoid jumping ahead;
- report blockers;
- validate before marking work complete;
- update state;
- stop at phase/task completion.

Agents must not:

- implement future roadmap features merely because they are listed;
- expand a phase into the next phase;
- redefine roadmap priorities;
- skip required gates to move faster;
- change product identity to satisfy a roadmap milestone.

---

# 24. Roadmap Evolution

The roadmap may evolve as implementation reveals:

- technical constraints;
- dependency ordering;
- resource constraints;
- reliability issues;
- distribution requirements;
- user-experience discoveries.

However, roadmap changes should preserve the established product direction unless explicitly changed through governance.

When a significant roadmap change occurs:

1. identify the reason;
2. identify affected milestones/phases;
3. identify dependency changes;
4. update relevant decisions if product intent changes;
5. update TASKS/STATE as needed.

---

# 25. Current High-Level Sequence

The complete intended sequence is:

```text
M0 FOUNDATION
    Repository
    Governance
    Quickshell runtime
    State
    Events
        ↓
M1 DESKTOP FOUNDATION
    Workspaces
    Windows
    Navigation
        ↓
M2 INTERACTION
    Dock
    Top Island
    Command Center
    App Drawer
        ↓
M3 SYSTEM FEEDBACK
    Notifications
    OSD
    Media
    Status
        ↓
M4 PERSONALIZATION
    Wallpaper
    Matugen
    Palette
    Theme
    Widgets
    Headquarter
        ↓
M5 DESKTOP EXPERIENCE
    Chrome
    Smart arrangement
    Snap
    Alt+Tab
    Overview
    Multi-monitor
        ↓
M6 PERSONALITY
    Bongo Cat
    Power Menu
    Chibi
    Special transitions
    Editorial details
        ↓
M7 DISTRIBUTION
    Installer
    Updater
    Uninstaller
    Doctor
    Recovery
    Packaging
    Docs
        ↓
M8 HARDENING
    Performance
    Reliability
    Accessibility
    Multi-monitor
    Regression
    Anti-slop
        ↓
M9 RELEASE READINESS
    Feature freeze
    UX review
    Design review
    Performance review
    Documentation
    Release
```

This sequence is a planning baseline, not a substitute for engineering judgment.

---

# 26. Roadmap Completion Principle

The roadmap is successful when each stage makes the next stage easier and safer.

The project should not optimize for:

> "How many visible features can be shown?"

It should optimize for:

> **"How reliably can each capability support the next coherent layer of BASEUS?"**

The intended result is a desktop shell that feels like one system rather than a collection of independently built surfaces.

---

# 27. Closing Principle

BASEUS should be built in a way that protects its identity while allowing its capabilities to grow.

The roadmap therefore follows:

> **Foundation → Capability → Surface**

and validates progress through:

> **Design Gate → Technical Gate → Release Gate**

The roadmap gives the project direction.

The locked product and design documents give it identity.

The current task and state documents give agents executable reality.

No single roadmap milestone is more important than preserving the coherence of the whole product.
