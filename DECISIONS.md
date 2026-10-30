# DECISIONS.md

**Project:** BASEUS  
**Document role:** Accepted decision record / product governance ledger
**Authority:** MASTER.md remains the highest product source of truth. This document records explicit decisions that clarify, constrain, or operationalize that truth.

---

# 1. Purpose

`DECISIONS.md` records important BASEUS decisions so that:

- the owner does not need to repeat them;
- agents do not need to infer them;
- implementation does not silently redefine product direction;
- future changes can be compared against an explicit historical decision;
- superseded decisions remain understandable;
- disagreements can be resolved from written project history.

This file is a **decision ledger**, not a second MASTER.

It should record decisions that are important enough to preserve but too specific, numerous, or historical to belong entirely in MASTER.md.

---

# 2. Decision Authority

Decision authority follows the project governance defined in MASTER.md.

## Highest authority

`MASTER.md`

Defines:

- what BASEUS is;
- core identity;
- product boundaries;
- foundational principles;
- governance;
- major non-goals.

## Design authority

`DESIGN.md`

Defines:

- visual language;
- interaction language;
- surface behavior;
- motion;
- spatial composition;
- detailed UX rules.

## Decision authority

`DECISIONS.md`

Defines:

- explicit accepted decisions;
- rationale;
- alternatives;
- consequences;
- historical decisions that remain relevant;
- decisions that have been superseded.

## Planning authority

`ROADMAP.md`

Defines:

- milestone structure;
- phase order;
- intended development sequence.

## Execution authority

`TASKS.md`

Defines:

- current implementation scope;
- current phase work;
- acceptance criteria.

## Reality/state authority

`STATE.md`

Defines:

- what is actually implemented;
- current project condition;
- blockers;
- known gaps.

---

# 3. Decision Status

Every decision uses one of four statuses.

## Proposed

A possible decision under consideration.

It is **not binding**.

Agents must not treat a Proposed decision as permission to change product direction.

## Accepted

The decision is approved and currently authoritative within its stated scope.

Implementation should follow it unless a newer accepted decision supersedes it.

## Superseded

The decision was previously accepted but has been replaced by another decision.

It remains in the ledger for historical context.

## Rejected

The proposal was explicitly considered and rejected.

A rejected decision should remain documented when its history is useful for preventing the same proposal from being reintroduced without new information.

---

# 4. Decision Record Format

Every accepted or proposed decision should use:

```text
## DEC-XXX — Short decision title

Status: Accepted | Proposed | Superseded | Rejected
Date: YYYY-MM-DD
Scope: Product | Design | UX | Interaction | Architecture | Performance | Distribution | Governance | Release
Source: Owner decision | Design review | Implementation discovery | Other

### Decision

What was decided.

### Why

Why this decision was made.

### Alternatives Considered

What meaningful alternatives were considered.

### Consequences

What this decision enables, constrains, or requires.

### Affected Documents

Which source-of-truth documents are relevant.

### Supersedes

Previous decision ID if applicable.

### Superseded By

New decision ID if applicable.
```

Not every historical proposal needs every field, but accepted decisions should be sufficiently documented to remove ambiguity.

---

# 5. Recording Rules

## 5.1 Record decisions, not conversations

This file should not become a transcript.

Do not record:

- every brainstorming thought;
- every rejected implementation detail;
- casual preferences;
- temporary debugging notes;
- ordinary task progress.

Record the resulting decision and enough reasoning to understand it.

---

## 5.2 One decision, one identity

Each meaningful decision gets a stable ID.

IDs should not be reused.

If a decision changes:

- create a new decision;
- mark the previous one `Superseded`;
- link the two.

Do not silently edit history into a different decision.

---

## 5.3 Explicit beats implied

If an important behavior was only implied during discussion and later becomes implementation-critical, it should be recorded explicitly.

This prevents:

> "I thought we had decided that."

from becoming an implementation problem.

---

## 5.4 No retroactive invention

Agents must not create a decision and claim the owner approved it unless that approval actually occurred.

If the project history does not establish a decision, the agent must mark the matter as open or ask for owner direction when required.

---

# 6. Current Decision Ledger

The following decisions are derived from the locked BASEUS product and design decisions established before this document.

---

## DEC-001 — BASEUS is a personalized Linux desktop shell

Status: **Accepted**  
Date: 2026-09-25  
Scope: Product  
Source: Owner decision

### Decision

BASEUS is a personalized Linux desktop shell built with **Quickshell**, targeting **Linux + Hyprland**.

### Why

The project is intended to create a deeply personalized desktop experience rather than a conventional application or standalone theme.

