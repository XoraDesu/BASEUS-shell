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
    // Tonal Hierarchy — Surfaces (Solid Preference, DESIGN.md §8)
    // =========================================================
    // No glassmorphism, blur abuse, or unnecessary gradients.

    // Deepest background canvas (screen root behind surfaces)
    property color surfaceBase: "#16161e"

    // Standard solid surface container (Dock, Top Island, Drawer panels)
    property color surfaceSolid: "#1f2335"

    // Elevated surface (contextual help bubbles, dropdowns, detached dialogs)
    property color surfaceElevated: "#24283b"

    // Recessed / Sunken surface (search inputs, inactive indicator wells)
    property color surfaceRecessed: "#13131a"

    // Interactive hover / active tint on surfaces
    property color surfaceHighlight: "#292e42"

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

    // Subtle 1px boundary line for structural separation
    property color borderSubtle: "#292e42"

    // Distinct boundary for focused or active interactive elements
    property color borderFocus: "#7aa2f7"

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

        // Optional surface overrides from Matugen
        if (paletteData.surfaceBase) surfaceBase = paletteData.surfaceBase
        if (paletteData.surfaceSolid) surfaceSolid = paletteData.surfaceSolid
        if (paletteData.surfaceElevated) surfaceElevated = paletteData.surfaceElevated
        if (paletteData.surfaceRecessed) surfaceRecessed = paletteData.surfaceRecessed
        if (paletteData.surfaceHighlight) surfaceHighlight = paletteData.surfaceHighlight
        if (paletteData.borderSubtle) borderSubtle = paletteData.borderSubtle
        if (paletteData.textPrimary) textPrimary = paletteData.textPrimary
        if (paletteData.textSecondary) textSecondary = paletteData.textSecondary
        if (paletteData.textMuted) textMuted = paletteData.textMuted
    }
}
