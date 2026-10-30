# ANTI-SLOP.md

**Project:** BASEUS  
**Document role:** Design quality system / anti-slop standard
**Applies to:** All BASEUS UI, UX, interaction, visual, motion, copy, personalization, and surface decisions

---

## 1. Purpose

BASEUS must not become a generic "modern Linux desktop" assembled from fashionable interface patterns.

The purpose of this document is to protect intentionality.

Anti-slop does **not** mean:

- making everything minimal;
- removing all decoration;
- making every surface flat;
- refusing visual personality;
- refusing animation;
- refusing rounded geometry;
- refusing complexity where complexity is useful.

Anti-slop means that every visible or interactive choice has a reason.

A design can be visually simple and still be slop.  
A design can be visually rich and still be intentional.

BASEUS is allowed to be expressive, playful, unusual, dense, sparse, animated, asymmetric, editorial, cyberpunk, or cute when those qualities serve the established identity and experience.

The standard is not:

> "Does this look cool?"

The standard is:

> **"Is this intentional, useful, coherent, and unmistakably BASEUS?"**

MASTER.md defines product truth. DESIGN.md defines the established visual and interaction language. ANTI-SLOP.md protects both from gradual degradation during implementation.

---

# 2. Core Principle

## Intentionality over decoration

Every meaningful interface element should be defensible.

Before introducing an element, ask:

1. **What does this element do?**
2. **Why does it exist?**
3. **Why is it here?**
4. **Why is it this size?**
5. **Why is it this prominent?**
6. **Why does it have this color or tonal treatment?**
7. **Why does it behave this way?**
8. **Why does it move?**
9. **Why does it feel like BASEUS?**
10. **What becomes worse if it is removed?**

If there is no convincing answer, the element is suspect.

Aesthetic justification alone is insufficient for functional UI.

"Because modern interfaces do this" is not a justification.

"Because the screenshot looked empty" is not a justification.

"Because an AI suggested it" is never a justification.

---

# 3. The Removal Test

For every new visual or interaction element:

> **Remove it mentally. What gets worse?**

Possible valid answers include:

- the user loses necessary information;
- hierarchy becomes unclear;
- an interaction becomes harder to discover;
- state becomes ambiguous;
- navigation becomes slower;
- a meaningful personality cue disappears;
- an established BASEUS interaction pattern breaks;
- accessibility becomes worse;
- feedback becomes insufficient.

Weak answers include:

- "the screen feels less premium";
- "it fills the empty space";
- "it looks more futuristic";
- "it makes the screenshot prettier";
- "modern dashboards usually have one";
- "it makes the UI feel complete."

If removal produces no meaningful loss, the element should generally not exist.

---

# 4. The BASEUS Identity Test

For any substantial UI decision, ask:

> **Could this belong to another Linux shell without anyone noticing?**

If the answer is yes, the decision requires scrutiny.

BASEUS identity comes from the combination of:

- wabi-sabi restraint;
- intentional empty space;
- editorial/archival hierarchy;
- asymmetric but controlled composition;
- edge-integrated geometry;
- solid surfaces;
- contextual motion;
- semantic and personalized iconography;
- typography used as a real visual tool;
- palette-driven visual state;
- cyberpunk expressed primarily through motion/effects rather than permanent neon;
- freeform desktop interaction;
- Android-like mental models where appropriate;
- playful personality appearing with purpose rather than as decoration.

A component does not need to contain every characteristic.

However, a growing collection of generic components is a warning sign even if each individual component appears acceptable.

---

# 5. What Counts as Slop

"Slop" is any design or implementation that:

- exists without a meaningful purpose;
- imitates a current visual trend without understanding its purpose;
- substitutes decoration for hierarchy;
- adds containers instead of solving composition;
- uses animation because animation is available;
- uses icons because an icon slot exists;
- adds data because an area looks empty;
- adds settings because customization sounds powerful;
- increases complexity without meaningful user benefit;
- makes the UI look better in a screenshot while making it worse to use;
- hides uncertainty behind polished visuals;
- makes BASEUS look interchangeable with generic AI-generated UI;
- ignores established product decisions;
- weakens performance, accessibility, or clarity for aesthetic novelty.

