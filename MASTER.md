# BASEUS — Master Product Truth

> BASEUS's design language is not a skin. It is the identity and soul of the project.

## What BASEUS Is

BASEUS is a personalized Linux desktop shell built on Quickshell and designed around Hyprland. It aims to feel calm, intentional, expressive, and deeply integrated with the user's workflow without becoming visually noisy or technically wasteful.

BASEUS requires Hyprland, not Arch. Arch and Nix are first-class environments, while the installer should adapt to other Linux distributions where Hyprland and required capabilities are available.

## Core Principles

1. **Wabi-sabi** — restraint, intentionality, whitespace, and acceptance that not every space needs to be filled.
2. **Personalized** — the desktop should feel adaptable to the user's habits and preferences.
3. **User-friendly** — the user should not need a manual to understand the interface.
4. **System-friendly** — beautiful by design, efficient by default.
5. **Simple for the user, powerful underneath.**
6. **Progressive disclosure** — complexity appears when needed, not all at once.
7. **Focus grows. Context recedes.**
8. **Freeform first. Smart when necessary. Never fight the user.**

## Visual Identity

- Solid surfaces are preferred.
- No default gradients, glassmorphism, neon/RGB styling, scanlines, or permanent cyberpunk decoration.
- Cyberpunk is a motion/effects influence, not the permanent visual identity.
- Empty space is intentional.
- Typography is preferred when it communicates better than an icon.
- Icons are semantic, simple, geometric, palette-aware, and not decorative filler.
- Consistency means shared principles, not mechanical uniformity.
- BASEUS should not look like generic AI-generated modern UI.

## Motion Identity

Motion communicates hierarchy, context, state, appearance/disappearance, or spatial relationship.

- Transient surfaces use smooth pixel/game-like curtain reveals.
- Fullscreen surfaces use smooth curtain reveals without pixel trails.
- Workspace changes use hierarchical scaling/focus scaling.
- Theme and palette changes morph smoothly.
- Idle desktop remains calm.

## Desktop Mental Model

- **Dock** = what am I using / current context.
- **App Drawer** = what can I open.
- **Command Center** = what do I want to do.
- **Headquarter** = where do I configure BASEUS.
- **Overview / Helicopter View** = where are my windows and workspaces.

## Major Product Concepts

### Bottom Dock
Bottom-center, bottom-edge integrated, compact, hidden/recessed by default, with inverse corner radius. Pinned apps are global; active apps are workspace-specific. No search.

### Top Island
Top-center, top-edge integrated, separate from the Dock. Normally only the clock is visible. It expands on hover. In fullscreen applications, shell UI collapses; a compact clock can be summoned from the top area.

### Command Center
A universal action and search surface. Prefixes:

- no prefix — applications
- `>` — actions/shortcuts
- `@web:` — web
- `@settings:` — settings
- `@file:` — files
- `@folder:` — folders
- `?help` — help

### App Drawer
Fullscreen, Pixel/Android-inspired application browser. Search is always available. Applications form one continuous dynamic grid; there are no A/B/C section blocks. Recent/Suggested is a separate landing surface.

### Headquarter
Fullscreen main settings application. One-way setting: configurable things live here. Right sidebar stays visible. Progressive disclosure and contextual help are mandatory principles.

### Notifications
Floating top-left. Solid, palette-aware, compact, actionable. Hover pauses pending notification timeout. Interaction should remain useful without becoming a persistent dashboard.

### OSD
All temporary system feedback originates from Top Island and uses the bubble-drop transition. Feedback is not a notification.

### Workspace / Window Model
Ten fixed workspaces, editable by name/tag, with per-monitor state. Windows are floating/freeform by default. Smart arrangement assists without becoming tiling. New and restored windows appear centered.

### Theme
A theme is a visual snapshot: wallpaper, four-color palette, extraction characteristic, widget visual state, surface visuals, icon appearance, and other visual elements. It does not contain behavior such as shortcuts or gesture bindings.

### Wallpaper
Static wallpaper may be per-workspace. Live wallpaper is global. Multi-monitor default spans monitor geometry. Dynamic palette extraction is sampled only when needed and cached.

## Performance Contract

BASEUS must prefer event-driven updates, cached state, minimal background services, and genuinely idle UI. Avoid unnecessary polling, continuous palette recomputation, always-running animation, and hidden resource-heavy surfaces.

## Governance

BASEUS is open source, but open source does not mean loss of product identity. The project has a single maintainer/project owner with final authority over direction. Contributors may participate through written GitHub issues, pull requests, and design proposals.

Significant identity-level UI changes require a Design Proposal before implementation and owner approval. Agents may not silently override accepted product truth.

## Source-of-Truth Hierarchy

1. `MASTER.md`
2. `DESIGN.md` and accepted entries in `DECISIONS.md`
3. `ROADMAP.md`
4. `TASKS.md`
5. implementation

`ANTI-SLOP.md` and `AGENTS.md` apply across all layers.
