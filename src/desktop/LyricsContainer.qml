// BASEUS — Media Widget Lyrics Container
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §31, DESIGN.md §33, and DEC-026:
//   - Structural lyrics slot within dedicated MediaWidget
//   - Synchronized line presentation when stream is active
//   - Restrained, legible typography with editorial fallback for instrumental/offline tracks
//   - Solid Wabi-sabi recessed surface, zero blur, zero drop shadows

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: lyricsContainer

    // =========================================================
    // Dependencies & Properties
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: lyricsContainer.theme ? lyricsContainer.theme : lyricsContainer.defaultTheme

    property var mediaService: null
    property string customLyrics: ""
    readonly property bool hasLyrics: customLyrics.length > 0

    radius: lyricsContainer.currentTheme.geometry.radiusSmall
    color: lyricsContainer.currentTheme.colors.surfaceContainerLowest
    border.width: 1
    border.color: lyricsContainer.currentTheme.colors.outlineVariant
    clip: true

    readonly property string activeTitle: lyricsContainer.mediaService ? lyricsContainer.mediaService.trackTitle : ""
    readonly property string activeArtist: lyricsContainer.mediaService ? lyricsContainer.mediaService.trackArtist : ""
    readonly property bool isPlaying: lyricsContainer.mediaService ? lyricsContainer.mediaService.isPlaying : false

    Column {
        anchors.fill: parent
        anchors.margins: lyricsContainer.currentTheme.spacing.sm
        spacing: 4

        // Subsystem Header
        Row {
            width: parent.width
            spacing: lyricsContainer.currentTheme.spacing.xs

            // Status indicator pip
            Rectangle {
                width: 6
                height: 6
                radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: lyricsContainer.isPlaying
                    ? lyricsContainer.currentTheme.colors.dominant
                    : lyricsContainer.currentTheme.colors.textMuted
            }

            Text {
                text: "LYRICS ARCHIVE"
                font.family: lyricsContainer.currentTheme.typography.fontFamilyMono
                font.pixelSize: lyricsContainer.currentTheme.typography.sizeMicro
                font.weight: lyricsContainer.currentTheme.typography.weightBold
                color: lyricsContainer.currentTheme.colors.textSecondary
            }
        }

        // Lyrics Body
        Item {
            width: parent.width
            height: parent.height - 18

            // Live / Custom Lyrics Stream
            Text {
                id: liveLyricsText
                anchors.centerIn: parent
                width: parent.width
                visible: lyricsContainer.hasLyrics
                text: lyricsContainer.customLyrics
                font.family: lyricsContainer.currentTheme.typography.fontFamily
                font.pixelSize: lyricsContainer.currentTheme.typography.sizeCaption
                font.weight: lyricsContainer.currentTheme.typography.weightMedium
                color: lyricsContainer.currentTheme.colors.textPrimary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }

            // Clean Editorial Fallback (Instrumental / Sync Idle)
            Column {
                anchors.centerIn: parent
                width: parent.width
                visible: !lyricsContainer.hasLyrics
                spacing: 2

                Text {
                    width: parent.width
                    text: lyricsContainer.activeTitle.length > 0
                        ? "“" + lyricsContainer.activeTitle + "”"
                        : "No Active Track"
                    font.family: lyricsContainer.currentTheme.typography.fontFamilyDisplay
                    font.pixelSize: lyricsContainer.currentTheme.typography.sizeCaption
                    font.weight: lyricsContainer.currentTheme.typography.weightMedium
                    color: lyricsContainer.currentTheme.colors.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: lyricsContainer.isPlaying
                        ? (lyricsContainer.activeArtist.length > 0 ? lyricsContainer.activeArtist + " — Playback Active" : "Playback Active")
                        : "Stream Paused / Synchronized Lyrics Idle"
                    font.family: lyricsContainer.currentTheme.typography.fontFamilyMono
                    font.pixelSize: lyricsContainer.currentTheme.typography.sizeMicro
                    color: lyricsContainer.currentTheme.colors.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }
    }

    function getSnapshot(): var {
        return {
            hasLyrics: lyricsContainer.hasLyrics,
            activeTrack: lyricsContainer.activeTitle,
            activeArtist: lyricsContainer.activeArtist,
            isPlaying: lyricsContainer.isPlaying
        }
    }
}

