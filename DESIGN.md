# BASEUS — DESIGN

**Product:** BASEUS  
**Design role:** Visual and interaction design source of truth  
**Depends on:** `MASTER.md`

---

## 1. Purpose

`DESIGN.md` defines how BASEUS should **look, feel, move, and communicate visually**.

`MASTER.md` defines the product philosophy.

`DESIGN.md` turns that philosophy into a more concrete design language so implementation can remain flexible without drifting into a generic Linux shell, generic “modern UI,” or AI-generated visual style.

This document defines:

- visual language,
- composition,
- surfaces,
- typography,
- color,
- palette usage,
- iconography,
- spacing,
- geometry,
- motion,
- interaction feedback,
- hierarchy,
- fullscreen/transient behavior,
- whitespace,
- personalization,
- and visual quality boundaries.

It does **not** replace `DECISIONS.md`.

Where a behavior has been explicitly decided elsewhere, that decision remains authoritative.

Where this document does not specify an implementation detail, implementation may remain flexible.

---

# 2. Design Identity

BASEUS should feel:

- restrained,
- intentional,
- personal,
- calm,
- expressive,
- responsive,
- slightly playful,
- and technically alive without becoming visually noisy.

The design should have enough personality to be memorable without becoming a visual spectacle.

BASEUS should not look like a collection of popular Linux shell trends placed together.

Its identity comes from the **relationship between restraint, hierarchy, motion, personalization, and contextual appearance**.

---

# 3. Wabi-sabi as the Visual Foundation

Wabi-sabi is the foundation of the static visual language.

This means BASEUS values:

- intentional imperfection,
- breathing room,
- asymmetry when meaningful,
- restrained decoration,
- contextual visibility,
- and visual elements that do not need to occupy every available pixel.

### Empty space is an active design choice.

Whitespace can:

- separate contexts,
- establish hierarchy,
- give a surface room to breathe,
- make focused elements feel important,
- and prevent the desktop from becoming a dashboard.

Whitespace must not be used mechanically.

“Minimal” does not mean “remove everything.”

The question is always:

> **Does the empty space improve the composition or interaction?**

---

# 4. Static Style vs Motion Style

BASEUS has two related but distinct visual influences.

## Static visual language

Primarily:

- Wabi-sabi,
- restrained geometry,
- solid surfaces,
- typography,
- tonal hierarchy,
- personalized palette,
- controlled asymmetry,
- whitespace.

## Motion language

May introduce:

- cyberpunk influence,
- pixel/game-like transitions,
- glitch,
- gooey transitions,
- playful choreography,
- controlled distortion,
- and expressive effects.

Cyberpunk belongs primarily to **motion and effects**.

A screenshot of BASEUS should not automatically look like a neon cyberpunk interface.

The system should be able to feel cyberpunk while moving without being cyberpunk-colored at rest.

---

# 5. Visual Hierarchy

BASEUS uses hierarchy rather than decoration to create visual interest.

Hierarchy may be communicated through:

- size,
- scale,
- position,
- typography,
- tonal contrast,
- opacity,
- spacing,
- motion,
- and focus.

A focused element should not require:

- a glow,
- a giant shadow,
- neon color,
- or an oversized badge

just to be recognizable.

The preferred approach is:

> **Make the important thing clearer. Make the secondary thing quieter.**

---

# 6. Focus Grows, Context Recedes

This is the primary interaction hierarchy principle.

When the user focuses something:

- the focused element can scale up,
- secondary elements can scale down,
- surrounding context can fade,
- typography can become more prominent,
- and spatial emphasis can increase.

This is **hierarchical scaling**, not arbitrary zooming.

The UI should remain spatially understandable.

Examples include:

- workspace switching,
- Alt+Tab,
- Overview,
- fast alphabet scrolling,
- contextual menus,
- selected application,
- selected workspace.

The movement should feel like focus changing, not the camera flying around the interface.

---

# 7. Surfaces

BASEUS uses surfaces intentionally.

A surface exists when containment helps:

- interaction,
- hierarchy,
- readability,
- grouping,
- or spatial understanding.

