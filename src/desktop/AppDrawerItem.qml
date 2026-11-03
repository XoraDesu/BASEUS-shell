pragma ComponentBehavior: Bound

// BASEUS — App Drawer Item
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §14, DESIGN.md §20–21, and DEC-018:
//   - Grid item tile representing an application in the App Drawer
//   - Clean application icon with typographical fallback glyph
//   - Readable application title
//   - Zero running indicators (running state belongs exclusively to Dock per DEC-018)
//   - Tactile state layer hover/press feedback with micro-motion duration
//   - Solid Wabi-sabi hover highlight without nested card containers (ANTI-SLOP.md §6.1)

import QtQuick
import Quickshell.Widgets
import "../theme"

Item {
    id: appDrawerItem

    // =========================================================
    // Properties & Theme
    // =========================================================
    property Theme theme: null
    readonly property Theme currentTheme: theme !== null ? theme : Theme

    required property var itemData
    property bool active: false

    signal clicked()
    signal rightClicked()

    readonly property string appId: itemData ? String(itemData.id || "") : ""
    readonly property string appTitle: itemData ? String(itemData.title || itemData.id || "") : ""
    readonly property string appCommand: itemData ? String(itemData.command || "") : ""
    readonly property string appIcon: itemData ? String(itemData.icon || "") : ""
    readonly property string appSection: itemData ? String(itemData.section || "") : ""

    implicitWidth: 150
    implicitHeight: 96

    // =========================================================
    // Surface & Tactile State Feedback
    // =========================================================
    Rectangle {
        id: itemBackground
        anchors.fill: parent
        anchors.margins: appDrawerItem.currentTheme.spacing.xs
        color: mouseArea.pressed
            ? appDrawerItem.currentTheme.colors.statePressed
            : (mouseArea.containsMouse
                ? appDrawerItem.currentTheme.colors.stateHover
                : (appDrawerItem.active ? appDrawerItem.currentTheme.colors.stateSelected : "transparent"))
        border.color: mouseArea.containsMouse
            ? appDrawerItem.currentTheme.colors.outlineVariant
            : (appDrawerItem.active ? appDrawerItem.currentTheme.colors.borderFocus : "transparent")
        border.width: 1
        radius: appDrawerItem.currentTheme.geometry.radiusMedium

        Behavior on color {
            ColorAnimation {
                duration: appDrawerItem.currentTheme.motion.durationMicro
                easing.type: appDrawerItem.currentTheme.motion.easingMicro
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: appDrawerItem.currentTheme.motion.durationMicro
                easing.type: appDrawerItem.currentTheme.motion.easingMicro
            }
        }

        // =====================================================
        // Icon & Title Column
        // =====================================================
        Column {
            anchors.centerIn: parent
            spacing: appDrawerItem.currentTheme.spacing.xs
            width: parent.width - (appDrawerItem.currentTheme.spacing.sm * 2)

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: 40

                IconImage {
                    id: iconImg
                    anchors.fill: parent
                    source: appDrawerItem.appIcon
                    visible: status === Image.Ready
                }

                Rectangle {
                    id: fallbackGlyph
                    anchors.fill: parent
                    color: appDrawerItem.currentTheme.colors.surfaceContainerLowest
                    border.color: appDrawerItem.currentTheme.colors.outlineVariant
                    border.width: 1
                    radius: appDrawerItem.currentTheme.geometry.concentricRadius(appDrawerItem.currentTheme.geometry.radiusMedium, 4)
                    visible: !iconImg.visible

                    Text {
                        anchors.centerIn: parent
                        text: appDrawerItem.appTitle.length > 0 ? appDrawerItem.appTitle.substring(0, 1).toUpperCase() : "?"
                        font.family: appDrawerItem.currentTheme.typography.fontFamilyMono
                        font.pixelSize: appDrawerItem.currentTheme.typography.sizeTitle
                        font.weight: Font.DemiBold
                        color: appDrawerItem.currentTheme.colors.dominant
                    }
                }
            }

            Text {
                id: titleText
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: appDrawerItem.appTitle
                font.family: appDrawerItem.currentTheme.typography.fontFamily
                font.pixelSize: appDrawerItem.currentTheme.typography.sizeBody
                color: mouseArea.containsMouse
                    ? appDrawerItem.currentTheme.colors.textPrimary
                    : appDrawerItem.currentTheme.colors.textSecondary
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
            }
        }
    }

    // =========================================================
    // Pointer Interaction
    // =========================================================
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                appDrawerItem.rightClicked()
            } else {
                appDrawerItem.clicked()
            }
        }
    }
}
