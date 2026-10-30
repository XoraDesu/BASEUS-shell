// BASEUS — Visual Design Preview Stage
// Copyright (c) 2026 xoradesu — MIT License
//
// Interactive visual testbed for BASEUS design tokens and geometry.
// Renders the edge-integrated Top Island and Dock with authentic
// Inverse Corner Radius (ICR) fillets and 10-workspace indicators.
//
// Operates standalone or embedded within the Quickshell/mock harness.

pragma ComponentBehavior: Bound

import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: stage
    width: 1280
    height: 720
    color: theme.colors.surfaceBase

    // Reference Theme tokens
    ThemeModule.Theme {
        id: theme
    }

    // Active simulated state
    property int activeWorkspace: 1
    property bool isFullscreen: false

    // =========================================================
    // 1. TOP ISLAND (DESIGN.md §13)
    // =========================================================
    // Top-center, edge-integrated, flush with top, ICR fillets.

    Item {
        id: topIslandContainer
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: 36
        visible: !stage.isFullscreen
        opacity: stage.isFullscreen ? theme.motion.recedeOpacity : 1.0

        Behavior on opacity {
            NumberAnimation { duration: theme.motion.durationNormal; easing.type: theme.motion.easingStandard }
        }

        // Left ICR Fillet
        ThemeModule.InverseCorner {
            anchors.right: islandBody.left
            anchors.top: parent.top
            cornerRadius: theme.geometry.islandIcr
            fillColor: theme.colors.surfaceSolid
            position: "top-left"
        }

        // Island Solid Body
        Rectangle {
            id: islandBody
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220
            height: parent.height
            color: theme.colors.surfaceSolid

            // Flush top corners, rounded bottom corners
            radius: theme.geometry.islandRadiusBottom

            Row {
                anchors.centerIn: parent
                spacing: theme.spacing.md

                Text {
                    text: stage.activeWorkspace === 1 ? "MAIN" : (stage.activeWorkspace === 2 ? "DEV" : "WS " + stage.activeWorkspace)
                    font.family: theme.typography.fontFamilyMono
                    font.pixelSize: theme.typography.sizeCaption
                    font.weight: theme.typography.weightBold
                    color: theme.colors.dominant
                }

                Rectangle {
                    width: 1
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: theme.colors.borderSubtle
                }

                Text {
                    text: "08:42"
                    font.family: theme.typography.fontFamilyMono
                    font.pixelSize: theme.typography.sizeCaption
                    font.weight: theme.typography.weightRegular
                    color: theme.colors.textPrimary
                }
            }
        }

        // Right ICR Fillet
        ThemeModule.InverseCorner {
            anchors.left: islandBody.right
            anchors.top: parent.top
            cornerRadius: theme.geometry.islandIcr
            fillColor: theme.colors.surfaceSolid
            position: "top-right"
        }
    }

    // =========================================================
    // 2. DOCK (MASTER.md §10, DESIGN.md §11)
    // =========================================================
    // Bottom-center, edge-integrated, flush with bottom, ICR fillets.

    Item {
        id: dockContainer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: 48
        visible: !stage.isFullscreen
        opacity: stage.isFullscreen ? theme.motion.recedeOpacity : 1.0

        Behavior on opacity {
            NumberAnimation { duration: theme.motion.durationNormal; easing.type: theme.motion.easingStandard }
        }

        // Left ICR Fillet (flares into bottom edge)
        ThemeModule.InverseCorner {
            anchors.right: dockBody.left
            anchors.bottom: parent.bottom
            cornerRadius: theme.geometry.dockIcr
            fillColor: theme.colors.surfaceSolid
            position: "bottom-left"
        }

        // Dock Solid Body
        Rectangle {
            id: dockBody
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 440
            height: parent.height
            color: theme.colors.surfaceSolid

            // Rounded top corners, flush bottom corners
            radius: theme.geometry.dockRadiusTop

            Row {
                anchors.centerIn: parent
                spacing: theme.spacing.lg

                // Workspace Indicator Pips (10 fixed workspaces, DEC-010)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: theme.spacing.xs

                    Repeater {
                        model: 10
                        Rectangle {
                            id: wsPip
                            required property int index
                            width: (wsPip.index + 1) === stage.activeWorkspace ? 18 : 6
                            height: 6
                            radius: theme.geometry.radiusPill
                            color: (wsPip.index + 1) === stage.activeWorkspace ? theme.colors.dominant : theme.colors.surfaceRecessed

                            Behavior on width {
                                NumberAnimation { duration: theme.motion.durationFast; easing.type: theme.motion.easingFocus }
                            }
                            Behavior on color {
                                ColorAnimation { duration: theme.motion.durationFast }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: stage.activeWorkspace = wsPip.index + 1
                            }
                        }
                    }
                }

                // Vertical Divider
                Rectangle {
                    width: 1
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: theme.colors.borderSubtle
                }

                // Sample App Launcher / Pinned Slots
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: theme.spacing.sm

                    Repeater {
                        model: ["term", "web", "code", "files"]
                        Rectangle {
                            id: appSlot
                            required property string modelData
                            width: 28
                            height: 28
                            radius: theme.geometry.radiusSmall
                            color: theme.colors.surfaceRecessed

                            Text {
                                anchors.centerIn: parent
                                text: appSlot.modelData[0].toUpperCase()
                                font.family: theme.typography.fontFamilyMono
                                font.pixelSize: theme.typography.sizeCaption
                                font.weight: theme.typography.weightBold
                                color: theme.colors.textSecondary
                            }
                        }
                    }
                }
            }
        }

        // Right ICR Fillet (flares into bottom edge)
        ThemeModule.InverseCorner {
            anchors.left: dockBody.right
            anchors.bottom: parent.bottom
            cornerRadius: theme.geometry.dockIcr
            fillColor: theme.colors.surfaceSolid
            position: "bottom-right"
        }
    }

    // =========================================================
    // 3. OFFLINE SIMULATION CONTROLLER (Floating Test Palette)
    // =========================================================

    Rectangle {
        id: controlPanel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: theme.spacing.lg
        width: 260
        height: 200
        color: theme.colors.surfaceSolid
        radius: theme.geometry.radiusMedium
        border.color: theme.colors.borderSubtle
        border.width: theme.geometry.borderWidth

        Column {
            anchors.fill: parent
            anchors.margins: theme.spacing.md
            spacing: theme.spacing.sm

            Text {
                text: "BASEUS DESIGN STAGE"
                font.family: theme.typography.fontFamilyMono
                font.pixelSize: theme.typography.sizeMicro
                font.weight: theme.typography.weightBold
                font.letterSpacing: theme.typography.letterSpacingCaps
                color: theme.colors.textMuted
            }

            Text {
                text: "Workspace Navigation (1–10)"
                font.family: theme.typography.fontFamily
                font.pixelSize: theme.typography.sizeCaption
                color: theme.colors.textSecondary
            }

            Grid {
                columns: 5
                spacing: theme.spacing.xs

                Repeater {
                    model: 10
                    Rectangle {
                        id: wsGridCell
                        required property int index
                        width: 40
                        height: 24
                        radius: theme.geometry.radiusSmall
                        color: (wsGridCell.index + 1) === stage.activeWorkspace ? theme.colors.dominant : theme.colors.surfaceRecessed

                        Text {
                            anchors.centerIn: parent
                            text: String(wsGridCell.index + 1)
                            font.family: theme.typography.fontFamilyMono
                            font.pixelSize: theme.typography.sizeCaption
                            font.weight: theme.typography.weightBold
                            color: (wsGridCell.index + 1) === stage.activeWorkspace ? theme.colors.textInverse : theme.colors.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: stage.activeWorkspace = wsGridCell.index + 1
                        }
                    }
                }
            }

            // Fullscreen toggle simulation
            Rectangle {
                width: parent.width
                height: 28
                radius: theme.geometry.radiusSmall
                color: stage.isFullscreen ? theme.colors.accent : theme.colors.surfaceRecessed

                Text {
                    anchors.centerIn: parent
                    text: stage.isFullscreen ? "Exit Fullscreen" : "Simulate Fullscreen App"
                    font.family: theme.typography.fontFamily
                    font.pixelSize: theme.typography.sizeCaption
                    font.weight: theme.typography.weightMedium
                    color: stage.isFullscreen ? theme.colors.textInverse : theme.colors.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: stage.isFullscreen = !stage.isFullscreen
                }
            }
        }
    }
}
