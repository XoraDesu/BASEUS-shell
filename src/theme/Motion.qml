// BASEUS — Motion Tokens & Animation Curves
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by DESIGN.md §6, §39 and ANTI-SLOP.md §7:
//   - Motion restraint: animation exists to communicate causality, not spectacle
//   - "Focus grows, context recedes"
//   - Fast, responsive execution (120–200ms default)
//   - Support for reduced motion accessibility

import QtQuick

QtObject {
    id: motion

    // =========================================================
    // Reduced Motion Accessibility
    // =========================================================
    property bool reducedMotion: false

    // =========================================================
    // Animation Durations (Milliseconds)
    // =========================================================

    // Instant / zero duration for reduced motion or instantaneous feedback
    readonly property int durationInstant: 0

    // Micro-interactions: hover highlights, press states, icon color shift
    readonly property int durationFast: reducedMotion ? 0 : 120

    // Standard transitions: Dock reveal, Top Island expand, tooltip pop
    readonly property int durationNormal: reducedMotion ? 0 : 200

    // Structural transitions: App Drawer slide, Command Center open
    readonly property int durationSlow: reducedMotion ? 0 : 300

    // Visual state crossfades: Theme palette transition
    readonly property int durationTheme: reducedMotion ? 0 : 400

    // =========================================================
    // Easing Curves
    // =========================================================

    // Standard balanced transition
    readonly property int easingStandard: Easing.InOutQuad

    // Focus grows smoothly and settles briskly
    readonly property int easingFocus: Easing.OutCubic

    // Inactive context recedes into background
    readonly property int easingRecede: Easing.InCubic

    // Gentle bounce for small physical feedback (used sparingly)
    readonly property int easingSpring: Easing.OutBack

    // =========================================================
    // Spatial Scale & Opacity ("Focus grows, context recedes")
    // =========================================================

    // Focused active element scales subtly upward
    readonly property real focusScale: 1.02

    // Background/inactive context scales subtly downward
    readonly property real recedeScale: 0.98

    // Background context dims slightly to enhance focus readability
    readonly property real recedeOpacity: 0.60
}