Slop can be visual, interactional, architectural, copywriting-related, or performance-related.

---

# 6. Anti-Slop Pattern Catalog

## 6.1 Cardification

### Pattern

Turning every piece of information into an individual rounded card.

Examples:

- clock card;
- battery card;
- network card;
- media card;
- workspace card;
- weather card;
- system card;
- notification card;
- settings card;
- card containing more cards.

### Why it is dangerous

Cards create artificial boundaries.

When everything becomes a card, nothing has hierarchy.

BASEUS prefers:

- continuous surfaces;
- typography;
- spacing;
- alignment;
- tonal separation;
- edge-integrated geometry;
- direct composition.

A card must exist because grouping is functionally meaningful, not because a component library provides a Card component.

### Test

If removing the card border/background and keeping the same content still communicates the same relationship, the card may be unnecessary.

---

## 6.2 Container Addiction

### Pattern

Adding a container around an element simply because the element "needs a place."

Common chain:

```text
screen
└── container
    └── card
        └── inner card
            └── icon box
                └── icon
```

### Rule

Do not solve composition by nesting boxes.

Prefer:

- position;
- scale;
- whitespace;
- typography;
- dividers;
- tonal contrast;
- edge relationship.

Containers are structural tools, not decorative punctuation.

---

## 6.3 Rounded-Everything

### Pattern

Applying rounded corners to:

- every panel;
- every button;
- every icon;
- every list;
- every popup;
- every image;
- every input;
- every surface.

### Rule

Rounded geometry must communicate something.

Possible reasons:

- transient surface;
- intentional soft transition;
- inherited visual language;
- particular interaction boundary.

Do not round an element merely because "modern UI is rounded."

BASEUS uses rounded geometry selectively.

---

## 6.4 Gradient Abuse

### Pattern

Using gradients as a default method of making interfaces look premium.

Examples:

- gradient backgrounds;
- gradient buttons;
- gradient text;
- gradient borders;
- gradient cards;
- gradient overlays;
- gradient everywhere.

### Rule

Palette should provide identity without requiring gradient treatment.

BASEUS has a strong palette system, but palette does not mean every surface must interpolate between colors.

A solid surface with good hierarchy is often stronger.

Gradients are permitted when they communicate:

- depth;
- transition;
- wallpaper-derived visual state;
- meaningful visual emphasis;
- a deliberate effect.

They must not become a substitute for composition.

---

## 6.5 Glassmorphism

### Pattern

Transparent blurred surfaces layered over everything.

### Why it is dangerous

Glass often introduces:

- visual noise;
- poor contrast;
- unnecessary blur;
- fake depth;
- performance cost;
- indistinct hierarchy.

BASEUS is not a glass showcase.

Solid surfaces are preferred.

Transparency may be used when it has a specific semantic or compositional reason, but "make it glassy" is not a design direction.

---

## 6.6 Glow / Neon / Cyberpunk Abuse

### Pattern

Treating "cyberpunk" as:

- neon borders;
- RGB glow;
- glowing text;
- glowing icons;
- glowing cards;
- permanent electric colors;
- excessive bloom.

### Rule

Cyberpunk is primarily a **motion/effects language**, not a permanent neon skin.

BASEUS can use:

- luminous transitions;
- focused highlights;
- subtle glow;
- energetic state changes;
- pixel-like reveals;
- controlled light effects.

It must not become a neon dashboard.

If every element glows, nothing glows.

---

## 6.7 Decorative UI and Fake Data

### Pattern

Adding information-looking elements that do not represent real information.

Examples:

- fake system graphs;
- random numbers;
- meaningless status dots;
- decorative percentages;
- fake telemetry;
- fake timestamps;
- fake activity charts;
- meaningless labels;
- random "SYSTEM ONLINE" messages.

### Rule

Do not manufacture information to make the interface look alive.

