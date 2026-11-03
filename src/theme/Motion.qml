pragma ComponentBehavior: Bound

// BASEUS — Motion Tokens & Animation Curves
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by DESIGN.md §6, §39 and ANTI-SLOP.md §7:
//   - Motion restraint: animation exists to communicate causality, not spectacle
//   - "Focus grows, context recedes"
//   - Crisp decelerate/accelerate curves: zero oscillating bounce (OutBack/OutElastic forbidden)
//   - Immediate Layer-Shell 0x0 hitmask contraction on exit
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

    // Micro-interactions: hover highlights, press states, border tint, state layers
    readonly property int durationMicro: reducedMotion ? 0 : 90

    // Fast exit / collapse transitions: rapid clean retraction (130ms–150ms)
    readonly property int durationFast: reducedMotion ? 0 : 140

    // Standard enter / expand transitions: calm landing, zero overshoot (200ms–220ms)
    readonly property int durationNormal: reducedMotion ? 0 : 210

    // Structural transitions: App Drawer slide, Command Center open, Headquarter curtain
    readonly property int durationSlow: reducedMotion ? 0 : 300

    // Visual state crossfades: Theme palette transition
    readonly property int durationTheme: reducedMotion ? 0 : 400

    // =========================================================
    // Easing Curves (Crisp Decelerate / Accelerate)
    // =========================================================

    // Standard balanced transition
    readonly property int easingStandard: Easing.InOutQuad

    // Enter / Expand: Fast initial response, calm Wabi-Sabi landing, zero overshoot
    readonly property int easingEnter: Easing.OutCubic

    // Exit / Collapse: Rapid clean retraction so mask contracts to 0x0 without blocking
    readonly property int easingExit: Easing.InCubic

    // Micro-state transitions: Smooth micro-transitions for hover / press / borders
    readonly property int easingMicro: Easing.OutQuad

    // Aliases for backward compatibility
    readonly property int easingFocus: easingEnter
    readonly property int easingRecede: easingExit

    // Non-oscillating curve enforcing hitmask safety (OutBack/OutBounce forbidden by ANTI-SLOP)
    readonly property int easingSpring: Easing.OutCubic

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
