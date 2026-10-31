pragma ComponentBehavior: Bound

// BASEUS — Alphabet Fast Scroller
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §16, DESIGN.md §23, and DEC-022:
//   - Fixed A–Z–0–9–# fast navigation model
//   - Idle: ~1px subtle hairline rail on right edge, no permanent floating letters
//   - Active: ~3px rail, letter strip appears to the left
//   - Hierarchical scrubbing: selected letter enlarges/highlights, neighbors shrink/dim
//     ("Focus grows. Context recedes.")
//   - Emits letterSelected(token) to drive continuous grid jumping

import QtQuick
import "../theme"

Item {
    id: alphabetScroller

    // =========================================================
    // Properties & Theme
    // =========================================================
    property Theme theme: null
    readonly property Theme currentTheme: theme !== null ? theme : Theme

    readonly property var tokens: [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
        "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
        "U", "V", "W", "X", "Y", "Z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "#"
    ]

    property int selectedIndex: -1
    readonly property string selectedLetter: (selectedIndex >= 0 && selectedIndex < tokens.length)
        ? String(tokens[selectedIndex])
        : ""

    readonly property bool scrollerActive: scrubArea.containsMouse || scrubArea.pressed

    signal letterSelected(string letter)

    implicitWidth: 48

    // =========================================================
    // Scrub Interaction Handler
    // =========================================================
    function _updateScrub(mouseYCoord: real) {
        var h = scrubArea.height
        if (h <= 0) return
        var ratio = Math.max(0.0, Math.min(0.999, mouseYCoord / h))
        var idx = Math.floor(ratio * tokens.length)
        if (idx < 0) idx = 0
        if (idx >= tokens.length) idx = tokens.length - 1
        if (selectedIndex !== idx) {
            selectedIndex = idx
            alphabetScroller.letterSelected(tokens[idx])
        }
    }

    function selectLetter(letter: string): bool {
        var upper = String(letter || "").toUpperCase()
        for (var i = 0; i < alphabetScroller.tokens.length; i++) {
            if (alphabetScroller.tokens[i] === upper) {
                alphabetScroller.selectedIndex = i
                alphabetScroller.letterSelected(alphabetScroller.tokens[i])
                return true
            }
        }
        return false
    }

    // =========================================================
    // Subtle Vertical Rail (Idle: 1px, Active: 3px)
    // =========================================================
    Rectangle {
        id: rail
        anchors.right: parent.right
        anchors.rightMargin: 1
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: alphabetScroller.scrollerActive ? 3 : 1
        color: alphabetScroller.scrollerActive
            ? alphabetScroller.currentTheme.colors.dominant
            : alphabetScroller.currentTheme.colors.borderSubtle

        Behavior on width {
            NumberAnimation { duration: alphabetScroller.currentTheme.motion.durationFast }
        }
        Behavior on color {
            ColorAnimation { duration: alphabetScroller.currentTheme.motion.durationFast }
        }
    }

    // =========================================================
    // Alphabet Letters Column (Appears on Hover / Scrub)
    // =========================================================
    Item {
        id: letterStrip
        anchors.right: rail.left
        anchors.rightMargin: alphabetScroller.currentTheme.spacing.xs
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 32
        opacity: alphabetScroller.scrollerActive ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: alphabetScroller.currentTheme.motion.durationFast }
        }

        Column {
            anchors.fill: parent

            Repeater {
                model: alphabetScroller.tokens

                delegate: Item {
                    id: tokenDelegate
                    required property string modelData
                    required property int index

                    width: 32
                    height: letterStrip.height / alphabetScroller.tokens.length

                    readonly property int distance: alphabetScroller.selectedIndex >= 0
                        ? Math.abs(index - alphabetScroller.selectedIndex)
                        : 99

                    readonly property bool isSelected: distance === 0
                    readonly property bool isAdjacent: distance === 1
                    readonly property bool isNear: distance === 2

                    Text {
                        anchors.centerIn: parent
                        text: tokenDelegate.modelData
                        font.family: alphabetScroller.currentTheme.typography.fontFamilyMono
                        font.weight: tokenDelegate.isSelected ? Font.Bold : Font.Normal

                        font.pixelSize: tokenDelegate.isSelected
                            ? alphabetScroller.currentTheme.typography.sizeHeadline
                            : (tokenDelegate.isAdjacent
                                ? alphabetScroller.currentTheme.typography.sizeBody
                                : (tokenDelegate.isNear
                                    ? alphabetScroller.currentTheme.typography.sizeCaption
                                    : alphabetScroller.currentTheme.typography.sizeMicro))

                        color: tokenDelegate.isSelected
                            ? alphabetScroller.currentTheme.colors.dominant
                            : (tokenDelegate.isAdjacent
                                ? alphabetScroller.currentTheme.colors.textPrimary
                                : (tokenDelegate.isNear
                                    ? alphabetScroller.currentTheme.colors.textSecondary
                                    : alphabetScroller.currentTheme.colors.textMuted))

                        opacity: tokenDelegate.isSelected
                            ? 1.0
                            : (tokenDelegate.isAdjacent ? 0.85 : (tokenDelegate.isNear ? 0.5 : 0.25))

                        Behavior on font.pixelSize {
                            NumberAnimation { duration: alphabetScroller.currentTheme.motion.durationFast }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: alphabetScroller.currentTheme.motion.durationFast }
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // Mouse / Touch Scrub Area
    // =========================================================
    MouseArea {
        id: scrubArea
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: alphabetScroller.width
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        onPositionChanged: function(mouse) {
            if (pressed || containsMouse) {
                alphabetScroller._updateScrub(mouse.y)
            }
        }

        onPressed: function(mouse) {
            alphabetScroller._updateScrub(mouse.y)
        }

        onExited: {
            if (!pressed) {
                alphabetScroller.selectedIndex = -1
            }
        }

        onReleased: {
            if (!containsMouse) {
                alphabetScroller.selectedIndex = -1
            }
        }
    }
}
