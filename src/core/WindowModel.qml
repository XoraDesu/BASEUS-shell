// BASEUS — Window Model
// Copyright (c) 2026 xoradesu — MIT License
//
// Tracks window state for the BASEUS shell.
// Per MASTER.md §6 and DEC-008:
//   - Freeform floating windows (default)
//   - Centered new windows
//   - Overlap allowed
//   - Minimize / maximize / native fullscreen distinction
//   - No scratchpad (DEC-038)
//
// State ownership:
//   - WindowModel owns the BASEUS view of window state
//   - HyprlandBridge / MockHyprlandBridge provides normalized window events
//   - Surfaces consume window state from here

import QtQuick

QtObject {
    id: windowModel

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null

    // =========================================================
    // Window Registry
    // =========================================================
    // List of tracked windows
    // Each entry: { address, title, appClass, workspace, monitor,
    //               floating, fullscreen, maximized, minimized, focused }
    property var windows: []

    // Currently focused window address
    property string focusedAddress: ""

    // =========================================================
    // Internal Mutators
    // =========================================================

    function _normalizeEntry(windowData) {
        return {
            address: String(windowData.address || ""),
            title: String(windowData.title || ""),
            appClass: String(windowData.appClass || windowData["class"] || ""),
            workspace: typeof windowData.workspace === "number" ? windowData.workspace : 1,
            monitor: typeof windowData.monitor === "number" ? windowData.monitor : 0,
            floating: windowData.floating !== undefined ? Boolean(windowData.floating) : true,
            fullscreen: Boolean(windowData.fullscreen),
            maximized: Boolean(windowData.maximized),
            minimized: Boolean(windowData.minimized),
            focused: Boolean(windowData.focused)
        }
    }

    function _upsertWindow(windowData) {
        if (!windowData || !windowData.address) return null
        var entry = _normalizeEntry(windowData)
        var next = windows.slice()
        for (var i = 0; i < next.length; i++) {
            if (next[i].address === entry.address) {
                next[i] = entry
                windows = next
                if (entry.focused) focusedAddress = entry.address
                return entry
            }
        }
        next.push(entry)
        windows = next
        if (entry.focused) focusedAddress = entry.address
        if (logger) logger.debug("WindowModel",
            "Window tracked: '%1' (%2)".arg(entry.title).arg(entry.address))
        return entry
    }

    function _deleteWindow(address) {
        var next = windows.slice()
        for (var i = 0; i < next.length; i++) {
            if (next[i].address === address) {
                var removed = next.splice(i, 1)[0]
                windows = next
                if (focusedAddress === address) {
                    focusedAddress = ""
                }
                if (logger) logger.debug("WindowModel",
                    "Window removed: '%1' (%2)".arg(removed.title).arg(address))
                return removed
            }
        }
        return null
    }

    function _applyFocus(address) {
        if (focusedAddress === address) return false
        var previous = focusedAddress
        focusedAddress = address || ""

        var next = windows.slice()
        for (var i = 0; i < next.length; i++) {
            var copy = _normalizeEntry(next[i])
            copy.focused = (copy.address === focusedAddress)
            next[i] = copy
        }
        windows = next

        if (logger) logger.debug("WindowModel",
            "Focus: %1 → %2".arg(previous || "none").arg(focusedAddress || "none"))
        return true
    }

    // =========================================================
    // Public Window Operations
    // =========================================================

    function addWindow(windowData) {
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].address === windowData.address) {
                if (logger) logger.warn("WindowModel",
                    "Duplicate window: %1".arg(windowData.address))
                return
            }
        }
        var entry = _upsertWindow(windowData)
        if (entry && eventBus) {
            eventBus.emit("window", { source: "model", type: "created", window: entry })
        }
    }

    function removeWindow(address) {
        var removed = _deleteWindow(address)
        if (removed && eventBus) {
            eventBus.emit("window", { source: "model", type: "destroyed", window: removed, address: address })
        }
    }

    function setFocused(address) {
        var previous = focusedAddress
        if (!_applyFocus(address)) return
        if (eventBus) {
            eventBus.emit("window", {
                source: "model",
                type: "focused",
                address: focusedAddress,
                previousAddress: previous
            })
        }
    }

    // =========================================================
    // Queries
    // =========================================================

    function getWindowsByWorkspace(workspaceId) {
        return windows.filter(function(w) { return w.workspace === workspaceId })
    }

    function getWindowsByMonitor(monitorIndex) {
        return windows.filter(function(w) { return w.monitor === monitorIndex })
    }

    function getWindowByAddress(address) {
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].address === address) return windows[i]
        }
        return null
    }

    function hasFullscreenWindow(monitorIndex) {
        return windows.some(function(w) {
            return w.monitor === monitorIndex && w.fullscreen
        })
    }

    // =========================================================
    // Lifecycle & Event Subscriptions
    // =========================================================

    function initialize() {
        windows = []
        focusedAddress = ""
        if (!eventBus) return

        eventBus.subscribe("WindowModel", "window", function(ev) {
            if (!ev || ev.source === "model") return
            if (ev.type === "synced" && Array.isArray(ev.windows)) {
                var list = []
                var focusAddr = ev.focusedAddress || ""
                for (var i = 0; i < ev.windows.length; i++) {
                    var item = _normalizeEntry(ev.windows[i])
                    if (item.focused && !focusAddr) focusAddr = item.address
                    list.push(item)
                }
                windows = list
                focusedAddress = focusAddr
            } else if (ev.type === "created" && ev.window) {
                _upsertWindow(ev.window)
            } else if (ev.type === "destroyed" && ev.address) {
                _deleteWindow(ev.address)
            } else if (ev.type === "focused" && ev.address !== undefined) {
                _applyFocus(ev.address)
            } else if (ev.type === "moved" && ev.address && typeof ev.workspace === "number") {
                var existing = getWindowByAddress(ev.address)
                if (existing) {
                    var movedCopy = _normalizeEntry(existing)
                    movedCopy.workspace = ev.workspace
                    _upsertWindow(movedCopy)
                }
            } else if (ev.type === "fullscreen" && ev.address) {
                var fsWin = getWindowByAddress(ev.address)
                if (fsWin) {
                    var fsCopy = _normalizeEntry(fsWin)
                    fsCopy.fullscreen = Boolean(ev.fullscreen)
                    _upsertWindow(fsCopy)
                }
            }
        })

        if (logger) logger.info("WindowModel", "Window model initialized.")
    }

    function teardown() {
        if (eventBus) {
            eventBus.unsubscribeAll("WindowModel")
        }
    }

    function reset() {
        windows = []
        focusedAddress = ""
        if (logger) logger.debug("WindowModel", "Window model reset.")
    }
}
