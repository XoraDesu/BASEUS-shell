# BASEUS — MASTER

**Status:** LOCKED  
**Product:** BASEUS  
**Owner / Public Identity:** xoradesu  
**Copyright:** Copyright (c) 2026 xoradesu  
**License:** MIT

---

## 1. Product Definition

BASEUS is a personalized Linux desktop shell built with **Quickshell**, targeting **Linux + Hyprland**.

BASEUS is intended to be:

- simple for the user,
- powerful underneath,
- highly intentional visually,
- responsive,
- personal,
- system-friendly,
- and unmistakably its own product.

BASEUS is not merely a collection of widgets or a skin placed on top of a desktop environment.

> **BASEUS's design language is not a skin. It is the identity and soul of the project.**

---

# 2. Core Philosophy

BASEUS follows these foundational principles:

### Simple for the user. Powerful underneath.

The internal system may be sophisticated.

The user experience should not require understanding that complexity.

### User mental model over developer architecture.

Users should interact with concepts they understand:

- applications,
- workspaces,
- actions,
- settings,
- media,
- notifications,
- windows,
- desktop.

Internal implementation structure must not leak unnecessarily into the UX.

### Progressive disclosure.

The system should show what is useful now and reveal complexity when it becomes relevant.

### Focus grows. Context recedes.

When something becomes important:

- it may grow,
- move into focus,
- become more prominent,
- while secondary context becomes quieter.

This principle applies to both static hierarchy and motion.

### Beautiful by design, efficient by default.

Performance is part of product identity.

BASEUS should feel alive without continuously consuming resources to prove that it is alive.

---

# 3. Design Identity

## Wabi-sabi

Wabi-sabi is the core static aesthetic.

BASEUS values:

- restraint,
- whitespace,
- intentional emptiness,
- asymmetry when meaningful,
- contextual visibility,
- and visual elements that do not need to occupy every available pixel.

Empty space is not a failure state.

The desktop does not need to be filled with dashboards, cards, metrics, greetings, or decorative information.

## Cyberpunk

Cyberpunk is primarily a **motion/effects language**, not the permanent static appearance of the desktop.

BASEUS should therefore not default to:

- neon,
- RGB,
- scanlines,
- glowing borders,
- excessive HUD elements,
- or cyberpunk decoration everywhere.

A BASEUS screenshot may look restrained while the interface still feels cyberpunk when it moves.

---

# 4. Product Personality

BASEUS should feel:

- calm when idle,
- clear when needed,
- expressive when interacted with,
- personal when customized,
- playful when appropriate,
- technically alive,
- and restrained when nothing needs to happen.

BASEUS should never feel like it is constantly asking for attention.

> **The desktop is a place, not a dashboard.**

---

# 5. Desktop Mental Models

BASEUS organizes the desktop around user-facing concepts.

### Dock

> **What am I using?**

The Dock exposes:

- current context,
- pinned applications,
- active applications,
- workspace context.

### App Drawer

> **What can I open?**

The App Drawer is the application browsing and launching space.

### Command Center

> **What do I want to do?**

The Command Center is a universal action/search gateway.

### Headquarter

> **Where do I configure BASEUS?**

Headquarter is the central settings application.

### Overview

> **Where am I and what's there?**

Overview represents the current desktop/workspace context.

These mental models are more important than internal component architecture.

---

# 6. Window Philosophy

BASEUS is **freeform first**.

Windows are:

- floating by default,
- centered when newly created,
- allowed to overlap,
- movable,
- resizable,
- minimizable,
- maximizable,
- and capable of native fullscreen.

Tiling is not the default window philosophy.

> **Freeform by default. Smart when necessary. Never fight the user.**

Smart assistance may:

- prevent literal stacking,
- slightly shift windows,
- offer snapping/grid assistance,
- help arrangement.

It should not take control away from the user.

---

# 7. Workspace Model

BASEUS uses exactly **10 workspaces**.

Users can edit workspace:

- tag,
- name/label.

They cannot change the number of workspaces.

Workspace state is per-monitor.

Navigation defaults:

- 4-finger swipe left/right,
- `Super+1` through `Super+0`.

Workspace transitions represent a context change.

Applications are not physically animated across the screen as though the desktop were moving them.

---

# 8. Navigation Model

BASEUS follows an Android-inspired conceptual model without becoming an Android clone.

The three primary navigation concepts are:

- **Back** — previous context,
- **Home** — desktop,
- **Overview** — Helicopter View.

Navigation should appear when called.

It should not permanently occupy the desktop.

---

# 9. Idle State

At idle, BASEUS should be quiet.

Expected persistent elements may include:

- wallpaper,
- selected widgets,
- Top Island clock,
- subtle live wallpaper activity.

The desktop should not permanently show:

- taskbars,
- workspace numbers,
- notification clutter,
- greeting text,
- productivity dashboards,
- or empty-state messages.

Interaction causes UI to appear.

When the interaction is finished, contextual UI should disappear again.

> **BASEUS does not judge the desktop and does not fill it simply because space exists.**

---

# 10. Dock

The Dock is separate from the Top Island.

It is:

- bottom-center,
- integrated with the bottom edge,
- not floating,
- compact,
- and hidden/recessed by default.

The bottom-edge trigger is approximately 1–2 px.

The reveal begins from the cursor's first trigger point.

The reveal uses a pixel/game-like curtain-style motion.

Possible composition:

- optional BASEUS launcher/logo,
- workspace indicator,
- pinned applications,
- active applications for the current workspace.

Pinned applications are global.

Active applications are workspace-specific.

The Dock has no search.

The Dock is a continuous surface, not a collection of individual cards.

A launcher/logo should only remain if it has a functional purpose such as opening the App Drawer.

---

# 11. Workspace Indicator

Workspace indicators appear contextually during workspace switching.

They should not permanently display workspace numbers.

The transition uses hierarchical scaling.

Example:

`1 → 2`

- `1` shifts/shrinks,
- `2` shifts/grows,
- `2` becomes primary,
- the composition settles.

The current workspace indicator may use a palette-derived background.

After approximately 2 seconds, secondary contextual information disappears.

A contextual label may morph the indicator into a compact pill:

`2 — WEB`

Workspace labels remain optional and user-defined.

---

# 12. Top Island

The Top Island is separate from the Dock.

It is:

- top-center,
- edge-integrated,
- compact,
- contextual,
- palette-aware.

At idle, it normally shows only the clock.

In a normal desktop state, hovering the Top Island can expand it into its controls/menu.

In fullscreen applications:

- shell UI collapses,
- the fullscreen application receives visual priority,
- hovering the top/notch area can summon the compact clock,
- clicking can request further interaction.

All OSDs originate from the Top Island.

The media player also integrates with the Top Island.

---

# 13. Command Center

Command Center is a universal shortcut/action launcher, not merely a search box.

Default prefix behavior:

- no prefix → app search,
- `>` → action/shortcut,
- `@web:` → web,
- `@settings:` → settings,
- `@file:` → file,
- `@folder:` → folder,
- `?help` → help.

Actions can be parameterized.

Examples include:

- mute microphone,
- next workspace,
- screenshot,
- brightness 70,
- workspace 3,
- wallpaper next,
- theme cyberpunk.

Users can create/configure shortcuts.

Shortcut discovery can show key combinations.

Settings results show:

- title,
- exact category/path.

File results show:

- filename,
- path.

Folder results use the same concept.

Results can be grouped:

- APPS,
- SETTINGS,
- ACTIONS.

`@web:` acts as a gateway to web results rather than a browser clone.

`?help` provides a compact inline reference.

The first-launch tutorial should be short, integrated, and revisitable.

Command Center is transient, slightly above vertical center.

The search area is at the top and results are below it.

Height is dynamic/fit-content up to a maximum, with internal scrolling when necessary.

---

# 14. App Drawer

The App Drawer is inspired by stock Android tablet / Pixel-like application browsing.

It is literally fullscreen.

Geometry:

- top corners rounded,
- bottom corners integrated with the screen edge rather than rounded.