A surface should not exist simply because the UI needs somewhere to put content.

## Preferred surface characteristics

- solid or mostly solid,
- palette-derived,
- clear tonal relationship,
- restrained radius,
- purposeful edge integration,
- enough breathing room,
- no unnecessary glow.

## Avoid

- cards inside cards inside cards,
- every item becoming its own container,
- excessive floating panels,
- arbitrary borders,
- decorative shadows,
- glass everywhere.

---

# 8. Solid Surfaces

Solid surfaces are the default BASEUS preference.

The palette should provide enough tonal variation that hierarchy can exist without gradients.

Gradients are not automatically forbidden, but they are exceptions.

A gradient must have a clear reason to exist.

The same applies to:

- blur,
- glass,
- glow,
- transparency,
- shadow,
- and other effects.

They should never become the default visual treatment simply because they make screenshots look richer.

---

# 9. Geometry and Corner Treatment

BASEUS uses rounded geometry selectively.

Rounded corners should communicate:

- a surface boundary,
- a distinct interactive region,
- an intentional transition between surface and environment,
- or a specific visual character.

Not everything should become a rounded pill.

The system should avoid:

> **rounded-everything syndrome.**

Some surfaces intentionally meet the screen edge and therefore should use edge-integrated geometry rather than floating-card geometry.

This is particularly important for:

- Dock,
- Top Island,
- App Drawer,
- Headquarter sidebar.

---

# 10. Inverse Corner Radius

BASEUS may use **Inverse Corner Radius (ICR)** for surfaces that are integrated into a screen edge.

ICR is part of BASEUS's visual language for making an edge-integrated surface feel intentional rather than like a floating rectangle glued to the screen.

Important distinction:

> **Edge-integrated does not mean full-width.**

A component can be edge-integrated while remaining compact and centered.

This applies particularly to:

- Dock,
- Top Island,
- and selected edge-integrated fullscreen surfaces.

---

# 11. Dock Visual Design

The Dock is:

- bottom-center,
- edge-integrated,
- compact,
- recessed by default,
- and not floating.

It should feel like a piece of the bottom edge becoming active.

It should **not** feel like a floating macOS-style dock hovering above the desktop.

## Idle

The Dock is hidden/recessed.

A very small bottom-edge trigger region remains available.

The trigger is approximately 1–2 px by default.

## Reveal

The Dock reveal begins from the cursor's first trigger point.

The surface is exposed from the edge rather than simply scaling a floating object upward.

The reveal uses BASEUS's pixel/game-like motion language.

## Composition

Possible layout:

- optional BASEUS launcher identity,
- workspace indicator,
- pinned applications,
- active applications in current workspace.

The Dock is one continuous surface.

It should not become a collection of independent floating cards.

---

# 12. Workspace Indicator

Workspace numbers should not permanently occupy the desktop.

The workspace indicator appears contextually when switching workspace.

The interaction uses hierarchical scaling.

Example:

`1 → 2`

The previous `1`:

- shifts,
- shrinks,
- recedes.

The new `2`:

- shifts into focus,
- grows,
- becomes prominent,
- then settles.

The current workspace may use a palette-derived background/shape.

After the contextual transition, secondary information disappears.

If a contextual workspace label exists, the indicator may morph into a compact pill such as:

`2 — WEB`

Workspace labels remain optional and user-defined.

BASEUS does not require app-derived workspace names.

---

# 13. Top Island Visual Design

The Top Island is separate from the Dock.

It is:

- top-center,
- edge-integrated,
- compact,
- contextual,
- and not full-width.

At idle, the visual presence should be extremely restrained.

The clock is the primary persistent element.

When the user interacts with it, the surface can expand.

The expansion should feel like the edge becoming active rather than a generic floating panel appearing from nowhere.

---

# 14. Fullscreen Shell Behavior

Fullscreen applications should receive visual priority.

When an application is fullscreen:

- Dock recedes,
- Top Island recedes,
- other shell UI recedes.

The shell should not compete with the fullscreen application.

