pragma ComponentBehavior: Bound

// BASEUS — Modular Top Island Component (M6-04)
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §9, §12; DESIGN.md §9, §10, §13, §14; and ANTI-SLOP.md §37:
//   - Minimal edge-integrated top-center solid Wabi-sabi anchor
//   - Flanked by Inverse Corner Radius (ICR) fillets that travel with the body
//   - Houses typographic clock, awake pip, and integrated M6 personality subsystems:
//       * BongoCat: reactive companion in the secondary/utility slot (collapsible via config)
//       * ContextualCue: subtle editorial system status beside the center clock pill
//   - Strict layer-shell input region discipline (hitRegion) ensuring pass-through desktop
//   - Zero blur, zero drop shadows, zero translucent glass

import QtQuick
import QtQuick.Shapes
import "../../src/theme" as ThemeModule
import "../../src/core" as CoreModule
import "../personality" as PersonalityModule

Item {
    id: barIslandRoot

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property ThemeModule.Theme theme
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: barIslandRoot.theme ? barIslandRoot.theme : barIslandRoot.defaultTheme

    property CoreModule.Config config
    property CoreModule.HyprlandBridge hyprlandBridge
    property CoreModule.AudioService audioService
    property CoreModule.StatusService statusService
    property CoreModule.IdleService idleService
    property CoreModule.WorkspaceModel workspaceModel
    property CoreModule.WindowModel windowModel
    property CoreModule.ActionRegistry actionRegistry

    property int monitorIndex: 0
    property bool isFullscreen: false
    property bool fullscreenSummon: false

    // Dimensions
    readonly property int islandHeight: 32
    readonly property int minIslandWidth: 80
    readonly property int expandedWidth: 360
    readonly property int triggerHeight: 2

    readonly property int idleBodyWidth: Math.max(centerCluster.implicitWidth + 32, barIslandRoot.minIslandWidth)

    // Contextual time/date strings
    property string timeText: "00:00"
    property string dateText: ""

    // Expansion / Hover state
    property bool expanded: false
    property bool summoned: false
    property bool _simulatedHover: false

    readonly property bool bodyRevealed: !barIslandRoot.fullscreenSummon || barIslandRoot.summoned || barIslandRoot.expanded
    readonly property bool hoverActive: islandHover.hovered || barIslandRoot._simulatedHover

    // Public aliases for layer-shell mask and telemetry
    readonly property alias anchorItem: hitRegion
    readonly property alias bodyItem: islandBody
    readonly property alias bongoCat: utilityBongoCat
    readonly property alias contextualCue: centerCue

    anchors.top: parent ? parent.top : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    height: barIslandRoot.islandHeight
    width: islandBody.width + (barIslandRoot.currentTheme.geometry.islandIcr * 2)

    // Fullscreen recession
    opacity: barIslandRoot.isFullscreen ? 0.0 : 1.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: barIslandRoot.currentTheme.motion.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    // =========================================================
    // Control API
    // =========================================================
    function expand(): void {
        exitTimer.stop()
        hoverIntentTimer.stop()
        if (barIslandRoot.fullscreenSummon) barIslandRoot.summoned = true
        barIslandRoot.expanded = true
    }

    function collapse(): void {
        exitTimer.stop()
        hoverIntentTimer.stop()
        barIslandRoot.expanded = false
        barIslandRoot.summoned = false
        barIslandRoot._simulatedHover = false
    }

    function applyHover(hovered: bool): void {
        barIslandRoot._simulatedHover = hovered
        if (hovered) {
            exitTimer.stop()
            if (barIslandRoot.fullscreenSummon) {
                barIslandRoot.summoned = true
            } else if (!barIslandRoot.expanded) {
                hoverIntentTimer.restart()
            }
        } else {
            hoverIntentTimer.stop()
            if (barIslandRoot.bodyRevealed) exitTimer.restart()
        }
    }

    Timer {
        id: hoverIntentTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (barIslandRoot.hoverActive) barIslandRoot.expand()
        }
    }

    Timer {
        id: exitTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!barIslandRoot.hoverActive) barIslandRoot.collapse()
        }
    }

    // =========================================================
    // Dynamic Input Mask Hit Box (0x0 pass-through outside body)
    // =========================================================
    Item {
        id: hitRegion
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: barIslandRoot.expanded ? barIslandRoot.expandedWidth : barIslandRoot.idleBodyWidth
        height: barIslandRoot.expanded ? (barIslandRoot.islandHeight + 160) : (barIslandRoot.bodyRevealed ? barIslandRoot.islandHeight : barIslandRoot.triggerHeight)

        HoverHandler {
            id: islandHover
            onHoveredChanged: barIslandRoot.applyHover(islandHover.hovered)
        }

        TapHandler {
            onTapped: {
                if (barIslandRoot.fullscreenSummon && !barIslandRoot.summoned) return
                barIslandRoot.expand()
            }
        }
    }

    // =========================================================
    // Island Notch Container & Continuous ICR Silhouette
    // =========================================================
    Item {
        id: islandContainer
        anchors.top: parent.top
        anchors.topMargin: barIslandRoot.bodyRevealed ? 0 : -barIslandRoot.islandHeight
        anchors.horizontalCenter: parent.horizontalCenter
        width: islandBody.width + (barIslandRoot.currentTheme.geometry.islandIcr * 2)
        height: islandBody.height

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: barIslandRoot.currentTheme.motion.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        Shape {
            id: islandShape
            anchors.fill: parent
            asynchronous: false

            readonly property int flareWidth: barIslandRoot.currentTheme.geometry.islandIcr
            readonly property int flareHeight: Math.min(Math.round(parent.height * 0.45), 22)
            readonly property int cornerRadius: barIslandRoot.currentTheme.geometry.islandRadiusBottom

            // Solid opaque Wabi-sabi fill
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: barIslandRoot.currentTheme.colors.surfaceSolid
                joinStyle: ShapePath.MiterJoin

                startX: 0
                startY: 0

                PathCubic {
                    x: islandShape.flareWidth
                    y: islandShape.flareHeight
                    control1X: islandShape.flareWidth * 0.25
                    control1Y: 0
                    control2X: islandShape.flareWidth
                    control2Y: islandShape.flareHeight * 0.5
                }
                PathLine {
                    x: islandShape.flareWidth
                    y: islandContainer.height - islandShape.cornerRadius
                }
                PathArc {
                    x: islandShape.flareWidth + islandShape.cornerRadius
                    y: islandContainer.height
                    radiusX: islandShape.cornerRadius
                    radiusY: islandShape.cornerRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: islandContainer.width - islandShape.flareWidth - islandShape.cornerRadius
                    y: islandContainer.height
                }
                PathArc {
                    x: islandContainer.width - islandShape.flareWidth
                    y: islandContainer.height - islandShape.cornerRadius
                    radiusX: islandShape.cornerRadius
                    radiusY: islandShape.cornerRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: islandContainer.width - islandShape.flareWidth
                    y: islandShape.flareHeight
                }
                PathCubic {
                    x: islandContainer.width
                    y: 0
                    control1X: islandContainer.width - islandShape.flareWidth
                    control1Y: islandShape.flareHeight * 0.5
                    control2X: islandContainer.width - islandShape.flareWidth * 0.25
                    control2Y: 0
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }

            // Continuous 1px perimeter stroke
            ShapePath {
                strokeWidth: barIslandRoot.currentTheme.geometry.borderWidth
                strokeColor: barIslandRoot.currentTheme.colors.borderSubtle
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin

                startX: 0
                startY: 0

                PathCubic {
                    x: islandShape.flareWidth
                    y: islandShape.flareHeight
                    control1X: islandShape.flareWidth * 0.25
                    control1Y: 0
                    control2X: islandShape.flareWidth
                    control2Y: islandShape.flareHeight * 0.5
                }
                PathLine {
                    x: islandShape.flareWidth
                    y: islandContainer.height - islandShape.cornerRadius
                }
                PathArc {
                    x: islandShape.flareWidth + islandShape.cornerRadius
                    y: islandContainer.height
                    radiusX: islandShape.cornerRadius
                    radiusY: islandShape.cornerRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: islandContainer.width - islandShape.flareWidth - islandShape.cornerRadius
                    y: islandContainer.height
                }
                PathArc {
                    x: islandContainer.width - islandShape.flareWidth
                    y: islandContainer.height - islandShape.cornerRadius
                    radiusX: islandShape.cornerRadius
                    radiusY: islandShape.cornerRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: islandContainer.width - islandShape.flareWidth
                    y: islandShape.flareHeight
                }
                PathCubic {
                    x: islandContainer.width
                    y: 0
                    control1X: islandContainer.width - islandShape.flareWidth
                    control1Y: islandShape.flareHeight * 0.5
                    control2X: islandContainer.width - islandShape.flareWidth * 0.25
                    control2Y: 0
                }
            }
        }

        // Island Solid Body
        Item {
            id: islandBody
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: barIslandRoot.islandHeight
            width: barIslandRoot.expanded ? barIslandRoot.expandedWidth : barIslandRoot.idleBodyWidth
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: barIslandRoot.currentTheme.motion.durationNormal
                    easing.type: Easing.OutCubic
                }
            }

            // Compact Idle/Resting Center Cluster (Structured Row)
            Row {
                id: centerCluster
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: barIslandRoot.islandHeight
                spacing: barIslandRoot.currentTheme.spacing.sm

                // 1. Contextual Cue (M6-03): Mounted beside center pill
                PersonalityModule.ContextualCue {
                    id: centerCue
                    anchors.verticalCenter: parent.verticalCenter
                    theme: barIslandRoot.currentTheme
                    config: barIslandRoot.config
                    hyprlandBridge: barIslandRoot.hyprlandBridge
                    statusService: barIslandRoot.statusService
                    audioService: barIslandRoot.audioService
                }

                // 2. Center Pill (Clock + Awake Pip)
                Row {
                    id: clockCluster
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        id: clockLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: barIslandRoot.timeText
                        font.family: barIslandRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: barIslandRoot.currentTheme.typography.sizeCaption
                        font.weight: Font.Medium
                        color: barIslandRoot.currentTheme.colors.textPrimary
                    }

                    Rectangle {
                        id: awakePip
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: 4
                        radius: 2
                        color: barIslandRoot.currentTheme.colors.accent
                        visible: barIslandRoot.idleService && barIslandRoot.idleService.inhibited
                    }
                }

                // 3. Bongo Cat Personality Component (M6-01): Secondary Utility Slot
                PersonalityModule.BongoCat {
                    id: utilityBongoCat
                    anchors.verticalCenter: parent.verticalCenter
                    theme: barIslandRoot.currentTheme
                    config: barIslandRoot.config
                    hyprlandBridge: barIslandRoot.hyprlandBridge
                    audioService: barIslandRoot.audioService
                    visible: (barIslandRoot.config && barIslandRoot.config.personality && barIslandRoot.config.personality.bongoCat)
                        ? (barIslandRoot.config.personality.bongoCat.enabled === true)
                        : true
                }
            }
        }
    }

    // =========================================================
    // Minute-Aligned Clock Updates (Zero Polling)
    // =========================================================
    function updateTime(): void {
        var now = new Date()
        var h = now.getHours()
        var m = now.getMinutes()
        var hStr = (h < 10 ? "0" : "") + h
        var mStr = (m < 10 ? "0" : "") + m
        barIslandRoot.timeText = hStr + ":" + mStr
        barIslandRoot.dateText = Qt.formatDate(now, "dddd, d MMMM yyyy")
    }

    function _restartClock(): void {
        barIslandRoot.updateTime()
        var now = new Date()
        syncTimer.interval = Math.max(250, (60 - now.getSeconds()) * 1000 - now.getMilliseconds())
        clockTimer.stop()
        syncTimer.restart()
    }

    Timer {
        id: syncTimer
        repeat: false
        onTriggered: {
            barIslandRoot.updateTime()
            clockTimer.restart()
        }
    }

    Timer {
        id: clockTimer
        interval: 60000
        running: false
        repeat: true
        onTriggered: {
            barIslandRoot.updateTime()
        }
    }

    Component.onCompleted: {
        barIslandRoot._restartClock()
    }

    Component.onDestruction: {
        syncTimer.stop()
        clockTimer.stop()
    }

    // Diagnostic Snapshot
    function getDiagnosticSnapshot(): string {
        return "TopIsland: expanded=" + barIslandRoot.expanded +
               " | time=" + barIslandRoot.timeText +
               " | bongoVisible=" + utilityBongoCat.visible +
               " | cueActive=" + centerCue.hasActiveCue
    }
}