### Alternatives Considered

- Conventional desktop environment.
- Theme-only customization.
- Traditional panel/taskbar shell.
- Tiling-first desktop experience.

### Consequences

- Hyprland is a required runtime dependency.
- Quickshell is a core implementation foundation.
- Desktop shell behavior is part of the product.
- Distribution must account for Hyprland and Linux environment differences.

### Affected Documents

- MASTER.md
- DESIGN.md
- ROADMAP.md
- AGENTS.md

---

## DEC-002 — BASEUS design language is product identity

Status: **Accepted**  
Date: 2026-09-25  
Scope: Product / Design / Governance  
Source: Owner decision

### Decision

BASEUS's design language is not a skin. It is the identity and soul of the project.

### Why

The project should remain recognizable and coherent even as implementation, features, and internals evolve.

### Alternatives Considered

- Treating design as a replaceable theme.
- Allowing implementation convenience to determine visual language.
- Allowing contributors to redefine core identity through individual features.

### Consequences

- Major identity changes require explicit governance.
- Agents cannot alter core design to make implementation easier.
- Contributors can participate without automatically redefining product direction.
- DESIGN.md is a protected source of truth.

### Affected Documents

- MASTER.md
- DESIGN.md
- ANTI-SLOP.md
- AGENTS.md

---

## DEC-003 — Wabi-sabi is the static visual foundation

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design  
Source: Owner decision

### Decision

Wabi-sabi principles provide the static visual foundation of BASEUS.

This includes:

- restraint;
- intentional emptiness;
- controlled imperfection;
- natural rhythm;
- composition over decoration.

### Why

The visual foundation should feel calm, deliberate, human, and distinct from generic polished UI.

### Alternatives Considered

- Pure minimalism.
- Glassmorphism.
- Traditional desktop chrome.
- Fully futuristic visual language.

### Consequences

- Empty space can be intentional.
- Decorative accumulation is discouraged.
- Wabi-sabi does not justify broken or sloppy UI.
- Alignment and usability remain important.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-004 — Cyberpunk is primarily motion and effects

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design / Motion  
Source: Owner decision

### Decision

Cyberpunk contributes primarily through:

- motion;
- transitions;
- effects;
- energetic state changes;
- moments of visual intensity.

It is not a permanent neon/RGB skin.

### Why

Permanent neon would overwhelm the wabi-sabi foundation and make the interface visually noisy.

### Alternatives Considered

- Permanent neon palette.
- RGB/glow-heavy dashboard.
- Sci-fi control-panel aesthetic.

### Consequences

- Neon/glow must be controlled.
- Motion is an important identity tool.
- Cyberpunk effects should be contextual.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-005 — Editorial/archival influence is structural, not ornamental

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design  
Source: Owner decision

### Decision

Editorial/archival influence may use:

- typography;
- numbering;
- dividers;
- hierarchy;
- asymmetry;
- visual rhythm.

It should not become classical, brutalist, or ornament-heavy decoration.

### Why

The desired reference contributes hierarchy and personality without turning BASEUS into a historical-themed interface.

### Consequences

- Typography is an important design tool.
- Asymmetry must remain controlled.
- Decorative historical elements are not automatically appropriate.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-006 — Solid surfaces are preferred

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design  
Source: Owner decision

### Decision

BASEUS prefers solid, palette-derived surfaces over:

- glassmorphism;
- excessive transparency;
- blur-heavy panels;
- ornamental depth.

### Why

Solid surfaces preserve hierarchy, readability, performance, and the established visual identity.

### Alternatives Considered

- Glass-heavy desktop shell.
- Transparent dashboard surfaces.
- Blur-first visual system.

### Consequences

- Transparency requires justification.
- Blur must not become the default surface treatment.
- Surfaces should be visually intentional.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-007 — Avoid long full-width bars

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design / UX  
Source: Owner decision

### Decision

BASEUS should avoid traditional long full-width bars.

Major shell surfaces should generally use:

- centered;
- dock-like;
- edge-integrated;
- contextual;
- transient

geometry where appropriate.

### Why

The desired desktop should not resemble a conventional taskbar/panel-based desktop.

### Consequences

- Dock is bottom-centered.
- Top Island is top-centered.
- Shell surfaces should avoid unnecessary horizontal sprawl.
- Traditional panel behavior is not the default.

### Affected Documents

- MASTER.md
- DESIGN.md

---

## DEC-008 — Freeform windows are the default mental model

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Window Management  
Source: Owner decision

### Decision

BASEUS favors freeform floating windows.

Tiling is not the primary window-management model.

### Why