However, the top/notch area can act as a summon point.

Hovering the top area may reveal a **compact clock only**.

A click can request further interaction.

This preserves fullscreen focus while keeping the system accessible.

---

# 15. Transient vs Fullscreen Motion

BASEUS has two broad motion families.

## Transient surfaces

Examples:

- Dock,
- Command Center,
- notifications,
- OSD,
- temporary controls.

These may use:

- pixel-like reveal,
- block-like trail,
- curtain exposure,
- origin-aware motion,
- smooth but expressive transitions.

The surface should feel like it is being **revealed**, not simply scaled from zero.

## Fullscreen surfaces

Examples:

- App Drawer,
- Power Menu,
- Headquarter,
- Overview when applicable.

These use smoother curtain-like transitions.

They should not necessarily use the same pixel trail used by small transient surfaces.

---

# 16. Pixel-like Reveal

The BASEUS pixel/game-like reveal is a specific motion concept.

It is **not**:

- zooming the entire surface,
- rotating a panel,
- scaling a card from its center.

The intended idea is:

> The surface already has its width; its visible height/area is progressively exposed.

This produces a curtain-like or block-reveal feeling.

It should remain smooth and buttery despite the pixel-inspired visual character.

---

# 17. Notifications — Visual Language

Notifications are floating surfaces in the top-left.

They appear left → right.

Visual composition:

- large application icon in the background,
- approximately 70% transparency,
- notification text visually interacting with/overlapping the icon,
- prominent title,
- smaller message.

The icon should function as visual identity, not as a separate giant icon card.

Notifications use solid palette-derived surfaces.

No gradient-heavy notification cards.

---

# 18. Notification Silence Feedback

Silencing a notification should have its own clear visual sequence.

During a long-hold silence interaction:

1. a solid tonal/dark/high-contrast fill progresses left → right,
2. the notification becomes visibly silenced,
3. a silent/bell-silent indicator appears,
4. `"Silent"` can accompany the state.

The state should not rely on alarming red.

Silence is a calm state, not an error state.

---

# 19. Command Center Visual Design

Command Center is slightly above vertical center.

Its composition:

- search/input area at the top,
- results beneath,
- dynamic height,
- fit-content behavior up to a maximum,
- internal scrolling only when needed.

It should feel like a focused command surface, not a giant application window.

Width should be responsive within sensible bounds.

Results should establish hierarchy through:

- title,
- secondary description,
- grouping,
- selection state.

The selected result should be visually obvious without requiring a glow.

If one result is clearly the intended result, it may be automatically selected.

---

# 20. App Drawer Visual Design

App Drawer is literally fullscreen.

It integrates with the screen edges.

Top corners are rounded.

Bottom corners do not need rounding because the surface meets the bottom edge.

The reveal is:

> **bottom → top**

using a smooth curtain-like motion.

It should not feel like a giant card being zoomed into place.

---

# 21. App Drawer Landing State

The first visual layer may contain:

- search,
- recent applications,
- suggested applications.

Recent is visually distinct from the full application collection.

Recent should feel like a welcome/landing layer rather than a giant dashboard.

It may use a darker tonal surface.

Application names should remain readable and meaningful.

Icons should not dominate the layout.

---

# 22. App Drawer Search Transition

When search becomes active:

1. Recent/Suggested content smoothly collapses upward.
2. Search results become the primary content.
3. Search result hierarchy becomes visually dominant.
4. Clearing the search reverses the transition.

The change should feel like pulling one visual layer away rather than switching abruptly between unrelated screens.

---

# 23. Alphabet Fast Scroller

The fast scroller lives near the right edge.

Idle:

- approximately 1 px wide,
- palette-colored,
- subtle,
- around 1 px from the screen edge,
- no permanent letter.

On interaction:

- expands to approximately 3 px,
- letters appear beside it,
- dragging jumps through the application collection.

During fast scrolling:

- the entire UI becomes slightly de-emphasized,
- the selected letter becomes large/high contrast,
- surrounding letters shrink/dim,
- matching applications become more prominent.

