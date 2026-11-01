pragma ComponentBehavior: Bound

// BASEUS — Workspace Model
// Copyright (c) 2026 xoradesu — MIT License
//
// Manages the fixed 10-workspace model.
// Per MASTER.md §7, §39 and DEC-010:
//   - Exactly 10 workspaces (count is fixed and immutable)
//   - Per-monitor workspace state (active + previous workspace per monitor)
//   - Super+1 through Super+0 direct navigation
//   - 4-finger swipe left/right / bounded 1..10 relative stepping
//   - Optional user-defined workspace labels and tags
//
// State ownership:
//   - WorkspaceModel owns workspace metadata (label, tag) and BASEUS workspace state
//   - HyprlandBridge / MockHyprlandBridge translates compositor events into EventBus
//   - WorkspaceModel consumes normalized events from EventBus and emits
//     authoritative { source: "model", type: "changed", ... } events for UI surfaces

import QtQuick

QtObject {
    id: workspaceModel

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var config: null
    property var windowModel: null

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

    // Previous active workspace per monitor — supports Back navigation (DEC-024)
    // and WorkspaceIndicator hierarchical scaling (DESIGN.md §12)
    property var previousWorkspaces: ({ 0: 1 })

    // Workspace labels — user-defined, optional (e.g. { 1: "WEB", 2: "DEV" })
    property var labels: ({})

    // Workspace tags — user-defined, optional (MASTER.md §7)
    property var tags: ({})

    // =========================================================
    // Validation Helpers
    // =========================================================

    function isValidWorkspaceId(workspaceId) {
        return typeof workspaceId === "number"
            && !isNaN(workspaceId)
            && Math.floor(workspaceId) === workspaceId
            && workspaceId >= 1
            && workspaceId <= workspaceCount
    }

    function _normalizeMonitorIndex(monitorIndex) {
        return (typeof monitorIndex === "number" && !isNaN(monitorIndex) && monitorIndex >= 0)
            ? Math.floor(monitorIndex)
            : 0
    }

    function _copyStringMap(sourceObj) {
        var result = {}
        if (!sourceObj || typeof sourceObj !== "object") return result
        for (var key in sourceObj) {
            var numId = parseInt(String(key), 10)
            if (!isNaN(numId) && numId >= 1 && numId <= workspaceCount && typeof sourceObj[key] === "string") {
                result[numId] = sourceObj[key]
            }
        }
        return result
    }

    // =========================================================
    // Internal Mutators
    // =========================================================

    function _applyActiveWorkspace(monitorIndex, workspaceId) {
        var mon = _normalizeMonitorIndex(monitorIndex)
        if (!isValidWorkspaceId(workspaceId)) {
            if (logger) logger.warn("WorkspaceModel",
                "Ignoring out-of-range workspace ID %1 (BASEUS fixed model is 1–10)".arg(workspaceId))
            return {
                changed: false,
                monitorIndex: mon,
                previous: getActiveWorkspace(mon),
                current: getActiveWorkspace(mon)
            }
        }

        var hadExplicitEntry = Object.prototype.hasOwnProperty.call(activeWorkspaces, mon)
        var previous = getActiveWorkspace(mon)
        if (hadExplicitEntry && previous === workspaceId) {
            return {
                changed: false,
                monitorIndex: mon,
                previous: previous,
                current: workspaceId
            }
        }

        var updatedActive = {}
        for (var ak in activeWorkspaces) {
            updatedActive[ak] = activeWorkspaces[ak]
        }
        updatedActive[mon] = workspaceId

        var updatedPrev = {}
        for (var pk in previousWorkspaces) {
            updatedPrev[pk] = previousWorkspaces[pk]
        }
        updatedPrev[mon] = previous

        previousWorkspaces = updatedPrev
        activeWorkspaces = updatedActive

        if (logger) logger.debug("WorkspaceModel",
            "Monitor %1: workspace %2 → %3"
                .arg(mon).arg(previous).arg(workspaceId))

        return {
            changed: previous !== workspaceId,
            monitorIndex: mon,
            previous: previous,
            current: workspaceId
        }
    }

    function _emitChanged(change) {
        if (!change || !change.changed || !eventBus) return
        eventBus.emit("workspace", {
            source: "model",
            type: "changed",
            monitorIndex: change.monitorIndex,
            previous: change.previous,
            current: change.current,
            label: getLabel(change.current),
            tag: getTag(change.current)
        })
    }

    function _reconcileMonitors(monitorList) {
        if (!Array.isArray(monitorList) || monitorList.length === 0) {
            if (Object.keys(activeWorkspaces).length === 0) {
                activeWorkspaces = { 0: 1 }
                previousWorkspaces = { 0: 1 }
            }
            return
        }

        var nextActive = {}
        var nextPrev = {}
        for (var i = 0; i < monitorList.length; i++) {
            var monEntry = monitorList[i]
            if (!monEntry) continue
            var idx = _normalizeMonitorIndex(monEntry.index)
            var currentWs = activeWorkspaces[idx]
            var prevWs = previousWorkspaces[idx]
            nextActive[idx] = isValidWorkspaceId(currentWs) ? currentWs : 1
            nextPrev[idx] = isValidWorkspaceId(prevWs) ? prevWs : nextActive[idx]
        }

        if (Object.keys(nextActive).length > 0) {
            activeWorkspaces = nextActive
            previousWorkspaces = nextPrev
        }
    }

    // =========================================================
    // Workspace Queries & Operations
    // =========================================================

    function getActiveWorkspace(monitorIndex) {
        var mon = _normalizeMonitorIndex(monitorIndex)
        var ws = activeWorkspaces[mon]
        return isValidWorkspaceId(ws) ? ws : 1
    }

    function getPreviousWorkspace(monitorIndex) {
        var mon = _normalizeMonitorIndex(monitorIndex)
        var prev = previousWorkspaces[mon]
        return isValidWorkspaceId(prev) ? prev : getActiveWorkspace(mon)
    }

    function getRelativeWorkspace(monitorIndex, delta) {
        var current = getActiveWorkspace(monitorIndex)
        var step = (typeof delta === "number" && !isNaN(delta))
            ? (delta >= 0 ? Math.floor(delta) : Math.ceil(delta))
            : 0
        var target = current + step
        if (target < 1) target = 1
        if (target > workspaceCount) target = workspaceCount
        return target
    }

    function canStepWorkspace(monitorIndex, delta) {
        return getRelativeWorkspace(monitorIndex, delta) !== getActiveWorkspace(monitorIndex)
    }

    function getMonitorForWorkspace(workspaceId) {
        if (!isValidWorkspaceId(workspaceId)) return -1
        for (var monKey in activeWorkspaces) {
            if (activeWorkspaces[monKey] === workspaceId) {
                var parsed = parseInt(String(monKey), 10)
                if (!isNaN(parsed)) return parsed
            }
        }
        return -1
    }

    function getWindowCount(workspaceId) {
        if (!isValidWorkspaceId(workspaceId) || !windowModel) return 0
        var list = windowModel.getWindowsByWorkspace(workspaceId)
        return Array.isArray(list) ? list.length : 0
    }

    function setActiveWorkspace(monitorIndex, workspaceId) {
        var change = _applyActiveWorkspace(monitorIndex, workspaceId)
        if (!change.changed) return false
        _emitChanged(change)
        return true
    }

    // =========================================================
    // Labels & Tags (MASTER.md §7)
    // =========================================================

    function getLabel(workspaceId) {
        return labels[workspaceId] || labels[String(workspaceId)] || ""
    }

    function getWorkspaceLabel(workspaceId) {
        return getLabel(workspaceId)
    }

    function setLabel(workspaceId, label) {
        if (!isValidWorkspaceId(workspaceId)) return false
        var cleanLabel = String(label || "")
        var updated = {}
        for (var k in labels) {
            updated[k] = labels[k]
        }
        if (cleanLabel.length > 0) {
            updated[workspaceId] = cleanLabel
        } else {
            delete updated[workspaceId]
            delete updated[String(workspaceId)]
        }
        labels = updated

        if (logger) logger.debug("WorkspaceModel",
            "Workspace %1 label set to '%2'".arg(workspaceId).arg(cleanLabel))

        if (eventBus) {
            eventBus.emit("workspace", {
                source: "model",
                type: "label_changed",
                workspaceId: workspaceId,
                label: cleanLabel
            })
        }
        return true
    }

    function getTag(workspaceId) {
        return tags[workspaceId] || tags[String(workspaceId)] || ""
    }

    function setTag(workspaceId, tag) {
        if (!isValidWorkspaceId(workspaceId)) return false
        var cleanTag = String(tag || "")
        var updated = {}
        for (var k in tags) {
            updated[k] = tags[k]
        }
        if (cleanTag.length > 0) {
            updated[workspaceId] = cleanTag
        } else {
            delete updated[workspaceId]
            delete updated[String(workspaceId)]
        }
        tags = updated

        if (logger) logger.debug("WorkspaceModel",
            "Workspace %1 tag set to '%2'".arg(workspaceId).arg(cleanTag))

        if (eventBus) {
            eventBus.emit("workspace", {
                source: "model",
                type: "tag_changed",
                workspaceId: workspaceId,
                tag: cleanTag
            })
        }
        return true
    }

    function getSnapshot(monitorIndex) {
        var mon = _normalizeMonitorIndex(monitorIndex)
        var activeOnMon = getActiveWorkspace(mon)
        var prevOnMon = getPreviousWorkspace(mon)
        var items = []

        for (var id = 1; id <= workspaceCount; id++) {
            var ownerMon = getMonitorForWorkspace(id)
            items.push({
                id: id,
                active: id === activeOnMon,
                visibleOnMonitor: ownerMon,
                windowCount: getWindowCount(id),
                label: getLabel(id),
                tag: getTag(id)
            })
        }

        return {
            workspaceCount: workspaceCount,
            monitorIndex: mon,
            activeWorkspace: activeOnMon,
            previousWorkspace: prevOnMon,
            activeWorkspaces: activeWorkspaces,
            previousWorkspaces: previousWorkspaces,
            workspaces: items
        }
    }

    // =========================================================
    // Lifecycle & Event Subscriptions
    // =========================================================

    function initialize() {
        activeWorkspaces = { 0: 1 }
        previousWorkspaces = { 0: 1 }
        labels = (config && config.workspaceLabels) ? _copyStringMap(config.workspaceLabels) : ({})
        tags = (config && config.workspaceTags) ? _copyStringMap(config.workspaceTags) : ({})

        if (!eventBus) return

        eventBus.subscribe("WorkspaceModel", "workspace", function(ev) {
            if (!ev || ev.source === "model") return
            if (ev.type === "activated" || ev.type === "switched") {
                var wsId = typeof ev.current === "number" ? ev.current : ev.workspaceId
                var monIdx = _normalizeMonitorIndex(ev.monitorIndex)
                if (typeof wsId === "number") {
                    var change = _applyActiveWorkspace(monIdx, wsId)
                    if (change.changed) {
                        _emitChanged(change)
                    }
                }
            } else if (ev.type === "synced" && ev.activeWorkspaces) {
                var syncedActive = {}
                var syncedPrev = {}
                for (var monKey in ev.activeWorkspaces) {
                    var parsedMon = parseInt(String(monKey), 10)
                    var idVal = ev.activeWorkspaces[monKey]
                    if (!isNaN(parsedMon) && parsedMon >= 0 && isValidWorkspaceId(idVal)) {
                        var oldVal = activeWorkspaces[parsedMon]
                        syncedActive[parsedMon] = idVal
                        syncedPrev[parsedMon] = isValidWorkspaceId(oldVal)
                            ? (oldVal !== idVal ? oldVal : (previousWorkspaces[parsedMon] || idVal))
                            : idVal
                    }
                }
                if (Object.keys(syncedActive).length > 0) {
                    activeWorkspaces = syncedActive
                    previousWorkspaces = syncedPrev
                }
            }
        })

        eventBus.subscribe("WorkspaceModel", "monitor", function(ev) {
            if (!ev) return
            if ((ev.type === "synced" || ev.type === "updated") && Array.isArray(ev.monitors)) {
                _reconcileMonitors(ev.monitors)
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
        previousWorkspaces = { 0: 1 }
        labels = ({})
        tags = ({})
        if (logger) logger.debug("WorkspaceModel", "Workspace model reset.")
    }
}
