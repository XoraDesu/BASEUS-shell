// BASEUS — Dedicated Desktop Media Widget
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §31, DESIGN.md §33, DEC-026, and ANTI-SLOP.md §37:
//   - Dedicated modular desktop media widget
//   - Compact State (idle / paused): Minimalist footprint displaying track title,
//     artist, play/pause toggle, compact progress bar, and resting Bongo Cat.
//   - Expanded State (playing / user toggle): Smoothly reveals extended controls
//     (prev, next, seek slider, session selector), dedicated structural lyrics slot,
//     and synchronized rhythm-tapping Bongo Cat companion.
//   - Solid Wabi-sabi palette styling (surfaceSolid + borderSubtle), zero blur, zero drop shadows.
//   - Layer-shell bounding integration with zero-cost idle desktop hitmasking.

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import "../theme" as ThemeModule

Rectangle {
    id: mediaWidget

    // =========================================================
    // Dependencies & Properties
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: mediaWidget.theme ? mediaWidget.theme : mediaWidget.defaultTheme

    property var mediaService: null

    // State Toggles
    property bool widgetVisible: true
    property bool userExpanded: false
    property bool autoExpandOnPlay: true
    readonly property bool effectiveExpanded: (mediaWidget.autoExpandOnPlay && mediaWidget.isPlaying) || mediaWidget.userExpanded

    // Media State Bindings
    readonly property bool isPlaying: mediaWidget.mediaService ? mediaWidget.mediaService.isPlaying : false
    readonly property string displayTitle: mediaWidget.mediaService && mediaWidget.mediaService.trackTitle.length > 0
        ? mediaWidget.mediaService.trackTitle
        : "No Media Playing"
    readonly property string displayArtist: mediaWidget.mediaService && mediaWidget.mediaService.trackArtist.length > 0
        ? mediaWidget.mediaService.trackArtist
        : "Idle"
    readonly property string displayAlbum: mediaWidget.mediaService ? mediaWidget.mediaService.trackAlbum : ""
    readonly property real trackLength: mediaWidget.mediaService ? mediaWidget.mediaService.trackLength : 0.0
    readonly property real trackPosition: mediaWidget.mediaService ? mediaWidget.mediaService.trackPosition : 0.0
    readonly property real trackProgress: mediaWidget.mediaService ? mediaWidget.mediaService.trackProgress : 0.0
    readonly property string activePlayer: mediaWidget.mediaService ? mediaWidget.mediaService.activePlayerIdentity : ""

    // Predictable Geometry per MASTER.md §31
    implicitWidth: 340
    width: 340
    implicitHeight: mediaWidget.effectiveExpanded ? 254 : 108
    height: mediaWidget.effectiveExpanded ? 254 : 108

    Behavior on height {
        NumberAnimation {
            duration: mediaWidget.currentTheme.motion.durationNormal
            easing.type: mediaWidget.currentTheme.motion.easingStandard
        }
    }

    radius: mediaWidget.currentTheme.geometry.radiusLarge
    color: mediaWidget.currentTheme.colors.surfaceSolid
    border.width: 1
    border.color: mediaWidget.currentTheme.colors.borderSubtle
    clip: true

    visible: mediaWidget.widgetVisible
    opacity: mediaWidget.widgetVisible ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation {
            duration: mediaWidget.currentTheme.motion.durationFast
            easing.type: mediaWidget.currentTheme.motion.easingStandard
        }
    }

    // Hit Region Item for Layer-Shell Input Mask
    readonly property var hitRegionItem: mediaWidget.widgetVisible ? mediaWidget : null

    // =========================================================
    // Time Formatter Helper
    // =========================================================
    function formatTime(seconds: real): string {
        var s = Math.floor(seconds)
        var m = Math.floor(s / 60)
        var sec = s % 60
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    // =========================================================
    // Main Container Layout
    // =========================================================
    Column {
        anchors.fill: parent
        anchors.margins: mediaWidget.currentTheme.spacing.md
        spacing: mediaWidget.currentTheme.spacing.sm

        // -----------------------------------------------------
        // 1. Compact Header Row (Artwork, Info, Bongo Cat, Toggle)
        // -----------------------------------------------------
        Row {
            width: parent.width
            height: 52
            spacing: mediaWidget.currentTheme.spacing.sm

            // Album Artwork / Monogram Thumbnail
            Rectangle {
                width: 44
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                radius: mediaWidget.currentTheme.geometry.radiusMedium
                color: mediaWidget.currentTheme.colors.surfaceHighlight
                border.width: 1
                border.color: mediaWidget.currentTheme.colors.borderSubtle
                clip: true

                IconImage {
                    id: albumThumb
                    anchors.fill: parent
                    source: mediaWidget.mediaService ? mediaWidget.mediaService.trackArtUrl : ""
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !albumThumb.visible
                    text: "♪"
                    font.family: mediaWidget.currentTheme.typography.fontFamilyMono
                    font.pixelSize: 16
                    color: mediaWidget.isPlaying
                        ? mediaWidget.currentTheme.colors.dominant
                        : mediaWidget.currentTheme.colors.textMuted
                }
            }

            // Track & Artist Information
            Item {
                width: 154
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 2

                    Text {
                        width: parent.width
                        text: mediaWidget.displayTitle
                        font.family: mediaWidget.currentTheme.typography.fontFamily
                        font.pixelSize: mediaWidget.currentTheme.typography.sizeBody
                        font.weight: mediaWidget.currentTheme.typography.weightBold
                        color: mediaWidget.currentTheme.colors.textPrimary
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: mediaWidget.displayArtist
                        font.family: mediaWidget.currentTheme.typography.fontFamilyMono
                        font.pixelSize: mediaWidget.currentTheme.typography.sizeCaption
                        color: mediaWidget.currentTheme.colors.textSecondary
                        elide: Text.ElideRight
                    }
                }
            }

            // Bongo Cat Visual Companion
            BongoCatCompanion {
                id: bongoCat
                theme: mediaWidget.theme
                isPlaying: mediaWidget.isPlaying
                width: 80
                height: 48
                anchors.verticalCenter: parent.verticalCenter
            }

            // Expand / Collapse Drawer Toggle
            Rectangle {
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                radius: mediaWidget.currentTheme.geometry.radiusSmall
                color: expandHover.hovered ? mediaWidget.currentTheme.colors.surfaceHighlight : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: mediaWidget.effectiveExpanded ? "▲" : "▼"
                    font.pixelSize: 10
                    color: expandHover.hovered
                        ? mediaWidget.currentTheme.colors.dominant
                        : mediaWidget.currentTheme.colors.textMuted
                }

                HoverHandler {
                    id: expandHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: mediaWidget.toggleExpand()
                }
            }
        }

        // -----------------------------------------------------
        // 2. Compact Progress Bar & Timestamps
        // -----------------------------------------------------
        Column {
            width: parent.width
            spacing: 3

            // Progress hairline track
            Rectangle {
                id: progressTrack
                width: parent.width
                height: mediaWidget.effectiveExpanded ? 4 : 2
                radius: 1
                color: mediaWidget.currentTheme.colors.surfaceHighlight

                Behavior on height {
                    NumberAnimation {
                        duration: mediaWidget.currentTheme.motion.durationFast
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, Math.min(parent.width, parent.width * mediaWidget.trackProgress))
                    radius: 1
                    color: mediaWidget.isPlaying
                        ? mediaWidget.currentTheme.colors.dominant
                        : mediaWidget.currentTheme.colors.textSecondary
                }

                // Interactive Seek Area in Expanded Mode
                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -4
                    anchors.bottomMargin: -4
                    enabled: mediaWidget.effectiveExpanded
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: function(mouse) {
                        if (mediaWidget.mediaService && mediaWidget.trackLength > 0.0) {
                            let fraction = Math.max(0.0, Math.min(1.0, mouse.x / progressTrack.width))
                            mediaWidget.mediaService.seek(fraction * mediaWidget.trackLength)
                        }
                    }
                }
            }

            // Timestamps
            Item {
                width: parent.width
                height: 14

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: mediaWidget.formatTime(mediaWidget.trackPosition)
                    font.family: mediaWidget.currentTheme.typography.fontFamilyMono
                    font.pixelSize: mediaWidget.currentTheme.typography.sizeMicro
                    color: mediaWidget.currentTheme.colors.textMuted
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: mediaWidget.formatTime(mediaWidget.trackLength)
                    font.family: mediaWidget.currentTheme.typography.fontFamilyMono
                    font.pixelSize: mediaWidget.currentTheme.typography.sizeMicro
                    color: mediaWidget.currentTheme.colors.textMuted
                }
            }
        }

        // -----------------------------------------------------
        // 3. Expanded Section: Extended Controls & Lyrics Slot
        // -----------------------------------------------------
        Column {
            width: parent.width
            spacing: mediaWidget.currentTheme.spacing.sm
            visible: mediaWidget.effectiveExpanded
            opacity: mediaWidget.effectiveExpanded ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: mediaWidget.currentTheme.motion.durationFast
                    easing.type: mediaWidget.currentTheme.motion.easingStandard
                }
            }

            // Extended Controls Row
            Row {
                width: parent.width
                spacing: mediaWidget.currentTheme.spacing.sm

                // Previous Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: mediaWidget.currentTheme.geometry.radiusSmall
                    color: prevHover.hovered ? mediaWidget.currentTheme.colors.surfaceElevated : mediaWidget.currentTheme.colors.surfaceHighlight

                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        font.pixelSize: 11
                        color: prevHover.hovered ? mediaWidget.currentTheme.colors.textPrimary : mediaWidget.currentTheme.colors.textSecondary
                    }

                    HoverHandler {
                        id: prevHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (mediaWidget.mediaService) mediaWidget.mediaService.previous()
                        }
                    }
                }

                // Seek -10s
                Rectangle {
                    width: 28
                    height: 28
                    radius: mediaWidget.currentTheme.geometry.radiusSmall
                    color: rwdHover.hovered ? mediaWidget.currentTheme.colors.surfaceElevated : mediaWidget.currentTheme.colors.surfaceHighlight

                    Text {
                        anchors.centerIn: parent
                        text: "-10"
                        font.family: mediaWidget.currentTheme.typography.fontFamilyMono
                        font.pixelSize: mediaWidget.currentTheme.typography.sizeMicro
                        color: rwdHover.hovered ? mediaWidget.currentTheme.colors.textPrimary : mediaWidget.currentTheme.colors.textSecondary
                    }

                    HoverHandler {
                        id: rwdHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (mediaWidget.mediaService) {
                                mediaWidget.mediaService.seek(Math.max(0.0, mediaWidget.trackPosition - 10.0))
                            }
                        }
                    }
                }

                // Play / Pause Main Button
                Rectangle {
                    width: 32
                    height: 28
                    radius: mediaWidget.currentTheme.geometry.radiusSmall
                    color: playHover.hovered
                        ? mediaWidget.currentTheme.colors.dominant
                        : (mediaWidget.isPlaying ? mediaWidget.currentTheme.colors.surfaceHighlight : mediaWidget.currentTheme.colors.surfaceElevated)

                    Text {
                        anchors.centerIn: parent
                        text: mediaWidget.isPlaying ? "❚❚" : "▶"
                        font.pixelSize: 12
                        color: playHover.hovered
                            ? mediaWidget.currentTheme.colors.textInverse
                            : (mediaWidget.isPlaying ? mediaWidget.currentTheme.colors.dominant : mediaWidget.currentTheme.colors.textPrimary)
                    }

                    HoverHandler {
                        id: playHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (mediaWidget.mediaService) mediaWidget.mediaService.togglePlay()
                        }
                    }
                }

                // Seek +10s
                Rectangle {
                    width: 28
                    height: 28
                    radius: mediaWidget.currentTheme.geometry.radiusSmall
                    color: fwdHover.hovered ? mediaWidget.currentTheme.colors.surfaceElevated : mediaWidget.currentTheme.colors.surfaceHighlight

                    Text {
                        anchors.centerIn: parent
                        text: "+10"
                        font.family: mediaWidget.currentTheme.typography.fontFamilyMono
                        font.pixelSize: mediaWidget.currentTheme.typography.sizeMicro
                        color: fwdHover.hovered ? mediaWidget.currentTheme.colors.textPrimary : mediaWidget.currentTheme.colors.textSecondary
                    }

                    HoverHandler {
                        id: fwdHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (mediaWidget.mediaService) {
                                mediaWidget.mediaService.seek(Math.min(mediaWidget.trackLength, mediaWidget.trackPosition + 10.0))
                            }
                        }
                    }
                }

                // Next Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: mediaWidget.currentTheme.geometry.radiusSmall
                    color: nextHover.hovered ? mediaWidget.currentTheme.colors.surfaceElevated : mediaWidget.currentTheme.colors.surfaceHighlight

                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        font.pixelSize: 11
                        color: nextHover.hovered ? mediaWidget.currentTheme.colors.textPrimary : mediaWidget.currentTheme.colors.textSecondary
                    }

                    HoverHandler {
                        id: nextHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (mediaWidget.mediaService) mediaWidget.mediaService.next()
                        }
                    }
                }

                // Session / Player Switcher Pill
                Rectangle {
                    height: 28
                    width: 104
                    radius: mediaWidget.currentTheme.geometry.radiusSmall
                    color: sessionHover.hovered ? mediaWidget.currentTheme.colors.surfaceElevated : mediaWidget.currentTheme.colors.surfaceRecessed
                    border.width: 1
                    border.color: mediaWidget.currentTheme.colors.borderSubtle
                    clip: true

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "●"
                            font.pixelSize: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: mediaWidget.currentTheme.colors.accent
                        }

                        Text {
                            text: mediaWidget.activePlayer.length > 0 ? mediaWidget.activePlayer : "player"
                            font.family: mediaWidget.currentTheme.typography.fontFamilyMono
                            font.pixelSize: mediaWidget.currentTheme.typography.sizeMicro
                            color: mediaWidget.currentTheme.colors.textSecondary
                            elide: Text.ElideRight
                        }
                    }

                    HoverHandler {
                        id: sessionHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (mediaWidget.mediaService && mediaWidget.mediaService.playerList.length > 1) {
                                const nextIdx = (mediaWidget.mediaService.activePlayerIndex + 1) % mediaWidget.mediaService.playerList.length
                                mediaWidget.mediaService.selectPlayer(nextIdx)
                            }
                        }
                    }
                }
            }

            // Dedicated Structural Lyrics Slot
            LyricsContainer {
                id: lyricsSlot
                theme: mediaWidget.theme
                mediaService: mediaWidget.mediaService
                width: parent.width
                height: 72
            }
        }
    }

    // =========================================================
    // Public API & Methods
    // =========================================================

    function toggle(): void {
        mediaWidget.widgetVisible = !mediaWidget.widgetVisible
    }

    function show(): void {
        mediaWidget.widgetVisible = true
    }

    function hide(): void {
        mediaWidget.widgetVisible = false
    }

    function toggleExpand(): void {
        mediaWidget.userExpanded = !mediaWidget.userExpanded
    }

    function getSnapshot(): var {
        return {
            visible: mediaWidget.widgetVisible,
            expanded: mediaWidget.effectiveExpanded,
            userExpanded: mediaWidget.userExpanded,
            height: mediaWidget.height,
            isPlaying: mediaWidget.isPlaying,
            trackTitle: mediaWidget.displayTitle,
            trackArtist: mediaWidget.displayArtist,
            trackAlbum: mediaWidget.displayAlbum,
            position: mediaWidget.trackPosition,
            length: mediaWidget.trackLength,
            progress: mediaWidget.trackProgress,
            player: mediaWidget.activePlayer,
            bongoCat: bongoCat.getSnapshot(),
            lyrics: lyricsSlot.getSnapshot()
        }
    }
}