Transition example:

`A → B`

`A` shrinks and recedes.

`B` grows and becomes focused.

The fast scroller should communicate navigation, not become a permanent decorative rail.

---

# 24. Headquarter Visual Design

Headquarter is a fullscreen application.

The right sidebar is always visible.

It is not collapsed into icon-only mode.

The sidebar has edge-integrated geometry, including ICR at the relevant right-side corners.

The main content area should have enough breathing room to avoid feeling like a settings dashboard.

Home may use:

- subtle editorial typography,
- archival-inspired hierarchy,
- numbering,
- asymmetry,
- carefully composed greeting.

It should not become:

- a KPI dashboard,
- a card grid,
- or a statistics cockpit.

---

# 25. Contextual Help Visual Design

Contextual help should feel attached to the thing it explains.

Help appears to the **right** of the relevant setting.

It should:

- not shift the main layout,
- not block the entire screen,
- not become a generic modal,
- remain contextual,
- disappear when context changes.

The help bubble should have enough visual distinction to be readable without becoming another dashboard card.

---

# 26. Typography

Typography is a primary design tool in BASEUS.

Typography can communicate:

- hierarchy,
- identity,
- action,
- status,
- navigation,
- context,
- and personality.

BASEUS may use editorial/archival-inspired typography in selected compositions.

However, typography must not become decorative noise.

Avoid:

- giant hero text without purpose,
- arbitrary uppercase everywhere,
- random numbering,
- fake editorial labels,
- excessive typographic ornaments.

Typography should answer:

> **Why does this text need to look this way?**

Exact fonts and exact type scale are intentionally left for a more specific design decision if needed.

---

# 27. Color System

BASEUS uses a dynamic palette derived primarily from wallpaper.

The palette has **four main colors**.

Color should establish:

- hierarchy,
- grouping,
- focus,
- state,
- and identity.

Color should not be used as decorative noise.

The four-color system should remain coherent across the entire shell.

A component should not invent a fifth, unrelated accent merely because it looks visually attractive.

Exceptions should be explicitly justified by semantics or accessibility.

---

# 28. Tonal Hierarchy

Not every element needs a different color.

Hierarchy can be created through:

- tonal shifts,
- opacity,
- contrast,
- size,
- spacing,
- typography,
- and position.

For example:

- primary surface,
- secondary surface,
- focused element,
- inactive context.

This allows BASEUS to remain visually rich without requiring gradients, neon accents, or multiple arbitrary colors.

---

# 29. Theme Transitions

Theme changes should feel like a visual state transformation.

Transitions may include:

- bubble/ripple,
- glitch,
- wavy wipe,
- circle wipe,
- random transition selection,
- saved transition preference.

The visual state should morph rather than abruptly swapping every component.

The transition may coordinate:

- wallpaper,
- palette,
- widgets,
- surfaces,
- icons,
- typography,
- and contextual elements.

The goal is choreography, not spectacle.

---

# 30. Widget Motion

Widgets that remain during a visual transition should move toward their new positions naturally.

They should not teleport unless necessary.

Widgets that disappear may:

1. shake,
2. glitch,
3. POP,
4. disappear.

This playful behavior is allowed because it communicates removal while adding personality.

The effect must remain controlled.

---

# 31. Power Menu Visual Language

The Power Menu is intentionally sparse.

Its visual environment:

- quiet,
- dark,
- spacious,
- constellation-inspired,
- palette-aware.

The constellation should form the navigation structure.

Action labels are integrated into the visual composition.

Focused action may:

- brighten,
- scale slightly,
- become more readable.

Secondary actions recede.

The sleeping chibi can float subtly with:

- slight bobbing,
- restrained `zzz`,
- quiet personality.

The chibi is personality, not primary UI.

---

# 32. OSD Visual Language

OSD should feel like system feedback rather than a notification.

The expanded surface should be:

- solid,
- clean,
- readable,
- temporary.

The transition provides the personality.

The content itself should remain extremely clear.

For example:

```text
VOLUME
72%
```

is preferable to a complicated visual meter if the typography already communicates the information.