The intended experience is closer to a freeform desktop with intelligent assistance than a tiling-first workflow.

### Consequences

- New windows may open centered.
- Windows may overlap.
- Minimize and restore remain meaningful.
- Smart arrangement should assist rather than force.
- BASEUS should never fight the user's placement.

### Affected Documents

- MASTER.md
- DESIGN.md
- ROADMAP.md

---

## DEC-009 — "Freeform first. Smart when necessary. Never fight the user."

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Interaction  
Source: Owner decision

### Decision

Smart behavior may assist the user, but must not override freeform control without a strong reason.

### Why

Automation should reduce friction, not replace user intent.

### Consequences

Any automatic arrangement should:

- be predictable;
- remain lightweight;
- preserve user agency;
- avoid forcing a layout;
- avoid hidden behavior.

### Affected Documents

- MASTER.md
- DESIGN.md
- AGENTS.md

---

## DEC-010 — Fixed ten-workspace model

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Window Management  
Source: Owner decision

### Decision

BASEUS uses **10 workspaces**.

Navigation includes:

- 4-finger left/right;
- Super+1 through Super+0.

Workspaces are per-monitor.

### Why

A fixed model provides predictable spatial navigation without requiring workspace creation/deletion management.

### Consequences

- Workspace indicators can assume a stable set.
- Navigation must remain coherent across monitors.
- Workspace identity may be represented contextually rather than permanently displayed.

### Affected Documents

- MASTER.md
- DESIGN.md

---

## DEC-011 — Exactly four main palette colors

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design / Theming  
Source: Owner decision

### Decision

BASEUS uses exactly **four main colors** as its primary palette system.

Matugen is used as part of the palette pipeline.

### Why

A bounded palette preserves identity and prevents uncontrolled color accumulation.

### Consequences

- UI elements should derive from the palette system.
- Individual components should not invent arbitrary colors.
- Dynamic wallpaper extraction must ultimately resolve into the four-color model.

### Affected Documents

- MASTER.md
- DESIGN.md
- ROADMAP.md

---

## DEC-012 — Theme is visual state, not behavior

Status: **Accepted**  
Date: 2026-09-25  
Scope: Theming / Architecture  
Source: Owner decision

### Decision

A BASEUS theme represents visual state.

Theme state may include:

- wallpaper;
- palette;
- extraction characteristic;
- widget arrangement;
- Home/Dock/Top Island/notification visual configuration;
- app icon appearance.

Theme state does **not** include:

- gestures;
- shortcuts;
- window behavior;
- notification timeout;
- Dock trigger behavior.

### Why

Visual personalization should not silently alter interaction semantics.

### Consequences

Theme switching changes appearance without unexpectedly changing how the desktop operates.

### Affected Documents

- MASTER.md
- DESIGN.md
- ROADMAP.md

---

## DEC-013 — Static wallpaper is per-workspace; live wallpaper is global

Status: **Accepted**  
Date: 2026-09-25  
Scope: Wallpaper / Performance  
Source: Owner decision

### Decision

Static wallpapers can differ per workspace.

Live wallpaper is global.

### Why

This allows meaningful workspace identity while controlling resource consumption for live rendering.

### Consequences

- Static wallpaper state must be workspace-aware.
- Live wallpaper must not require independent rendering per workspace.
- Palette extraction for live wallpaper should be bounded.

### Affected Documents

- MASTER.md
- DESIGN.md

---

## DEC-014 — Live wallpaper palette extraction is bounded and cached

Status: **Accepted**  
Date: 2026-09-25  
Scope: Theming / Performance  
Source: Owner decision

### Decision

For live wallpaper:

1. sample briefly;
2. sample multiple frames;
3. filter abnormal frames;
4. extract the palette;
5. run Matugen once;
6. cache the result.

### Why

Continuous palette extraction would waste resources and produce unstable visual state.

### Consequences

- Palette extraction is not a continuous background operation.
- Abnormal frames must not destabilize the theme.
- Cached results should be reused where appropriate.

### Affected Documents

- MASTER.md
- DESIGN.md

---

## DEC-015 — Dock is bottom-centered and edge-integrated

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design / UX  
Source: Owner decision

### Decision

The Dock is:

- bottom-centered;
- edge-integrated;
- hidden/recessed when idle;
- triggered by a bottom 1–2px cursor region;
- revealed from the cursor trigger;
- visually continuous with its surface.

The Dock does not contain search.

Pinned applications are global.

Active applications are workspace-specific.

### Why

The Dock should feel like part of the desktop rather than a permanent taskbar.

### Consequences