Search is always visible.

Default search position is top; bottom placement may be configurable.

Application ordering is fixed:

`A–Z–0–9–#`

Users do not change the sort algorithm.

Fast alphabet scrolling is supported.

Recent applications form a separate hierarchy.

Frequently used applications are not a separate permanent section; they contribute to recent/suggestion ranking.

Recent content should be visually distinct and can use a darker tonal surface.

Recent is the initial landing layer.

Recent defaults to a maximum of 3 columns, with configurability possible later.

Application names are important and icons should not become disproportionately large.

The main browse state is:

- search,
- recent/suggested,
- continuous alphabetical application grid.

There are no separate A/B/C/etc. sections.

The application collection remains one continuous dynamic grid.

---

# 15. App Drawer Search Behavior

When searching:

1. Recent/Suggested content smoothly collapses upward.
2. Search results become primary.
3. Search result hierarchy becomes dominant.

Clearing search reverses the transition.

The change should feel like one layer moving away rather than switching between unrelated screens.

---

# 16. App Drawer Fast Scroller

The right-side fast scroller is:

### Idle

- approximately 1 px wide,
- palette-colored,
- subtle,
- around 1 px from the screen edge,
- no permanent letter.

### Active

- approximately 3 px wide,
- letters appear to the left,
- dragging jumps alphabetically.

During active fast scrolling:

- the overall interface dims slightly,
- selected letter becomes large/high contrast,
- secondary letters shrink/dim,
- matching applications become high contrast.

Example:

`A → B`

`A` shrinks/dims.

`B` grows/highlights.

Normal scrolling remains normal scrolling.

---

# 17. App Context Menu

Right-clicking an application may expose:

- App Info,
- Run as Administrator,
- Open Folder Location,
- Pin to Dock/Taskbar,
- Uninstall.

There is no drag-to-Dock requirement.

The App Drawer is global across workspaces and appears on the monitor where it was triggered.

It can be triggered by:

- keyboard shortcut,
- 3-finger swipe up,
- future configurable triggers.

---

# 18. Headquarter

Headquarter is the main BASEUS settings application.

It follows a one-way setting principle:

> **If something is configurable, it belongs in Headquarter.**

The right sidebar is always visible.

It cannot collapse into icon-only mode.

The sidebar uses edge-integrated geometry and ICR on its relevant right corners.

Headquarter's information architecture follows the user's mental model, not internal implementation structure.

---

# 19. Headquarter Home

The Home page can contain a memorable greeting and a light overview of the desktop/theme.

It may use:

- editorial typography,
- archival-inspired composition,
- subtle numbering,
- asymmetry,
- carefully controlled visual personality.

It must not become a statistics dashboard or card-heavy cockpit.

---

# 20. Settings Search

Headquarter settings search behaves like Command Center `@settings:`.

Results should show:

- setting title,
- location/path/category/subcategory.

Duplicates should expose their context/path.

Selecting a result opens the exact setting location.

---

# 21. Contextual Help

Contextual help follows progressive disclosure.

Descriptions are hidden by default.

A `?` icon provides access.

Behavior:

- hover → preview,
- click → pin/open,
- bubble appears to the right of the setting,
- main layout does not shift,
- not modal,
- explains “what does this do?” in user language,
- disappears when context changes.

---

# 22. Headquarter Principles

Headquarter follows:

- progressive disclosure,
- one setting → one obvious effect,
- live preview,
- live apply,
- sensible defaults,
- user-facing terminology,
- minimal confirmation dialogs,
- easy reset,
- searchability,
- advanced does not mean complicated.

---

# 23. Theme System

A Theme is a **visual state**, not a behavior profile.

A Theme can store:

- wallpaper,
- four main colors,
- palette extraction characteristic,
- widget arrangement,
- widget appearance,
- Home visual layout,
- Dock visual configuration,
- Top Island visual configuration,
- notification visual configuration,
- app icon/theme appearance,
- other visual elements.

A Theme does not store:

- gestures,
- shortcuts,
- window behavior,
- notification timeout,
- Dock trigger behavior,
- general interaction behavior.

