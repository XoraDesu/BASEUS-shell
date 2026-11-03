pragma ComponentBehavior: Bound

// BASEUS — Constellation Visual Geometry Transition (M6-02)
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §32, DESIGN.md §31, and ANTI-SLOP.md §37:
//   - Visual geometry transition for PowerMenu confirmations and session lock states.
//   - Pure vector nodes (Rectangle points, 2x2 to 4x4px) and interconnecting lines (QtQuick.Shapes).
//   - Zero shaders, zero blur, zero particle physics engines.
//   - Deterministic motion: 8 procedural nodes moving along fixed trajectory vectors (duration <= 350ms, OutCubic).
//   - Strict CPU discipline: zero running timers or physics loops when idle or opacity === 0.0.
//   - Strict palette tokens: Theme.palette.primary, Theme.palette.outline, Theme.palette.surfaceVariant.
//   - Strictly pass-through input mask (0x0 hitmask / acceptedDevices: PointerDevice.None).

import QtQuick
import QtQuick.Shapes
import "../../src/theme" as ThemeModule
import "../../src/core" as CoreModule

Item {
    id: constellationRoot

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property ThemeModule.Theme theme
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: constellationRoot.theme ? constellationRoot.theme : constellationRoot.defaultTheme

    property CoreModule.Config config

    // =========================================================
    // Motion Parameters (Strict Config SoT)
    // =========================================================
    property bool active: false
    property real progress: 0.0

    readonly property int duration: (constellationRoot.config && constellationRoot.config.personality && constellationRoot.config.personality.constellation)
        ? constellationRoot.config.personality.constellation.duration
        : 350

    readonly property int nodeCount: (constellationRoot.config && constellationRoot.config.personality && constellationRoot.config.personality.constellation)
        ? constellationRoot.config.personality.constellation.nodeCount
        : 8

    // Input Discipline: non-interactive telemetry & visual layer
    enabled: false
    TapHandler {
        acceptedDevices: PointerDevice.None
    }

    // State Visibility Gating: completely invisible and un-rendered when inactive
    visible: constellationRoot.active && constellationRoot.opacity > 0.0
    opacity: constellationRoot.active ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // =========================================================
    // One-Shot Deterministic Motion Animation
    // =========================================================
    NumberAnimation {
        id: motionAnimation
        target: constellationRoot
        property: "progress"
        from: 0.0
        to: 1.0
        duration: constellationRoot.duration
        easing.type: Easing.OutCubic
        running: false
    }

    onActiveChanged: {
        if (constellationRoot.active) {
            motionAnimation.restart()
        } else {
            motionAnimation.stop()
            constellationRoot.progress = 0.0
        }
    }

    onVisibleChanged: {
        if (!constellationRoot.visible) {
            motionAnimation.stop()
            constellationRoot.progress = 0.0
        }
    }

    Component.onDestruction: {
        motionAnimation.stop()
    }

    // =========================================================
    // Fixed Procedural Vertices (Deterministic Trajectory Math)
    // =========================================================
    readonly property real n0x: constellationRoot.width * (0.16 + (0.24 - 0.16) * constellationRoot.progress)
    readonly property real n0y: constellationRoot.height * (0.22 + (0.36 - 0.22) * constellationRoot.progress)

    readonly property real n1x: constellationRoot.width * (0.36 + (0.42 - 0.36) * constellationRoot.progress)
    readonly property real n1y: constellationRoot.height * (0.14 + (0.26 - 0.14) * constellationRoot.progress)

    readonly property real n2x: constellationRoot.width * (0.64 + (0.58 - 0.64) * constellationRoot.progress)
    readonly property real n2y: constellationRoot.height * (0.16 + (0.28 - 0.16) * constellationRoot.progress)

    readonly property real n3x: constellationRoot.width * (0.84 + (0.76 - 0.84) * constellationRoot.progress)
    readonly property real n3y: constellationRoot.height * (0.26 + (0.40 - 0.26) * constellationRoot.progress)

    readonly property real n4x: constellationRoot.width * (0.80 + (0.70 - 0.80) * constellationRoot.progress)
    readonly property real n4y: constellationRoot.height * (0.76 + (0.64 - 0.76) * constellationRoot.progress)

    readonly property real n5x: constellationRoot.width * (0.56 + (0.50 - 0.56) * constellationRoot.progress)
    readonly property real n5y: constellationRoot.height * (0.84 + (0.72 - 0.84) * constellationRoot.progress)

    readonly property real n6x: constellationRoot.width * (0.34 + (0.38 - 0.34) * constellationRoot.progress)
    readonly property real n6y: constellationRoot.height * (0.80 + (0.66 - 0.80) * constellationRoot.progress)

    readonly property real n7x: constellationRoot.width * (0.14 + (0.22 - 0.14) * constellationRoot.progress)
    readonly property real n7y: constellationRoot.height * (0.68 + (0.54 - 0.68) * constellationRoot.progress)

    // =========================================================
    // Interconnecting Vector Lines (QtQuick.Shapes)
    // =========================================================
    Shape {
        id: constellationLines
        anchors.fill: parent
        asynchronous: false
        visible: constellationRoot.visible

        // Outer polygon perimeter
        ShapePath {
            strokeWidth: 1
            strokeColor: constellationRoot.currentTheme.palette.outline
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: constellationRoot.n0x; startY: constellationRoot.n0y
            PathLine { x: constellationRoot.n1x; y: constellationRoot.n1y }
            PathLine { x: constellationRoot.n2x; y: constellationRoot.n2y }
            PathLine { x: constellationRoot.n3x; y: constellationRoot.n3y }
            PathLine { x: constellationRoot.n4x; y: constellationRoot.n4y }
            PathLine { x: constellationRoot.n5x; y: constellationRoot.n5y }
            PathLine { x: constellationRoot.n6x; y: constellationRoot.n6y }
            PathLine { x: constellationRoot.n7x; y: constellationRoot.n7y }
            PathLine { x: constellationRoot.n0x; y: constellationRoot.n0y }
        }

        // Inner harmonic structural cross-ties
        ShapePath {
            strokeWidth: 1
            strokeColor: constellationRoot.currentTheme.palette.outline
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: constellationRoot.n1x; startY: constellationRoot.n1y
            PathLine { x: constellationRoot.n6x; y: constellationRoot.n6y }
        }

        ShapePath {
            strokeWidth: 1
            strokeColor: constellationRoot.currentTheme.palette.outline
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: constellationRoot.n2x; startY: constellationRoot.n2y
            PathLine { x: constellationRoot.n5x; y: constellationRoot.n5y }
        }

        ShapePath {
            strokeWidth: 1
            strokeColor: constellationRoot.currentTheme.palette.outline
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: constellationRoot.n0x; startY: constellationRoot.n0y
            PathLine { x: constellationRoot.n4x; y: constellationRoot.n4y }
        }
    }

    // =========================================================
    // Procedural Star Nodes (2x2 to 4x4px Solid Geometries)
    // =========================================================
    Rectangle {
        x: Math.round(constellationRoot.n0x - width / 2)
        y: Math.round(constellationRoot.n0y - height / 2)
        width: 4
        height: 4
        radius: 1
        color: constellationRoot.currentTheme.palette.primary
        border.width: 1
        border.color: constellationRoot.currentTheme.palette.outline
    }

    Rectangle {
        x: Math.round(constellationRoot.n1x - width / 2)
        y: Math.round(constellationRoot.n1y - height / 2)
        width: 3
        height: 3
        radius: 1
        color: constellationRoot.currentTheme.palette.surfaceVariant
        border.width: 1
        border.color: constellationRoot.currentTheme.palette.outline
    }

    Rectangle {
        x: Math.round(constellationRoot.n2x - width / 2)
        y: Math.round(constellationRoot.n2y - height / 2)
        width: 4
        height: 4
        radius: 1
        color: constellationRoot.currentTheme.palette.primary
        border.width: 1
        border.color: constellationRoot.currentTheme.palette.outline
    }

    Rectangle {
        x: Math.round(constellationRoot.n3x - width / 2)
        y: Math.round(constellationRoot.n3y - height / 2)
        width: 3
        height: 3
        radius: 1
        color: constellationRoot.currentTheme.palette.surfaceVariant
        border.width: 1
        border.color: constellationRoot.currentTheme.palette.outline
    }

    Rectangle {
        x: Math.round(constellationRoot.n4x - width / 2)
        y: Math.round(constellationRoot.n4y - height / 2)
        width: 4
        height: 4
        radius: 1
        color: constellationRoot.currentTheme.palette.primary
        border.width: 1
        border.color: constellationRoot.currentTheme.palette.outline
    }

    Rectangle {
        x: Math.round(constellationRoot.n5x - width / 2)
        y: Math.round(constellationRoot.n5y - height / 2)
        width: 3
        height: 3
        radius: 1
        color: constellationRoot.currentTheme.palette.surfaceVariant
        border.width: 1
        border.color: constellationRoot.currentTheme.palette.outline
    }

    Rectangle {
        x: Math.round(constellationRoot.n6x - width / 2)
        y: Math.round(constellationRoot.n6y - height / 2)
        width: 4
        height: 4
        radius: 1
        color: constellationRoot.currentTheme.palette.primary
        border.width: 1
        border.color: constellationRoot.currentTheme.palette.outline
    }

    Rectangle {
        x: Math.round(constellationRoot.n7x - width / 2)
        y: Math.round(constellationRoot.n7y - height / 2)
        width: 3
        height: 3
        radius: 1
        color: constellationRoot.currentTheme.palette.surfaceVariant
        border.width: 1
        border.color: constellationRoot.currentTheme.palette.outline
    }

    // =========================================================
    // Diagnostic State API
    // =========================================================
    function getDiagnosticSnapshot(): string {
        return "Constellation: active=" + constellationRoot.active +
               " | progress=" + constellationRoot.progress.toFixed(2) +
               " | animating=" + motionAnimation.running +
               " | duration=" + constellationRoot.duration + "ms"
    }
}