- No permanent taskbar-like presence.
- Dock reveal must be contextual.
- Application state must distinguish global pins from workspace activity.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-016 — Top Island is top-centered and contextual

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design / UX / Motion  
Source: Owner decision

### Decision

The Top Island is:

- top-centered;
- edge-integrated;
- clock-first while idle;
- expandable on hover;
- the origin for OSD transitions;
- integrated with media.

Fullscreen hides the shell except for a compact clock summon.

### Why

The shell should provide system context without permanently occupying a large top bar.

### Consequences

- OSD transitions originate from the Top Island.
- Media can integrate into the Top Island.
- Fullscreen behavior must preserve minimal shell access without restoring a traditional panel.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-017 — Command Center is the universal action/search surface

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Navigation  
Source: Owner decision

### Decision

The Command Center is the universal action/search interface.

It appears slightly above center.

Its composition is:

- search at the top;
- results below;
- dynamic height;
- capped maximum height;
- transient presentation;
- curtain-like top-to-bottom reveal.

### Why

Actions should have one strong universal entry point instead of being distributed across unrelated controls.

### Consequences

New universal actions should be evaluated for Command Center integration before creating another launcher-like surface.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-018 — App Drawer is fullscreen and search-first

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Navigation  
Source: Owner decision

### Decision

The App Drawer is:

- fullscreen;
- search-visible at all times;
- organized with a fixed A–Z–0–9–# fast navigation model;
- populated with recent/suggested applications;
- presented as a continuous grid;
- equipped with a fast scroller;
- global;
- monitor-triggered.

The running state is not represented as a persistent indicator in the drawer.

### Why

The App Drawer represents:

> "What can I open?"

It should not become another task manager.

### Consequences

- Search remains prominent.
- Application discovery is fast.
- Running state belongs elsewhere.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-019 — Headquarter is the configuration headquarters

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Settings  
Source: Owner decision

### Decision

Headquarter is the primary BASEUS configuration surface.

It is fullscreen and uses:

- a persistent right sidebar;
- edge-integrated composition;
- memorable greeting;
- contextual help to the right;
- progressive disclosure.

### Why

Configuration should have one coherent home rather than being scattered through independent settings popups.

### Consequences

New BASEUS settings should be evaluated for Headquarter placement.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-020 — Notifications are top-left transient surfaces

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Notifications  
Source: Owner decision

### Decision

Notifications appear top-left.

Their visual treatment includes:

- background application icon at approximately 70% transparency;
- text overlapping the icon region;
- solid surfaces;
- controlled silent animation.

### Why

Notifications should remain recognizable and contextual without becoming card-heavy dashboard elements.

### Consequences

Notification design must preserve source recognition while avoiding decorative notification stacks.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-021 — OSD originates from Top Island

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Motion  
Source: Owner decision

### Decision

System OSD events originate from the Top Island and use a bubble-drop / gooey transition into the expanded OSD state.

Repeated rapid events should morph/update one OSD rather than create competing OSD stacks.

### Why

System feedback should have one coherent spatial origin.

### Consequences

Volume, brightness, and similar system feedback should follow this pattern.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-022 — App Drawer uses a fixed A–Z–0–9–# fast-navigation model

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX  
Source: Owner decision

### Decision

The App Drawer uses a fixed alphabetical/numeric/symbol fast navigation structure:

`A–Z–0–9–#`

The fast scroller is:

- approximately 1px when idle;
- approximately 3px when active;
- accompanied by dimming during fast scrolling;
- focused on the selected letter.

### Why

The application drawer should remain fast to navigate even with many installed applications.

### Consequences

Application indexing must support the navigation model.

### Affected Documents

- DESIGN.md

---

## DEC-023 — Workspace/window experience is freeform with smart assistance

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Window Management  
Source: Owner decision

### Decision

New windows may open centered.

Windows may overlap.

Minimize is supported.

Restore is centered.

Maximize means literal full workspace/screen occupation.

Native fullscreen remains distinct.

Smart arrangement may make slight adjustments but must not force a tiling model.

There is no scratchpad concept.

Moving a window to another workspace uses a POP-style transition.

### Why

The desired mental model is a freeform desktop rather than a tiling manager.

### Consequences

Window management implementation must preserve floating behavior as the primary model.

### Affected Documents

- DESIGN.md
- ROADMAP.md

---

## DEC-024 — Android-like mental model for navigation

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Navigation  
Source: Owner decision

### Decision

Where useful, BASEUS may use the Android-like mental model of:

- Back;
- Home;
- Overview.

This is a mental model, not a requirement to visually clone Android.

### Why

The model provides an understandable navigation hierarchy for shell surfaces.

