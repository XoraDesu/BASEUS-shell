# BASEUS — Design Language

## 1. Intent

BASEUS should feel intentional rather than decorated. Wabi-sabi is the foundation: restraint, hierarchy, whitespace, and meaningful imperfection. Cyberpunk influences motion and effects only.

## 2. Surfaces

- Prefer solid surfaces.
- A surface must have a functional reason to exist.
- Not every element needs a container.
- Floating is contextual; Dock and Top Island are edge-integrated, while notifications and transient pickers may float.
- Avoid card stacks, glass panels, heavy shadows, and excessive radius usage.

## 3. Color

BASEUS uses Matugen for wallpaper-derived theming and exposes four main palette colors. The palette affects the whole shell. For monochrome or unstable wallpaper, use an HSL-based fallback. Palette changes transition smoothly.

## 4. Typography

Typography carries identity, hierarchy, action, and context. It may replace icons when text communicates more clearly. Editorial/archival details are allowed when they remain functional and restrained.

## 5. Iconography

Icons are semantic, simple, geometric, palette-aware, and consistent. Use icons mainly for state or concepts that typography cannot express efficiently. Avoid decorative icon collections and generic “Linux UI” icon noise.

## 6. Layout

Whitespace is intentional. Do not fill empty space merely because it exists. Centered, compact, edge-integrated surfaces are preferred to long full-width bars.

## 7. Motion

Motion must communicate one or more of:

- appearance/disappearance
- focus
- hierarchy
- state change
- spatial relationship
- transition

Transient surfaces can use pixel-like curtain reveals. Fullscreen surfaces use smooth curtain reveals. Workspace focus uses hierarchical scaling. Avoid animation on every interaction.

## 8. Interaction

BASEUS follows **Discover → Customize → Execute**. Users can discover actions through visible context, Command Center, and help. Customization lives in Headquarter. Execution should feel direct and reversible where appropriate.

## 9. Accessibility

Minimalism must not justify tiny text, poor contrast, color-only state, or gesture-only interaction. Keyboard alternatives should exist for important actions.

## 10. Idle State

Default idle is quiet: wallpaper, selected widgets, clock, and no permanent taskbar, workspace numbers, notification clutter, or greeting dashboard. BASEUS is allowed to do nothing.

## 11. Responsive Behavior

Surfaces should adapt to monitor geometry and input context. Multi-monitor behavior is explicit. Fullscreen applications should receive focus rather than competing with shell chrome.
