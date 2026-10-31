// BASEUS — Bongo Cat Visual Companion
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §31, DESIGN.md §33, and ANTI-SLOP.md §37:
//   - "Personality without noise: Personality should appear as character, not clutter."
//   - Contextual reaction:
//       * Playing: Alternates paw taps with rhythmic timing synced to active playback.
//       * Paused / Stopped: Immediately returns to a resting pose and halts all animation timers
//         (ZERO idle CPU consumption).
//   - Rendered using clean vector/token shapes adapting dynamically to palette shifts.
//   - Solid surfaces, zero blur, zero glassmorphism, zero drop shadows.

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: bongoCat

    // =========================================================
    // Dependencies & Properties
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: bongoCat.theme ? bongoCat.theme : bongoCat.defaultTheme

    property bool isPlaying: false
    property int tapInterval: 220 // ms per tap (~136 BPM rhythm)

    implicitWidth: 104
    implicitHeight: 64
    width: 104
    height: 64

    // =========================================================
    // Dynamic Paw State Machine
    // =========================================================
    property bool leftPawDown: true
    property bool rightPawDown: true
    property int _tapStep: 0

    // Strict Anti-Slop Rule: Timer runs ONLY during active playback.
    // When paused or stopped, timer halts immediately (0% idle CPU).
    Timer {
        id: tapTimer
        interval: bongoCat.tapInterval
        repeat: true
        running: bongoCat.isPlaying
        onTriggered: {
            bongoCat._tapStep = (bongoCat._tapStep + 1) % 2
            if (bongoCat._tapStep === 0) {
                bongoCat.leftPawDown = true
                bongoCat.rightPawDown = false
            } else {
                bongoCat.leftPawDown = false
                bongoCat.rightPawDown = true
            }
        }
    }

    onIsPlayingChanged: {
        if (!bongoCat.isPlaying) {
            // Immediately settle to resting pose
            bongoCat.leftPawDown = true
            bongoCat.rightPawDown = true
            bongoCat._tapStep = 0
        }
    }

    // =========================================================
    // Geometry & Silhouette Rendering
    // =========================================================

    // 1. Desk / Keyboard Platform
    Rectangle {
        id: deskPlatform
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 16
        radius: bongoCat.currentTheme.geometry.radiusSmall
        color: bongoCat.currentTheme.colors.surfaceRecessed
        border.width: 1
        border.color: bongoCat.currentTheme.colors.borderSubtle

        // Left bongo / drum pad
        Rectangle {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 8
            radius: 4
            color: bongoCat.leftPawDown && bongoCat.isPlaying
                ? bongoCat.currentTheme.colors.surfaceHighlight
                : bongoCat.currentTheme.colors.surfaceSolid
            border.width: 1
            border.color: bongoCat.currentTheme.colors.borderSubtle
        }

        // Right bongo / drum pad
        Rectangle {
            x: 64
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 8
            radius: 4
            color: bongoCat.rightPawDown && bongoCat.isPlaying
                ? bongoCat.currentTheme.colors.surfaceHighlight
                : bongoCat.currentTheme.colors.surfaceSolid
            border.width: 1
            border.color: bongoCat.currentTheme.colors.borderSubtle
        }
    }

    // 2. Ears
    // Left ear
    Rectangle {
        id: leftEar
        x: catHead.x + 4
        y: catHead.y - 6
        width: 14
        height: 14
        rotation: -20
        radius: 3
        color: bongoCat.currentTheme.colors.surfaceElevated
        border.width: 1
        border.color: bongoCat.currentTheme.colors.borderSubtle

        // Inner ear accent
        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 2
            color: bongoCat.currentTheme.colors.dominant
            opacity: 0.35
        }
    }

    // Right ear
    Rectangle {
        id: rightEar
        x: catHead.x + catHead.width - 18
        y: catHead.y - 6
        width: 14
        height: 14
        rotation: 20
        radius: 3
        color: bongoCat.currentTheme.colors.surfaceElevated
        border.width: 1
        border.color: bongoCat.currentTheme.colors.borderSubtle

        // Inner ear accent
        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 2
            color: bongoCat.currentTheme.colors.dominant
            opacity: 0.35
        }
    }

    // 3. Cat Head & Body Silhouette
    Rectangle {
        id: catHead
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: deskPlatform.top
        anchors.bottomMargin: -6
        width: 64
        height: 38
        radius: 19
        color: bongoCat.currentTheme.colors.surfaceElevated
        border.width: 1
        border.color: bongoCat.currentTheme.colors.borderSubtle

        // Face Details
        // Left Eye
        Rectangle {
            x: 18
            y: bongoCat.isPlaying ? 14 : 16
            width: 4
            height: bongoCat.isPlaying ? 5 : 2
            radius: bongoCat.isPlaying ? 2 : 1
            color: bongoCat.currentTheme.colors.textPrimary
        }

        // Right Eye
        Rectangle {
            x: 42
            y: bongoCat.isPlaying ? 14 : 16
            width: 4
            height: bongoCat.isPlaying ? 5 : 2
            radius: bongoCat.isPlaying ? 2 : 1
            color: bongoCat.currentTheme.colors.textPrimary
        }

        // Left Blush Cheek
        Rectangle {
            x: 12
            y: 20
            width: 6
            height: 3
            radius: 2
            color: bongoCat.currentTheme.colors.accent
            opacity: 0.4
        }

        // Right Blush Cheek
        Rectangle {
            x: 46
            y: 20
            width: 6
            height: 3
            radius: 2
            color: bongoCat.currentTheme.colors.accent
            opacity: 0.4
        }

        // Snout
        Rectangle {
            x: 30
            y: 17
            width: 4
            height: 2
            radius: 1
            color: bongoCat.currentTheme.colors.textSecondary
        }
    }

    // 4. Animated Paws
    // Left Paw
    Rectangle {
        id: leftPaw
        x: catHead.x + 10
        y: bongoCat.leftPawDown ? (deskPlatform.y - 2) : (deskPlatform.y - 12)
        width: 14
        height: 10
        radius: 5
        color: bongoCat.currentTheme.colors.surfaceHighlight
        border.width: 1
        border.color: bongoCat.currentTheme.colors.borderSubtle
        z: 3

        Behavior on y {
            NumberAnimation {
                duration: bongoCat.currentTheme.motion.durationFast
                easing.type: bongoCat.currentTheme.motion.easingStandard
            }
        }
    }

    // Right Paw
    Rectangle {
        id: rightPaw
        x: catHead.x + 40
        y: bongoCat.rightPawDown ? (deskPlatform.y - 2) : (deskPlatform.y - 12)
        width: 14
        height: 10
        radius: 5
        color: bongoCat.currentTheme.colors.surfaceHighlight
        border.width: 1
        border.color: bongoCat.currentTheme.colors.borderSubtle
        z: 3

        Behavior on y {
            NumberAnimation {
                duration: bongoCat.currentTheme.motion.durationFast
                easing.type: bongoCat.currentTheme.motion.easingStandard
            }
        }
    }

    // =========================================================
    // Diagnostic State
    // =========================================================
    function getSnapshot(): var {
        return {
            isPlaying: bongoCat.isPlaying,
            timerRunning: tapTimer.running,
            leftPawDown: bongoCat.leftPawDown,
            rightPawDown: bongoCat.rightPawDown,
            resting: !bongoCat.isPlaying,
            width: bongoCat.width,
            height: bongoCat.height
        }
    }
}