### Consequences

Navigation should remain predictable while retaining BASEUS's own visual identity.

### Affected Documents

- MASTER.md
- DESIGN.md

---

## DEC-025 — Overview uses a Helicopter View

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Window Management  
Source: Owner decision

### Decision

Overview provides a broad "Helicopter View" of the current desktop context.

### Why

Users need a way to understand:

> "Where am I and what's there?"

without turning Overview into a taskbar or application drawer.

### Consequences

Overview should emphasize spatial context and active desktop state.

### Affected Documents

- MASTER.md
- DESIGN.md

---

## DEC-026 — Media integrates with Top Island and a dedicated widget

Status: **Accepted**  
Date: 2026-09-25  
Scope: Media / Design  
Source: Owner decision

### Decision

Media is represented through:

- a compact fixed Top Island integration;
- a media widget;
- compact and expanded widget states;
- lyrics;
- Bongo Cat;
- conventional media controls;
- media switching.

Changing media does not produce a generic notification.

### Why

Media is contextual desktop state and should not create unnecessary notification noise.

### Consequences

Media state needs a coherent shared representation across the Top Island and widget.

### Affected Documents

- MASTER.md
- DESIGN.md

---

## DEC-027 — Power Menu is a fullscreen constellation

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Personality  
Source: Owner decision

### Decision

The Power Menu uses a fullscreen constellation composition with:

- quiet dark space;
- palette-derived visual treatment;
- pixel text;
- chibi personality;
- sparse composition.

It must not become a neon overload.

### Why

Power actions should feel distinct and memorable without becoming another dashboard.

### Consequences

Power Menu is a deliberate personality surface rather than a conventional menu list.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-028 — Gestures and shortcuts follow Discover → Customize → Execute

Status: **Accepted**  
Date: 2026-09-25  
Scope: UX / Accessibility / Interaction  
Source: Owner decision

### Decision

Gesture and shortcut interaction follows:

```text
Discover
→ Customize
→ Execute
```

Actions are primitives.

One action may have multiple triggers.

Conflict handling is required.

Memorization should not be mandatory for basic use.

### Why

Power-user input should remain discoverable and adaptable rather than requiring users to memorize a fixed secret vocabulary.

### Consequences

Shortcut and gesture architecture should separate action identity from trigger assignment.

### Affected Documents

- MASTER.md
- DESIGN.md
- ROADMAP.md

---

## DEC-029 — Idle desktop remains calm

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design / UX  
Source: Owner decision

### Decision

The idle desktop may show:

- wallpaper;
- widgets;
- clock.

It should not permanently show:

- taskbar;
- workspace numbers;
- notification clutter;
- permanent greeting;
- unnecessary empty-state messages.

### Why

Idle state is a visual rest state, not a monitoring dashboard.

### Consequences

Information should appear contextually rather than remaining permanently visible.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-030 — Event-driven and cached behavior is preferred

Status: **Accepted**  
Date: 2026-09-25  
Scope: Architecture / Performance  
Source: Owner decision

### Decision

BASEUS should prefer:

- event-driven updates;
- caching;
- bounded work;
- minimal background activity.

### Why

The shell should remain responsive and resource-conscious.

### Consequences

Continuous polling and repeated expensive computation require explicit justification.

### Affected Documents

- MASTER.md
- DESIGN.md
- ANTI-SLOP.md
- ROADMAP.md

---

## DEC-031 — Linux + Hyprland is the platform target; Arch and Nix are first-class

Status: **Accepted**  
Date: 2026-09-25  
Scope: Distribution  
Source: Owner decision

### Decision

BASEUS targets Linux + Hyprland.

Arch and Nix are first-class distribution targets.

The product principle is:

> **BASEUS requires Hyprland, not Arch.**

### Why

The shell should remain portable across Linux distributions while depending on the Hyprland environment.

### Consequences

- Installation must adapt to distribution differences.
- Dependency detection must not assume Arch.
- Nix requires first-class consideration rather than an afterthought.

### Affected Documents

- MASTER.md
- DESIGN.md
- ROADMAP.md

---

## DEC-032 — MIT license

Status: **Accepted**  
Date: 2026-09-25  
Scope: Governance / Legal  
Source: Owner decision

### Decision

BASEUS is released under the MIT License.

Copyright:

> Copyright (c) 2026 xoradesu

### Why

The project is open source while retaining a lightweight contribution model.

### Consequences

Repository licensing and public documentation must reflect this decision.

### Affected Documents

- MASTER.md
- README.md
- LICENSE
- CONTRIBUTING.md

---

