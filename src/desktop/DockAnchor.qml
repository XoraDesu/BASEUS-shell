// BASEUS — Dock Idle Anchor & Scaffolding
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §10; DESIGN.md §9, §10, §11, §14; ANTI-SLOP.md; and DEC-015:
//   - Bottom-centered edge-integrated solid Wabi-sabi surface (not floating)
//   - Flush with bottom display perimeter (radiusFlush: 0), rounded top corners (12px)
//   - Flanked by Inverse Corner Radius (ICR) organic fillets
//   - Hidden/recessed by default at idle with a bottom 1–2px invisible cursor trigger strip
//   - Contextual reveal from cursor trigger, auto-receding when cursor leaves dock bounds
//   - Dynamic input region mask so empty desktop remains 100% click-through at idle
//   - Recedes smoothly when native fullscreen is active on this monitor (DEC-023)

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: dockAnchor

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: dockAnchor.theme ? dockAnchor.theme : dockAnchor.defaultTheme
    property bool isFullscreen: false

    property var config: null
    property var windowModel: null
    property var workspaceModel: null
    property var bridge: null
    property int monitorIndex: 0

    // Dimensions
    readonly property int dockHeight: 48
    readonly property int minDockWidth: 160
    readonly property int triggerHeight: 2

    // State Machine
    property bool revealed: false

    // Dock Model & Telemetry (M2-T2)
    DockModel {
        id: dockModel
        config: dockAnchor.config
        windowModel: dockAnchor.windowModel
        workspaceModel: dockAnchor.workspaceModel
        bridge: dockAnchor.bridge
        monitorIndex: dockAnchor.monitorIndex
    }

    readonly property alias model: dockModel
    readonly property int itemCount: dockModel.itemCount
    readonly property var dockItems: dockModel.items

    function getSnapshot(): var {
        return dockModel.getSnapshot()
    }

    function activateItemById(id: string): bool {
        for (var i = 0; i < dockModel.items.length; i++) {
            var it = dockModel.items[i]
            if (it && (it.id === id || it.pinId === id || it.appClass === id)) {
                return dockModel.activateItem(it)
            }
        }
        return false
    }

    // Layer-shell mask aliases
    readonly property alias triggerItem: triggerArea
    readonly property alias hitRegionItem: activeHitBox
    readonly property alias bodyItem: dockBody

    anchors.bottom: parent ? parent.bottom : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    height: dockAnchor.dockHeight + dockAnchor.triggerHeight
    width: dockBody.width + (dockAnchor.currentTheme.geometry.dockIcr * 2)

    // Fullscreen recession (DESIGN.md §14, DEC-023)
    opacity: dockAnchor.isFullscreen ? 0.0 : 1.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: dockAnchor.currentTheme.motion.reducedMotion ? 0 : dockAnchor.currentTheme.motion.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    // =========================================================
    // Reveal & Recess Control API
    // =========================================================

    function reveal() {
        exitTimer.stop()
        dockAnchor.revealed = true
    }

    function hide() {
        exitTimer.stop()
        dockAnchor.revealed = false
    }

    function toggle() {
        if (dockAnchor.revealed) {
            dockAnchor.hide()
        } else {
            dockAnchor.reveal()
        }
    }

    // =========================================================
    // 1–2px Bottom-Edge Cursor Trigger (MASTER.md §10, DEC-015)
    // =========================================================
    Item {
        id: triggerArea
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(dockBody.width, 360)
        height: dockAnchor.triggerHeight

        HoverHandler {
            id: triggerHover
            onHoveredChanged: {
                if (triggerHover.hovered) {
                    dockAnchor.reveal()
                }
            }
        }
    }

    // =========================================================
    // Dynamic Input Mask Hit Box (DEC-029)
    // =========================================================
    // When idle: exactly the 1–2px bottom trigger.
    // When revealed: expands to cover the dock body and ICR fillets.
    Item {
        id: activeHitBox
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: dockAnchor.revealed ? (dockBody.width + (dockAnchor.currentTheme.geometry.dockIcr * 2)) : triggerArea.width
        height: dockAnchor.revealed ? dockAnchor.dockHeight : dockAnchor.triggerHeight
    }

    // =========================================================
    // Dock Container (Slides into view from bottom screen edge)
    // =========================================================
    Item {
        id: dockContainer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: dockAnchor.revealed ? 0 : -dockAnchor.dockHeight
        height: dockAnchor.dockHeight
        width: dockBody.width + (dockAnchor.currentTheme.geometry.dockIcr * 2)

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: dockAnchor.currentTheme.motion.reducedMotion ? 0 : dockAnchor.currentTheme.motion.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: dockHover
            onHoveredChanged: {
                if (dockHover.hovered) {
                    exitTimer.stop()
                    dockAnchor.reveal()
                } else {
                    exitTimer.restart()
                }
            }
        }

        // Left ICR Fillet (flares into bottom display edge)
        ThemeModule.InverseCorner {
            id: leftIcr
            anchors.right: dockBody.left
            anchors.bottom: dockBody.bottom
            cornerRadius: dockAnchor.currentTheme.geometry.dockIcr
            fillColor: dockAnchor.currentTheme.colors.surfaceSolid
            position: "bottom-left"
        }

        // Dock Solid Body (Edge-integrated Wabi-sabi surface)
        Rectangle {
            id: dockBody
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            height: dockAnchor.dockHeight
            width: Math.max(contentRow.width + 36, dockAnchor.minDockWidth)

            color: dockAnchor.currentTheme.colors.surfaceSolid

            // Edge integration: rounded top corners (12), flush bottom corners (0)
            topLeftRadius: dockAnchor.currentTheme.geometry.dockRadiusTop
            topRightRadius: dockAnchor.currentTheme.geometry.dockRadiusTop
            bottomLeftRadius: dockAnchor.currentTheme.geometry.dockRadiusBottom
            bottomRightRadius: dockAnchor.currentTheme.geometry.dockRadiusBottom

            // Hairline boundary (no neon glow, DEC-011)
            border.width: dockAnchor.currentTheme.geometry.borderWidth
            border.color: dockAnchor.currentTheme.colors.borderSubtle

            // Items content row (M2-T2)
            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: dockAnchor.currentTheme.spacing.xs

                Repeater {
                    model: dockModel.items

                    DockItem {
                        id: itemDelegate
                        required property var modelData
                        itemData: itemDelegate.modelData
                        theme: dockAnchor.currentTheme
                        onActivated: function(data) {
                            dockModel.activateItem(data)
                        }
                    }
                }
            }
        }

        // Right ICR Fillet (flares into bottom display edge)
        ThemeModule.InverseCorner {
            id: rightIcr
            anchors.left: dockBody.right
            anchors.bottom: dockBody.bottom
            cornerRadius: dockAnchor.currentTheme.geometry.dockIcr
            fillColor: dockAnchor.currentTheme.colors.surfaceSolid
            position: "bottom-right"
        }
    }

    // =========================================================
    // Auto-Recess Timer (400ms leave grace period)
    // =========================================================
    Timer {
        id: exitTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (!dockHover.hovered && !triggerHover.hovered) {
                dockAnchor.hide()
            }
        }
    }
}

