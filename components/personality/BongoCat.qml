pragma ComponentBehavior: Bound

// BASEUS — Reactive Bongo Cat Personality Component (M6-01)
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §31, DESIGN.md §33, and ANTI-SLOP.md §37:
//   - "Personality without noise: Personality should appear as character, not clutter."
//   - 5-State reactive machine:
//       * Idle: resting pose, zero background animation timers running (0% idle CPU).
//       * TypingLeft: left paw strike active against desk.
//       * TypingRight: right paw strike active against desk.
//       * Bimanual: rapid typing burst (<120ms interval streak), both paws striking.
//       * AudioBop: rhythmic beat animation synchronized when PipeWire / AudioService is active.
//   - Vector SVG Assets: clean, crisp, 1px stroke vector layers loaded via Image items.
//   - Clamped dimensions: fits strictly within the container / island notch (Theme.geometry.barHeight - 6px).
//   - Strict non-interactive input discipline (0x0 hitmask / acceptedDevices: PointerDevice.None).

import QtQuick
import "../../src/theme" as ThemeModule
import "../../src/core" as CoreModule

Item {
    id: bongoCatRoot

    // =========================================================
    // Dependencies (Injected or Fallback)
    // =========================================================
    property ThemeModule.Theme theme
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: bongoCatRoot.theme ? bongoCatRoot.theme : bongoCatRoot.defaultTheme

    property CoreModule.Config config
    property CoreModule.HyprlandBridge hyprlandBridge
    property CoreModule.AudioService audioService

    // =========================================================
    // Dimensions & Geometry Tokens (Strict Config SoT)
    // =========================================================
    // Dynamic Height-Conscious Size Discipline:
    // Clamped to island's usable height (parent.height or Theme.geometry.barHeight - 6px).
    readonly property int targetHeight: {
        var cfgSize = (bongoCatRoot.config && bongoCatRoot.config.personality && bongoCatRoot.config.personality.bongoCat)
            ? bongoCatRoot.config.personality.bongoCat.size
            : 24
        var maxUsable = (bongoCatRoot.currentTheme && bongoCatRoot.currentTheme.geometry && bongoCatRoot.currentTheme.geometry.barHeight > 0)
            ? (bongoCatRoot.currentTheme.geometry.barHeight - 6)
            : 26
        if (parent && typeof parent.height === "number" && parent.height > 0) {
            maxUsable = Math.min(maxUsable, Math.round(parent.height - 4))
        }
        return Math.min(cfgSize, Math.max(16, maxUsable))
    }

    // Aspect ratio 100:70 from SVG viewBox (0 0 100 70)
    readonly property int targetWidth: Math.round(bongoCatRoot.targetHeight * (100.0 / 70.0))
    readonly property alias bongoSize: bongoCatRoot.targetHeight

    readonly property int decayInterval: (bongoCatRoot.config && bongoCatRoot.config.personality && bongoCatRoot.config.personality.bongoCat)
        ? bongoCatRoot.config.personality.bongoCat.decayTimeout
        : 250

    implicitWidth: bongoCatRoot.targetWidth
    implicitHeight: bongoCatRoot.targetHeight
    width: bongoCatRoot.targetWidth
    height: bongoCatRoot.targetHeight

    // Strict non-interactive telemetry input discipline
    enabled: false
    TapHandler {
        acceptedDevices: PointerDevice.None
    }

    // =========================================================
    // Reactive State Machine
    // =========================================================
    // Valid states: "Idle", "TypingLeft", "TypingRight", "Bimanual", "AudioBop"
    property string currentState: "Idle"

    property real lastKeyPressTime: 0.0
    property int keyStreak: 0
    property int bopStep: 0
    property real bopOffset: 0.0

    readonly property bool leftPawActive: bongoCatRoot.currentState === "TypingLeft"
        || bongoCatRoot.currentState === "Bimanual"
        || (bongoCatRoot.currentState === "AudioBop" && bongoCatRoot.bopStep === 0)

    readonly property bool rightPawActive: bongoCatRoot.currentState === "TypingRight"
        || bongoCatRoot.currentState === "Bimanual"
        || (bongoCatRoot.currentState === "AudioBop" && bongoCatRoot.bopStep === 1)

    // Paw vertical displacement: resting on desk when striking (0), lifted when inactive (-lift)
    readonly property real pawLiftDistance: Math.max(2.0, bongoCatRoot.targetHeight * 0.12)

    readonly property real leftPawY: {
        if (bongoCatRoot.currentState === "Idle") return 0.0
        return bongoCatRoot.leftPawActive ? 0.0 : -bongoCatRoot.pawLiftDistance
    }

    readonly property real rightPawY: {
        if (bongoCatRoot.currentState === "Idle") return 0.0
        return bongoCatRoot.rightPawActive ? 0.0 : -bongoCatRoot.pawLiftDistance
    }

    // =========================================================
    // Timers (Decay & Audio Bop)
    // Strict Anti-Slop Rule: Zero timers run while Idle or Unmapped
    // =========================================================

    // Inactivity Decay Timer: returns to Idle after 250ms of silence
    Timer {
        id: decayTimer
        interval: bongoCatRoot.decayInterval
        repeat: false
        running: false
        onTriggered: {
            bongoCatRoot._onDecayTimeout()
        }
    }

    // Audio Bop Timer: ~130 BPM rhythmic beat (~230ms per half beat)
    Timer {
        id: audioBopTimer
        interval: 230
        repeat: true
        running: bongoCatRoot.visible && bongoCatRoot.currentState === "AudioBop"
        onTriggered: {
            bongoCatRoot.bopStep = (bongoCatRoot.bopStep + 1) % 2
            bongoCatRoot.bopOffset = (bongoCatRoot.bopStep === 0) ? -2.0 : 0.0
        }
    }

    // =========================================================
    // IPC & Telemetry Listeners
    // =========================================================

    Connections {
        target: bongoCatRoot.hyprlandBridge ? bongoCatRoot.hyprlandBridge : null

        function onKeyActivity() {
            if (bongoCatRoot.visible) {
                bongoCatRoot.registerKeyActivity()
            }
        }

        function onKeypressTickChanged() {
            if (bongoCatRoot.visible) {
                bongoCatRoot.registerKeyActivity()
            }
        }

        function onActiveSubmapChanged() {
            if (bongoCatRoot.visible) {
                bongoCatRoot.registerKeyActivity()
            }
        }
    }

    Connections {
        target: bongoCatRoot.audioService ? bongoCatRoot.audioService : null

        function onAudioChanged() {
            if (bongoCatRoot.visible && (bongoCatRoot.currentState === "Idle" || bongoCatRoot.currentState === "AudioBop")) {
                bongoCatRoot._checkAudioFallback()
            }
        }
    }

    // =========================================================
    // Lifecycle & Transition Logic
    // =========================================================

    function registerKeyActivity(): void {
        var now = Date.now()
        var delta = now - bongoCatRoot.lastKeyPressTime
        bongoCatRoot.lastKeyPressTime = now

        // Check for rapid typing streak (<=120ms threshold, 3+ rapid strokes triggers Bimanual)
        if (delta >= 0 && delta <= 120) {
            bongoCatRoot.keyStreak++
            if (bongoCatRoot.keyStreak >= 3) {
                bongoCatRoot.currentState = "Bimanual"
            } else {
                bongoCatRoot.currentState = (bongoCatRoot.currentState === "TypingLeft") ? "TypingRight" : "TypingLeft"
            }
        } else {
            bongoCatRoot.keyStreak = 1
            bongoCatRoot.currentState = (bongoCatRoot.currentState === "TypingLeft") ? "TypingRight" : "TypingLeft"
        }

        // Halt audio bop timer during active typing
        audioBopTimer.stop()
        bongoCatRoot.bopOffset = 0.0

        // Restart decay timeout
        decayTimer.restart()
    }

    function _onDecayTimeout(): void {
        bongoCatRoot.keyStreak = 0
        if (bongoCatRoot._isAudioActive()) {
            bongoCatRoot.currentState = "AudioBop"
            bongoCatRoot.bopStep = 0
            bongoCatRoot.bopOffset = 0.0
            audioBopTimer.start()
        } else {
            bongoCatRoot.currentState = "Idle"
            audioBopTimer.stop()
            bongoCatRoot.bopOffset = 0.0
        }
    }

    function _checkAudioFallback(): void {
        if (!bongoCatRoot.visible) return

        if (bongoCatRoot.currentState === "Idle" && bongoCatRoot._isAudioActive()) {
            bongoCatRoot.currentState = "AudioBop"
            bongoCatRoot.bopStep = 0
            bongoCatRoot.bopOffset = 0.0
            audioBopTimer.start()
        } else if (bongoCatRoot.currentState === "AudioBop" && !bongoCatRoot._isAudioActive()) {
            bongoCatRoot.currentState = "Idle"
            audioBopTimer.stop()
            bongoCatRoot.bopOffset = 0.0
        }
    }

    function _isAudioActive(): bool {
        if (!bongoCatRoot.audioService) return false
        return bongoCatRoot.audioService.isAudioActive
    }

    onVisibleChanged: {
        if (!bongoCatRoot.visible) {
            decayTimer.stop()
            audioBopTimer.stop()
            bongoCatRoot.currentState = "Idle"
            bongoCatRoot.bopOffset = 0.0
        } else {
            bongoCatRoot._checkAudioFallback()
        }
    }

    Component.onDestruction: {
        decayTimer.stop()
        audioBopTimer.stop()
    }

    // =========================================================
    // SVG Vector Layers (Base, Left Paw, Right Paw)
    // =========================================================

    // 1. Base Body & Desk Layer
    Image {
        id: baseImage
        anchors.fill: parent
        source: Qt.resolvedUrl("../../assets/personality/bongo-cat/base.svg")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        sourceSize.width: bongoCatRoot.targetWidth
        sourceSize.height: bongoCatRoot.targetHeight

        transform: Translate {
            y: bongoCatRoot.bopOffset
            Behavior on y {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    // 2. Left Paw Layer
    Image {
        id: leftPawImage
        anchors.fill: parent
        source: Qt.resolvedUrl("../../assets/personality/bongo-cat/paw_left.svg")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        sourceSize.width: bongoCatRoot.targetWidth
        sourceSize.height: bongoCatRoot.targetHeight

        transform: Translate {
            y: bongoCatRoot.leftPawY + (bongoCatRoot.currentState === "AudioBop" ? bongoCatRoot.bopOffset * 0.5 : 0.0)
            Behavior on y {
                NumberAnimation {
                    duration: 65
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    // 3. Right Paw Layer
    Image {
        id: rightPawImage
        anchors.fill: parent
        source: Qt.resolvedUrl("../../assets/personality/bongo-cat/paw_right.svg")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        sourceSize.width: bongoCatRoot.targetWidth
        sourceSize.height: bongoCatRoot.targetHeight

        transform: Translate {
            y: bongoCatRoot.rightPawY + (bongoCatRoot.currentState === "AudioBop" ? bongoCatRoot.bopOffset * 0.5 : 0.0)
            Behavior on y {
                NumberAnimation {
                    duration: 65
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    // =========================================================
    // Diagnostic State API
    // =========================================================
    function getDiagnosticState(): string {
        return "State: " + bongoCatRoot.currentState +
               " | Size: " + bongoCatRoot.targetWidth + "x" + bongoCatRoot.targetHeight + "px" +
               " | LeftPaw: " + (bongoCatRoot.leftPawActive ? "DOWN/STRIKE" : "UP") +
               " | RightPaw: " + (bongoCatRoot.rightPawActive ? "DOWN/STRIKE" : "UP") +
               " | Streak: " + bongoCatRoot.keyStreak +
               " | Decay: " + decayTimer.running +
               " | Bop: " + audioBopTimer.running
    }
}
