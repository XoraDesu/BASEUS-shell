// BASEUS — Workspace Model
// Copyright (c) 2026 xoradesu — MIT License
//
// Manages the fixed 10-workspace model.
// Per MASTER.md §7 and DEC-010:
//   - Exactly 10 workspaces
//   - Per-monitor workspace state
//   - Super+1 through Super+0 navigation
//   - 4-finger swipe left/right
//   - Workspace labels are optional and user-defined
//
// State ownership:
//   - WorkspaceModel owns workspace metadata (label, tag) and BASEUS workspace state
//   - HyprlandBridge / MockHyprlandBridge translates compositor events into EventBus
//   - WorkspaceModel consumes normalized events from EventBus

import QtQuick

QtObject {
    id: workspaceModel

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var config: null

    // =========================================================
    // Constants
    // =========================================================
    readonly property int workspaceCount: 10

    // =========================================================
    // Workspace State
    // =========================================================

    // Active workspace per monitor — keyed by monitor index
    // { 0: 1, 1: 3 } means monitor 0 is on workspace 1, monitor 1 on workspace 3
    property var activeWorkspaces: ({ 0: 1 })

    // Workspace labels — user-defined, optional
    // { 1: "WEB", 2: "DEV", 5: "MEDIA" }
    property var labels: ({})

    // =========================================================
    // Internal Mutators
    // =========================================================

    function _applyActiveWorkspace(monitorIndex, workspaceId) {
        if (workspaceId < 1 || workspaceId > workspaceCount) {
            if (logger) logger.warn("WorkspaceModel",
                "Ignoring out-of-range workspace ID %1 (BASEUS fixed model is 1–10)".arg(workspaceId))
            return false
        }

        var mon = (typeof monitorIndex === "number") ? monitorIndex : 0
        var previous = getActiveWorkspace(mon)
        if (previous === workspaceId && activeWorkspaces[mon] === workspaceId) return false

        var updated = {}
        for (var k in activeWorkspaces) {
            updated[k] = activeWorkspaces[k]
        }
        updated[mon] = workspaceId
        activeWorkspaces = updated

        if (logger) logger.debug("WorkspaceModel",
            "Monitor %1: workspace %2 → %3"
                .arg(mon).arg(previous).arg(workspaceId))
        return true
    }

    // =========================================================
    // Workspace Operations
    // =========================================================

    function getActiveWorkspace(monitorIndex) {
        var mon = (typeof monitorIndex === "number") ? monitorIndex : 0
        return activeWorkspaces[mon] || 1
    }

    function setActiveWorkspace(monitorIndex, workspaceId) {
        var mon = (typeof monitorIndex === "number") ? monitorIndex : 0
        var previous = getActiveWorkspace(mon)
        if (!_applyActiveWorkspace(mon, workspaceId)) return

        if (eventBus) {
            eventBus.emit("workspace", {
                source: "model",
                type: "activated",
                monitorIndex: mon,
                previous: previous,
                current: workspaceId,
                label: getLabel(workspaceId)
            })
        }
    }

    // =========================================================
    // Labels
    // =========================================================

    function getLabel(workspaceId) {
        return labels[workspaceId] || labels[String(workspaceId)] || ""
    }

    function setLabel(workspaceId, label) {
        if (workspaceId < 1 || workspaceId > workspaceCount) return
        var updated = {}
        for (var k in labels) {
            updated[k] = labels[k]
        }
        updated[workspaceId] = label
        labels = updated

        if (logger) logger.debug("WorkspaceModel",
            "Workspace %1 label set to '%2'".arg(workspaceId).arg(label))

        if (eventBus) {
            eventBus.emit("workspace", {
                source: "model",
                type: "label_changed",
                workspaceId: workspaceId,
                label: label
            })
        }
    }

    // =========================================================
    // Lifecycle & Event Subscriptions
    // =========================================================

    function initialize() {
        activeWorkspaces = { 0: 1 }
        labels = (config && config.workspaceLabels && typeof config.workspaceLabels === "object")
            ? config.workspaceLabels
            : ({})

        if (!eventBus) return

        eventBus.subscribe("WorkspaceModel", "workspace", function(ev) {
            if (!ev || ev.source === "model") return
            if (ev.type === "activated" || ev.type === "switched") {
                var wsId = typeof ev.current === "number" ? ev.current : ev.workspaceId
                var monIdx = typeof ev.monitorIndex === "number" ? ev.monitorIndex : 0
                if (typeof wsId === "number") {
                    _applyActiveWorkspace(monIdx, wsId)
                }
            } else if (ev.type === "synced" && ev.activeWorkspaces) {
                var synced = {}
                for (var monKey in ev.activeWorkspaces) {
                    var idVal = ev.activeWorkspaces[monKey]
                    if (idVal >= 1 && idVal <= workspaceCount) {
                        synced[monKey] = idVal
                    }
                }
                if (Object.keys(synced).length > 0) {
                    activeWorkspaces = synced
                }
            }
        })

        if (logger) logger.info("WorkspaceModel",
            "Workspace model initialized (%1 fixed workspaces)".arg(workspaceCount))
    }

    function teardown() {
        if (eventBus) {
            eventBus.unsubscribeAll("WorkspaceModel")
        }
    }

    function reset() {
        activeWorkspaces = { 0: 1 }
        labels = ({})
        if (logger) logger.debug("WorkspaceModel", "Workspace model reset.")
    }
}
