pragma ComponentBehavior: Bound

// BASEUS — Color Tokens & Palette System
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by DESIGN.md §27, §28 and DECISIONS.md DEC-011:
//   - Exactly four main colors (dominant, secondary, accent, neutral)
//   - Matugen dynamic extraction pipeline boundary
//   - Tonal hierarchy over gradient/glass decoration (ANTI-SLOP.md §6.4, §6.5)
//   - Solid surfaces are the default surface treatment

import QtQuick

QtObject {
    id: colors

    // =========================================================
    // The 4 Core Palette Colors (DEC-011, DESIGN.md §27)
    // =========================================================
    // Derived from wallpaper via Matugen or user override.
    // Default palette: Calm Wabi-Sabi Indigo / Slate.

    // 1. Dominant / Primary: Brand identity, active highlights, key focus
    property color dominant: "#7aa2f7"

    // 2. Secondary: Supporting structure, secondary actions, grouping
    property color secondary: "#bb9af7"

    // 3. Accent: Carefully metered emphasis, interactive feedback
    property color accent: "#7dcfff"

    // 4. Neutral: Solid surfaces, base canvas, structural outlines
    property color neutral: "#1a1b26"

    // =========================================================
    // 5-Step Tonal Surface Luminance Hierarchy (M3 Tonal Depth)
    // =========================================================
    // Governed by DESIGN.md §8, ANTI-SLOP.md §6.4:
    // Solid surfaces separated strictly by tonal luminance steps and 1px hairlines.

    // 1. Deepest recessed wells (search inputs, password fields, slider tracks, LyricsContainer)
    property color surfaceContainerLowest: "#13131a"

    // 2. Quiet background canvas (Headquarter main view area, LockScreen solid backdrop)
    property color surfaceContainerLow: "#16161e"

    // 3. Primary structural surfaces (TopIslandAnchor, Dock, Headquarter right sidebar, NotificationHost cards)
    property color surfaceContainer: "#1f2335"

    // 4. Floating overlays (CommandCenter, WallpaperPicker, MediaWidget, TopIslandMedia pill)
    property color surfaceContainerHigh: "#24283b"

    // 5. Interactive pills, active control surfaces, and TopIslandOsd
    property color surfaceContainerHighest: "#292e42"

    // =========================================================
    // Backward-Compatible Tonal Surface Aliases
    // =========================================================
    property alias surfaceRecessed: colors.surfaceContainerLowest
    property alias surfaceBase: colors.surfaceContainerLow
    property alias surfaceSolid: colors.surfaceContainer
    property alias surfaceElevated: colors.surfaceContainerHigh
    property alias surfaceHighlight: colors.surfaceContainerHighest

    // =========================================================
    // Tonal Hierarchy — Text & Content (DESIGN.md §26)
    // =========================================================

    // High contrast primary text and major titles
    property color textPrimary: "#c0caf5"

    // Medium contrast secondary descriptions and labels
    property color textSecondary: "#9aa5ce"

    // Quiet editorial timestamps, shortcuts, and inactive hints
    property color textMuted: "#565f89"

    // Inverted text color when drawn over dominant/accent filled buttons
    property color textInverse: "#15161e"

    // =========================================================
    // Structural Borders & Outlines (Hairline, no neon glow)
    // =========================================================

    // Subtle 1px boundary line for structural separation and outer floating overlays
    property color outline: "#292e42"

    // Alias for backward compatibility
    property alias borderSubtle: colors.outline

    // =========================================================
    // Palette Token Aliases (M6 Design System Alignment)
    // =========================================================
    property alias primary: colors.dominant
    property alias surfaceVariant: colors.surfaceContainerHighest
    property alias onSurfaceVariant: colors.textSecondary



    // Distinct boundary for focused or active interactive elements
    property color borderFocus: "#7aa2f7"

    // Softer interior 1px divider (45% alpha blend of outline over surfaceContainer)
    // Reduces visual grid noise inside Headquarter and CommandCenter
    property color outlineVariant: Qt.rgba(
        surfaceContainer.r * 0.55 + outline.r * 0.45,
        surfaceContainer.g * 0.55 + outline.g * 0.45,
        surfaceContainer.b * 0.55 + outline.b * 0.45,
        1.0
    )

    // =========================================================
    // Unified Tactile State Layers (Zero-cost flat opacity)
    // =========================================================
    // Governed by ANTI-SLOP.md: Zero ripple shaders, zero idle timers.
    property color stateHover: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.07)
    property color stateFocus: Qt.rgba(dominant.r, dominant.g, dominant.b, 0.12)
    property color statePressed: Qt.rgba(dominant.r, dominant.g, dominant.b, 0.16)
    property color stateSelected: Qt.rgba(dominant.r, dominant.g, dominant.b, 0.14)

    // =========================================================
    // Semantic Status Indicators (Restrained, accessible)
    // =========================================================

    property color statusSuccess: "#9ece6a"
    property color statusWarning: "#e0af68"
    property color statusError: "#f7768e"
    property color statusInfo: "#7dcfff"

    // =========================================================
    // Palette Mutation / Event Updates
    // =========================================================

    function applyPalette(paletteData) {
        if (!paletteData) return
        if (paletteData.dominant) dominant = paletteData.dominant
        if (paletteData.secondary) secondary = paletteData.secondary
        if (paletteData.accent) accent = paletteData.accent
        if (paletteData.neutral) neutral = paletteData.neutral

        // Surface containers & backward-compatible overrides
        if (paletteData.surfaceContainerLowest) surfaceContainerLowest = paletteData.surfaceContainerLowest
        else if (paletteData.surfaceRecessed) surfaceContainerLowest = paletteData.surfaceRecessed

        if (paletteData.surfaceContainerLow) surfaceContainerLow = paletteData.surfaceContainerLow
        else if (paletteData.surfaceBase) surfaceContainerLow = paletteData.surfaceBase

        if (paletteData.surfaceContainer) surfaceContainer = paletteData.surfaceContainer
        else if (paletteData.surfaceSolid) surfaceContainer = paletteData.surfaceSolid

        if (paletteData.surfaceContainerHigh) surfaceContainerHigh = paletteData.surfaceContainerHigh
        else if (paletteData.surfaceElevated) surfaceContainerHigh = paletteData.surfaceElevated

        if (paletteData.surfaceContainerHighest) surfaceContainerHighest = paletteData.surfaceContainerHighest
        else if (paletteData.surfaceHighlight) surfaceContainerHighest = paletteData.surfaceHighlight

        if (paletteData.outline) outline = paletteData.outline
        else if (paletteData.borderSubtle) outline = paletteData.borderSubtle

        if (paletteData.outlineVariant) outlineVariant = paletteData.outlineVariant

        if (paletteData.borderFocus) borderFocus = paletteData.borderFocus
        if (paletteData.textPrimary) textPrimary = paletteData.textPrimary
        if (paletteData.textSecondary) textSecondary = paletteData.textSecondary
        if (paletteData.textMuted) textMuted = paletteData.textMuted
    }
}
