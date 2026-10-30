pragma ComponentBehavior: Bound

// BASEUS — Spacing Tokens
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by DESIGN.md §3, §37 and ANTI-SLOP.md §12:
//   - Whitespace is an active design choice (Wabi-sabi)
//   - Hierarchy and grouping through spacing over nested card containers
//   - Consistent mathematical rhythm (4px/8px base)

import QtQuick

QtObject {
    id: spacing

    // =========================================================
    // Core Spacing Scale (Pixels)
    // =========================================================

    readonly property int xxs: 2
    readonly property int xs: 4
    readonly property int sm: 8
    readonly property int md: 12
    readonly property int lg: 16
    readonly property int xl: 24
    readonly property int xxl: 32
    readonly property int giant: 48

    // =========================================================
    // Semantic Layout Margins & Padding
    // =========================================================

    // Distance of floating/edge-attached surfaces from screen perimeter
    readonly property int edgeMargin: 16

    // Internal surface padding for Dock and Top Island
    readonly property int surfacePaddingHorizontal: 12
    readonly property int surfacePaddingVertical: 8

    // Internal padding for detached popups and drawers
    readonly property int dialogPadding: 16

    // Spacing between adjacent interactive items in lists/trays
    readonly property int itemSpacing: 8

    // Breathing room around emphasized landmarks
    readonly property int contextGutter: 24
}
