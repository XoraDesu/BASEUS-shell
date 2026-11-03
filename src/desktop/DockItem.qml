// BASEUS — Dock Item
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §10; DESIGN.md §11; ANTI-SLOP.md §6.1; and DEC-015:
//   - Clean direct composition on solid dock surface (STRICTLY NO card-in-card slop)
//   - Icon presentation with monospace typographical fallback
//   - Hierarchical running indicator pip (dominant elongated pill when focused,
//     primary pip when running on current workspace, muted pip when on other workspace)
//   - Subtle multi-window instance count badge (> 1)
//   - Tactile state layer hover/press feedback with micro-motion duration
//   - Smooth hover highlight and click activation

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import "../theme" as ThemeModule

Item {
    id: dockItem

    // =========================================================
    // Properties & Configuration
    // =========================================================
    property var itemData: null
    property var theme: null

    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: dockItem.theme ? dockItem.theme : dockItem.defaultTheme

    readonly property bool isRunning: dockItem.itemData ? Boolean(dockItem.itemData.isRunning) : false
    readonly property bool isFocused: dockItem.itemData ? Boolean(dockItem.itemData.isFocused) : false
    readonly property int windowCount: dockItem.itemData ? (dockItem.itemData.windowCount || 0) : 0
    readonly property bool hasWindowsOnWorkspace: dockItem.itemData ? Boolean(dockItem.itemData.hasWindowsOnWorkspace) : false
    readonly property string appTitle: dockItem.itemData ? String(dockItem.itemData.title || "") : ""
    readonly property string appIcon: dockItem.itemData ? String(dockItem.itemData.icon || "") : ""

    signal activated(var data)

    width: 36
    height: 36
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    // =========================================================
    // Hover / Press Highlight (Tactile State Layers, ANTI-SLOP.md)
    // =========================================================
    Rectangle {
        id: hoverBg
        anchors.fill: parent
        radius: dockItem.currentTheme.geometry.radiusSmall
        color: mouseArea.pressed
            ? dockItem.currentTheme.colors.statePressed
            : (mouseArea.containsMouse ? dockItem.currentTheme.colors.stateHover : "transparent")

        Behavior on color {
            ColorAnimation {
                duration: dockItem.currentTheme.motion.durationMicro
                easing.type: dockItem.currentTheme.motion.easingMicro
            }
        }
    }

    // =========================================================
    // Application Icon / Typographical Glyph
    // =========================================================
    IconImage {
        id: iconImg
        anchors.centerIn: parent
        anchors.verticalCenterOffset: dockItem.isRunning ? -2 : 0
        width: 20
        height: 20
        source: dockItem.appIcon
        visible: status === Image.Ready
    }

    Text {
        id: glyphText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: dockItem.isRunning ? -2 : 0
        text: dockItem.appTitle.length > 0 ? dockItem.appTitle.substring(0, 1).toUpperCase() : "?"
        font.family: dockItem.currentTheme.typography.fontFamilyMono
        font.pixelSize: dockItem.currentTheme.typography.sizeBody
        font.weight: Font.DemiBold
        color: dockItem.isFocused
               ? dockItem.currentTheme.colors.dominant
               : (mouseArea.containsMouse ? dockItem.currentTheme.colors.textPrimary : dockItem.currentTheme.colors.textSecondary)
        visible: !iconImg.visible
    }

    // =========================================================
    // Running State Indicator Pip ("Focus grows. Context recedes.")
    // =========================================================
    Rectangle {
        id: runningPip
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: dockItem.isFocused ? 12 : 4
        height: 3
        radius: dockItem.currentTheme.geometry.radiusPill
        color: dockItem.isFocused
               ? dockItem.currentTheme.colors.dominant
               : (dockItem.hasWindowsOnWorkspace ? dockItem.currentTheme.colors.textPrimary : dockItem.currentTheme.colors.textMuted)
        visible: dockItem.isRunning

        Behavior on width {
            NumberAnimation {
                duration: dockItem.currentTheme.motion.durationFast
                easing.type: dockItem.currentTheme.motion.easingStandard
            }
        }
    }

    // =========================================================
    // Multi-Window Instance Count Badge (Shown only when > 1)
    // =========================================================
    Text {
        id: multiCountText
        anchors.top: parent.top
        anchors.topMargin: 2
        anchors.right: parent.right
        anchors.rightMargin: 3
        text: dockItem.windowCount > 1 ? String(dockItem.windowCount) : ""
        font.family: dockItem.currentTheme.typography.fontFamilyMono
        font.pixelSize: 8
        font.weight: Font.Bold
        color: dockItem.isFocused ? dockItem.currentTheme.colors.dominant : dockItem.currentTheme.colors.textSecondary
        visible: dockItem.windowCount > 1
    }

    // =========================================================
    // Interaction MouseArea
    // =========================================================
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dockItem.activated(dockItem.itemData)
        }
    }
}