If a value is displayed, it should correspond to real state or an explicitly defined decorative concept.

BASEUS should not pretend to be a spaceship control panel.

---

## 6.8 Dashboard Syndrome

### Pattern

Trying to expose everything simultaneously.

Typical symptoms:

- CPU;
- RAM;
- network;
- battery;
- weather;
- music;
- notifications;
- calendar;
- workspaces;
- system status;
- shortcuts;
- recent files;
- random statistics;

all visible at once.

### Rule

BASEUS is a desktop shell, not a permanent monitoring dashboard.

The interface should expose context when context is useful.

Transient surfaces exist for this reason.

The user should not have to visually parse a cockpit just to use a desktop.

---

## 6.9 Screenshot-First Design

### Pattern

Designing primarily for a screenshot, showcase video, or promotional image.

Symptoms:

- excessive decoration while idle;
- fake content;
- oversized hero elements;
- unnecessary visual density;
- animation that looks impressive only once;
- permanent labels;
- impossible-to-ignore branding.

### Rule

BASEUS must be good while actually being used.

A screenshot is not a usability test.

A showcase video is not an interaction model.

The idle desktop should remain calm.

---

# 7. Animation Slop

## 7.1 Animation Everywhere

Animation must not become mandatory decoration.

Not every:

- hover;
- click;
- state;
- list;
- icon;
- button;
- text;
- surface

needs an animation.

Animation should communicate:

- appearance;
- disappearance;
- hierarchy;
- causality;
- state;
- focus;
- spatial relationship;
- context.

If an animation communicates nothing, remove it.

---

## 7.2 Excessive Microinteraction

Microinteractions can be valuable, but excessive microinteraction creates:

- latency;
- distraction;
- visual fatigue;
- unpredictable timing;
- a toy-like feeling;
- performance cost.

BASEUS should not celebrate every mouse movement.

The user is trying to use the desktop.

---

## 7.3 Animation as Identity

Animation is one of BASEUS's major identity tools.

This means animation deserves **more discipline**, not less.

Important motion principles from DESIGN.md:

- Focus grows; context recedes.
- Motion should be contextual.
- Transient surfaces should reveal themselves coherently.
- Fullscreen and transient surfaces have different motion roles.
- Pixel-like reveals are exposure/curtain behavior, not arbitrary scaling.
- OSD events should originate from the Top Island.
- Rapid repeated events should morph/update one OSD instead of producing a stack of competing animations.

Do not introduce animation that conflicts with these patterns.

---

# 8. Icon Slop

## Pattern

Using an icon for every concept.

Symptoms:

- icon next to every label;
- redundant icon + text + tooltip;
- generic icon libraries everywhere;
- decorative iconography;
- inconsistent icon metaphors;
- icons chosen because a slot exists.

### Rule

Icons should communicate:

- semantic meaning;
- state;
- action;
- concept;
- navigation;
- recognizable system affordance.

Typography is often preferable when it communicates the same thing more clearly.

BASEUS should avoid generic, ugly, context-free iconography.

Icons should feel:

- simple;
- intentional;
- semantic;
- palette-aware where appropriate;
- consistent with BASEUS.

---

# 9. Emoji Slop

Emoji are not a substitute for icon design.

Avoid:

- decorative emoji in every section;
- emoji as fake personality;
- emoji replacing clear system semantics;
- random emoji used to make empty UI feel alive.

If a playful visual needs to exist, it should be a deliberate BASEUS asset or interaction rather than random emoji decoration.

---

# 10. Typography Slop

Typography is a major part of BASEUS identity.

That makes typography especially vulnerable to overuse.

Avoid:

- too many fonts;
- excessive font weights;
- random uppercase labels;
- arbitrary letter spacing;
- meaningless giant text;
- tiny text used as decoration;
- numbers everywhere;
- labels that exist only to look editorial.

Editorial/archival influence should create hierarchy and personality, not turn every surface into a poster.

Typography must remain readable and functional.

---

# 11. Asymmetry Slop

BASEUS allows asymmetry.