## DEC-033 — Single maintainer / project owner

Status: **Accepted**  
Date: 2026-09-25  
Scope: Governance  
Source: Owner decision

### Decision

BASEUS has a single project owner/maintainer.

Contributors may participate through:

- issues;
- pull requests;
- design proposals;
- written GitHub communication.

Contribution does not automatically redefine project direction.

### Why

BASEUS has a deliberate product identity that requires centralized final direction.

### Consequences

- Owner approval is required for major identity changes.
- Contributors can improve implementation without automatically changing product philosophy.
- Governance remains lightweight.

### Affected Documents

- MASTER.md
- AGENTS.md
- CONTRIBUTING.md

---

## DEC-034 — Significant UI changes require a Design Proposal

Status: **Accepted**  
Date: 2026-09-25  
Scope: Governance / Design  
Source: Owner decision

### Decision

Significant UI changes require a Design Proposal before implementation.

Major identity changes require:

1. proposal;
2. impact analysis;
3. owner approval;
4. DECISIONS.md update;
5. migration plan where required.

### Why

Design identity is protected from accidental drift.

### Consequences

An implementation request alone is insufficient for major design changes.

### Affected Documents

- MASTER.md
- DESIGN.md
- AGENTS.md
- CONTRIBUTING.md

---

## DEC-035 — Agents cannot rewrite product truth to justify implementation

Status: **Accepted**  
Date: 2026-09-25  
Scope: Governance / Agent Behavior  
Source: Owner decision

### Decision

Agents may update execution/state documents, but may not modify:

- MASTER.md;
- locked DESIGN.md;
- accepted product decisions

simply to make an implementation fit.

If implementation conflicts with source of truth, the agent must stop the affected work and report the conflict.

### Why

Implementation convenience must not redefine the product.

### Consequences

Agents must escalate genuine source-of-truth conflicts rather than silently resolving them by changing the specification.

### Affected Documents

- MASTER.md
- AGENTS.md
- TASKS.md
- STATE.md

---

## DEC-036 — Anti-slop is an active quality gate

Status: **Accepted**  
Date: 2026-09-25  
Scope: Design / Quality  
Source: Owner decision

### Decision

ANTI-SLOP.md is an active review standard for UI/UX work.

It is not merely a list of prohibited aesthetics.

### Why

Generic interface patterns can enter incrementally even when each individual implementation seems acceptable.

### Consequences

UI work must be reviewed for:

- intentionality;
- hierarchy;
- unnecessary containers;
- decorative UI;
- animation misuse;
- complexity;
- identity;
- performance;
- accessibility.

### Affected Documents

- MASTER.md
- DESIGN.md
- ANTI-SLOP.md
- AGENTS.md

---

## DEC-037 — Theme switching changes visual state, not interaction semantics

Status: **Accepted**  
Date: 2026-09-25  
Scope: Theming / UX  
Source: Owner decision

### Decision

Switching a theme must not silently alter:

- gestures;
- shortcuts;
- window behavior;
- notification timeout;
- Dock trigger behavior.

### Why

Visual personalization and interaction configuration should remain separate mental models.

### Consequences

Theme transitions can be expressive without unexpectedly changing how the desktop operates.

### Affected Documents

- MASTER.md
- DESIGN.md

---

## DEC-038 — No scratchpad model

Status: **Accepted**  
Date: 2026-09-25  
Scope: Window Management  
Source: Owner decision

### Decision

BASEUS does not introduce a scratchpad window-management concept.

### Why

The product favors direct spatial desktop interaction and workspace context instead of adding another hidden window state.

### Consequences

Window organization should use the established workspace, minimize, restore, Overview, and freeform mechanisms.

### Affected Documents

- DESIGN.md

---

## DEC-039 — Media changes do not generate generic notifications

Status: **Accepted**  
Date: 2026-09-25  
Scope: Media / Notifications  
Source: Owner decision

### Decision

Changing media should update the dedicated media context rather than generating a normal notification.

### Why

Media changes are expected contextual state, not necessarily interruptive events.

### Consequences

The media surface must communicate relevant changes without adding notification noise.

### Affected Documents

- DESIGN.md
- ANTI-SLOP.md

---

## DEC-040 — Agent execution follows ORIENT → SOURCE OF TRUTH → STATE → PLAN → IMPLEMENT → VALIDATE

Status: **Accepted**  
Date: 2026-09-25  
Scope: Agent Governance  
Source: Owner decision

### Decision

BASEUS agent work follows:

