// BASEUS — Top Island Compact Media Surface
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §31, DESIGN.md §31–33, DEC-026, and ANTI-SLOP.md §20:
//   - Compact fixed media controller embedded in TopIslandHeader
//   - Fixed dimensions (328x38px): zero unpredictable layout jitter or dynamic resizing
//   - Elided typography for long titles/artists
//   - Restrained controls: previous, play/pause toggle, next
//   - Solid Wabi-sabi palette surface (surfaceSolid + borderSubtle), zero blur, zero drop shadows
//   - Hairline progress indicator

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import "../theme" as ThemeModule

Rectangle {
    id: topIslandMedia

    // =========================================================
    // Dependencies & Properties
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: topIslandMedia.theme ? topIslandMedia.theme : topIslandMedia.defaultTheme

    property var mediaService: null

    // Fixed predictable geometry per MASTER.md §31
    implicitWidth: 328
    implicitHeight: 38
    height: 38

    radius: topIslandMedia.currentTheme.geometry.radiusMedium
    color: topIslandMedia.currentTheme.colors.surfaceSolid
    border.width: 1
    border.color: topIslandMedia.currentTheme.colors.borderSubtle
    clip: true

    readonly property bool isPlaying: topIslandMedia.mediaService ? topIslandMedia.mediaService.isPlaying : false
    readonly property string displayTitle: topIslandMedia.mediaService && topIslandMedia.mediaService.trackTitle.length > 0
        ? topIslandMedia.mediaService.trackTitle
        : "No Media Playing"
    readonly property string displayArtist: topIslandMedia.mediaService && topIslandMedia.mediaService.trackArtist.length > 0
        ? topIslandMedia.mediaService.trackArtist
        : "Idle"
    readonly property real progressFraction: topIslandMedia.mediaService ? topIslandMedia.mediaService.trackProgress : 0.0

    // =========================================================
    // Media Row Layout
    // =========================================================
    Row {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: topIslandMedia.currentTheme.spacing.sm

        // Album Art / Monogram Thumbnail
        Rectangle {
            id: thumbRect
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            radius: topIslandMedia.currentTheme.geometry.radiusSmall
            color: topIslandMedia.currentTheme.colors.surfaceHighlight
            clip: true

            IconImage {
                id: albumArt
                anchors.fill: parent
                source: topIslandMedia.mediaService ? topIslandMedia.mediaService.trackArtUrl : ""
                visible: status === Image.Ready
            }

            Text {
                id: fallbackGlyph
                anchors.centerIn: parent
                visible: !albumArt.visible
                text: "♪"
                font.pixelSize: 11
                font.family: topIslandMedia.currentTheme.typography.fontFamilyMono
                color: topIslandMedia.currentTheme.colors.textMuted
            }
        }

        // Track & Artist Information (Fixed width to avoid dynamic jitter)
        Item {
            id: trackInfoBox
            width: 190
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 1

                Text {
                    width: parent.width
                    text: topIslandMedia.displayTitle
                    font.family: topIslandMedia.currentTheme.typography.fontFamily
                    font.pixelSize: topIslandMedia.currentTheme.typography.sizeCaption
                    font.weight: topIslandMedia.currentTheme.typography.weightMedium
                    color: topIslandMedia.currentTheme.colors.textPrimary
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: topIslandMedia.displayArtist
                    font.family: topIslandMedia.currentTheme.typography.fontFamilyMono
                    font.pixelSize: topIslandMedia.currentTheme.typography.sizeMicro
                    color: topIslandMedia.currentTheme.colors.textSecondary
                    elide: Text.ElideRight
                }
            }
        }

        // Controls: Previous, Play/Pause, Next
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: topIslandMedia.currentTheme.spacing.xs

            // Previous Button
            Rectangle {
                id: prevBtn
                width: 24
                height: 24
                radius: topIslandMedia.currentTheme.geometry.radiusSmall
                color: prevHover.hovered ? topIslandMedia.currentTheme.colors.surfaceElevated : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "⏮"
                    font.pixelSize: 10
                    color: prevHover.hovered ? topIslandMedia.currentTheme.colors.textPrimary : topIslandMedia.currentTheme.colors.textSecondary
                }

                HoverHandler {
                    id: prevHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (topIslandMedia.mediaService) topIslandMedia.mediaService.previous()
                    }
                }
            }

            // Play / Pause Toggle Button
            Rectangle {
                id: playBtn
                width: 24
                height: 24
                radius: topIslandMedia.currentTheme.geometry.radiusSmall
                color: playHover.hovered ? topIslandMedia.currentTheme.colors.surfaceElevated : topIslandMedia.currentTheme.colors.surfaceHighlight

                Text {
                    anchors.centerIn: parent
                    text: topIslandMedia.isPlaying ? "⏸" : "▶"
                    font.pixelSize: 11
                    color: playHover.hovered ? topIslandMedia.currentTheme.colors.dominant : topIslandMedia.currentTheme.colors.textPrimary
                }

                HoverHandler {
                    id: playHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (topIslandMedia.mediaService) topIslandMedia.mediaService.togglePlay()
                    }
                }
            }

            // Next Button
            Rectangle {
                id: nextBtn
                width: 24
                height: 24
                radius: topIslandMedia.currentTheme.geometry.radiusSmall
                color: nextHover.hovered ? topIslandMedia.currentTheme.colors.surfaceElevated : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "⏭"
                    font.pixelSize: 10
                    color: nextHover.hovered ? topIslandMedia.currentTheme.colors.textPrimary : topIslandMedia.currentTheme.colors.textSecondary
                }

                HoverHandler {
                    id: nextHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (topIslandMedia.mediaService) topIslandMedia.mediaService.next()
                    }
                }
            }
        }
    }

    // Hairline Track Progress (Subtle, 2px at bottom of compact surface)
    Rectangle {
        id: progressTrack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: topIslandMedia.currentTheme.colors.surfaceHighlight

        Rectangle {
            id: progressFill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.round(progressTrack.width * topIslandMedia.progressFraction)
            color: topIslandMedia.currentTheme.colors.dominant

            Behavior on width {
                NumberAnimation {
                    duration: topIslandMedia.currentTheme.motion.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}