One Theme applies the complete visual state.

There is no modular theme-mixing system.

There is no separate Theme Editor.

---

# 24. Theme Saving

Users can manually save the current visual state as a Theme.

Theme preview uses an automatic screenshot rather than a live interactive simulation.

Duplicate themes may exist as a convenience.

Theme inheritance is not required.

Manual saved themes are permanent.

Changing wallpaper does not automatically save a Theme.

Headquarter can directly change visual state.

Theme priority remains dynamic: where a Theme is relevant, its stored visual state wins.

---

# 25. Theme Transitions

Theme switching uses live visual transitions.

Possible transition types:

- random,
- saved preference,
- bubble/ripple,
- glitch,
- wavy wipe,
- circle wipe.

Duration/options may be configurable.

A circle wipe is a transition mask/boundary.

It must not scale the entire UI as though the whole interface were being zoomed.

Transitions may be playful or cinematic while remaining coherent.

---

# 26. Daily Theme Snapshot

The Theme hierarchy includes the concept of one daily auto-saved snapshot at the top, representing the current/latest daily visual state.

It should maintain a unique palette related to the current Theme.

Exact mechanics remain an implementation detail unless explicitly decided later.

---

# 27. Wallpaper

Static wallpaper is per-workspace.

Live wallpaper is global across the desktop.

Wallpaper positioning is user-controlled with sensible defaults.

On multi-monitor systems, the default can span across monitor geometry while adapting to the arrangement.

Wallpaper transitions can participate in Theme transitions.

The wallpaper picker is a transient/floating surface.

It may be triggered from:

- shortcut,
- Command Center,
- Headquarter,
- other appropriate entry points.

The picker supports:

- library,
- recent,
- favorites,
- preview.

There is no slideshow/random wallpaper system.

---

# 28. Live Wallpaper Palette Extraction

Live wallpaper should not continuously redefine the UI palette.

Palette extraction is sampled:

1. briefly,
2. across multiple frames where useful,
3. with abnormal frames filtered,
4. Matugen run once,
5. palette cached.

The resulting palette remains stable until another deliberate visual state update.

This prevents constant UI color churn and unnecessary resource use.

---

# 29. Dynamic Widgets

Widgets use a grid as a snapping aid.

Placement itself remains freeform.

Widget size is modular and freely adjustable within minimum/maximum bounds.

There is one global widget system/state rather than independent per-workspace widget states.

Empty space is intentional.

Widgets should not automatically pack the desktop to eliminate every gap.

During Theme transitions:

- remaining widgets rearrange/run into new positions,
- disappearing widgets may shake,
- glitch,
- POP,
- then disappear.

---

# 30. Notifications

Notifications appear floating in the top-left.

They use:

- left → right reveal,
- large background app icon,
- approximately 70% transparency on that icon,
- overlapping notification text,
- prominent title,
- smaller message,
- solid surface.

Interaction:

- click → launch,
- double-click → dismiss,
- middle-click → configure per-app notification settings,
- hold ~2 seconds → snooze or silence all notifications,
- hover → reveal remaining message and pause timeout.

Hover pauses the timeout for all pending notifications.

Default timeout is approximately 3 seconds.

Timeout is configurable in Headquarter.

Supported notification archetypes include:

- general,
- messaging,
- actionable,
- OTP.

OTP can expose a copy-code action.

Messaging may support:

- mark read,
- quick reply,
- launch floating app.

---

# 31. Media

Media exists as both:

- a widget,
- and a Top Island component.

Top Island media has a fixed compact layout.

It should not resize unpredictably according to content.

Widget states:

- idle → compact,
- playing → expanded,
- expanded → lyrics area may appear.

Controls include:

- play/pause,
- previous/next,
- seek,
- volume,
- player interaction.

Multiple media sessions can expose a media switcher.

Media state does not produce media-change notifications.

Media changes belong to the media player.

Bongo Cat provides personality.

---

# 32. Power Menu

Power Menu is fullscreen.

Actions:

- Lock,
- Sleep,
- Logout,
- Restart,
- Shutdown.