```text
ORIENT
→ READ SOURCE OF TRUTH
→ CHECK CURRENT STATE
→ UNDERSTAND CURRENT PHASE
→ PLAN
→ IMPLEMENT
→ VALIDATE
→ UI/UX REVIEW
→ UPDATE STATE
→ CHECKPOINT
→ REPORT
→ STOP
```

### Why

Agents must understand product truth and current reality before changing implementation.

### Consequences

Agents should not begin implementation from an isolated task description when broader source-of-truth context is required.

### Affected Documents

- MASTER.md
- AGENTS.md
- TASKS.md
- STATE.md
- CHECKPOINT.md

---

## DEC-041 — Agent scope must remain within the current phase

Status: **Accepted**  
Date: 2026-09-25  
Scope: Agent Governance / Planning  
Source: Owner decision

### Decision

Agents must not expand task scope except when:

- a blocking dependency requires it;
- a critical bug requires it;
- the owner explicitly requests it.

### Why

Autonomous scope expansion causes hidden project drift.

### Consequences

Discovered unrelated improvements should be recorded for later rather than silently implemented.

### Affected Documents

- ROADMAP.md
- TASKS.md
- AGENTS.md

---

## DEC-042 — Agent stops after completing the requested scope

Status: **Accepted**  
Date: 2026-09-25  
Scope: Agent Governance  
Source: Owner decision

### Decision

After completing and validating the current task/phase scope, the agent stops rather than automatically continuing into future work.

### Why

The owner controls progression between phases and milestones.

### Consequences

Completion should produce:

- validation;
- state update;
- checkpoint when appropriate;
- concise report;
- stop.

### Affected Documents

- AGENTS.md
- TASKS.md
- STATE.md
- CHECKPOINT.md

---

## DEC-043 — Foundation Freeze protects fundamental architecture

Status: **Accepted**  
Date: 2026-09-25  
Scope: Governance / Architecture  
Source: Owner decision

### Decision

After the foundation phase passes its gate, fundamental changes require:

1. proposal;
2. impact analysis;
3. owner approval;
4. decision update;
5. migration plan where required.

### Why

Late foundational changes have disproportionate cost and can destabilize the entire project.

### Consequences

Foundation is intentionally flexible before the freeze and protected afterward.

### Affected Documents

- MASTER.md
- ROADMAP.md
- AGENTS.md
- DECISIONS.md

---

## DEC-044 — Three project quality gates

Status: **Accepted**  
Date: 2026-09-25  
Scope: Quality / Governance  
Source: Owner decision

### Decision

BASEUS uses three broad quality gates:

1. **Design Gate**
2. **Technical Gate**
3. **Release Gate**

### Why

A feature can be technically functional while still being visually wrong, and visually correct while technically unstable.

### Consequences

Completion requires more than code execution.

### Affected Documents

- MASTER.md
- ROADMAP.md
- AGENTS.md

---

## DEC-045 — Product roadmap uses Foundation → Capability → Surface

Status: **Accepted**  
Date: 2026-09-25  
Scope: Planning  
Source: Owner decision

### Decision

The roadmap uses a hybrid structure:

```text
Milestone
→ Phase
→ Task
```

with broad development direction:

```text
Foundation
→ Capability
→ Surface
```

### Why

Building isolated surfaces before the underlying capabilities creates fragile implementation.

### Consequences

Roadmap sequencing should establish foundations before dependent shell surfaces.

### Affected Documents

- MASTER.md
- ROADMAP.md
- TASKS.md

---

## DEC-046 — Tasks use explicit scope boundaries

Status: **Accepted**  
Date: 2026-09-25  
Scope: Planning / Agent Governance  
Source: Owner decision

### Decision

Each implementation phase/task should define:

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

### Why

Explicit boundaries prevent accidental scope expansion and make agent execution auditable.

### Consequences

TASKS.md should remain phase-focused rather than becoming a permanent giant backlog.

### Affected Documents

- ROADMAP.md
- TASKS.md
- AGENTS.md

---

## DEC-047 — MASTER-PROMPT is a launcher, not product truth

Status: **Accepted**  
Date: 2026-09-25  
Scope: Agent Governance / Documentation  
Source: Owner decision

### Decision

`MASTER-PROMPT.md` is a thin agent launcher/boot prompt.

It must not become a second source of truth.

### Why

Duplicated specifications drift.

### Consequences

Agents should load authoritative documents rather than relying on a giant copied prompt.

### Affected Documents

- MASTER.md
- AGENTS.md
- MASTER-PROMPT.md

---

## DEC-048 — One source of truth per responsibility

Status: **Accepted**  
Date: 2026-09-25  
Scope: Governance / Documentation  
Source: Owner decision

### Decision

