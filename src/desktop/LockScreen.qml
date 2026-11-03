// BASEUS — Lock Screen Surface
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §35, DESIGN.md §35, DEC-025, and ANTI-SLOP.md:
//   - Airtight session lock surface covering the full display
//   - 100% solid, opaque background (Theme.colors.surfaceSolid)
//   - Strictly zero visual leakage, zero transparency, zero background window bleed
//   - Restrained layout: minute-aligned quiet clock, formatted date, user session pill
//   - Monospace password input with dot glyphs, instant focus grab
//   - Enter submits password; Escape clears input buffer (strictly non-dismissible)
//   - Subtle hairline border tint on auth failure; zero loud alert dialogs

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: lockScreen

    // =========================================================
    // Dependencies
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: lockScreen.theme ? lockScreen.theme : lockScreen.defaultTheme

    property var authService: null
    property var statusService: null
    property var screen: null

    // =========================================================
    // Time & Date Formatter (Minute-aligned, zero continuous polling)
    // =========================================================
    property string _timeText: "00:00"
    property string _dateText: ""

    function _updateClock() {
        var now = new Date()
        var h = now.getHours()
        var m = now.getMinutes()
        lockScreen._timeText = (h < 10 ? "0" + h : String(h)) + ":" + (m < 10 ? "0" + m : String(m))

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        lockScreen._dateText = days[now.getDay()] + ", " + now.getDate() + " " + months[now.getMonth()] + " " + now.getFullYear()
    }

    Timer {
        id: clockTimer
        interval: 1000
        repeat: true
        running: lockScreen.visible
        onTriggered: lockScreen._updateClock()
    }

    Component.onCompleted: {
        lockScreen._updateClock()
        passwordInput.forceActiveFocus()
    }

    onVisibleChanged: {
        if (lockScreen.visible) {
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }
    }

    // =========================================================
    // Input & Authentication Handling
    // =========================================================
    function submitPassword() {
        if (!lockScreen.authService) return
        var pw = passwordInput.text
        lockScreen.authService.authenticate(pw)
    }

    Connections {
        target: lockScreen.authService ? lockScreen.authService : null

        function onAuthenticationFailed() {
            passwordInput.text = ""
            failureTimer.restart()
        }

        function onUnlocked() {
            passwordInput.text = ""
        }
    }

    Timer {
        id: failureTimer
        interval: 900
        repeat: false
    }

    // =========================================================
    // Visual Layer: 100% Solid Opaque Background (Zero leakage)
    // =========================================================
    Rectangle {
        id: lockBackground
        anchors.fill: parent
        color: lockScreen.currentTheme.colors.surfaceSolid

        // Universal focus capture mouse area
        MouseArea {
            anchors.fill: parent
            onClicked: passwordInput.forceActiveFocus()
        }

        // =====================================================
        // Center Content Column
        // =====================================================
        Column {
            id: contentColumn
            anchors.centerIn: parent
            spacing: lockScreen.currentTheme.spacing.lg
            width: Math.min(parent.width - 40, 360)

            // Monospace Quiet Clock (calm, authoritative)
            Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                text: lockScreen._timeText
                font.family: lockScreen.currentTheme.typography.fontFamilyMono
                font.pixelSize: 64
                font.weight: Font.Medium
                color: lockScreen.currentTheme.colors.textPrimary
            }

            // Formatted Date
            Text {
                id: dateText
                anchors.horizontalCenter: parent.horizontalCenter
                text: lockScreen._dateText
                font.family: lockScreen.currentTheme.typography.fontFamily
                font.pixelSize: lockScreen.currentTheme.typography.sizeBody
                font.weight: Font.Normal
                color: lockScreen.currentTheme.colors.textSecondary
            }

            // Spacer
            Item {
                width: 1
                height: lockScreen.currentTheme.spacing.md
            }

            // User Session Pill
            Row {
                id: userRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: lockScreen.currentTheme.colors.accent
                }

                Text {
                    id: userLabel
                    text: lockScreen.authService ? lockScreen.authService.user : "baseus"
                    font.family: lockScreen.currentTheme.typography.fontFamilyMono
                    font.pixelSize: lockScreen.currentTheme.typography.sizeCaption
                    font.weight: Font.Medium
                    color: lockScreen.currentTheme.colors.textMuted
                }
            }

            // Minimalist Password Input Field
            Rectangle {
                id: inputContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 40
                radius: lockScreen.currentTheme.geometry.radiusSmall
                color: lockScreen.currentTheme.colors.surfaceRecessed
                border.width: 1
                border.color: {
                    if (failureTimer.running) {
                        return lockScreen.currentTheme.colors.statusWarning
                    }
                    if (lockScreen.authService && lockScreen.authService.authState === "authenticating") {
                        return lockScreen.currentTheme.colors.accent
                    }
                    if (passwordInput.activeFocus) {
                        return lockScreen.currentTheme.colors.dominant
                    }
                    return lockScreen.currentTheme.colors.borderSubtle
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: lockScreen.currentTheme.motion.durationFast
                    }
                }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: lockScreen.currentTheme.typography.fontFamilyMono
                    font.pixelSize: lockScreen.currentTheme.typography.sizeBody
                    color: lockScreen.currentTheme.colors.textPrimary
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    focus: true
                    clip: true

                    // Placeholder text when empty and not authenticating
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: {
                            if (failureTimer.running) return "Authentication failed"
                            if (lockScreen.authService && lockScreen.authService.authState === "authenticating") return "Authenticating..."
                            return "Enter password..."
                        }
                        font.family: lockScreen.currentTheme.typography.fontFamilyMono
                        font.pixelSize: lockScreen.currentTheme.typography.sizeCaption
                        color: failureTimer.running
                            ? lockScreen.currentTheme.colors.statusWarning
                            : lockScreen.currentTheme.colors.textMuted
                        visible: passwordInput.text.length === 0
                    }

                    Keys.onReturnPressed: lockScreen.submitPassword()
                    Keys.onEnterPressed: lockScreen.submitPassword()

                    // Escape resets the current password buffer; strictly does not dismiss
                    Keys.onEscapePressed: {
                        passwordInput.text = ""
                    }
                }
            }
        }

        // =====================================================
        // Calm Bottom Edge System Status
        // =====================================================
        Row {
            id: bottomStatusRow
            anchors.bottom: parent.bottom
            anchors.bottomMargin: lockScreen.currentTheme.spacing.lg
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: lockScreen.currentTheme.spacing.md

            // Battery Status
            Row {
                spacing: 4
                visible: lockScreen.statusService && lockScreen.statusService.hasBattery

                Text {
                    text: lockScreen.statusService ? lockScreen.statusService.batteryGlyph : "BAT"
                    font.family: lockScreen.currentTheme.typography.fontFamilyMono
                    font.pixelSize: lockScreen.currentTheme.typography.sizeMicro
                    color: lockScreen.currentTheme.colors.textMuted
                }

                Text {
                    text: lockScreen.statusService ? lockScreen.statusService.batteryLabel : ""
                    font.family: lockScreen.currentTheme.typography.fontFamilyMono
                    font.pixelSize: lockScreen.currentTheme.typography.sizeMicro
                    color: lockScreen.currentTheme.colors.textMuted
                }
            }

            // Divider
            Text {
                text: "·"
                font.pixelSize: lockScreen.currentTheme.typography.sizeMicro
                color: lockScreen.currentTheme.colors.borderSubtle
                visible: lockScreen.statusService && lockScreen.statusService.hasBattery
            }

            // Network Status
            Row {
                spacing: 4

                Text {
                    text: lockScreen.statusService ? lockScreen.statusService.networkGlyph : "NET"
                    font.family: lockScreen.currentTheme.typography.fontFamilyMono
                    font.pixelSize: lockScreen.currentTheme.typography.sizeMicro
                    color: lockScreen.currentTheme.colors.textMuted
                }

                Text {
                    text: lockScreen.statusService ? lockScreen.statusService.networkLabel : "Offline"
                    font.family: lockScreen.currentTheme.typography.fontFamilyMono
                    font.pixelSize: lockScreen.currentTheme.typography.sizeMicro
                    color: lockScreen.currentTheme.colors.textMuted
                }
            }
        }
    }

    // Diagnostic snapshot
    function getSnapshot(): var {
        return {
            "visible": lockScreen.visible,
            "timeText": lockScreen._timeText,
            "dateText": lockScreen._dateText,
            "user": lockScreen.authService ? lockScreen.authService.user : "baseus",
            "hasInput": passwordInput.text.length > 0,
            "inputLength": passwordInput.text.length,
            "isFailureTinted": failureTimer.running
        }
    }
}

