// BASEUS — Monitor Model
// Copyright (c) 2026 xoradesu — MIT License
//
// Tracks monitor state for multi-monitor support.
// Per MASTER.md §39:
//   - Workspace state is per-monitor
//   - Surfaces appear on the monitor where interaction occurs
//   - Support different geometries, resolutions, scale factors
//   - Adapt to changing monitor configurations

import QtQuick

QtObject {
    id: monitorModel

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null

    // =========================================================
    // Monitor Registry
    // =========================================================
    // Each entry: { index, name, width, height, x, y, scale, active }
    property var monitors: []

    // Primary monitor index
    property int primaryIndex: 0

    // Currently focused monitor
    property int focusedIndex: 0

    // =========================================================
    // Internal State Mutators
    // =========================================================

    function _applyMonitors(monitorList, focusedIdx) {
        monitors = (monitorList && monitorList.length > 0) ? monitorList : [{
            index: 0,
            name: "default",
            width: 1920,
            height: 1080,
            x: 0,
            y: 0,
            scale: 1.0,
            active: true
        }]
        if (typeof focusedIdx === "number") {
            focusedIndex = focusedIdx
        }
        monitorsChanged()

        if (logger) logger.debug("MonitorModel",
            "Monitors updated: %1 monitor(s)".arg(monitors.length))
    }

    function _applyFocus(monitorIndex) {
        if (focusedIndex === monitorIndex) return false
        var previous = focusedIndex
        focusedIndex = monitorIndex
        if (logger) logger.debug("MonitorModel",
            "Focus: monitor %1 → %2".arg(previous).arg(monitorIndex))
        return true
    }

    // =========================================================
    // Public Monitor Operations
    // =========================================================

    function updateMonitors(monitorList) {
        _applyMonitors(monitorList)
        if (eventBus) {
            eventBus.emit("monitor", {
                source: "model",
                type: "updated",
                count: monitors.length,
                monitors: monitors
            })
        }
    }

    function setFocused(monitorIndex) {
        var previous = focusedIndex
        if (!_applyFocus(monitorIndex)) return
        if (eventBus) {
            eventBus.emit("monitor", {
                source: "model",
                type: "focused",
                index: monitorIndex,
                previousIndex: previous
            })
        }
    }

    // =========================================================
    // Queries
    // =========================================================

    function getMonitor(index) {
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].index === index) return monitors[i]
        }
        return null
    }

    function getMonitorCount() {
        return monitors.length
    }

    // =========================================================
    // Lifecycle & Event Subscriptions
    // =========================================================

    function initialize() {
        _applyMonitors(null, 0)
        if (!eventBus) return

        eventBus.subscribe("MonitorModel", "monitor", function(ev) {
            if (!ev || ev.source === "model") return
            if (ev.type === "synced" || ev.type === "updated") {
                _applyMonitors(ev.monitors, ev.focusedIndex)
            } else if (ev.type === "focused" && typeof ev.index === "number") {
                _applyFocus(ev.index)
            }
        })

        if (logger) logger.info("MonitorModel",
            "Monitor model initialized (%1 monitor(s))".arg(monitors.length))
    }

    function teardown() {
        if (eventBus) {
            eventBus.unsubscribeAll("MonitorModel")
        }
    }

    function reset() {
        _applyMonitors(null, 0)
        primaryIndex = 0
        if (logger) logger.debug("MonitorModel", "Monitor model reset.")
    }
}