Visual language:

- stellar/constellation composition,
- quiet dark space,
- palette-derived stars,
- sparse layout,
- subtle movement.

Typography/pixel-style text is preferred where it communicates the action more effectively than icons.

The constellation itself can form the menu structure.

Focused items brighten/scale.

Secondary items recede.

A sleeping chibi can float around the scene with subtle bobbing and `zzz`.

Avoid:

- giant planets,
- excessive particles,
- giant HUD elements,
- neon sci-fi overload.

The Power Menu should feel like:

> **A quiet place between states.**

---

# 33. OSD

All OSDs originate from the Top Island.

The transition uses a gooey “bubble drop” concept:

1. small bubble drops,
2. stretches,
3. expands into the OSD,
4. communicates feedback,
5. collapses,
6. merges back into the Top Island.

The gooey behavior belongs primarily to the transition boundary.

The expanded OSD itself is solid and clean.

Rapid repeated events should morph/update one OSD instead of spawning many.

OSD is temporary system feedback, not notification infrastructure.

Typography may communicate state directly.

Example:

`VOLUME`

`72%`

---

# 34. Gesture and Shortcut Philosophy

BASEUS follows:

> **Discover → Customize → Execute**

An action should be the conceptual primitive.

Bindings are ways of triggering actions.

One action may have multiple triggers.

Command Center can expose shortcut information.

Headquarter contains Shortcuts & Gestures categories such as:

- Workspace,
- Surfaces,
- System,
- Windows.

Conflicts should be explained.

Possible conflict handling:

- Replace,
- Cancel,
- choose another binding.

Gesture conflicts should receive clear warnings.

Users should not be required to memorize everything.

Command Center and `?help` provide discoverability.

---

# 35. Window Movement Between Workspaces

Moving a window to another workspace uses a subtle spatial transition.

Conceptually:

1. window scales/squeezes slightly,
2. micro movement occurs,
3. window POPs/disappears from the old workspace,
4. inverse POP occurs in the new workspace,
5. window settles.

The animation communicates context movement without pretending the application physically travels across the monitor.

---

# 36. Minimize and Restore

New windows open centered.

Windows are floating by default.

Minimizing removes them from active desktop context.

Restoring a minimized window should return it to a centered/centered-context position rather than producing an awkward random placement.

Maximize means literal workspace/fullscreen-area occupation.

Native application fullscreen remains distinct.

---

# 37. Smart Arrangement

BASEUS may provide smart arrangement and snapping.

Smart arrangement should primarily prevent literal stacking and improve discoverability.

It should not:

- tile everything automatically,
- constantly rearrange the user's layout,
- override deliberate placement,
- or become a hidden tiling manager.

The user's freeform placement remains authoritative.

---

# 38. No Scratchpad Requirement

BASEUS does not require a dedicated scratchpad mental model.

Transient applications should instead use:

- floating behavior,
- Command Center,
- normal window management,
- contextual surfaces,
- or other explicit interaction patterns.

---

# 39. Multi-monitor Philosophy

BASEUS supports multiple monitors.

Workspace state is per-monitor.

Surfaces should appear on the monitor where interaction occurs where appropriate.

The shell should adapt to:

- different monitor geometries,
- spanning wallpaper,
- different resolutions,
- different scale factors,
- and changing monitor configurations.

The design must not assume one fixed monitor.

---

# 40. Distribution

BASEUS targets:

- Linux,
- Hyprland.

BASEUS is not Arch-only.

Arch and Nix are intended to be first-class/native targets.

> **BASEUS requires Hyprland, not Arch.**

The installer should:

- detect system,
- detect Hyprland,
- detect dependencies,
- detect package manager,
- install/configure dependencies,
- validate environment,
- deploy BASEUS.

The installer should adapt where possible when a dependency is unavailable rather than unnecessarily rejecting an otherwise compatible distribution.

---

# 41. System Optimization

BASEUS should be event-driven and cached wherever possible.

Principles:

- idle UI should be genuinely idle/recessed,
- animations only run when necessary,
- live wallpaper sampling only occurs when necessary,
- widgets are event-driven,
- media is event-driven,
- notifications are event-driven,
- palettes are cached,
- themes are state-based,
- background services remain minimal,
- Quickshell components should only remain active when needed.

Performance is a product feature.

---

# 42. Accessibility

Accessibility should not be treated as a final cosmetic layer.

Visual hierarchy must remain understandable without relying only on:

- color,
- animation,
- glow,
- or tiny visual differences.

Important states should have redundant communication through:

- typography,
- shape,
- position,
- tonal contrast,
- labels,
- or interaction feedback.

Reduced-motion considerations should be respected where technically supported.

---

# 43. Icon Language

BASEUS icons are semantic rather than decorative.

Icons should be:

- simple,
- geometric,
- consistent,
- palette-aware,
- informative,
- and state-aware.

Avoid:

- gradient icons,
- glossy 3D icons,
- random neon icons,
- decorative icon overload,
- generic ugly AI/Linux iconography.

Typography is preferred when typography communicates the concept more clearly.

Icons are especially useful for:

- state,
- familiar system concepts,
- compact controls.

Shapes are useful for:

- interaction,
- state,
- hierarchy.

Color alone should not be the only status indicator.

---

# 44. BASEUS Icon Language

The icon language follows:

1. Semantic meaning over decoration.
2. Palette awareness.
3. Simple/geometric construction.
4. Consistent visual weight.
5. No gradient/gloss/3D/neon as default.
6. State communicated through shape/fill/typography/tonal contrast.
7. Typography used for identity/action/navigation where sufficient.
8. Icons used for state and familiar concepts.

---

# 45. Visual Inspiration Boundaries

BASEUS can take inspiration from:

### Google Pixel / Android / Material You

Useful inspiration:

- hierarchy,
- dynamic color,
- app drawer behavior,
- contextual interaction,
- system-wide visual coherence.

BASEUS is not a direct clone.

### Ryuko / editorial / archival references

Useful inspiration:

- typography,
- numbering,
- dividers,
- asymmetry,
- composition.

BASEUS should not become:

- statue-heavy,
- classical,
- brutalist for its own sake,
- or overloaded with editorial decoration.

---

# 46. Anti-generic UI Rules

BASEUS should actively avoid:

- excessive rounded cards,
- card-inside-card composition,
- gradients as default,
- glassmorphism as default,
- excessive shadows,
- glow-heavy focus,
- neon/RGB styling,
- scanline decoration,
- over-animation,
- mechanically uniform spacing,
- decorative filler,
- random metrics,
- fake system data,
- giant dashboard layouts,
- unnecessary badges,
- emoji as a substitute for proper iconography,
- excessive microinteraction,
- and screenshot-first design.

The purpose of these rules is not generic minimalism.

The purpose is **intentionality**.

A detailed anti-slop system belongs in `ANTI-SLOP.md`.

---

# 47. Interaction and Visual State

BASEUS distinguishes:

- idle,
- focused,
- contextual,
- active,
- transient,
- fullscreen,
- and transitioning states.

The same component should not look equally prominent in every state.

Idle state should generally be the quietest.

Interaction can temporarily increase:

- scale,
- contrast,
- surface size,
- motion,
- or information density.

When the interaction ends, the component should return to its appropriate contextual state.

---

# 48. Desktop as a Place

BASEUS does not assume that every desktop needs:

- widgets,
- productivity metrics,
- system monitors,
- quotes,
- greetings,
- task lists,
- weather,
- clocks everywhere,
- or permanent controls.

The desktop may simply contain:

- wallpaper,
- windows,
- selected widgets,
- and quiet shell presence.

This is intentional.

---

# 49. Governance and Identity

BASEUS is open source.

Open source means people can participate.

It does not mean BASEUS must lose its identity.

The project has a single owner/project direction.

Contributors may:

- report issues,
- submit pull requests,
- propose changes,
- participate in written GitHub discussion.

Contribution does not automatically redefine product direction.

The established design language is protected as product identity.

Significant UI changes require a Design Proposal before implementation.

Major identity changes require:

1. proposal,
2. impact discussion,
3. owner approval,
4. `DECISIONS.md` update.

The agent must not alter locked product truth merely to make an implementation convenient.

---

# 50. Agent Boundaries

The implementation agent may:

- implement accepted decisions,
- update progress,
- update `TASKS.md`,
- update `STATE.md`,
- create checkpoints after validation,
- fix implementation bugs,
- improve internal architecture without changing product intent.

The agent may not:

- redefine BASEUS identity,
- silently change locked design,
- modify `MASTER.md` to justify an implementation,
- modify accepted decisions to avoid a conflict,
- expand phase scope without justification/approval.

If implementation conflicts with source of truth:

1. stop the affected work,
2. report the conflict,
3. explain the implementation impact,
4. propose a resolution,
5. wait for owner direction.

---

# 51. Quality Gates

BASEUS uses three broad quality gates.

## Design Gate

Checks:

- visual identity,
- hierarchy,
- whitespace,
- motion,
- interaction language,
- anti-slop compliance,
- accessibility,
- consistency with `MASTER.md` and `DESIGN.md`.

## Technical Gate

Checks:

- functionality,
- architecture,
- performance,
- resource usage,
- event-driven behavior,
- multi-monitor behavior,
- failure handling,
- installation/runtime correctness.

## Release Gate

Checks:

- complete intended scope,
- regressions,
- documentation,
- clean installation,
- UX review,
- visual review,
- performance,
- accessibility,
- anti-slop review.

---

# 52. Source-of-Truth Hierarchy

The project uses the following hierarchy:

1. `MASTER.md`
2. `DESIGN.md` / `DECISIONS.md`
3. `ROADMAP.md`
4. `TASKS.md`
5. implementation

Supporting documents:

- `ANTI-SLOP.md` applies across design work.
- `AGENTS.md` applies to agent behavior.
- `MASTER-PROMPT.md` launches/boots agent context but is not itself product truth.
- `STATE.md` records current reality.
- `CHECKPOINT.md` records known-good save points.

The agent must never treat implementation convenience as higher authority than product truth.

---

# 53. Roadmap Direction

The roadmap uses:

> **Foundation → Capability → Surface**

with:

> **Milestone → Phase → Task**

The intended broad sequence is:

### M0 — Foundation

- repository/governance,
- Quickshell runtime,
- core state/event architecture.

### M1 — Desktop Foundation

- workspace/window capability,
- navigation/context,
- core desktop surfaces.

### M2 — Interaction

- Dock,
- Top Island,
- Command Center,
- App Drawer.

### M3 — System Feedback

- notifications,
- OSD,
- media,
- status,
- transient interaction.

### M4 — Personalization

- wallpaper,
- Matugen,
- Theme,
- palette,
- widgets,
- Headquarter.

### M5 — Desktop Experience

- window chrome,
- smart arrangement,
- snap,
- Alt+Tab,
- Overview,
- multi-monitor.

### M6 — Personality

- Bongo Cat,
- Power Menu constellation,
- chibi,
- special transitions,
- choreography,
- editorial details.

### M7 — Distribution

- installer,
- updater,
- uninstaller,
- doctor/recovery,
- distro detection,
- dependencies,
- Hyprland,
- multi-distro support,
- packaging,
- documentation.

### M8 — Hardening

- performance,
- startup,
- memory,
- animation,
- failure recovery,
- accessibility,
- multi-monitor,
- regression,
- clean install.

### M9 — Release Readiness

- feature freeze,
- UX review,
- anti-slop review,
- performance review,
- documentation,
- release.

A Foundation Freeze occurs after the foundation phase passes its gate.

After Foundation Freeze, fundamental changes require:

- proposal,
- impact analysis,
- owner approval,
- decision update,
- migration plan where needed.

---

# 54. Phase Discipline

Each phase should define:

- Goal,
- Scope,
- Non-goals,
- Dependencies,
- Tasks,
- Acceptance Criteria,
- Validation,
- Exit Criteria,
- IN SCOPE,
- OUT OF SCOPE.

The agent should not expand scope except for:

