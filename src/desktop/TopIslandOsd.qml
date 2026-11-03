// BASEUS — Top Island System OSD
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §33, DESIGN.md §32–33, DEC-021, and ANTI-SLOP.md §20:
//   - Originates from Top Island with a "bubble-drop" transition
//   - Drops smoothly below the top notch, communicates feedback, auto-collapses back
//   - Rapid repeated events morph/update in place without animation queue pile-up
//   - Direct readable typography ("VOLUME" / "72%", "BRIGHTNESS" / "60%", "MUTED")
//   - Solid Wabi-sabi surface (surfaceSolid + borderSubtle), zero blur, zero drop shadows
//   - Non-blocking: 100% click-through (pointer events pass straight through to windows)

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: topIslandOsd

    // =========================================================
    // Dependencies & Properties
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: topIslandOsd.theme ? topIslandOsd.theme : topIslandOsd.defaultTheme

    property string osdType: "volume"
    property real value: 0.72
    property bool isMuted: false
    property bool active: false
    property int restingY: 38

    readonly property int percent: Math.round(topIslandOsd.value * 100)
    readonly property int displayTimeoutMs: 1800

    // Non-blocking hitmask: zero mouse capture so desktop underneath stays click-through
    enabled: false

    // Geometry
    width: 220
    height: 42
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    y: topIslandOsd.restingY

    // Visibility
    opacity: 0.0
    visible: opacity > 0.0

    transform: [
        Translate {
            id: dropTranslate
            y: 0
        },
        Scale {
            id: dropScale
            origin.x: topIslandOsd.width / 2
            origin.y: 0
            xScale: 1.0
            yScale: 1.0
        }
    ]

    // =========================================================
    // OSD Surface & Layout (Solid Wabi-sabi, ANTI-SLOP.md)
    // =========================================================
    Rectangle {
        id: surfaceRect
        anchors.fill: parent
        radius: topIslandOsd.currentTheme.geometry.radiusLarge
        color: topIslandOsd.currentTheme.colors.surfaceContainerHighest
        border.width: 1
        border.color: topIslandOsd.isMuted
            ? topIslandOsd.currentTheme.colors.statusWarning
            : topIslandOsd.currentTheme.colors.outline
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 7
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 5

            // Typography Row: Label & Value / Mute Status
            Row {
                width: parent.width

                Text {
                    text: topIslandOsd.osdType === "brightness" ? "BRIGHTNESS" : "VOLUME"
                    font.pixelSize: topIslandOsd.currentTheme.typography.sizeMicro
                    font.letterSpacing: topIslandOsd.currentTheme.typography.letterSpacingCaps
                    font.bold: true
                    font.family: topIslandOsd.currentTheme.typography.fontFamilyMono
                    color: topIslandOsd.isMuted
                        ? topIslandOsd.currentTheme.colors.statusWarning
                        : topIslandOsd.currentTheme.colors.textMuted
                }

                Item {
                    // Flexible spacer
                    width: Math.max(0, parent.width - parent.children[0].implicitWidth - valueLabel.implicitWidth)
                    height: 1
                }

                Text {
                    id: valueLabel
                    text: topIslandOsd.isMuted ? "MUTED" : (topIslandOsd.percent + "%")
                    font.pixelSize: topIslandOsd.currentTheme.typography.sizeMicro
                    font.bold: true
                    font.family: topIslandOsd.currentTheme.typography.fontFamilyMono
                    color: topIslandOsd.isMuted
                        ? topIslandOsd.currentTheme.colors.statusWarning
                        : topIslandOsd.currentTheme.colors.textPrimary
                }
            }

            // Restrained Solid Linear Bar
            Rectangle {
                id: trackRect
                width: parent.width
                height: 4
                radius: 2
                color: topIslandOsd.currentTheme.colors.surfaceHighlight

                Rectangle {
                    id: fillRect
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: 2
                    width: Math.round(trackRect.width * topIslandOsd.value)
                    color: topIslandOsd.isMuted
                        ? topIslandOsd.currentTheme.colors.textMuted
                        : topIslandOsd.currentTheme.colors.dominant

                    // In-place smooth morphing for rapid events
                    Behavior on width {
                        NumberAnimation {
                            duration: topIslandOsd.currentTheme.motion.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // Bubble-Drop & In-Place Morphing Mechanics (DEC-021)
    // =========================================================

    function show(type: string, val: real, mutedState: bool): void {
        var t = (type && type.length > 0) ? type : "volume"
        var v = Math.max(0.0, Math.min(1.0, val))
        var m = mutedState

        topIslandOsd.osdType = t
        topIslandOsd.value = v
        topIslandOsd.isMuted = m

        if (topIslandOsd.active && topIslandOsd.opacity > 0.0) {
            // Rapid repeated event: update in place without re-triggering entrance animation
            dismissTimer.restart()
            return
        }

        topIslandOsd.active = true
        collapseAnim.stop()

        if (topIslandOsd.currentTheme.motion.reducedMotion) {
            dropTranslate.y = 0
            dropScale.xScale = 1.0
            dropScale.yScale = 1.0
            topIslandOsd.opacity = 1.0
        } else {
            dropAnim.restart()
        }

        dismissTimer.restart()
    }

    function collapse(): void {
        dismissTimer.stop()
        if (topIslandOsd.currentTheme.motion.reducedMotion) {
            topIslandOsd.opacity = 0.0
            topIslandOsd.active = false
        } else {
            collapseAnim.restart()
        }
    }

    // Bubble-Drop entrance animation: stretches downward from island, snaps into place
    ParallelAnimation {
        id: dropAnim

        NumberAnimation {
            target: topIslandOsd
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: topIslandOsd.currentTheme.motion.durationFast
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            NumberAnimation {
                target: dropTranslate
                property: "y"
                from: -14
                to: 4
                duration: Math.round(topIslandOsd.currentTheme.motion.durationNormal * 0.7)
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: dropTranslate
                property: "y"
                from: 4
                to: 0
                duration: topIslandOsd.currentTheme.motion.durationFast
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation {
            NumberAnimation {
                target: dropScale
                property: "yScale"
                from: 0.70
                to: 1.08
                duration: Math.round(topIslandOsd.currentTheme.motion.durationNormal * 0.6)
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: dropScale
                property: "yScale"
                from: 1.08
                to: 1.0
                duration: topIslandOsd.currentTheme.motion.durationFast
                easing.type: Easing.OutCubic
            }
        }

        NumberAnimation {
            target: dropScale
            property: "xScale"
            from: 0.85
            to: 1.0
            duration: topIslandOsd.currentTheme.motion.durationNormal
            easing.type: Easing.OutBack
        }
    }

    // Bubble-Drop collapse animation: merges back into the Top Island
    ParallelAnimation {
        id: collapseAnim

        NumberAnimation {
            target: topIslandOsd
            property: "opacity"
            to: 0.0
            duration: topIslandOsd.currentTheme.motion.durationFast
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: dropTranslate
            property: "y"
            to: -10
            duration: topIslandOsd.currentTheme.motion.durationFast
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: dropScale
            property: "yScale"
            to: 0.75
            duration: topIslandOsd.currentTheme.motion.durationFast
            easing.type: Easing.InCubic
        }

        onFinished: {
            topIslandOsd.active = false
        }
    }

    Timer {
        id: dismissTimer
        interval: topIslandOsd.displayTimeoutMs
        repeat: false
        onTriggered: {
            topIslandOsd.collapse()
        }
    }

    // =========================================================
    // Diagnostic Snapshot
    // =========================================================
    function getSnapshot(): var {
        return {
            available: true,
            active: topIslandOsd.active,
            visible: topIslandOsd.visible,
            type: topIslandOsd.osdType,
            value: topIslandOsd.value,
            percent: topIslandOsd.percent,
            isMuted: topIslandOsd.isMuted,
            osdWidth: topIslandOsd.width,
            osdHeight: topIslandOsd.height
        }
    }
}

