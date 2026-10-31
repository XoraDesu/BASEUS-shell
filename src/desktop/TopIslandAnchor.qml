// BASEUS — Top Island
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §9, §12; DESIGN.md §9, §10, §13, §14; DEC-016, DEC-029:
//   - Minimal edge-integrated top-center solid Wabi-sabi anchor
//   - Flush with top display perimeter (radiusFlush: 0), rounded bottom corners
//   - Flanked by Inverse Corner Radius (ICR) organic fillets that travel with the body,
//     so expansion reads as the edge becoming active, not a detached panel
//   - Quiet typographic idle clock with minute-aligned timer (zero polling)
//   - Hover (or tap) expands the same surface downward into the contextual header
//   - Fullscreen summon (fullscreenSummon: true, hosted in a dedicated Overlay surface):
//       idle   → 2px top-edge trigger only
//       hover  → compact clock slides in
//       tap    → expands into the contextual header
//   - Layer-shell input region (hitRegionItem) tracks the interactive footprint so the
//     rest of the desktop stays click-through in every state
//   - Recedes when native fullscreen is active on this monitor (main surface instance)

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../theme" as ThemeModule

Item {
    id: topIslandAnchor

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: topIslandAnchor.theme ? topIslandAnchor.theme : topIslandAnchor.defaultTheme
    property bool isFullscreen: false

    // True for the instance hosted by the fullscreen summon surface
    property bool fullscreenSummon: false

    property var actionRegistry: null
    property var workspaceModel: null
    property var windowModel: null
    property int monitorIndex: 0

    // Dimensions
    readonly property int islandHeight: 32
    readonly property int minIslandWidth: 80
    readonly property int expandedWidth: 360
    readonly property int triggerHeight: 2
    readonly property int idleBodyWidth: Math.max(clockLabel.implicitWidth + 36, topIslandAnchor.minIslandWidth)
    readonly property int expandedHeight: topIslandAnchor.islandHeight + islandHeader.implicitHeight

    // Timing
    readonly property int hoverIntentMs: 120
    readonly property int exitGraceMs: 350

    // =========================================================
    // State Machine
    // =========================================================
    // expanded: contextual header is open
    // summoned: (fullscreen summon only) compact clock is revealed from the top edge
    property bool expanded: false
    property bool summoned: false
    property bool _simulatedHover: false

    readonly property bool bodyRevealed: !topIslandAnchor.fullscreenSummon || topIslandAnchor.summoned || topIslandAnchor.expanded
    readonly property bool hoverActive: islandHover.hovered || topIslandAnchor._simulatedHover

    // Public aliases for layer-shell mask and telemetry
    readonly property alias anchorItem: hitRegion
    readonly property alias bodyItem: islandBody
    readonly property string timeText: _timeText
    readonly property string dateText: _dateText

    // Contextual time/date strings
    property string _timeText: "00:00"
    property string _dateText: ""

    anchors.top: parent ? parent.top : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    height: islandHeight
    width: islandBody.width + (topIslandAnchor.currentTheme.geometry.islandIcr * 2)

    // Fullscreen recession (DESIGN.md §14)
    opacity: topIslandAnchor.isFullscreen ? 0.0 : 1.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: topIslandAnchor.currentTheme.motion.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    // =========================================================
    // Expansion / Recession Control API
    // =========================================================

    function expand() {
        exitTimer.stop()
        hoverIntentTimer.stop()
        if (topIslandAnchor.fullscreenSummon) topIslandAnchor.summoned = true
        topIslandAnchor.expanded = true
    }

    function summon() {
        exitTimer.stop()
        topIslandAnchor.summoned = true
    }

    function collapse() {
        exitTimer.stop()
        hoverIntentTimer.stop()
        topIslandAnchor.expanded = false
        topIslandAnchor.summoned = false
        topIslandAnchor._simulatedHover = false
    }

    // Single entry point for real pointer hover and diagnostic simulation
    function applyHover(hovered: bool) {
        topIslandAnchor._simulatedHover = hovered
        if (hovered) {
            exitTimer.stop()
            if (topIslandAnchor.fullscreenSummon) {
                // Explicit push to the screen edge: reveal compact clock immediately
                topIslandAnchor.summon()
            } else if (!topIslandAnchor.expanded) {
                hoverIntentTimer.restart()
            }
        } else {
            hoverIntentTimer.stop()
            if (topIslandAnchor.bodyRevealed) exitTimer.restart()
        }
    }

    // Tap is the non-hover path to the same expansion (touch / accessibility)
    function applyTap() {
        if (topIslandAnchor.fullscreenSummon && !topIslandAnchor.summoned) return
        topIslandAnchor.expand()
    }

    // Diagnostic hooks mirror the pointer path exactly
    function simulateHover(hovered: bool) {
        topIslandAnchor.applyHover(hovered)
    }

    function activateTrigger(actionId: string): bool {
        return topIslandAnchor.expanded ? islandHeader.activate(actionId) : false
    }

    function getSnapshot(): var {
        return {
            fullscreenSummon: topIslandAnchor.fullscreenSummon,
            expanded: topIslandAnchor.expanded,
            summoned: topIslandAnchor.summoned,
            bodyRevealed: topIslandAnchor.bodyRevealed,
            hovered: topIslandAnchor.hoverActive,
            timeText: topIslandAnchor._timeText,
            dateText: topIslandAnchor._dateText,
            hitRegion: {
                width: hitRegion.width,
                height: hitRegion.height
            },
            header: islandHeader.getSnapshot()
        }
    }

    onIsFullscreenChanged: topIslandAnchor.collapse()

    Timer {
        id: hoverIntentTimer
        interval: topIslandAnchor.hoverIntentMs
        repeat: false
        onTriggered: {
            if (topIslandAnchor.hoverActive) topIslandAnchor.expand()
        }
    }

    Timer {
        id: exitTimer
        interval: topIslandAnchor.exitGraceMs
        repeat: false
        onTriggered: {
            if (!topIslandAnchor.hoverActive) topIslandAnchor.collapse()
        }
    }

    // =========================================================
    // Dynamic Input Mask Hit Box (DEC-029)
    // =========================================================
    // Not animated: the compositor input region switches to the final footprint at once.
    //   normal desktop   idle → clock body, expanded → header body
    //   fullscreen       idle → 2px edge trigger, summoned → clock body, expanded → header body
    Item {
        id: hitRegion
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: topIslandAnchor.expanded
            ? topIslandAnchor.expandedWidth
            : topIslandAnchor.idleBodyWidth
        height: topIslandAnchor.expanded
            ? topIslandAnchor.expandedHeight
            : (topIslandAnchor.bodyRevealed ? topIslandAnchor.islandHeight : topIslandAnchor.triggerHeight)

        HoverHandler {
            id: islandHover
            onHoveredChanged: topIslandAnchor.applyHover(islandHover.hovered)
        }

        TapHandler {
            onTapped: topIslandAnchor.applyTap()
        }
    }

    // =========================================================
    // Island Container (slides in from the top edge in fullscreen summon)
    // =========================================================
    Item {
        id: islandContainer
        anchors.top: parent.top
        anchors.topMargin: topIslandAnchor.bodyRevealed ? 0 : -topIslandAnchor.islandHeight
        anchors.horizontalCenter: parent.horizontalCenter
        width: islandBody.width + (topIslandAnchor.currentTheme.geometry.islandIcr * 2)
        height: islandBody.height

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: topIslandAnchor.currentTheme.motion.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        // Unified Edge-Integrated Surface (Shape)
        // Renders the continuous Wabi-sabi notch silhouette matching DESIGN.md §10, §13
        // and MASTER.md §12: flush top edge with bezel, smooth concave ICR fillets,
        // straight side walls, and convex rounded bottom corners with zero internal seams.
        Shape {
            id: islandShape
            anchors.fill: parent
            asynchronous: false

            readonly property int flareWidth: topIslandAnchor.currentTheme.geometry.islandIcr
            readonly property int flareHeight: Math.min(Math.round(parent.height * 0.45), 22)
            readonly property int cornerRadius: topIslandAnchor.currentTheme.geometry.islandRadiusBottom

            // 1. Solid opaque Wabi-sabi fill (DEC-011, zero blur/glow)
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: topIslandAnchor.currentTheme.colors.surfaceSolid
                joinStyle: ShapePath.MiterJoin

                startX: 0
                startY: 0

                // Top-left concave ICR flare
                PathCubic {
                    x: islandShape.flareWidth
                    y: islandShape.flareHeight
                    control1X: islandShape.flareWidth * 0.25
                    control1Y: 0
                    control2X: islandShape.flareWidth
                    control2Y: islandShape.flareHeight * 0.5
                }
                // Left vertical wall
                PathLine {
                    x: islandShape.flareWidth
                    y: islandContainer.height - islandShape.cornerRadius
                }
                // Bottom-left convex rounded corner
                PathArc {
                    x: islandShape.flareWidth + islandShape.cornerRadius
                    y: islandContainer.height
                    radiusX: islandShape.cornerRadius
                    radiusY: islandShape.cornerRadius
                    direction: PathArc.Counterclockwise
                }
                // Flat bottom edge
                PathLine {
                    x: islandContainer.width - islandShape.flareWidth - islandShape.cornerRadius
                    y: islandContainer.height
                }
                // Bottom-right convex rounded corner
                PathArc {
                    x: islandContainer.width - islandShape.flareWidth
                    y: islandContainer.height - islandShape.cornerRadius
                    radiusX: islandShape.cornerRadius
                    radiusY: islandShape.cornerRadius
                    direction: PathArc.Counterclockwise
                }
                // Right vertical wall
                PathLine {
                    x: islandContainer.width - islandShape.flareWidth
                    y: islandShape.flareHeight
                }
                // Top-right concave ICR flare
                PathCubic {
                    x: islandContainer.width
                    y: 0
                    control1X: islandContainer.width - islandShape.flareWidth
                    control1Y: islandShape.flareHeight * 0.5
                    control2X: islandContainer.width - islandShape.flareWidth * 0.25
                    control2Y: 0
                }
                // Across top bezel back to (0, 0)
                PathLine {
                    x: 0
                    y: 0
                }
            }

            // 2. Continuous outer perimeter hairline stroke (zero internal seams)
            ShapePath {
                strokeWidth: topIslandAnchor.currentTheme.geometry.borderWidth
                strokeColor: topIslandAnchor.currentTheme.colors.borderSubtle
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin

                startX: 0
                startY: 0

                // Top-left concave ICR flare
                PathCubic {
                    x: islandShape.flareWidth
                    y: islandShape.flareHeight
                    control1X: islandShape.flareWidth * 0.25
                    control1Y: 0
                    control2X: islandShape.flareWidth
                    control2Y: islandShape.flareHeight * 0.5
                }
                // Left vertical wall
                PathLine {
                    x: islandShape.flareWidth
                    y: islandContainer.height - islandShape.cornerRadius
                }
                // Bottom-left convex rounded corner
                PathArc {
                    x: islandShape.flareWidth + islandShape.cornerRadius
                    y: islandContainer.height
                    radiusX: islandShape.cornerRadius
                    radiusY: islandShape.cornerRadius
                    direction: PathArc.Counterclockwise
                }
                // Flat bottom edge
                PathLine {
                    x: islandContainer.width - islandShape.flareWidth - islandShape.cornerRadius
                    y: islandContainer.height
                }
                // Bottom-right convex rounded corner
                PathArc {
                    x: islandContainer.width - islandShape.flareWidth
                    y: islandContainer.height - islandShape.cornerRadius
                    radiusX: islandShape.cornerRadius
                    radiusY: islandShape.cornerRadius
                    direction: PathArc.Counterclockwise
                }
                // Right vertical wall
                PathLine {
                    x: islandContainer.width - islandShape.flareWidth
                    y: islandShape.flareHeight
                }
                // Top-right concave ICR flare
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

        // Island Solid Body (hosts typography and contextual header)
        Item {
            id: islandBody
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: topIslandAnchor.expanded ? topIslandAnchor.expandedHeight : topIslandAnchor.islandHeight
            width: topIslandAnchor.expanded ? topIslandAnchor.expandedWidth : topIslandAnchor.idleBodyWidth
            clip: true

            // Focus grows: body morphs in place instead of swapping surfaces
            Behavior on width {
                NumberAnimation {
                    duration: topIslandAnchor.currentTheme.motion.durationNormal
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: topIslandAnchor.currentTheme.motion.durationNormal
                    easing.type: Easing.OutCubic
                }
            }

            // Typographic idle clock (monospace, calm tonal contrast); stays put on expansion
            Text {
                id: clockLabel
                anchors.top: parent.top
                anchors.topMargin: Math.round((topIslandAnchor.islandHeight - clockLabel.implicitHeight) / 2)
                anchors.horizontalCenter: parent.horizontalCenter
                text: topIslandAnchor._timeText
                font.family: topIslandAnchor.currentTheme.typography.fontFamilyMono
                font.pixelSize: topIslandAnchor.currentTheme.typography.sizeCaption
                font.weight: Font.Medium
                color: topIslandAnchor.currentTheme.colors.textPrimary
            }

            // Contextual header (revealed only while expanded)
            TopIslandHeader {
                id: islandHeader
                anchors.top: parent.top
                anchors.topMargin: topIslandAnchor.islandHeight
                anchors.horizontalCenter: parent.horizontalCenter
                width: topIslandAnchor.expandedWidth

                currentTheme: topIslandAnchor.currentTheme
                actionRegistry: topIslandAnchor.actionRegistry
                workspaceModel: topIslandAnchor.workspaceModel
                windowModel: topIslandAnchor.windowModel
                monitorIndex: topIslandAnchor.monitorIndex
                dateText: topIslandAnchor._dateText
                active: topIslandAnchor.expanded

                opacity: topIslandAnchor.expanded ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: topIslandAnchor.currentTheme.motion.durationFast
                        easing.type: Easing.OutCubic
                    }
                }

                // Collapse after a successful action; a refused action keeps the header open
                onActionExecuted: function(actionId, ok) {
                    if (ok) topIslandAnchor.collapse()
                }
            }
        }
    }

    // =========================================================
    // Minute-Aligned Clock Updates (Zero polling per AGENTS.md §21)
    // =========================================================
    // Timers run only while the clock is on screen. A hidden summon instance
    // does no work until it is summoned.
    readonly property bool clockActive: topIslandAnchor.fullscreenSummon
        ? topIslandAnchor.bodyRevealed
        : !topIslandAnchor.isFullscreen

    function updateTime() {
        var now = new Date()
        var h = now.getHours()
        var m = now.getMinutes()
        var hStr = (h < 10 ? "0" : "") + h
        var mStr = (m < 10 ? "0" : "") + m
        _timeText = hStr + ":" + mStr
        _dateText = Qt.formatDate(now, "dddd, d MMMM yyyy")
    }

    function _restartClock() {
        topIslandAnchor.updateTime()
        var now = new Date()
        syncTimer.interval = Math.max(250, (60 - now.getSeconds()) * 1000 - now.getMilliseconds())
        clockTimer.stop()
        syncTimer.restart()
    }

    onClockActiveChanged: {
        if (topIslandAnchor.clockActive) {
            topIslandAnchor._restartClock()
        } else {
            syncTimer.stop()
            clockTimer.stop()
        }
    }

    // Fires once at the next minute boundary
    Timer {
        id: syncTimer
        repeat: false
        onTriggered: {
            topIslandAnchor.updateTime()
            clockTimer.restart()
        }
    }

    // Once aligned, fires exactly every 60,000ms
    Timer {
        id: clockTimer
        interval: 60000
        running: false
        repeat: true
        onTriggered: {
            topIslandAnchor.updateTime()
        }
    }

    Component.onCompleted: {
        if (topIslandAnchor.clockActive) {
            topIslandAnchor._restartClock()
        } else {
            topIslandAnchor.updateTime()
        }
    }
}