Each project document has a defined responsibility.

The planned source-of-truth architecture is:

```text
MASTER.md
DESIGN.md
ANTI-SLOP.md
DECISIONS.md
ROADMAP.md
TASKS.md
STATE.md
CHECKPOINT.md
AGENTS.md
MASTER-PROMPT.md
```

Public documentation and repository metadata serve users and contributors without replacing the internal product sources of truth.

### Why

Ambiguous ownership between documents creates contradictions.

### Consequences

New information should be placed in the document responsible for that information rather than duplicated everywhere.

### Affected Documents

- MASTER.md
- AGENTS.md

---

## DEC-049 — Implementation records reality; it does not define product intent

Status: **Accepted**  
Date: 2026-09-25  
Scope: Governance  
Source: Owner decision

### Decision

Implementation may reveal technical constraints and actual behavior.

It does not automatically become product truth.

The hierarchy is:

```text
MASTER
 /   \
DESIGN  DECISIONS
 \     /
  ROADMAP
    ↓
  TASKS
    ↓
IMPLEMENTATION
```

### Why

A workaround discovered during implementation should not silently become a product decision.

### Consequences

Implementation discoveries should be recorded in the appropriate state/decision process.

### Affected Documents

- MASTER.md
- AGENTS.md
- STATE.md
- DECISIONS.md

---

## DEC-050 — BASEUS should never make the user fight the interface

Status: **Accepted**  
Date: 2026-09-25  
Scope: Product / UX  
Source: Owner decision

### Decision

The product-level UX principle is:

> **BASEUS should never make the user fight the interface.**

### Why

All visual personality, automation, customization, and power must remain subordinate to usability and user agency.

### Consequences

When a design conflict exists between decorative cleverness and clear user control, the interface should preserve user control.

### Affected Documents

- MASTER.md
- DESIGN.md
- ANTI-SLOP.md

---

# 7. Open Decisions

This section is intentionally reserved for matters that have not been explicitly decided.

An open issue must not be silently converted into an accepted decision by implementation.

When a future issue becomes important enough to require a durable decision, create a new `DEC-XXX` entry.

Examples of potentially future decisions include:

- detailed internal architecture choices not yet explicitly locked;
- exact implementation libraries where alternatives remain open;
- detailed installer UX;
- packaging specifics;
- exact accessibility controls;
- future feature behavior not yet established.

The absence of a decision means the matter remains open.

It does not mean "the agent may choose permanently."

---

# 8. Superseding a Decision

When an accepted decision needs to change:

1. Create a new decision ID.
2. Explain the new decision.
3. Explain why the previous decision no longer applies.
4. Link the previous decision under `Supersedes`.
5. Mark the previous decision `Superseded`.
6. Update affected source-of-truth documents where necessary.
7. Update implementation/state documentation if behavior changes.

Never silently rewrite a historical accepted decision.

---

# 9. Decision Quality Standard

A strong decision record should make it possible for someone who was not present during the original discussion to understand:

- what was decided;
- why it was decided;
- what was not chosen;
- what consequences were accepted;
- where the decision applies;
- whether it is still active.

A decision should reduce ambiguity, not create more prose for its own sake.

---

# 10. Agent Rules for DECISIONS.md

Agents may:

- read decisions;
- reference decisions;
- propose decisions;
- record explicitly approved decisions;
- mark decisions superseded when a newer accepted decision explicitly replaces them;
- use decisions to resolve implementation ambiguity.

Agents may not:

- invent owner approval;
- convert a technical workaround into product policy;
- silently supersede an accepted decision;
- rewrite history to make implementation appear compliant;
- use a proposed/rejected decision as if it were accepted;
- modify locked product truth simply to avoid escalation.

When uncertain:

> **Do not guess a permanent product decision.**

Use the established governance path.

---

# 11. Relationship to Locked Documents

At the time this file is created:

- `MASTER.md` is locked.
- `DESIGN.md` is locked.
- `ANTI-SLOP.md` is locked.

Those documents establish the baseline from which this decision ledger is derived.

If a contradiction is discovered:

1. identify the exact contradiction;
2. do not silently choose one;
3. determine whether an existing decision resolves it;
4. if not, escalate through the governance process.

---

# 12. Closing Principle

`DECISIONS.md` exists to preserve intent.

The goal is not to document every thought.

The goal is to ensure that important choices become durable enough that:

- the owner does not have to repeat them;
- agents do not have to infer them;
- contributors do not accidentally redefine them;
- implementation does not erase them;
- future BASEUS work can remain coherent.

A decision is valuable when it makes the next correct action easier to identify.
