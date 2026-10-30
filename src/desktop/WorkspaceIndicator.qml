// BASEUS — Contextual Workspace Indicator
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §11, DESIGN.md §12, and DEC-029:
//   - Completely hidden at idle (never permanently showing workspace numbers)
//   - Appears transiently (~2 seconds) on workspace switch
//   - Uses solid Wabi-sabi surface (no glass, blur, gradients, or neon glow)
//   - Hierarchical scaling ("Focus grows. Context recedes.")
//   - Morphs cleanly into a compact pill when user-defined label is present
//   - Rapid consecutive switches update in place without animation stacking (AGENTS.md §20)
//   - Respects reduced motion accessibility

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: workspaceIndicator

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: workspaceIndicator.theme ? workspaceIndicator.theme : workspaceIndicator.defaultTheme
    property var workspaceModel: null
    property int monitorIndex: 0

    // State Tracking
    property int previousWorkspace: 1
    property int currentWorkspace: 1
    property string workspaceLabel: ""
    property bool active: false

    // Center in host surface
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: indicatorContainer.width
    height: indicatorContainer.height

    // Contextual presentation (fades out at idle)
    opacity: workspaceIndicator.active ? 1.0 : 0.0
    visible: opacity > 0.0
    scale: workspaceIndicator.active ? 1.0 : 0.95

    Behavior on opacity {
        NumberAnimation {
            duration: workspaceIndicator.currentTheme.motion.reducedMotion ? 0 : workspaceIndicator.currentTheme.motion.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: workspaceIndicator.currentTheme.motion.reducedMotion ? 0 : workspaceIndicator.currentTheme.motion.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    // =========================================================
    // Reactive WorkspaceModel Tracking
    // =========================================================
    readonly property int _modelWs: {
        if (workspaceIndicator.workspaceModel &&
            workspaceIndicator.workspaceModel.activeWorkspaces &&
            typeof workspaceIndicator.workspaceModel.activeWorkspaces[workspaceIndicator.monitorIndex] === "number") {
            return workspaceIndicator.workspaceModel.activeWorkspaces[workspaceIndicator.monitorIndex]
        }
        return 1
    }

    readonly property int _modelPrevWs: {
        if (workspaceIndicator.workspaceModel &&
            workspaceIndicator.workspaceModel.previousWorkspaces &&
            typeof workspaceIndicator.workspaceModel.previousWorkspaces[workspaceIndicator.monitorIndex] === "number") {
            return workspaceIndicator.workspaceModel.previousWorkspaces[workspaceIndicator.monitorIndex]
        }
        return workspaceIndicator._modelWs
    }

    // Initial sync suppression: wait until initial monitor topology settles
    property int _lastSeenWs: -1
    property bool _ready: false

    Timer {
        id: readyTimer
        interval: 600
        running: true
        repeat: false
        onTriggered: {
            workspaceIndicator._lastSeenWs = workspaceIndicator._modelWs
            workspaceIndicator._ready = true
        }
    }

    on_ModelWsChanged: {
        if (!workspaceIndicator._ready) {
            workspaceIndicator._lastSeenWs = workspaceIndicator._modelWs
            workspaceIndicator.currentWorkspace = workspaceIndicator._modelWs
            workspaceIndicator.previousWorkspace = workspaceIndicator._modelPrevWs
            return
        }
        if (workspaceIndicator._lastSeenWs === workspaceIndicator._modelWs) return
        var prev = (workspaceIndicator._lastSeenWs > 0) ? workspaceIndicator._lastSeenWs : workspaceIndicator._modelPrevWs
        workspaceIndicator._lastSeenWs = workspaceIndicator._modelWs

        var lbl = ""
        if (workspaceIndicator.workspaceModel) {
            if (typeof workspaceIndicator.workspaceModel.getLabel === "function") {
                lbl = workspaceIndicator.workspaceModel.getLabel(workspaceIndicator._modelWs) || ""
            } else if (typeof workspaceIndicator.workspaceModel.getWorkspaceLabel === "function") {
                lbl = workspaceIndicator.workspaceModel.getWorkspaceLabel(workspaceIndicator._modelWs) || ""
            }
        }
        workspaceIndicator.showIndicator(prev, workspaceIndicator._modelWs, lbl)
    }

    // =========================================================
    // Indicator Display & Hide Routine
    // =========================================================

    function showIndicator(prev: int, curr: int, label: string) {
        workspaceIndicator.previousWorkspace = (prev > 0) ? prev : curr
        workspaceIndicator.currentWorkspace = (curr > 0) ? curr : 1
        workspaceIndicator.workspaceLabel = label ? label : ""
        workspaceIndicator.active = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        running: false
        onTriggered: {
            workspaceIndicator.active = false
        }
    }

    // =========================================================
    // Visual Presentation Surface
    // =========================================================
    Rectangle {
        id: indicatorContainer
        anchors.centerIn: parent
        height: 42
        width: Math.max(contentLayout.width + 36, 76)

        color: workspaceIndicator.currentTheme.colors.surfaceSolid

        // Morphing radius: pill when label exists, large rounded rect otherwise
        radius: (workspaceIndicator.workspaceLabel !== "")
            ? workspaceIndicator.currentTheme.geometry.radiusPill
            : workspaceIndicator.currentTheme.geometry.radiusLarge

        border.width: workspaceIndicator.currentTheme.geometry.borderWidth
        border.color: workspaceIndicator.currentTheme.colors.borderSubtle

        Behavior on width {
            NumberAnimation {
                duration: workspaceIndicator.currentTheme.motion.reducedMotion ? 0 : workspaceIndicator.currentTheme.motion.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: workspaceIndicator.currentTheme.motion.reducedMotion ? 0 : workspaceIndicator.currentTheme.motion.durationFast
            }
        }

        // =====================================================
        // Content Layout: Mode A (Labeled Pill) or Mode B (Hierarchical 1 → 2)
        // =====================================================
        Row {
            id: contentLayout
            anchors.centerIn: parent
            spacing: workspaceIndicator.currentTheme.spacing.sm

            // Mode A: Contextual Label Present ("2 — WEB")
            Row {
                id: labeledMode
                visible: workspaceIndicator.workspaceLabel !== ""
                spacing: workspaceIndicator.currentTheme.spacing.xs
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: workspaceIndicator.currentWorkspace + " — " + workspaceIndicator.workspaceLabel
                    font.family: workspaceIndicator.currentTheme.typography.fontFamilyMono
                    font.pixelSize: workspaceIndicator.currentTheme.typography.sizeTitle
                    font.weight: Font.Bold
                    color: workspaceIndicator.currentTheme.colors.dominant
                }
            }

            // Mode B: Number Transition ("1 → 2" or "1")
            Row {
                id: scalingMode
                visible: workspaceIndicator.workspaceLabel === ""
                spacing: workspaceIndicator.currentTheme.spacing.md
                anchors.verticalCenter: parent.verticalCenter

                // Previous workspace (receding context)
                Item {
                    id: prevItem
                    visible: workspaceIndicator.previousWorkspace !== workspaceIndicator.currentWorkspace
                    width: prevLabel.width
                    height: prevLabel.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: prevLabel
                        anchors.centerIn: parent
                        text: String(workspaceIndicator.previousWorkspace)
                        font.family: workspaceIndicator.currentTheme.typography.fontFamilyMono
                        font.pixelSize: workspaceIndicator.currentTheme.typography.sizeBody
                        font.weight: Font.Normal
                        color: workspaceIndicator.currentTheme.colors.textMuted
                        scale: 0.85
                        opacity: 0.5
                    }
                }

                // Arrow transition
                Text {
                    id: arrowLabel
                    visible: workspaceIndicator.previousWorkspace !== workspaceIndicator.currentWorkspace
                    anchors.verticalCenter: parent.verticalCenter
                    text: "→"
                    font.family: workspaceIndicator.currentTheme.typography.fontFamilyMono
                    font.pixelSize: workspaceIndicator.currentTheme.typography.sizeCaption
                    color: workspaceIndicator.currentTheme.colors.textMuted
                }

                // Current workspace (focused growth)
                Rectangle {
                    id: currentPill
                    anchors.verticalCenter: parent.verticalCenter
                    width: currLabel.width + 16
                    height: 28
                    radius: workspaceIndicator.currentTheme.geometry.radiusSmall
                    color: workspaceIndicator.currentTheme.colors.surfaceHighlight

                    Text {
                        id: currLabel
                        anchors.centerIn: parent
                        text: String(workspaceIndicator.currentWorkspace)
                        font.family: workspaceIndicator.currentTheme.typography.fontFamilyMono
                        font.pixelSize: workspaceIndicator.currentTheme.typography.sizeHeadline
                        font.weight: Font.Bold
                        color: workspaceIndicator.currentTheme.colors.dominant
                        scale: 1.05
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        workspaceIndicator._lastSeenWs = workspaceIndicator._modelWs
        workspaceIndicator.previousWorkspace = workspaceIndicator._modelPrevWs
        workspaceIndicator.currentWorkspace = workspaceIndicator._modelWs
        if (workspaceIndicator.workspaceModel) {
            if (typeof workspaceIndicator.workspaceModel.getLabel === "function") {
                workspaceIndicator.workspaceLabel = workspaceIndicator.workspaceModel.getLabel(workspaceIndicator._modelWs) || ""
            } else if (typeof workspaceIndicator.workspaceModel.getWorkspaceLabel === "function") {
                workspaceIndicator.workspaceLabel = workspaceIndicator.workspaceModel.getWorkspaceLabel(workspaceIndicator._modelWs) || ""
            }
        }
    }
}
