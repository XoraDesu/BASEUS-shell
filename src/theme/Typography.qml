// BASEUS — Typography Tokens
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by DESIGN.md §26 and ANTI-SLOP.md §10:
//   - Typography is a primary design tool, not decorative noise
//   - Editorial / archival structural influence
//   - Clear functional scale: display → micro
//   - Monospace reserved for telemetry, workspace indicators, and tags

import QtQuick

QtObject {
    id: typography

    // =========================================================
    // Font Families
    // =========================================================

    // Clean, legible UI sans for general shell interfaces (Roboto preferred)
    property string fontFamily: "Roboto, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif"

    // Monospaced font for clocks, workspace numbers, indices, and telemetry
    property string fontFamilyMono: "'Roboto Mono', 'JetBrains Mono', 'Fira Code', Consolas, monospace"

    // Editorial display font for major landmarks (Power Menu, Header)
    property string fontFamilyDisplay: "Roboto, sans-serif"

    // =========================================================
    // Type Scale (Pixels)
    // =========================================================

    // Large landmarks, clock, power menu constellation
    readonly property int sizeDisplay: 24

    // Section headings, App Drawer titles
    readonly property int sizeHeadline: 18

    // Component headers, cardless grouping labels, dialog titles
    readonly property int sizeTitle: 14

    // Standard body text, app labels, menu items
    readonly property int sizeBody: 13

    // Secondary metadata, hotkey hints, tooltips
    readonly property int sizeCaption: 11

    // Monospaced indicators, subtle archival tags, timestamps
    readonly property int sizeMicro: 9

    // =========================================================
    // Font Weights
    // =========================================================

    readonly property int weightLight: Font.Light       // 300
    readonly property int weightRegular: Font.Normal     // 400
    readonly property int weightMedium: Font.Medium     // 500
    readonly property int weightBold: Font.Bold         // 700

    // =========================================================
    // Letter Spacing
    // =========================================================

    // Tight tracking for large display headers
    readonly property real letterSpacingDisplay: -0.5

    // Standard tracking
    readonly property real letterSpacingNormal: 0.0

    // Expanded tracking for uppercase tags and editorial metadata
    readonly property real letterSpacingCaps: 0.8
}
