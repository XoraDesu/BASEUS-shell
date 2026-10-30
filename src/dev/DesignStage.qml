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
import "../desktop" as DesktopModule

Rectangle {
    id: stage
    width: 1280
    height: 720
    color: stageTheme.colors.surfaceBase

    // Reference Theme tokens
    ThemeModule.Theme {
        id: stageTheme
    }

    // Active simulated state
    property int activeWorkspace: 1
    property int prevWorkspace: 1
    property bool isFullscreen: false
    property bool showM1SurfacesPreview: true

    // =========================================================
    // 1. PRODUCTION SURFACES PREVIEW (M1-T5, M2-T1)
    // =========================================================
    DesktopModule.TopIslandAnchor {
        id: liveTopIsland
        theme: stageTheme
        isFullscreen: stage.isFullscreen
        visible: stage.showM1SurfacesPreview && !stage.isFullscreen
    }

    DesktopModule.WorkspaceIndicator {
        id: liveWorkspaceIndicator
        theme: stageTheme
        currentWorkspace: stage.activeWorkspace
        previousWorkspace: stage.prevWorkspace
        workspaceLabel: stage.activeWorkspace === 2 ? "WEB" : (stage.activeWorkspace === 3 ? "DEV" : "")
        visible: stage.showM1SurfacesPreview && liveWorkspaceIndicator.active
    }

    DesktopModule.DockAnchor {
        id: liveDock
        theme: stageTheme
        isFullscreen: stage.isFullscreen
        visible: stage.showM1SurfacesPreview && !stage.isFullscreen
    }

    // =========================================================
    // 2. DESIGN CONCEPT MOCK (Toggled off when M1 surfaces are active)
    // =========================================================
    Item {
        id: topIslandContainer
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: 36
        visible: !stage.showM1SurfacesPreview && !stage.isFullscreen
        opacity: stage.isFullscreen ? stageTheme.motion.recedeOpacity : 1.0

        Behavior on opacity {
            NumberAnimation { duration: stageTheme.motion.durationNormal; easing.type: stageTheme.motion.easingStandard }
        }

        // Left ICR Fillet
        ThemeModule.InverseCorner {
            anchors.right: islandBody.left
            anchors.top: parent.top
            cornerRadius: stageTheme.geometry.islandIcr
            fillColor: stageTheme.colors.surfaceSolid
            position: "top-left"
        }

        // Island Solid Body
        Rectangle {
            id: islandBody
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220
            height: parent.height
            color: stageTheme.colors.surfaceSolid

            // Flush top corners, rounded bottom corners
            radius: stageTheme.geometry.islandRadiusBottom

            Row {
                anchors.centerIn: parent
                spacing: stageTheme.spacing.md

                Text {
                    text: stage.activeWorkspace === 1 ? "MAIN" : (stage.activeWorkspace === 2 ? "DEV" : "WS " + stage.activeWorkspace)
                    font.family: stageTheme.typography.fontFamilyMono
                    font.pixelSize: stageTheme.typography.sizeCaption
                    font.weight: stageTheme.typography.weightBold
                    color: stageTheme.colors.dominant
                }

                Rectangle {
                    width: 1
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: stageTheme.colors.borderSubtle
                }

                Text {
                    text: "08:42"
                    font.family: stageTheme.typography.fontFamilyMono
                    font.pixelSize: stageTheme.typography.sizeCaption
                    font.weight: stageTheme.typography.weightRegular
                    color: stageTheme.colors.textPrimary
                }
            }
        }

        // Right ICR Fillet
        ThemeModule.InverseCorner {
            anchors.left: islandBody.right
            anchors.top: parent.top
            cornerRadius: stageTheme.geometry.islandIcr
            fillColor: stageTheme.colors.surfaceSolid
            position: "top-right"
        }
    }

    // =========================================================
    // 3. DOCK CONCEPT (M2 roadmap target, hidden in M1 focus mode)
    // =========================================================
    Item {
        id: dockContainer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: 48
        visible: !stage.showM1SurfacesPreview && !stage.isFullscreen
        opacity: stage.isFullscreen ? stageTheme.motion.recedeOpacity : 1.0

        Behavior on opacity {
            NumberAnimation { duration: stageTheme.motion.durationNormal; easing.type: stageTheme.motion.easingStandard }
        }

        // Left ICR Fillet (flares into bottom edge)
        ThemeModule.InverseCorner {
            anchors.right: dockBody.left
            anchors.bottom: parent.bottom
            cornerRadius: stageTheme.geometry.dockIcr
            fillColor: stageTheme.colors.surfaceSolid
            position: "bottom-left"
        }

        // Dock Solid Body
        Rectangle {
            id: dockBody
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 440
            height: parent.height
            color: stageTheme.colors.surfaceSolid

            // Rounded top corners, flush bottom corners
            radius: stageTheme.geometry.dockRadiusTop

            Row {
                anchors.centerIn: parent
                spacing: stageTheme.spacing.lg

                // Workspace Indicator Pips (10 fixed workspaces, DEC-010)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: stageTheme.spacing.xs

                    Repeater {
                        model: 10
                        Rectangle {
                            id: wsPip
                            required property int index
                            width: (wsPip.index + 1) === stage.activeWorkspace ? 18 : 6
                            height: 6
                            radius: stageTheme.geometry.radiusPill
                            color: (wsPip.index + 1) === stage.activeWorkspace ? stageTheme.colors.dominant : stageTheme.colors.surfaceRecessed

                            Behavior on width {
                                NumberAnimation { duration: stageTheme.motion.durationFast; easing.type: stageTheme.motion.easingFocus }
                            }
                            Behavior on color {
                                ColorAnimation { duration: stageTheme.motion.durationFast }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    stage.prevWorkspace = stage.activeWorkspace
                                    stage.activeWorkspace = wsPip.index + 1
                                    liveWorkspaceIndicator.showIndicator(stage.prevWorkspace, stage.activeWorkspace, stage.activeWorkspace === 2 ? "WEB" : (stage.activeWorkspace === 3 ? "DEV" : ""))
                                }
                            }
                        }
                    }
                }

                // Vertical Divider
                Rectangle {
                    width: 1
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: stageTheme.colors.borderSubtle
                }

                // Sample App Launcher / Pinned Slots
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: stageTheme.spacing.sm

                    Repeater {
                        model: ["term", "web", "code", "files"]
                        Rectangle {
                            id: appSlot
                            required property string modelData
                            width: 28
                            height: 28
                            radius: stageTheme.geometry.radiusSmall
                            color: stageTheme.colors.surfaceRecessed

                            Text {
                                anchors.centerIn: parent
                                text: appSlot.modelData[0].toUpperCase()
                                font.family: stageTheme.typography.fontFamilyMono
                                font.pixelSize: stageTheme.typography.sizeCaption
                                font.weight: stageTheme.typography.weightBold
                                color: stageTheme.colors.textSecondary
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
            cornerRadius: stageTheme.geometry.dockIcr
            fillColor: stageTheme.colors.surfaceSolid
            position: "bottom-right"
        }
    }

    // =========================================================
    // 4. TEST HARNESS CONTROLLER (Floating Test Palette)
    // =========================================================
    Rectangle {
        id: controlPanel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: stageTheme.spacing.lg
        width: 260
        height: 285
        color: stageTheme.colors.surfaceSolid
        radius: stageTheme.geometry.radiusMedium
        border.color: stageTheme.colors.borderSubtle
        border.width: stageTheme.geometry.borderWidth

        Column {
            anchors.fill: parent
            anchors.margins: stageTheme.spacing.md
            spacing: stageTheme.spacing.sm

            Text {
                text: "BASEUS DESIGN STAGE"
                font.family: stageTheme.typography.fontFamilyMono
                font.pixelSize: stageTheme.typography.sizeMicro
                font.weight: stageTheme.typography.weightBold
                font.letterSpacing: stageTheme.typography.letterSpacingCaps
                color: stageTheme.colors.textMuted
            }

            Text {
                text: "Workspace Navigation (1–10)"
                font.family: stageTheme.typography.fontFamily
                font.pixelSize: stageTheme.typography.sizeCaption
                color: stageTheme.colors.textSecondary
            }

            Grid {
                columns: 5
                spacing: stageTheme.spacing.xs

                Repeater {
                    model: 10
                    Rectangle {
                        id: wsGridCell
                        required property int index
                        width: 40
                        height: 24
                        radius: stageTheme.geometry.radiusSmall
                        color: (wsGridCell.index + 1) === stage.activeWorkspace ? stageTheme.colors.dominant : stageTheme.colors.surfaceRecessed

                        Text {
                            anchors.centerIn: parent
                            text: String(wsGridCell.index + 1)
                            font.family: stageTheme.typography.fontFamilyMono
                            font.pixelSize: stageTheme.typography.sizeCaption
                            font.weight: stageTheme.typography.weightBold
                            color: (wsGridCell.index + 1) === stage.activeWorkspace ? stageTheme.colors.textInverse : stageTheme.colors.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                stage.prevWorkspace = stage.activeWorkspace
                                stage.activeWorkspace = wsGridCell.index + 1
                                liveWorkspaceIndicator.showIndicator(stage.prevWorkspace, stage.activeWorkspace, stage.activeWorkspace === 2 ? "WEB" : (stage.activeWorkspace === 3 ? "DEV" : ""))
                            }
                        }
                    }
                }
            }

            // Production Surface Preview Toggle
            Rectangle {
                width: parent.width
                height: 28
                radius: stageTheme.geometry.radiusSmall
                color: stage.showM1SurfacesPreview ? stageTheme.colors.surfaceHighlight : stageTheme.colors.surfaceRecessed
                border.width: stageTheme.geometry.borderWidth
                border.color: stage.showM1SurfacesPreview ? stageTheme.colors.dominant : stageTheme.colors.borderSubtle

                Text {
                    anchors.centerIn: parent
                    text: stage.showM1SurfacesPreview ? "Production Preview: Active" : "Production Preview: Off"
                    font.family: stageTheme.typography.fontFamily
                    font.pixelSize: stageTheme.typography.sizeCaption
                    font.weight: stageTheme.typography.weightMedium
                    color: stage.showM1SurfacesPreview ? stageTheme.colors.dominant : stageTheme.colors.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: stage.showM1SurfacesPreview = !stage.showM1SurfacesPreview
                }
            }

            // Dock reveal toggle
            Rectangle {
                width: parent.width
                height: 28
                radius: stageTheme.geometry.radiusSmall
                color: liveDock.revealed ? stageTheme.colors.surfaceHighlight : stageTheme.colors.surfaceRecessed
                border.width: stageTheme.geometry.borderWidth
                border.color: liveDock.revealed ? stageTheme.colors.dominant : stageTheme.colors.borderSubtle

                Text {
                    anchors.centerIn: parent
                    text: liveDock.revealed ? "Dock: Revealed" : "Dock: Idle (Recessed)"
                    font.family: stageTheme.typography.fontFamily
                    font.pixelSize: stageTheme.typography.sizeCaption
                    font.weight: stageTheme.typography.weightMedium
                    color: liveDock.revealed ? stageTheme.colors.dominant : stageTheme.colors.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: liveDock.toggle()
                }
            }

            // Fullscreen toggle simulation
            Rectangle {
                width: parent.width
                height: 28
                radius: stageTheme.geometry.radiusSmall
                color: stage.isFullscreen ? stageTheme.colors.accent : stageTheme.colors.surfaceRecessed

                Text {
                    anchors.centerIn: parent
                    text: stage.isFullscreen ? "Exit Fullscreen" : "Simulate Fullscreen App"
                    font.family: stageTheme.typography.fontFamily
                    font.pixelSize: stageTheme.typography.sizeCaption
                    font.weight: stageTheme.typography.weightMedium
                    color: stage.isFullscreen ? stageTheme.colors.textInverse : stageTheme.colors.textPrimary
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
