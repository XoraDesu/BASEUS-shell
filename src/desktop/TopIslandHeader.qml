// BASEUS — Top Island Contextual Header
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §12; DESIGN.md §13, §14; ANTI-SLOP.md §6.8; DEC-016, DEC-028:
//   - Content revealed when the Top Island expands (hover, or click in fullscreen summon)
//   - Quiet and functional: full date, real session context (workspace, window counts),
//     and navigation triggers that execute ActionRegistry actions (Discover → Execute)
//   - Typographic composition on the island's own solid surface: no nested cards
//   - No telemetry, no fake system data, no media, no volume/brightness (reserved for M3)
//   - Every trigger shows its registry-defined shortcut so the keyboard path is discoverable

pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Item {
    id: header

    // =========================================================
    // Dependencies
    // =========================================================
    required property ThemeModule.Theme currentTheme
    property var actionRegistry: null
    property var workspaceModel: null
    property var windowModel: null
    property var mediaService: null
    property int monitorIndex: 0

    // Provided by the island clock (updated on minute boundaries, no polling here)
    property string dateText: ""

    // True while the island is expanded; context is re-read on every expansion
    property bool active: false

    signal actionExecuted(string actionId, bool ok)

    // =========================================================
    // Navigation Triggers (DEC-024 primitives exposed through DEC-028 registry)
    // =========================================================
    readonly property var triggerIds: ["navigation.back", "navigation.home", "navigation.overview"]

    // Descriptors (title, shortcut, enabled) read from ActionRegistry.
    // Re-read on every expansion so `enabled` is never stale; the list itself is stable
    // while collapsed so the expanded geometry does not change on open.
    readonly property var triggers: {
        var _active = header.active
        var out = []
        if (!header.actionRegistry) return out
        for (var i = 0; i < header.triggerIds.length; i++) {
            var desc = header.actionRegistry.get(header.triggerIds[i])
            if (desc) out.push(desc)
        }
        return out
    }

    // =========================================================
    // Real Session Context (no fabricated values)
    // =========================================================
    readonly property int activeWorkspace: {
        var _map = header.workspaceModel ? header.workspaceModel.activeWorkspaces : null
        return header.workspaceModel ? header.workspaceModel.getActiveWorkspace(header.monitorIndex) : 1
    }

    readonly property string sessionText: {
        var _windows = header.windowModel ? header.windowModel.windows : []
        var _labels = header.workspaceModel ? header.workspaceModel.labels : null
        var _active = header.active
        var ws = header.activeWorkspace
        var parts = ["Workspace " + ws + " of 10"]
        if (header.workspaceModel) {
            var label = header.workspaceModel.getLabel(ws)
            if (label.length > 0) parts.push(label)
        }
        if (header.windowModel) {
            var shown = header.windowModel.getVisibleWindowsByWorkspace(ws).length
            parts.push(shown + (shown === 1 ? " window" : " windows"))
            var minimized = header.windowModel.getMinimizedWindows(ws).length
            if (minimized > 0) parts.push(minimized + " minimized")
        }
        return parts.join("  ·  ")
    }

    // Executes a trigger's action; returns true on success
    function activate(actionId: string): bool {
        if (!header.actionRegistry) return false
        var res = header.actionRegistry.execute(actionId)
        var ok = res && res.ok === true
        header.actionExecuted(actionId, ok)
        return ok
    }

    function getSnapshot(): var {
        var ids = []
        for (var i = 0; i < header.triggers.length; i++) {
            ids.push({
                id: header.triggers[i].id,
                title: header.triggers[i].title,
                shortcut: header.triggers[i].defaultShortcut,
                enabled: header.triggers[i].enabled
            })
        }
        return {
            dateText: header.dateText,
            sessionText: header.sessionText,
            activeWorkspace: header.activeWorkspace,
            triggers: ids,
            media: header.mediaService ? header.mediaService.getSnapshot() : null
        }
    }

    // =========================================================
    // Layout
    // =========================================================
    readonly property int contentPadding: header.currentTheme.spacing.lg
    implicitHeight: contentColumn.implicitHeight + header.currentTheme.spacing.sm + header.currentTheme.spacing.md

    Column {
        id: contentColumn
        anchors.top: parent.top
        anchors.topMargin: header.currentTheme.spacing.sm
        anchors.horizontalCenter: parent.horizontalCenter
        width: header.width - (header.contentPadding * 2)
        spacing: header.currentTheme.spacing.sm

        // Full date (the clock above already carries the time)
        Text {
            id: dateLabel
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: header.dateText
            font.family: header.currentTheme.typography.fontFamily
            font.pixelSize: header.currentTheme.typography.sizeBody
            font.weight: header.currentTheme.typography.weightMedium
            color: header.currentTheme.colors.textPrimary
        }

        // Session context for this monitor
        Text {
            id: sessionLabel
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: header.sessionText
            font.family: header.currentTheme.typography.fontFamily
            font.pixelSize: header.currentTheme.typography.sizeCaption
            color: header.currentTheme.colors.textSecondary
        }

        // Compact Media Integration (M3-T3, DEC-026, MASTER.md §31)
        TopIslandMedia {
            id: headerMedia
            theme: header.currentTheme
            mediaService: header.mediaService
            width: parent.width
        }

        // Navigation triggers: title + registry shortcut, no containers
        Row {
            id: triggerRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: header.currentTheme.spacing.xl

            Repeater {
                model: header.triggers

                Item {
                    id: trigger
                    required property var modelData

                    readonly property bool triggerEnabled: trigger.modelData.enabled === true

                    width: Math.max(titleLabel.implicitWidth, shortcutLabel.implicitWidth) + header.currentTheme.spacing.sm
                    height: titleLabel.implicitHeight + shortcutLabel.implicitHeight + header.currentTheme.spacing.xxs

                    Column {
                        anchors.centerIn: parent
                        spacing: header.currentTheme.spacing.xxs

                        Text {
                            id: titleLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: trigger.modelData.title
                            font.family: header.currentTheme.typography.fontFamily
                            font.pixelSize: header.currentTheme.typography.sizeBody
                            font.weight: header.currentTheme.typography.weightMedium
                            color: !trigger.triggerEnabled
                                ? header.currentTheme.colors.textMuted
                                : (triggerHover.hovered ? header.currentTheme.colors.accent : header.currentTheme.colors.textPrimary)

                            Behavior on color {
                                ColorAnimation { duration: header.currentTheme.motion.durationFast }
                            }
                        }

                        Text {
                            id: shortcutLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: trigger.modelData.defaultShortcut
                            font.family: header.currentTheme.typography.fontFamilyMono
                            font.pixelSize: header.currentTheme.typography.sizeMicro
                            color: header.currentTheme.colors.textMuted
                        }
                    }

                    HoverHandler {
                        id: triggerHover
                        enabled: trigger.triggerEnabled
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: trigger.triggerEnabled
                        onTapped: header.activate(trigger.modelData.id)
                    }
                }
            }
        }
    }
}