---

# 33. Media Visual Language

The media player can contain more personality than many other system surfaces.

Bongo Cat can act as a visual companion.

However, media UI should remain structurally understandable.

The media player must still clearly communicate:

- current media,
- play/pause,
- previous/next,
- seek,
- volume,
- session switching.

Personality supplements usability.

It does not replace it.

---

# 34. Window Chrome

Window chrome should remain minimal but familiar.

Default visual behavior:

- floating windows,
- minimal titlebar,
- conventional close/maximize/minimize,
- subtle focus indication.

Focus should preferably use:

- tonal contrast,
- border/text contrast,
- slight hierarchy.

Avoid:

- glowing focused windows,
- giant accent outlines,
- decorative chrome.

Maximized windows may reduce chrome where appropriate.

---

# 35. Alt+Tab Visual Design

Alt+Tab is a transient context switcher.

It should not become a full Overview replacement.

Visual hierarchy:

- selected item = `1.0`,
- immediate context ≈ `0.85`,
- farther context ≈ `0.7` / fade.

The selected item grows.

Neighbors recede.

Preview + application name are primary.

Icon is secondary.

No 3D coverflow.

No dramatic perspective distortion.

---

# 36. Overview Visual Design

Overview represents the entire desktop context.

The selected workspace grows slightly.

Other workspaces recede.

Window representations remain freeform.

They should preserve enough of their spatial relationships to communicate:

- what windows exist,
- where they are,
- and which workspace is selected.

Overview is a contextual map, not a tiling manager.

---

# 37. Whitespace Rules

Whitespace is intentional.

BASEUS should allow:

- large gaps,
- empty desktop regions,
- breathing room around focused content,
- asymmetrical composition.

But whitespace should have purpose.

Do not add:

- filler cards,
- decorative widgets,
- random lines,
- fake metrics,
- particles,
- or text

simply because an area looks empty.

The absence of content can itself be the composition.

---

# 38. Asymmetry

Asymmetry is allowed and can be important to BASEUS identity.

However:

> **Intentional asymmetry ≠ random misalignment.**

Asymmetry should support:

- hierarchy,
- visual tension,
- composition,
- rhythm,
- or personality.

It should not make controls difficult to discover or create accidental inconsistency.

---

# 39. Motion Restraint

BASEUS uses motion intentionally.

Not every interaction needs:

- bounce,
- scale,
- blur,
- fade,
- spring,
- ripple,
- or glitch.

Motion should have a reason.

Preferred reasons:

1. Appearance.
2. Disappearance.
3. Focus.
4. Hierarchy.
5. State change.
6. Spatial relationship.
7. Feedback.
8. Transition between visual states.

If animation does not communicate one of these reasonably well, it should be questioned.

---

# 40. Idle Motion

The desktop should not constantly perform visual activity.

Idle motion may exist through:

- live wallpaper,
- subtle widget activity,
- extremely restrained personality elements.

But BASEUS should not continuously animate shell chrome simply to make the desktop appear alive.

> **Alive does not mean busy.**

---

# 41. Interaction Feedback

Feedback should usually come from the component performing the action.

Examples:

- volume → OSD,
- workspace switch → workspace indicator,
- app launch → App Drawer/Dock context,
- notification silence → notification state,
- theme change → theme transition,
- focus → focus hierarchy.

Avoid duplicate feedback.

A single action should not produce:

- a notification,
- an OSD,
- a toast,
- a badge,
- and an animation

unless there is a genuine reason for multiple channels.

---

# 42. Personalization Without Chaos

Personalization should modify visual state without destroying hierarchy.

Users can customize meaningful aspects.

However, the system should continue to preserve:

- readability,
- hierarchy,
- palette coherence,
- interaction clarity,
- and BASEUS identity.

Customization should not create an interface where every component looks unrelated.

---

# 43. “Modern” Is Not a Design Specification

Words such as:

- sleek,
- premium,
- futuristic,
- modern,
- elegant,
- polished

are not sufficient design instructions.

Any such direction must be translated into concrete BASEUS principles.