That does not mean:

> "Make everything slightly misaligned."

Asymmetry should create:

- hierarchy;
- rhythm;
- visual tension;
- editorial character;
- intentional composition.

It must remain controlled.

Random misalignment is not wabi-sabi.

Wabi-sabi is not an excuse for sloppy layout.

---

# 12. Empty-Space Abuse

Empty space is intentional in BASEUS.

That does not mean empty space should be manufactured everywhere.

Avoid:

- huge gaps that slow scanning;
- oversized margins that make controls difficult to reach;
- empty screens containing only decorative typography;
- blank regions used to imitate luxury;
- intentionally sparse layouts that hide useful information.

The correct question is:

> "Does this empty space improve hierarchy, calm, focus, or composition?"

If not, it may simply be unused space.

---

# 13. Personalization Slop

BASEUS supports meaningful personalization.

Personalization must not become:

> "Every pixel can be configured."

Avoid:

- hundreds of toggles;
- arbitrary per-component styling;
- redundant theme controls;
- settings for things users should never need to think about;
- customization that destroys visual coherence.

Themes represent visual state.

They are not an excuse to expose the implementation model.

The user should customize BASEUS's experience, not administer its internals.

---

# 14. Settings Slop

## Pattern

Creating settings because a behavior exists.

Examples:

- animation speed for every animation;
- separate radius setting for every component;
- individual opacity for every surface;
- independent spacing controls;
- dozens of nearly identical toggles.

### Rule

A setting should exist because a meaningful user need exists.

Before adding a setting, ask:

1. Who needs this?
2. What problem does it solve?
3. Why is a global/default behavior insufficient?
4. Does it belong in the user's mental model?
5. Will users understand the consequence?
6. Does it preserve BASEUS identity?

If the answer is weak, do not expose the setting.

---

# 15. Feature Slop

A feature is not valuable merely because it can be implemented.

Avoid:

- novelty features without a user need;
- duplicated functionality;
- widgets added to fill space;
- integrations added because they are technically possible;
- alternate modes with no clear use;
- "power user" complexity without a real workflow.

BASEUS should become more capable without becoming more noisy.

---

# 16. Complexity Creep

Complexity often enters incrementally.

A component is added.

Then a toggle.

Then an exception.

Then a compatibility mode.

Then another state.

Then another settings page.

Eventually the original mental model disappears.

### Rule

Every meaningful addition should be evaluated at system level.

Ask:

- What new states does this create?
- What new interactions does it require?
- What documentation does it require?
- What testing does it require?
- What failure modes does it create?
- What does it make harder to reason about?
- Does the benefit justify the permanent complexity?

Small code does not necessarily mean small product complexity.

---

# 17. Generic "Modern UI" Slop

Avoid design language that could describe almost any product:

- modern;
- clean;
- sleek;
- futuristic;
- premium;
- polished;
- elegant;

These words are not design specifications.

BASEUS requires concrete decisions.

Instead of:

> "Make it modern."

Use:

> "Use a solid palette-derived surface, preserve the edge-integrated geometry, reduce secondary scale, and reveal the transient surface with the established curtain motion."

Specific language protects identity.

---

# 18. Copywriting Slop

UI text should not pretend to be more meaningful than it is.

Avoid:

- fake inspirational messages;
- unnecessary welcome copy;
- corporate slogans;
- random system poetry;
- generic AI-generated labels;
- redundant explanations;
- excessive capitalization;
- fake urgency.

BASEUS can have personality.

Personality must be intentional.

A memorable greeting in Headquarter is meaningful because it is part of the established experience. That does not justify adding greetings everywhere.

---

# 19. Empty-State Slop

Do not add empty-state messages simply because a region is empty.

BASEUS explicitly allows calm emptiness.

Avoid:

- "Nothing here yet!" on every empty surface;
- decorative illustrations with no purpose;
- prompts telling users what to do when no action is necessary;
- fake activity to make an empty surface look populated.

If the correct state is simply empty, let it be empty.

---

# 20. Notification Slop

