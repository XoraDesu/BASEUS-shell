// BASEUS — Notification Host Surface
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §30, DESIGN.md §17, §18, DEC-020, and ANTI-SLOP.md §20:
//   - Anchored top-left with 16px margins
//   - Stacks visible notifications vertically (maxVisible: 3 to avoid desktop slop)
//   - Dynamic Layer-Shell input mask (hitRegionItem):
//       * width=0, height=0 when 0 notifications are active (100% click-through idle desktop space)
//       * dynamically expands to exact bounding footprint when notifications are displayed
//   - Native application fullscreen recession (DESIGN.md §14)
//   - Hover pause and hold-to-silence coordination

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: notificationHost

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: notificationHost.theme ? notificationHost.theme : notificationHost.defaultTheme

    property var notificationModel: null
    property bool isFullscreen: false
    property int monitorIndex: 0

    // Top-left anchor placement (DESIGN.md §17, DEC-020)
    anchors.top: parent ? parent.top : undefined
    anchors.left: parent ? parent.left : undefined
    anchors.topMargin: 16
    anchors.leftMargin: 16

    readonly property bool hasVisibleNotifications: notificationHost.notificationModel
        ? notificationHost.notificationModel.notifications.length > 0
        : false

    width: 360
    height: hasVisibleNotifications ? Math.max(notifColumn.implicitHeight, notifColumn.childrenRect.height) : 0

    // Native application fullscreen recession (DESIGN.md §14)
    opacity: notificationHost.isFullscreen ? 0.0 : 1.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: notificationHost.currentTheme.motion.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    // =========================================================
    // Dynamic Layer-Shell Input Hitmask (DEC-029 pattern)
    // =========================================================
    // When no notifications are active, boundingBox has width 0, height 0,
    // ensuring the entire top-left desktop region is completely click-through.
    readonly property alias hitRegionItem: boundingBox

    Item {
        id: boundingBox
        anchors.top: parent.top
        anchors.left: parent.left
        width: (notificationHost.hasVisibleNotifications && notificationHost.visible) ? 360 : 0
        height: (notificationHost.hasVisibleNotifications && notificationHost.visible) ? Math.max(notifColumn.implicitHeight, notifColumn.childrenRect.height) : 0
    }

    // =========================================================
    // Notification Stack Layout
    // =========================================================
    Column {
        id: notifColumn
        anchors.top: parent.top
        anchors.left: parent.left
        width: 360
        spacing: notificationHost.currentTheme.spacing.sm

        Repeater {
            model: {
                if (!notificationHost.notificationModel) return []
                var list = notificationHost.notificationModel.notifications
                var maxN = notificationHost.notificationModel.maxVisible
                return list.slice(0, maxN)
            }

            delegate: NotificationItem {
                id: itemDelegate
                required property var modelData
                required property int index

                theme: notificationHost.theme
                itemData: modelData

                onDismissed: id => {
                    if (notificationHost.notificationModel) {
                        notificationHost.notificationModel.dismiss(id)
                    }
                }

                onActivated: id => {
                    // Activate / launch app
                    if (notificationHost.notificationModel) {
                        notificationHost.notificationModel.dismiss(id)
                    }
                }

                onActionInvoked: (id, actionId) => {
                    if (notificationHost.notificationModel) {
                        notificationHost.notificationModel.invokeAction(id, actionId)
                    }
                }

                onSilenced: {
                    if (notificationHost.notificationModel) {
                        notificationHost.notificationModel.silenceAll()
                    }
                }

                onHoverChanged: hovered => {
                    if (notificationHost.notificationModel) {
                        notificationHost.notificationModel.setPaused(hovered)
                    }
                }
            }
        }
    }

    // =========================================================
    // Diagnostic Snapshot
    // =========================================================
    function getSnapshot(): var {
        return {
            available: true,
            monitorIndex: notificationHost.monitorIndex,
            visible: notificationHost.visible,
            isFullscreen: notificationHost.isFullscreen,
            count: notificationHost.notificationModel ? notificationHost.notificationModel.count : 0,
            hasVisible: notificationHost.hasVisibleNotifications,
            hitRegion: {
                width: boundingBox.width,
                height: boundingBox.height
            }
        }
    }
}