- blocking dependencies,
- critical bugs,
- explicit owner requests.

The roadmap is not a giant task list.

`TASKS.md` contains the actionable work for the current phase.

---

# 55. Agent Lifecycle

The intended agent lifecycle is:

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

Before work:

- read `MASTER.md`,
- read `AGENTS.md`,
- read `TASKS.md`,
- read `STATE.md`.

For UI work also read:

- `DESIGN.md`,
- `ANTI-SLOP.md`.

For architecture work also read:

- `DECISIONS.md`,
- relevant architecture documentation.

---

# 56. Change Discipline

Every meaningful implementation change should be understandable through:

- what changes,
- why it changes,
- which files/components are affected,
- what remains untouched,
- how it will be validated.

Prefer the smallest coherent change.

Do not mix unrelated refactors into feature implementation without reason.

---

# 57. Failure Discipline

When something fails:

1. attempt,
2. diagnose,
3. make a small correction,
4. validate again.

Repeated failure should trigger:

- stop,
- report blocker,
- preserve evidence,
- avoid hiding the failure by weakening validation.

The agent must never change the validation criteria simply because implementation failed.

---

# 58. Definition of Done

A task is not Done merely because code exists.

Done means:

- implementation works,
- regressions were checked,
- UX is sensible,
- visual behavior follows design,
- anti-slop review was considered,
- performance is acceptable,
- validation was performed,
- relevant state is documented.

At phase completion, the agent stops rather than automatically beginning another phase.

---

# 59. Open Source Structure

Planned repository structure:

```text
BASEUS/
├── MASTER.md
├── DESIGN.md
├── ANTI-SLOP.md
├── DECISIONS.md
├── ROADMAP.md
├── TASKS.md
├── STATE.md
├── CHECKPOINT.md
├── AGENTS.md
├── MASTER-PROMPT.md
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── docs/
│   ├── installation.md
│   ├── getting-started.md
│   ├── configuration.md
│   ├── theming.md
│   ├── keybindings.md
│   ├── gestures.md
│   ├── troubleshooting.md
│   ├── architecture.md
│   └── development.md
└── .github/
    ├── ISSUE_TEMPLATE/
    │   ├── bug
    │   ├── feature
    │   └── design-proposal
    ├── PULL_REQUEST_TEMPLATE.md
    └── workflows/
```

---

# 60. License and Identity

BASEUS uses the MIT License.

Copyright:

```text
Copyright (c) 2026 xoradesu
```

Public project identity:

```text
xoradesu
```

---

# 61. Final Product Principles

BASEUS should always preserve these principles:

1. **Simple for the user. Powerful underneath.**
2. **The desktop is a place, not a dashboard.**
3. **Wabi-sabi is the static visual foundation.**
4. **Cyberpunk belongs primarily to motion and effects.**
5. **Focus grows. Context recedes.**
6. **Freeform first. Smart when necessary. Never fight the user.**
7. **Personalization must remain meaningful.**
8. **Empty space is allowed.**
9. **Motion must communicate something.**
10. **Solid surfaces are preferred over decorative effects.**
11. **Typography is a first-class design tool.**
12. **Icons are semantic, not decorative.**
13. **Idle should be quiet.**
14. **Context should appear when needed and disappear when finished.**
15. **Performance is part of the product identity.**
16. **User mental models matter more than implementation structure.**
17. **Open source participation does not require loss of product identity.**
18. **Implementation must serve the design, not redefine it.**
19. **BASEUS should feel unmistakably BASEUS.**
20. **BASEUS should never make the user fight the interface.**

---

# 62. Master Rule

When a future decision is ambiguous, prefer the solution that:

- preserves user agency,
- reduces unnecessary complexity,
- strengthens hierarchy,
- preserves whitespace,
- uses motion intentionally,
- respects performance,
- maintains BASEUS identity,
- and does not add visual or functional noise merely because it is technically possible.

The goal is not to make BASEUS contain everything.

The goal is to make the things that exist feel **deliberate**.

---

**LOCKED — This document is the highest-level product source of truth.**