Notifications are interruptions, not decorations.

Avoid:

- excessive notification animation;
- permanent notification clutter;
- decorative notification chrome;
- redundant icons;
- unnecessary categorization;
- stacking behavior that overwhelms the desktop.

BASEUS notification behavior should preserve:

- source recognition;
- readable content;
- useful actions;
- clear dismissal;
- controlled motion;
- calm visual hierarchy.

A notification should communicate an event, not advertise that the shell has a notification system.

---

# 21. Performance Slop

Visual complexity has a cost.

Do not spend:

- CPU;
- GPU;
- memory;
- battery;
- startup time;

for decoration that users cannot meaningfully perceive or benefit from.

Examples:

- unnecessary continuous polling;
- redundant timers;
- repeated palette extraction;
- expensive blur;
- animations that run while irrelevant;
- background work with no visible purpose;
- rendering elements that are hidden.

BASEUS should prefer:

- event-driven behavior;
- caching;
- bounded sampling;
- one-time computation where appropriate;
- reuse of state;
- minimal background work.

A beautiful desktop that wastes resources is not a successful implementation.

---

# 22. Accessibility Slop

Accessibility is not an optional layer added after visual polish.

Avoid design decisions that make the interface harder to use solely for aesthetic effect.

Check:

- contrast;
- text legibility;
- focus visibility;
- input discoverability;
- motion sensitivity;
- hit targets;
- state communication;
- keyboard access;
- gesture alternatives;
- reduced-motion behavior where appropriate.

Do not hide essential information exclusively behind:

- color;
- motion;
- tiny text;
- hover;
- gesture;
- sound.

BASEUS's identity must remain usable.

---

# 23. Consistency vs Uniformity

These are not the same.

### Consistency

A user can predict behavior because related things follow related principles.

### Uniformity

Everything is forced to look and behave the same.

BASEUS wants consistency without uniformity.

Examples:

- Dock, Top Island, Command Center, App Drawer, and Headquarter can have different compositions.
- They should still share the same underlying visual language.
- Transient surfaces can move differently from fullscreen surfaces.
- A notification does not need to look like a settings panel.
- A media surface does not need to become another generic card.

Do not flatten the entire product into one component style.

---

# 24. Component Library Warning

Reusable components are useful.

A component library must not become the source of design truth.

If a reusable component forces BASEUS into:

- cardification;
- generic spacing;
- generic radii;
- generic shadows;
- generic transitions;
- generic typography;

then the component is wrong for the product, even if it is technically convenient.

Architecture should serve design identity.

Not the other way around.

---

# 25. Design Before Implementation

Before implementing a new surface, identify:

### Purpose

What user problem does it solve?

### Mental model

Which BASEUS mental model does it belong to?

- Dock = What am I using?
- App Drawer = What can I open?
- Command Center = What do I want to do?
- Headquarter = Where do I configure BASEUS?
- Overview = Where am I and what is there?

### Hierarchy

What is primary?

What is secondary?

What can disappear?

### Spatial role

Is it:

- edge-integrated;
- transient;
- fullscreen;
- contextual;
- workspace-specific;
- monitor-specific;
- global?

### Motion role

What causes it to appear?

What causes it to disappear?

What spatial relationship should the motion communicate?

### Identity

What makes it BASEUS rather than a generic shell component?

---

# 26. New Visual Element Gate

Every new visual element should pass the following gate.

## Required questions

**Purpose**
- What does it do?

**Placement**
- Why is it here?

**Scale**
- Why is it this size?

**Color**
- Why does it use this tonal/palette treatment?

**Motion**
- Why does it move?

**Interaction**
- Why does it behave this way?

**Identity**
- Why does it belong in BASEUS?

**Removal**
- What worsens if it is removed?

**Cost**
- What does it cost in complexity, performance, maintenance, or cognitive load?

**Accessibility**
- Does it introduce an accessibility problem?

If the answers are weak, redesign or remove the element.

---

# 27. New Interaction Gate

For any new interaction:

1. What user intent triggers it?
2. Is the trigger discoverable?
3. Is there an established BASEUS interaction that already solves this?
4. Does the interaction create a new mental model?
5. Can the user recover from mistakes?
6. Is the result visible?
7. Does the interaction conflict with existing shortcuts or gestures?
8. Does it require unnecessary memorization?
9. Is there a keyboard/mouse/touch/gesture alternative where appropriate?
10. Does it preserve the "freeform first, smart when necessary" principle?

Do not add interactions merely because a gesture, animation, or shortcut is technically available.

---

# 28. New Surface Gate

Before adding a new panel, popup, widget, drawer, overlay, or dashboard-like surface:

### Ask

- Why is this not part of an existing surface?
- What mental model does it represent?
- Does it need its own visual boundary?
- Could typography/spacing communicate the relationship instead?
- Is it transient or persistent?
- Should it be global or workspace-specific?
- Does it belong to a monitor?
- What causes it to appear?
- What causes it to disappear?
- What happens behind it?
- What happens when it is empty?
- What happens under rapid repeated input?
- What is the performance cost?

A new surface is a significant product decision.

---

# 29. Identity Protection Rules

The following are strong anti-slop boundaries for BASEUS:

- Do not turn BASEUS into a traditional panel.
- Do not turn BASEUS into a permanent taskbar.
- Do not turn BASEUS into a neon dashboard.
- Do not turn BASEUS into a glass showcase.
- Do not turn BASEUS into a card-based productivity dashboard.
- Do not turn BASEUS into a tiling-first shell.
- Do not turn BASEUS into a generic Material/Pixel/macOS clone.
- Do not turn BASEUS into an AI-generated futuristic interface.
- Do not use animation as a showcase instead of communication.
- Do not fill every empty region.
- Do not add information merely because space exists.
- Do not add settings merely because a behavior can be configured.
- Do not add icons merely because a slot exists.
- Do not add containers merely because a component exists.
- Do not use cyberpunk as an excuse for permanent neon.
- Do not use wabi-sabi as an excuse for sloppy design.
- Do not use asymmetry as an excuse for random alignment.
- Do not use personalization as an excuse for uncontrolled complexity.

---

# 30. The "Looks AI-Generated" Test

A design is suspicious if it has a combination of:

- excessive rounded cards;
- gradients;
- glass;
- glow;
- generic futuristic typography;
- meaningless status indicators;
- fake data;
- decorative charts;
- huge empty hero text;
- excessive iconography;
- generic dark-mode palette;
- random neon accents;
- excessive shadows;
- uniform component grids;
- identical corner radii everywhere;
- animations attached to everything.

Any one of these can be valid.

The problem is the **pattern**.

If the design could be generated from a generic "futuristic Linux desktop UI" prompt, it is not sufficiently intentional.

---

# 31. The "Cool but Wrong" Test

Some designs are objectively visually impressive and still wrong for BASEUS.

Examples:

- a beautiful glass dashboard;
- a gorgeous neon control center;
- an elaborate animated sidebar;
- a perfectly symmetrical component grid;
- an impressive 3D system monitor;
- a highly polished collection of glowing cards.

The question is not whether these can look good.

The question is whether they belong to the established product language.

BASEUS must resist the temptation to accept visually impressive work simply because it is visually impressive.

---

# 32. The "Would I Keep This If Nobody Saw It?" Test

A feature should be useful even when nobody is taking screenshots.

Ask:

> If the user were the only person who would ever see this interface, would this element still deserve to exist?

If the answer is no, it may be showcase-driven slop.

---

# 33. The "One More Thing" Test

Before adding another visual detail, ask:

> Is this actually necessary, or am I adding one more thing because the design feels unfinished?

This is one of the most important anti-slop checks.

An unfinished design may need:

- better hierarchy;
- better spacing;
- better typography;
- better interaction;
- better alignment;
- better state communication.

It does not necessarily need another component.

---

# 34. Wabi-Sabi Boundary

BASEUS draws from wabi-sabi as a philosophy of restraint, imperfection, natural rhythm, and intentional emptiness.