For example:

“modern” should not automatically mean:

- glass,
- gradient,
- blur,
- huge rounded cards,
- shadows,
- or neon.

The implementation must return to the actual design language.

---

# 44. Screenshot Independence

BASEUS must be designed for interaction first.

A screenshot can be beautiful and still represent a bad interface.

Visual review must therefore ask:

- Does it make sense when moving?
- Does it communicate state?
- Can the user understand focus?
- Does it remain usable?
- Does it behave naturally?
- Does it disappear appropriately?
- Does it still feel good after repeated use?

BASEUS is a desktop shell, not a screenshot composition.

---

# 45. Visual Quality Test

Before accepting a visual implementation, ask:

### Purpose

What does this element do?

### Placement

Why is it here?

### Scale

Why is it this size?

### Hierarchy

Why is it this prominent?

### Surface

Why does it need containment?

### Color

Why does it use this color/tonal level?

### Motion

Why does it move this way?

### Identity

Why does it feel like BASEUS?

### Removal

What gets worse if it disappears?

If the answers are weak, the design should be reconsidered.

---

# 46. Anti-generic Test

A useful BASEUS test:

> **Could this interface belong to another Linux shell without anyone noticing?**

If yes, it deserves review.

The answer does not have to be “no” for every individual primitive.

A basic text field can be generic.

A basic close button can be generic.

But the **composition and interaction language of the system as a whole** should feel distinctly BASEUS.

---

# 47. Design Priorities

When visual decisions conflict, prioritize approximately in this order:

1. Usability.
2. Product identity.
3. Clear hierarchy.
4. Intentional composition.
5. Accessibility.
6. Performance.
7. Personality.
8. Decorative novelty.

Personality is important.

Novelty is not more important than usability or identity.

---

# 48. Design Boundaries

### HARD RULE

The following are fundamental visual boundaries:

- Wabi-sabi remains the core static aesthetic.
- Cyberpunk is primarily motion/effects, not permanent visual styling.
- Solid surfaces are preferred.
- Empty space is allowed and intentional.
- BASEUS should not become card-heavy.
- BASEUS should not become neon/RGB/glow-heavy.
- Icons remain semantic.
- Typography is a legitimate primary UI tool.
- Focus grows; context recedes.
- Motion must have purpose.
- Fullscreen surfaces and transient surfaces use different motion families.
- Dock and Top Island remain distinct components.
- Dock is edge-integrated, not floating.
- Top Island is edge-integrated and compact, not a full-width bar.
- Fullscreen applications receive shell visual priority.
- Personalization must preserve BASEUS identity.

### DESIGN PRINCIPLE

The following are principles where implementation can vary:

- exact radius values,
- exact spacing,
- exact easing,
- exact animation duration,
- exact font,
- exact surface dimensions,
- exact responsive breakpoints,
- exact icon geometry.

### IMPLEMENTATION FREEDOM

Engineering may determine:

- rendering details,
- component structure,
- state implementation,
- caching strategy,
- animation mechanism,
- internal APIs,
- and technical architecture,

as long as the resulting experience remains consistent with this document and accepted decisions.

---

# 49. Explicit Non-goals

BASEUS design is not trying to become:

- a glassmorphism showcase,
- a neon cyberpunk dashboard,
- a traditional Linux panel,
- a permanent taskbar,
- a card-based productivity dashboard,
- a tiling window UI,
- a generic Material clone,
- a Pixel clone,
- a macOS clone,
- an AI-generated “futuristic” interface,
- or an animation showcase.

BASEUS may take inspiration from other products.

It must transform inspiration into its own language.

---

# 50. Design Definition

BASEUS should look like a system that knows when to be visible and when to disappear.

It should feel:

> **quiet when idle,**

> **clear when needed,**

> **expressive when interacted with,**

> **personal when customized,**

> **playful when appropriate,**

> **and restrained when nothing needs to happen.**

The design should not constantly ask:

> “How can we make this more impressive?”

It should ask:

> **“What is the most intentional way for this to exist?”**

---
