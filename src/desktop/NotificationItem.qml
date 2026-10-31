// BASEUS — Notification Item Surface
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §30, DESIGN.md §17, §18, DEC-020, and ANTI-SLOP.md §20:
//   - Floating surface in the top-left with left-to-right reveal
//   - Large background application icon with ~70% transparency (opacity: 0.30)
//   - Overlapping legible typography (prominent title, smaller message)
//   - Solid Wabi-sabi palette surface (surfaceSolid + borderSubtle hairline)
//   - Zero glassmorphism, zero blur, zero drop shadows
//   - Interaction:
//       * click → activate/launch
//       * double-click → dismiss immediately
//       * hold ~2 seconds → silence all notifications with left-to-right tonal progress fill
//       * hover → reveal full message and pause timeout

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import "../theme" as ThemeModule

Rectangle {
    id: notificationItem

    // =========================================================
    // Dependencies & Data
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: notificationItem.theme ? notificationItem.theme : notificationItem.defaultTheme

    property var itemData: null

    readonly property int notificationId: notificationItem.itemData ? Number(notificationItem.itemData.id || 0) : 0
    readonly property string appName: notificationItem.itemData ? String(notificationItem.itemData.appName || "System") : "System"
    readonly property string appIcon: notificationItem.itemData ? String(notificationItem.itemData.appIcon || "") : ""
    readonly property string summaryText: notificationItem.itemData ? String(notificationItem.itemData.summary || "") : ""
    readonly property string bodyText: notificationItem.itemData ? String(notificationItem.itemData.body || "") : ""
    readonly property string urgencyLevel: notificationItem.itemData ? String(notificationItem.itemData.urgency || "normal") : "normal"
    readonly property var actionList: (notificationItem.itemData && notificationItem.itemData.actions) ? notificationItem.itemData.actions : []

    readonly property bool isCritical: notificationItem.urgencyLevel === "critical"

    // Signals
    signal dismissed(int id)
    signal activated(int id)
    signal actionInvoked(int id, string actionId)
    signal silenced()
    signal hoverChanged(bool hovered)

    // =========================================================
    // Geometry & Styling (Solid Wabi-sabi, ANTI-SLOP.md §20)
    // =========================================================
    width: 360
    height: implicitHeight
    implicitHeight: Math.min(220, Math.max(76, contentColumn.implicitHeight + 24))

    radius: notificationItem.currentTheme.geometry.radiusLarge
    color: notificationItem.currentTheme.colors.surfaceSolid
    border.width: 1
    border.color: notificationItem.isCritical
        ? notificationItem.currentTheme.colors.statusWarning
        : (itemMouseArea.containsMouse ? notificationItem.currentTheme.colors.dominant : notificationItem.currentTheme.colors.borderSubtle)

    clip: true

    // Left-to-right reveal transition (DESIGN.md §17)
    transform: Translate {
        id: slideTrans
        x: -400
    }

    Component.onCompleted: {
        revealAnim.start()
    }

    NumberAnimation {
        id: revealAnim
        target: slideTrans
        property: "x"
        from: -400
        to: 0
        duration: notificationItem.currentTheme.motion.durationNormal
        easing.type: Easing.OutCubic
    }

    // =========================================================
    // Hold-to-Silence Interaction State (DESIGN.md §18)
    // =========================================================
    property real holdProgress: 0.0
    property bool isSilentState: false

    Rectangle {
        id: silenceProgressFill
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * notificationItem.holdProgress
        color: notificationItem.currentTheme.colors.surfaceHighlight
        visible: notificationItem.holdProgress > 0.0
    }

    NumberAnimation {
        id: holdAnim
        target: notificationItem
        property: "holdProgress"
        from: 0.0
        to: 1.0
        duration: 2000
        easing.type: Easing.Linear

        onFinished: {
            if (notificationItem.holdProgress >= 1.0) {
                notificationItem.isSilentState = true
                silenceConfirmationTimer.start()
            }
        }
    }

    Timer {
        id: silenceConfirmationTimer
        interval: 350
        repeat: false
        onTriggered: {
            notificationItem.silenced()
        }
    }

    // =========================================================
    // 70% Transparent Background Application Icon (DESIGN.md §17)
    // =========================================================
    Item {
        id: bgIconContainer
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 80
        height: 80
        opacity: 0.30 // ~70% transparency per MASTER.md §30 and DESIGN.md §17
        clip: true

        IconImage {
            id: bgIcon
            anchors.fill: parent
            source: notificationItem.appIcon
            visible: status === Image.Ready
        }

        Text {
            id: fallbackGlyph
            anchors.centerIn: parent
            visible: !bgIcon.visible
            text: notificationItem.appName.length > 0 ? notificationItem.appName.substring(0, 1).toUpperCase() : ""
            font.pixelSize: 64
            font.bold: true
            font.family: notificationItem.currentTheme.typography.fontFamilyMono
            color: notificationItem.currentTheme.colors.textMuted
        }
    }

    // =========================================================
    // Content Layout (Overlapping Legible Typography)
    // =========================================================
    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 12
        spacing: notificationItem.currentTheme.spacing.xs

        // Header Row: App Name, Urgency badge, Silent state, Close
        Row {
            width: parent.width
            spacing: notificationItem.currentTheme.spacing.sm

            Text {
                text: notificationItem.appName.toUpperCase()
                font.pixelSize: notificationItem.currentTheme.typography.sizeMicro
                font.letterSpacing: notificationItem.currentTheme.typography.letterSpacingCaps
                font.bold: true
                font.family: notificationItem.currentTheme.typography.fontFamilyMono
                color: notificationItem.isCritical
                    ? notificationItem.currentTheme.colors.statusWarning
                    : notificationItem.currentTheme.colors.textMuted
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 200)
            }

            Rectangle {
                id: silentBadge
                visible: notificationItem.isSilentState
                width: silentLabel.implicitWidth + 8
                height: 14
                radius: notificationItem.currentTheme.geometry.radiusSmall
                color: notificationItem.currentTheme.colors.surfaceHighlight
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: silentLabel
                    anchors.centerIn: parent
                    text: "SILENT"
                    font.pixelSize: 9
                    font.bold: true
                    font.family: notificationItem.currentTheme.typography.fontFamilyMono
                    color: notificationItem.currentTheme.colors.textPrimary
                }
            }

            Item {
                // Flexible spacer
                width: Math.max(0, parent.width - (parent.children[0].width + (silentBadge.visible ? silentBadge.width + 8 : 0) + closeBtn.width + 16))
                height: 1
            }

            Rectangle {
                id: closeBtn
                width: 18
                height: 18
                radius: notificationItem.currentTheme.geometry.radiusSmall
                color: closeHover.hovered ? notificationItem.currentTheme.colors.surfaceElevated : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 14
                    color: closeHover.hovered ? notificationItem.currentTheme.colors.textPrimary : notificationItem.currentTheme.colors.textMuted
                }

                HoverHandler {
                    id: closeHover
                }

                TapHandler {
                    onTapped: {
                        notificationItem.dismissed(notificationItem.notificationId)
                    }
                }
            }
        }

        // Summary / Title
        Text {
            id: summaryLabel
            width: parent.width
            text: notificationItem.summaryText
            font.pixelSize: notificationItem.currentTheme.typography.sizeTitle
            font.bold: true
            font.family: notificationItem.currentTheme.typography.fontFamily
            color: notificationItem.currentTheme.colors.textPrimary
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Body Message (Hover reveals full content per MASTER.md §30)
        Text {
            id: bodyLabel
            width: parent.width
            text: notificationItem.bodyText
            visible: text.length > 0
            font.pixelSize: notificationItem.currentTheme.typography.sizeBody
            font.family: notificationItem.currentTheme.typography.fontFamily
            color: notificationItem.currentTheme.colors.textSecondary
            wrapMode: Text.Wrap
            maximumLineCount: itemMouseArea.containsMouse ? 8 : 3
            elide: Text.ElideRight
        }

        // Action Buttons Row (Solid pills, ANTI-SLOP.md)
        Row {
            id: actionsRow
            visible: notificationItem.actionList.length > 0
            spacing: notificationItem.currentTheme.spacing.xs
            topPadding: 4

            Repeater {
                model: notificationItem.actionList

                delegate: Rectangle {
                    id: actionPill
                    required property var modelData
                    required property int index

                    readonly property string actId: String(modelData.id || "")
                    readonly property string actText: String(modelData.text || "")

                    width: actLabel.implicitWidth + 16
                    height: 24
                    radius: notificationItem.currentTheme.geometry.radiusSmall
                    color: actHover.hovered
                        ? notificationItem.currentTheme.colors.surfaceHighlight
                        : notificationItem.currentTheme.colors.surfaceElevated
                    border.width: 1
                    border.color: actHover.hovered
                        ? notificationItem.currentTheme.colors.dominant
                        : notificationItem.currentTheme.colors.borderSubtle

                    Text {
                        id: actLabel
                        anchors.centerIn: parent
                        text: actionPill.actText
                        font.pixelSize: notificationItem.currentTheme.typography.sizeCaption
                        font.family: notificationItem.currentTheme.typography.fontFamily
                        color: actHover.hovered
                            ? notificationItem.currentTheme.colors.textPrimary
                            : notificationItem.currentTheme.colors.textSecondary
                    }

                    HoverHandler {
                        id: actHover
                    }

                    TapHandler {
                        onTapped: {
                            notificationItem.actionInvoked(notificationItem.notificationId, actionPill.actId)
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // Mouse Interaction (Click, Double-Click, Hold-to-Silence, Hover)
    // =========================================================
    MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onEntered: {
            notificationItem.hoverChanged(true)
        }

        onExited: {
            notificationItem.hoverChanged(false)
            if (holdAnim.running) {
                holdAnim.stop()
                notificationItem.holdProgress = 0.0
            }
        }

        onPressed: mouse => {
            if (mouse.button === Qt.LeftButton) {
                holdAnim.restart()
            }
        }

        onReleased: {
            if (holdAnim.running) {
                holdAnim.stop()
                notificationItem.holdProgress = 0.0
            }
        }

        onDoubleClicked: {
            holdAnim.stop()
            notificationItem.holdProgress = 0.0
            notificationItem.dismissed(notificationItem.notificationId)
        }

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (notificationItem.holdProgress < 1.0 && !notificationItem.isSilentState) {
                    notificationItem.activated(notificationItem.notificationId)
                }
            }
        }
    }
}
