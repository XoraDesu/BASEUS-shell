// BASEUS — Session & Power Management Constellation Overlay
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §32, DESIGN.md §31, DEC-027, and ANTI-SLOP.md:
//   - Fullscreen constellation composition: quiet dark space, palette-aware stars, sparse layout
//   - Five core session actions: Lock, Sleep (Suspend), Logout, Restart (Reboot), Shutdown (Poweroff)
//   - Strict accidental trigger prevention: hold-to-confirm progress fill for destructive actions (reboot, poweroff)
//   - Mnemonic shortcuts (L, S, O, R, P) & Arrow / Enter / Escape navigation
//   - Restrained sleeping chibi companion with zero-CPU idle timer gating
//   - Solid Wabi-sabi palette styling (Theme.colors.surfaceBase + borderSubtle), zero blur, zero drop shadows

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: sessionOverlayRoot

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: sessionOverlayRoot.theme ? sessionOverlayRoot.theme : sessionOverlayRoot.defaultTheme

    property var powerService: null
    property var shellState: null
    property var hostRef: null
    property int monitorIndex: 0

    // =========================================================
    // State Properties
    // =========================================================
    property bool active: false
    property int selectedIndex: 0
    property bool isHolding: false
    property real holdingProgress: 0.0 // 0.0 .. 1.0

    signal dismissRequested()

    readonly property var actions: [
        { "id": "lock", "label": "LOCK", "num": "01", "subtitle": "Secure Screen", "shortcut": "L", "destructive": false, "xOffset": -280, "yOffset": -40 },
        { "id": "suspend", "label": "SLEEP", "num": "02", "subtitle": "Suspend System", "shortcut": "S", "destructive": false, "xOffset": -140, "yOffset": 30 },
        { "id": "logout", "label": "LOGOUT", "num": "03", "subtitle": "End Session", "shortcut": "O", "destructive": false, "xOffset": 0, "yOffset": -50 },
        { "id": "reboot", "label": "RESTART", "num": "04", "subtitle": "Reboot System", "shortcut": "R", "destructive": true, "xOffset": 140, "yOffset": 30 },
        { "id": "poweroff", "label": "SHUTDOWN", "num": "05", "subtitle": "Power Off", "shortcut": "P", "destructive": true, "xOffset": 280, "yOffset": -40 }
    ]

    // =========================================================
    // Timers
    // =========================================================
    Timer {
        id: holdTimer
        interval: 16
        repeat: true
        running: sessionOverlayRoot.isHolding && sessionOverlayRoot.active
        onTriggered: {
            sessionOverlayRoot.holdingProgress = Math.min(1.0, sessionOverlayRoot.holdingProgress + (16.0 / 1000.0))
            if (sessionOverlayRoot.holdingProgress >= 1.0) {
                holdTimer.stop()
                sessionOverlayRoot.isHolding = false
                sessionOverlayRoot._triggerSelectedAction()
            }
        }
    }

    // =========================================================
    // Public Control Methods
    // =========================================================
    function open(initialIndex: int) {
        sessionOverlayRoot.cancelHold()
        if (typeof initialIndex === "number" && initialIndex >= 0 && initialIndex < sessionOverlayRoot.actions.length) {
            sessionOverlayRoot.selectedIndex = initialIndex
        } else {
            sessionOverlayRoot.selectedIndex = 0
        }
        sessionOverlayRoot.active = true
        sessionOverlayRoot.forceActiveFocus()
    }

    function close() {
        sessionOverlayRoot.cancelHold()
        sessionOverlayRoot.active = false
    }

    function toggle() {
        if (sessionOverlayRoot.active) {
            sessionOverlayRoot.close()
        } else {
            sessionOverlayRoot.open(0)
        }
    }

    function cancelHold() {
        sessionOverlayRoot.isHolding = false
        sessionOverlayRoot.holdingProgress = 0.0
    }

    function selectAction(index: int) {
        if (index >= 0 && index < sessionOverlayRoot.actions.length) {
            sessionOverlayRoot.cancelHold()
            sessionOverlayRoot.selectedIndex = index
        }
    }

    function selectActionById(actionId: string) {
        for (var i = 0; i < sessionOverlayRoot.actions.length; i++) {
            if (sessionOverlayRoot.actions[i].id === actionId) {
                sessionOverlayRoot.selectAction(i)
                return
            }
        }
    }

    function executeCurrentAction() {
        var act = sessionOverlayRoot.actions[sessionOverlayRoot.selectedIndex]
        if (!act) return
        if (act.destructive) {
            // Require hold completion
            sessionOverlayRoot.isHolding = true
            sessionOverlayRoot.holdingProgress = 0.0
        } else {
            sessionOverlayRoot._triggerSelectedAction()
        }
    }

    function _triggerSelectedAction() {
        var act = sessionOverlayRoot.actions[sessionOverlayRoot.selectedIndex]
        if (!act) return
        var actionId = act.id

        if (sessionOverlayRoot.powerService && typeof sessionOverlayRoot.powerService.execute === "function") {
            sessionOverlayRoot.powerService.execute(actionId)
        }

        sessionOverlayRoot.close()
        sessionOverlayRoot.dismissRequested()
    }

    function getSnapshot(): var {
        var act = (sessionOverlayRoot.selectedIndex >= 0 && sessionOverlayRoot.selectedIndex < sessionOverlayRoot.actions.length)
            ? sessionOverlayRoot.actions[sessionOverlayRoot.selectedIndex]
            : null
        return {
            "active": sessionOverlayRoot.active,
            "selectedIndex": sessionOverlayRoot.selectedIndex,
            "selectedAction": act ? act.id : "",
            "isHolding": sessionOverlayRoot.isHolding,
            "holdingProgress": Math.round(sessionOverlayRoot.holdingProgress * 100) / 100,
            "actions": sessionOverlayRoot.actions,
            "monitorIndex": sessionOverlayRoot.monitorIndex
        }
    }

    // =========================================================
    // Keyboard Focus & Input Handling
    // =========================================================
    focus: sessionOverlayRoot.active

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (sessionOverlayRoot.isHolding) {
                sessionOverlayRoot.cancelHold()
            } else {
                sessionOverlayRoot.dismissRequested()
            }
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            sessionOverlayRoot.cancelHold()
            sessionOverlayRoot.selectedIndex = (sessionOverlayRoot.selectedIndex - 1 + sessionOverlayRoot.actions.length) % sessionOverlayRoot.actions.length
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            sessionOverlayRoot.cancelHold()
            sessionOverlayRoot.selectedIndex = (sessionOverlayRoot.selectedIndex + 1) % sessionOverlayRoot.actions.length
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            var act = sessionOverlayRoot.actions[sessionOverlayRoot.selectedIndex]
            if (act && act.destructive) {
                if (!event.isAutoRepeat && !sessionOverlayRoot.isHolding) {
                    sessionOverlayRoot.isHolding = true
                    sessionOverlayRoot.holdingProgress = 0.0
                }
            } else {
                sessionOverlayRoot._triggerSelectedAction()
            }
            event.accepted = true
            return
        }

        // Direct number selection (1..5)
        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
            sessionOverlayRoot.cancelHold()
            sessionOverlayRoot.selectedIndex = event.key - Qt.Key_1
            event.accepted = true
            return
        }

        // Mnemonics
        if (event.key === Qt.Key_L) {
            sessionOverlayRoot.selectActionById("lock")
            sessionOverlayRoot._triggerSelectedAction()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_S) {
            sessionOverlayRoot.selectActionById("suspend")
            sessionOverlayRoot._triggerSelectedAction()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_O) {
            sessionOverlayRoot.selectActionById("logout")
            sessionOverlayRoot._triggerSelectedAction()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_R) {
            sessionOverlayRoot.selectActionById("reboot")
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_P) {
            sessionOverlayRoot.selectActionById("poweroff")
            event.accepted = true
            return
        }
    }

    Keys.onReleased: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (sessionOverlayRoot.isHolding) {
                sessionOverlayRoot.cancelHold()
            }
            event.accepted = true
        }
    }

    // =========================================================
    // Visual Composition (Constellation Architecture)
    // =========================================================

    // Dark Quiet Space Scrim
    Rectangle {
        id: darkScrim
        anchors.fill: parent
        color: sessionOverlayRoot.currentTheme.colors.surfaceBase
        opacity: 0.94

        MouseArea {
            anchors.fill: parent
            onClicked: sessionOverlayRoot.dismissRequested()
        }
    }

    // Palette-Derived Background Stars (Deterministic, Sparse)
    Repeater {
        model: [
            { "xP": 0.12, "yP": 0.18, "size": 3, "alpha": 0.35 },
            { "xP": 0.22, "yP": 0.32, "size": 2, "alpha": 0.20 },
            { "xP": 0.35, "yP": 0.15, "size": 4, "alpha": 0.40 },
            { "xP": 0.48, "yP": 0.22, "size": 2, "alpha": 0.25 },
            { "xP": 0.65, "yP": 0.14, "size": 3, "alpha": 0.30 },
            { "xP": 0.78, "yP": 0.26, "size": 4, "alpha": 0.45 },
            { "xP": 0.88, "yP": 0.19, "size": 2, "alpha": 0.20 },
            { "xP": 0.15, "yP": 0.72, "size": 3, "alpha": 0.25 },
            { "xP": 0.28, "yP": 0.82, "size": 2, "alpha": 0.30 },
            { "xP": 0.72, "yP": 0.76, "size": 4, "alpha": 0.35 },
            { "xP": 0.84, "yP": 0.68, "size": 2, "alpha": 0.25 },
            { "xP": 0.42, "yP": 0.85, "size": 3, "alpha": 0.20 }
        ]

        delegate: Rectangle {
            id: starDelegate
            required property var modelData
            x: Math.round(sessionOverlayRoot.width * starDelegate.modelData.xP)
            y: Math.round(sessionOverlayRoot.height * starDelegate.modelData.yP)
            width: starDelegate.modelData.size
            height: starDelegate.modelData.size
            radius: starDelegate.modelData.size / 2
            color: sessionOverlayRoot.currentTheme.colors.accent
            opacity: starDelegate.modelData.alpha
        }
    }

    // Constellation Center Area
    Item {
        id: constellationArea
        anchors.centerIn: parent
        width: 760
        height: 380

        // Subtle Constellation Connecting Rail
        Rectangle {
            anchors.centerIn: parent
            width: 580
            height: 1
            color: sessionOverlayRoot.currentTheme.colors.borderSubtle
            opacity: 0.5
        }

        // Header: Archival / Constellation Title
        Column {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "BASEUS CONSTEL • SESSION CONTROL"
                font.family: sessionOverlayRoot.currentTheme.typography.fontFamilyMono
                font.pixelSize: sessionOverlayRoot.currentTheme.typography.sizeCaption
                font.letterSpacing: 3
                font.weight: Font.DemiBold
                color: sessionOverlayRoot.currentTheme.colors.accent
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "A quiet place between states."
                font.family: sessionOverlayRoot.currentTheme.typography.fontFamily
                font.pixelSize: sessionOverlayRoot.currentTheme.typography.sizeCaption
                color: sessionOverlayRoot.currentTheme.colors.textMuted
            }
        }

        // Constellation Action Nodes
        Item {
            anchors.centerIn: parent
            width: 720
            height: 180

            Repeater {
                model: sessionOverlayRoot.actions

                delegate: Item {
                    id: actionNodeDelegate
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: sessionOverlayRoot.selectedIndex === actionNodeDelegate.index
                    readonly property bool isDestructive: Boolean(actionNodeDelegate.modelData.destructive)

                    x: (parent.width / 2) + actionNodeDelegate.modelData.xOffset - (width / 2)
                    y: (parent.height / 2) + actionNodeDelegate.modelData.yOffset - (height / 2)
                    width: 110
                    height: 110

                    // Scale & Opacity transitions following "Focus grows. Context recedes."
                    scale: actionNodeDelegate.isSelected ? 1.08 : 0.95
                    opacity: actionNodeDelegate.isSelected ? 1.0 : 0.45

                    Behavior on scale {
                        NumberAnimation { duration: sessionOverlayRoot.currentTheme.motion.durationFast; easing.type: Easing.OutQuad }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: sessionOverlayRoot.currentTheme.motion.durationFast; easing.type: Easing.OutQuad }
                    }

                    // Node Outer Card Body
                    Rectangle {
                        id: nodeCard
                        anchors.fill: parent
                        radius: sessionOverlayRoot.currentTheme.geometry.radiusLarge
                        color: actionNodeDelegate.isSelected
                            ? sessionOverlayRoot.currentTheme.colors.surfaceSolid
                            : "transparent"
                        border.color: actionNodeDelegate.isSelected
                            ? (actionNodeDelegate.isDestructive ? sessionOverlayRoot.currentTheme.colors.accent : sessionOverlayRoot.currentTheme.colors.accent)
                            : sessionOverlayRoot.currentTheme.colors.borderSubtle
                        border.width: actionNodeDelegate.isSelected ? 2 : 1

                        // Hold Progress Fill Ring (for destructive confirmation)
                        Rectangle {
                            id: progressFill
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: Math.round(parent.height * (actionNodeDelegate.isSelected ? sessionOverlayRoot.holdingProgress : 0.0))
                            radius: sessionOverlayRoot.currentTheme.geometry.radiusLarge
                            color: sessionOverlayRoot.currentTheme.colors.surfaceHighlight
                            opacity: 0.5
                            visible: actionNodeDelegate.isDestructive && actionNodeDelegate.isSelected && sessionOverlayRoot.isHolding
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            // Number Tag (e.g. "01")
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: actionNodeDelegate.modelData.num
                                font.family: sessionOverlayRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: sessionOverlayRoot.currentTheme.typography.sizeMicro
                                font.weight: Font.DemiBold
                                color: actionNodeDelegate.isSelected
                                    ? sessionOverlayRoot.currentTheme.colors.accent
                                    : sessionOverlayRoot.currentTheme.colors.textMuted
                            }

                            // Main Action Label (e.g. "LOCK", "RESTART")
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: actionNodeDelegate.modelData.label
                                font.family: sessionOverlayRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: sessionOverlayRoot.currentTheme.typography.sizeBody
                                font.weight: Font.Bold
                                font.letterSpacing: 1
                                color: actionNodeDelegate.isSelected
                                    ? sessionOverlayRoot.currentTheme.colors.textPrimary
                                    : sessionOverlayRoot.currentTheme.colors.textSecondary
                            }

                            // Shortcut Mnemonic Pill (e.g. "[L]")
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 22
                                height: 16
                                radius: 4
                                color: actionNodeDelegate.isSelected
                                    ? sessionOverlayRoot.currentTheme.colors.surfaceHighlight
                                    : "transparent"
                                border.color: sessionOverlayRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: actionNodeDelegate.modelData.shortcut
                                    font.family: sessionOverlayRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: actionNodeDelegate.isSelected
                                        ? sessionOverlayRoot.currentTheme.colors.textPrimary
                                        : sessionOverlayRoot.currentTheme.colors.textMuted
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onEntered: sessionOverlayRoot.selectAction(actionNodeDelegate.index)

                            onPressed: {
                                sessionOverlayRoot.selectAction(actionNodeDelegate.index)
                                if (actionNodeDelegate.isDestructive) {
                                    sessionOverlayRoot.isHolding = true
                                    sessionOverlayRoot.holdingProgress = 0.0
                                } else {
                                    sessionOverlayRoot._triggerSelectedAction()
                                }
                            }

                            onReleased: {
                                if (actionNodeDelegate.isDestructive && sessionOverlayRoot.isHolding) {
                                    sessionOverlayRoot.cancelHold()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom Context Bar & Confirmation Guidance
        Item {
            id: bottomContextBar
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: 48

            readonly property var currentAct: (sessionOverlayRoot.selectedIndex >= 0 && sessionOverlayRoot.selectedIndex < sessionOverlayRoot.actions.length)
                ? sessionOverlayRoot.actions[sessionOverlayRoot.selectedIndex]
                : null

            Column {
                anchors.centerIn: parent
                spacing: 6

                // Status Guidance Text
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!bottomContextBar.currentAct) return ""
                        if (bottomContextBar.currentAct.destructive) {
                            if (sessionOverlayRoot.isHolding) {
                                return "HOLDING TO CONFIRM (" + Math.round(sessionOverlayRoot.holdingProgress * 100) + "%)"
                            }
                            return "HOLD ENTER OR CLICK TO " + bottomContextBar.currentAct.label
                        }
                        return "PRESS ENTER OR CLICK TO " + bottomContextBar.currentAct.label
                    }
                    font.family: sessionOverlayRoot.currentTheme.typography.fontFamilyMono
                    font.pixelSize: sessionOverlayRoot.currentTheme.typography.sizeBody
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                    color: (bottomContextBar.currentAct && bottomContextBar.currentAct.destructive && sessionOverlayRoot.isHolding)
                        ? sessionOverlayRoot.currentTheme.colors.accent
                        : sessionOverlayRoot.currentTheme.colors.textPrimary
                }

                // Subtitle / Shortcut Hint
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Arrows navigate • Enter execute • Esc return"
                    font.family: sessionOverlayRoot.currentTheme.typography.fontFamily
                    font.pixelSize: sessionOverlayRoot.currentTheme.typography.sizeCaption
                    color: sessionOverlayRoot.currentTheme.colors.textMuted
                }
            }
        }
    }

    // =========================================================
    // Sleeping Chibi Companion (MASTER.md §32, DESIGN.md §31)
    // =========================================================
    Item {
        id: chibiCompanion
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 48
        width: 120
        height: 80

        // Zero-CPU idle animation gating
        property real bobOffset: 0.0

        SequentialAnimation on bobOffset {
            running: sessionOverlayRoot.active && !sessionOverlayRoot.currentTheme.motion.reducedMotion
            loops: Animation.Infinite

            NumberAnimation { to: -6.0; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.0; duration: 1600; easing.type: Easing.InOutSine }
        }

        Item {
            anchors.centerIn: parent
            y: parent.height / 2 + chibiCompanion.bobOffset

            // Chibi Body Pill
            Rectangle {
                anchors.centerIn: parent
                width: 56
                height: 34
                radius: 17
                color: sessionOverlayRoot.currentTheme.colors.surfaceSolid
                border.color: sessionOverlayRoot.currentTheme.colors.borderSubtle
                border.width: 1

                // Sleeping Face Expression (-_-)
                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "—"
                        font.family: sessionOverlayRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: sessionOverlayRoot.currentTheme.colors.textMuted
                    }

                    Text {
                        text: "•"
                        font.pixelSize: 8
                        color: sessionOverlayRoot.currentTheme.colors.accent
                    }

                    Text {
                        text: "—"
                        font.family: sessionOverlayRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: sessionOverlayRoot.currentTheme.colors.textMuted
                    }
                }
            }

            // Quiet zzz Typographic Detail
            Text {
                x: 42
                y: -14
                text: "z z z"
                font.family: sessionOverlayRoot.currentTheme.typography.fontFamilyMono
                font.pixelSize: 9
                color: sessionOverlayRoot.currentTheme.colors.textMuted
                opacity: 0.6
            }
        }
    }
}
