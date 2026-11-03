pragma ComponentBehavior: Bound

// BASEUS — Geometry & Corner Treatment Tokens
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by:
//   - DESIGN.md §9 (Geometry and Corner Treatment)
//   - DESIGN.md §10 (Inverse Corner Radius - ICR)
//   - MASTER.md §10 (Dock is bottom-edge integrated, not floating)
//   - MASTER.md §14 (App Drawer: top corners rounded, bottom flush with edge)
//   - ANTI-SLOP.md §6.3 (Avoid "rounded-everything syndrome")
//
// Corner Philosophy:
//   1. Edge-integrated surfaces meet the display edge flush (radius = 0).
//   2. Exposed outer corners use controlled radii (8–12px).
//   3. Transition between surface and screen perimeter uses Inverse Corner
//      Radius (ICR / organic fillet) so surfaces feel anchored, not pasted on.

import QtQuick

QtObject {
    id: geometry

    // =========================================================
    // Core Corner Radii (Pixels)
    // =========================================================

    // Flush edges (corners meeting the display perimeter)
    readonly property int radiusFlush: 0

    // Small interactive chips, micro tags, status indicators
    readonly property int radiusSmall: 4

    // Default container surface radius (context menus, detached cards)
    readonly property int radiusMedium: 8

    // Major surfaces & dialogs (Command Center, App Drawer upper bounds)
    readonly property int radiusLarge: 12

    // Pills strictly for workspace indicators, badge counts (never cards)
    readonly property int radiusPill: 9999

    // =========================================================
    // Optical Concentric Corner Discipline
    // =========================================================
    // Calculates concentric curvature for inner elements nested within padded containers:
    // R_inner = max(4, R_outer - padding)
    // Note: NEVER applies to screen-bezel-flush edges governed by ICR.
    function concentricRadius(outerRadius: int, padding: int): int {
        return Math.max(radiusSmall, outerRadius - padding)
    }

    // =========================================================
    // Inverse Corner Radius (ICR — DESIGN.md §10)
    // =========================================================
    // The concave/fillet curve that flares outward where an edge-integrated
    // surface meets the screen border, creating an organic architectural seal.
    readonly property int inverseCornerRadius: 12

    // Alias for component readability
    readonly property int icr: inverseCornerRadius

    // =========================================================
    // Surface-Specific Corner Presets (MASTER.md §10, §14)
    // =========================================================

    // Dock: Bottom edge-integrated. Top corners rounded, bottom corners flush.
    readonly property int dockRadiusTop: radiusLarge
    readonly property int dockRadiusBottom: radiusFlush
    readonly property int dockIcr: inverseCornerRadius

    // Top Island: Top edge-integrated. Bottom corners rounded, top corners flush.
    readonly property int islandRadiusTop: radiusFlush
    readonly property int islandRadiusBottom: radiusLarge
    readonly property int islandIcr: inverseCornerRadius

    // App Drawer (MASTER.md §14): Fullscreen, top corners rounded, bottom flush.
    readonly property int drawerRadiusTop: radiusLarge
    readonly property int drawerRadiusBottom: radiusFlush

    // Detached Floating Surfaces: Command Center, OSD, Alt+Tab
    readonly property int floatingRadius: radiusMedium

    // =========================================================
    // Borders & Outlines
    // =========================================================

    // Hairline boundary width (no thick decorative outlines)
    readonly property int borderWidth: 1
}
