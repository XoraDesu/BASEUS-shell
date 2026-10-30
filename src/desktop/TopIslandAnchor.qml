// BASEUS — Top Island Idle Anchor
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §9, §12; DESIGN.md §9, §10, §13, §14; and DEC-029:
//   - Minimal edge-integrated top-center solid Wabi-sabi anchor
//   - Flush with top display perimeter (radiusFlush: 0), rounded bottom corners
//   - Flanked by Inverse Corner Radius (ICR) organic fillets
//   - Quiet typographic idle clock with minute-aligned timer (zero polling)
//   - Recedes smoothly when native fullscreen is active on this monitor
//   - Constrains layer-shell input region so empty desktop remains click-through

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: topIslandAnchor

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    property bool isFullscreen: false

    // Dimensions
    readonly property int islandHeight: 32
    readonly property int minIslandWidth: 80

    // Public aliases for layer-shell mask and telemetry
    readonly property alias anchorItem: islandBody
    readonly property string timeText: _timeText

    // Contextual time string
    property string _timeText: "00:00"

    anchors.top: parent ? parent.top : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    height: islandHeight
    width: islandBody.width + (theme ? (theme.geometry.islandIcr * 2) : 24)

    // Fullscreen recession (DESIGN.md §14)
    opacity: topIslandAnchor.isFullscreen ? 0.0 : 1.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: topIslandAnchor.theme ? (topIslandAnchor.theme.motion.reducedMotion ? 0 : topIslandAnchor.theme.motion.durationNormal) : 200
            easing.type: Easing.OutCubic
        }
    }

    // =========================================================
    // Left ICR Fillet (flares into top display perimeter)
    // =========================================================
    ThemeModule.InverseCorner {
        id: leftIcr
        anchors.right: islandBody.left
        anchors.top: islandBody.top
        cornerRadius: topIslandAnchor.theme ? topIslandAnchor.theme.geometry.islandIcr : 12
        fillColor: topIslandAnchor.theme ? topIslandAnchor.theme.colors.surfaceSolid : "#1f2335"
        position: "top-left"
    }

    // =========================================================
    // Island Solid Body (Edge-integrated Wabi-sabi surface)
    // =========================================================
    Rectangle {
        id: islandBody
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: topIslandAnchor.islandHeight
        width: Math.max(clockLabel.width + 36, topIslandAnchor.minIslandWidth)

        color: topIslandAnchor.theme ? topIslandAnchor.theme.colors.surfaceSolid : "#1f2335"

        // Edge integration: flush top corners (0), rounded bottom corners (12)
        topLeftRadius: topIslandAnchor.theme ? topIslandAnchor.theme.geometry.islandRadiusTop : 0
        topRightRadius: topIslandAnchor.theme ? topIslandAnchor.theme.geometry.islandRadiusTop : 0
        bottomLeftRadius: topIslandAnchor.theme ? topIslandAnchor.theme.geometry.islandRadiusBottom : 12
        bottomRightRadius: topIslandAnchor.theme ? topIslandAnchor.theme.geometry.islandRadiusBottom : 12

        // Hairline boundary (no neon glow)
        border.width: topIslandAnchor.theme ? topIslandAnchor.theme.geometry.borderWidth : 1
        border.color: topIslandAnchor.theme ? topIslandAnchor.theme.colors.borderSubtle : "#292e42"

        // Typographic idle clock (monospace, calm tonal contrast)
        Text {
            id: clockLabel
            anchors.centerIn: parent
            text: topIslandAnchor._timeText
            font.family: topIslandAnchor.theme ? topIslandAnchor.theme.typography.fontFamilyMono : "monospace"
            font.pixelSize: topIslandAnchor.theme ? topIslandAnchor.theme.typography.sizeCaption : 11
            font.weight: Font.Medium
            color: topIslandAnchor.theme ? topIslandAnchor.theme.colors.textPrimary : "#c0caf5"
        }
    }

    // =========================================================
    // Right ICR Fillet (flares into top display perimeter)
    // =========================================================
    ThemeModule.InverseCorner {
        id: rightIcr
        anchors.left: islandBody.right
        anchors.top: islandBody.top
        cornerRadius: topIslandAnchor.theme ? topIslandAnchor.theme.geometry.islandIcr : 12
        fillColor: topIslandAnchor.theme ? topIslandAnchor.theme.colors.surfaceSolid : "#1f2335"
        position: "top-right"
    }

    // =========================================================
    // Minute-Aligned Clock Updates (Zero polling per AGENTS.md §21)
    // =========================================================

    function updateTime() {
        var now = new Date()
        var h = now.getHours()
        var m = now.getMinutes()
        var hStr = (h < 10 ? "0" : "") + h
        var mStr = (m < 10 ? "0" : "") + m
        _timeText = hStr + ":" + mStr
    }

    // Calculates remaining milliseconds until next minute boundary
    Timer {
        id: syncTimer
        interval: {
            var now = new Date()
            var msToNextMinute = (60 - now.getSeconds()) * 1000 - now.getMilliseconds()
            return Math.max(250, msToNextMinute)
        }
        running: true
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
        updateTime()
    }
}