This does **not** mean:

- deliberately broken UI;
- inconsistent controls;
- sloppy alignment;
- arbitrary roughness;
- fake imperfections;
- unfinished visuals.

Imperfection must remain compatible with usability.

The interface may feel human and composed without feeling defective.

---

# 35. Cyberpunk Boundary

Cyberpunk contributes:

- energy;
- motion;
- transitions;
- effects;
- moments of intensity;
- visual contrast;
- responsive state changes.

It does **not** require:

- permanent neon;
- RGB;
- glowing borders everywhere;
- sci-fi jargon;
- fake telemetry;
- fake system warnings;
- hacker clichés.

Cyberpunk should be felt in moments of interaction.

---

# 36. Editorial / Archival Boundary

Editorial and archival influence contributes:

- hierarchy;
- numbering;
- typography;
- dividers;
- asymmetry;
- visual rhythm;
- information structure.

It does not require:

- classical statues;
- excessive brutalism;
- fake museum labels;
- pseudo-historical decoration;
- ornamental overload.

The influence should remain contemporary and functional.

---

# 37. Personality Without Noise

BASEUS has personality.

Personality can come from:

- Bongo Cat;
- Chibi elements;
- Power Menu constellation;
- distinctive transitions;
- editorial typography;
- carefully chosen iconography;
- contextual micro-details;
- meaningful wallpaper/theme relationships.

Personality should appear as **character**, not clutter.

A playful element becomes weaker when every element is playful.

---

# 38. Anti-Slop Review Procedure

Before accepting a substantial UI change:

## Step 1 — Compare with MASTER

Confirm that the change does not violate product identity or locked decisions.

## Step 2 — Compare with DESIGN

Confirm visual and interaction consistency.

## Step 3 — Run the removal test

Identify what would be lost without the new element.

## Step 4 — Run the identity test

Ask whether it feels unmistakably BASEUS.

## Step 5 — Inspect hierarchy

Check:

- primary;
- secondary;
- contextual;
- transient;
- empty.

## Step 6 — Inspect containers

Ask whether each boundary is necessary.

## Step 7 — Inspect motion

Ask whether every animation communicates something.

## Step 8 — Inspect personalization

Ask whether the feature adds meaningful choice or unnecessary configuration.

## Step 9 — Inspect complexity

Check new states, exceptions, dependencies, and maintenance cost.

## Step 10 — Inspect performance

Check CPU, GPU, memory, timers, polling, rendering, and startup impact.

## Step 11 — Inspect accessibility

Check contrast, legibility, input methods, focus, motion, and alternative access.

## Step 12 — Test without the screenshot

Use the interface normally.

The change must remain justified during real use.

---

# 39. Anti-Slop Review Questions

A reviewer should be able to answer:

### Purpose

- What problem is solved?
- Is the solution proportional to the problem?

### Visual

- Is hierarchy clear?
- Is empty space intentional?
- Are surfaces necessary?
- Are colors meaningful?
- Are icons meaningful?
- Is typography doing useful work?

### Motion

- Does motion communicate state or spatial relationship?
- Does it remain calm during repeated interaction?
- Does it avoid animation for animation's sake?

### Interaction

- Is the behavior discoverable?
- Does it fit an existing mental model?
- Does it avoid unnecessary memorization?

### Identity

- Does it feel like BASEUS?
- Does it preserve wabi-sabi restraint?
- Does it preserve contextual cyberpunk energy?
- Does it preserve editorial hierarchy without becoming ornamental?

### Complexity

- How many new states exist?
- How many new settings exist?
- How many new failure modes exist?
- How much maintenance does this create?

### Performance

- What work happens continuously?
- What work can be event-driven?
- What can be cached?

### Accessibility

- What information depends on color?
- What depends on motion?
- What depends on hover?
- What depends on a gesture?

### Real use

- Is it better during actual use?
- Or only better in a screenshot?

---

# 40. Final Anti-Slop Gate

A substantial change should not be considered design-complete until it passes all of the following:

- [ ] It has a clear purpose.
- [ ] It belongs to an established BASEUS mental model.
- [ ] It follows MASTER.md.
- [ ] It follows DESIGN.md.
- [ ] It does not conflict with accepted DECISIONS.
- [ ] Its hierarchy is intentional.
- [ ] Its empty space is intentional.
- [ ] Its containers are justified.
- [ ] Its icons are justified.
- [ ] Its typography is purposeful.
- [ ] Its colors have a reason.
- [ ] Its motion has a reason.
- [ ] Its interaction has a reason.
- [ ] Its personalization is meaningful.
- [ ] Its complexity is justified.
- [ ] Its performance cost is understood.
- [ ] Its accessibility implications are understood.
- [ ] It works without relying on screenshot appeal.
- [ ] It passes the removal test.
- [ ] It passes the BASEUS identity test.
- [ ] It does not introduce generic AI-generated UI patterns.
- [ ] It does not create unnecessary dashboard/card/container behavior.
- [ ] It does not weaken the established freeform-first philosophy.
- [ ] It remains coherent under real use.

---

# 41. Agent Enforcement

Agents implementing BASEUS must treat anti-slop as an active review system, not as optional design advice.

When an agent notices that an implementation is drifting toward:

- generic cards;
- generic panels;
- excessive containers;
- unnecessary gradients;
- excessive glow;
- fake data;
- decorative UI;
- unnecessary animation;
- icon proliferation;
- settings proliferation;
- complexity creep;
- screenshot-first optimization;

the agent should stop and reassess the implementation against this document.

The agent must not "fix" uncertainty by adding more UI.

When a source-of-truth conflict exists, the agent must not modify MASTER.md or DESIGN.md to justify an implementation.

The correct action is:

1. identify the conflict;
2. stop the affected work;
3. explain the conflict;
4. propose the smallest coherent resolution;
5. await the owner's decision when required by governance;
6. record an accepted decision through the proper source-of-truth process.

---

# 42. Relationship to Other Documents

## MASTER.md

Defines what BASEUS is.

ANTI-SLOP must protect that identity.

## DESIGN.md

Defines how BASEUS looks, feels, and behaves.

ANTI-SLOP evaluates whether implementation preserves that language.

## DECISIONS.md

Records explicit accepted decisions.

ANTI-SLOP does not override accepted decisions.

## ROADMAP.md

Defines the intended development sequence.

Anti-slop review should not be used as an excuse to expand roadmap scope.

## TASKS.md

Defines the current implementation scope.

Anti-slop review should help prevent task scope from silently expanding.

## AGENTS.md

Defines agent operating behavior.

AGENTS.md should require agents to use ANTI-SLOP for relevant UI work.

---

# 43. Anti-Slop Is Not a Veto Against Evolution

BASEUS must be able to evolve.

Anti-slop does not mean:

- never changing;
- never experimenting;
- never adding features;
- never revisiting decisions.

It means change must be intentional.

A genuinely better design may require:

- a new surface;
- a new interaction;
- a new visual treatment;
- a new setting;
- a new animation system.

If so, the change should be justified through the normal governance and design process.

The solution to a new idea is not to reject it because it is new.

The solution is to determine whether it belongs.

---

# 44. The Standard

The final standard is simple:

> **BASEUS should feel designed, not assembled.**

It should feel like one coherent product rather than:

- a component library;
- a collection of widgets;
- a theme pack;
- a showcase dashboard;
- an AI-generated mockup;
- a pile of fashionable effects.

Every part should have a reason.

Every reason should survive real use.

Every visual decision should reinforce the whole.

And when nothing needs to be added, BASEUS should be comfortable leaving the space empty.

---

# 45. Closing Principle

BASEUS should never become impressive merely because it has more.

It should become impressive because every part that remains has earned its place.

**Intentionality over decoration.**  
**Hierarchy over accumulation.**  
**Identity over trend.**  
**Use over screenshot.**  
**Meaning over novelty.**

That is the anti-slop standard.
