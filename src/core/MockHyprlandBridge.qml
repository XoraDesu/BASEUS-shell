// BASEUS — Mock Hyprland Integration Bridge
// Copyright (c) 2026 xoradesu — MIT License
//
// Provides a complete offline simulation of Hyprland IPC events.
// Used when developing on Windows, WSL2 without a live Hyprland compositor,
// or outside an active Hyprland session, allowing the state, event, and
// design token layers to be tested without compositor dependencies.
//
// Emits identical normalized events into EventBus as the real HyprlandBridge:
//   - "monitor": synced, focused
//   - "workspace": synced, activated
//   - "window": synced, created, destroyed, focused, moved, fullscreen

import QtQuick

QtObject {
    id: mockBridge

    // =========================================================
    // Dependencies (injected by Shell.qml)
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var workspaceModel: null
    property var monitorModel: null

    // =========================================================
    // Simulation State
    // =========================================================
    readonly property bool isMock: true
    property bool connected: false
    property string lastError: ""
    property int focusedMonitorIndex: 0
    property int currentWorkspace: 1
    property var mockActiveWorkspaces: ({ 0: 1 })
    property var mockMonitors: []
    property string focusedWindowAddress: "0x1a2b"

    property var mockWindows: []

    function _isValidWorkspaceId(workspaceId) {
        return typeof workspaceId === "number"
            && !isNaN(workspaceId)
            && Math.floor(workspaceId) === workspaceId
            && workspaceId >= 1
            && workspaceId <= 10
    }

    function _defaultMockMonitors(count) {
        var total = (typeof count === "number" && count >= 1) ? Math.floor(count) : 1
        var list = []
        for (var i = 0; i < total; i++) {
            list.push({
                index: i,
                name: "SIM-" + (i + 1),
                width: 1920,
                height: 1080,
                x: i * 1920,
                y: 0,
                scale: 1.0,
                active: true
            })
        }
        return list
    }

    function _defaultMockWindows() {
        return [
            {
                address: "0x1a2b",
                title: "terminal — zsh",
                appClass: "kitty",
                workspace: 1,
                monitor: 0,
                floating: true,
                fullscreen: false,
                maximized: false,
                minimized: false,
                focused: true
            },
            {
                address: "0x3c4d",
                title: "Mozilla Firefox",
                appClass: "firefox",
                workspace: 1,
                monitor: 0,
                floating: true,
                fullscreen: false,
                maximized: false,
                minimized: false,
                focused: false
            },
            {
                address: "0x5e6f",
                title: "BASEUS — Neovim",
                appClass: "nvim",
                workspace: 2,
                monitor: 0,
                floating: true,
                fullscreen: false,
                maximized: false,
                minimized: false,
                focused: false
            }
        ]
    }

    // =========================================================
    // Initialization
    // =========================================================

    function initialize() {
        if (logger) logger.info("MockBridge", "Starting offline Hyprland simulation...")

        focusedMonitorIndex = 0
        currentWorkspace = 1
        mockMonitors = _defaultMockMonitors(1)
        mockActiveWorkspaces = ({ 0: 1 })
        focusedWindowAddress = "0x1a2b"
        mockWindows = _defaultMockWindows()

        if (eventBus) {
            eventBus.emit("monitor", {
                source: "bridge",
                type: "synced",
                focusedIndex: focusedMonitorIndex,
                monitors: mockMonitors
            })

            eventBus.emit("workspace", {
                source: "bridge",
                type: "synced",
                activeWorkspaces: mockActiveWorkspaces
            })

            eventBus.emit("window", {
                source: "bridge",
                type: "synced",
                windows: mockWindows,
                focusedAddress: focusedWindowAddress
            })
        }

        connected = true
        lastError = ""
        if (logger) logger.info("MockBridge",
            "Simulation active (10 workspaces, %1 monitor(s), %2 sample windows)."
                .arg(mockMonitors.length).arg(mockWindows.length))
        return true
    }

    // =========================================================
    // Multi-Monitor Simulation
    // =========================================================

    function setMockMonitorCount(count) {
        if (!connected || typeof count !== "number" || isNaN(count) || count < 1) return false
        var total = Math.floor(count)
        mockMonitors = _defaultMockMonitors(total)

        var nextMap = {}
        for (var i = 0; i < total; i++) {
            var existing = mockActiveWorkspaces[i]
            nextMap[i] = _isValidWorkspaceId(existing) ? existing : Math.min(10, i + 1)
        }
        mockActiveWorkspaces = nextMap
        if (focusedMonitorIndex >= total) {
            focusedMonitorIndex = 0
        }
        currentWorkspace = mockActiveWorkspaces[focusedMonitorIndex] || 1

        if (eventBus) {
            eventBus.emit("monitor", {
                source: "bridge",
                type: "synced",
                focusedIndex: focusedMonitorIndex,
                monitors: mockMonitors
            })
            eventBus.emit("workspace", {
                source: "bridge",
                type: "synced",
                activeWorkspaces: mockActiveWorkspaces
            })
        }
        return true
    }

    function focusMonitor(monitorIndex) {
        if (!connected || typeof monitorIndex !== "number" || isNaN(monitorIndex)) return false
        var target = Math.floor(monitorIndex)
        if (target < 0 || target >= mockMonitors.length) {
            if (logger) logger.warn("MockBridge",
                "Cannot focus monitor %1 — simulated monitor count is %2.".arg(target).arg(mockMonitors.length))
            return false
        }

        focusedMonitorIndex = target
        currentWorkspace = getActiveWorkspaceId(target)

        if (eventBus) {
            eventBus.emit("monitor", {
                source: "bridge",
                type: "focused",
                index: target
            })
        }
        return true
    }

    // =========================================================
    // Workspace Simulation (DEC-010: Exactly 10 workspaces)
    // =========================================================

    function getActiveWorkspaceId(monitorIndex) {
        var mon = (typeof monitorIndex === "number" && !isNaN(monitorIndex))
            ? Math.floor(monitorIndex)
            : focusedMonitorIndex
        if (workspaceModel) {
            return workspaceModel.getActiveWorkspace(mon)
        }
        var ws = mockActiveWorkspaces[mon]
        return _isValidWorkspaceId(ws) ? ws : 1
    }

    function switchWorkspace(workspaceId, monitorIndex) {
        if (!_isValidWorkspaceId(workspaceId)) {
            if (logger) logger.warn("MockBridge",
                "Invalid workspace ID: %1 (must be integer 1–10)".arg(workspaceId))
            return false
        }

        if (!connected) return false

        var targetMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex))
            ? Math.floor(monitorIndex)
            : focusedMonitorIndex
        if (targetMon < 0 || targetMon >= mockMonitors.length) {
            if (logger) logger.warn("MockBridge",
                "Invalid monitor index %1 in switchWorkspace.".arg(targetMon))
            return false
        }

        if (targetMon !== focusedMonitorIndex) {
            focusMonitor(targetMon)
        }

        var previous = getActiveWorkspaceId(targetMon)
        var nextMap = {}
        for (var k in mockActiveWorkspaces) {
            nextMap[k] = mockActiveWorkspaces[k]
        }
        nextMap[targetMon] = workspaceId
        mockActiveWorkspaces = nextMap
        currentWorkspace = workspaceId

        if (logger) logger.info("MockBridge",
            "Simulating monitor %1 workspace switch: %2 → %3"
                .arg(targetMon).arg(previous).arg(workspaceId))

        if (eventBus) {
            eventBus.emit("workspace", {
                source: "bridge",
                type: "activated",
                monitorIndex: targetMon,
                previous: previous,
                current: workspaceId
            })
        }
        return true
    }

    function switchWorkspaceRelative(delta, monitorIndex) {
        if (!connected) return false
        var targetMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex))
            ? Math.floor(monitorIndex)
            : focusedMonitorIndex
        var step = (typeof delta === "number" && !isNaN(delta))
            ? (delta >= 0 ? Math.floor(delta) : Math.ceil(delta))
            : 0
        if (step === 0) return false

        var currentWs = getActiveWorkspaceId(targetMon)
        var targetWs = Math.max(1, Math.min(10, currentWs + step))
        if (targetWs === currentWs) return false
        return switchWorkspace(targetWs, targetMon)
    }

    function nextWorkspace(monitorIndex) {
        return switchWorkspaceRelative(1, monitorIndex)
    }

    function previousWorkspace(monitorIndex) {
        return switchWorkspaceRelative(-1, monitorIndex)
    }

    // =========================================================
    // Window Simulation
    // =========================================================

    function moveWindowToWorkspace(windowAddress, workspaceId) {
        if (!connected || !_isValidWorkspaceId(workspaceId) || !windowAddress) return false
        var addr = "0x" + String(windowAddress).replace(/^0x/, "")
        var found = false
        var next = []

        for (var i = 0; i < mockWindows.length; i++) {
            var copy = {}
            for (var wk in mockWindows[i]) {
                copy[wk] = mockWindows[i][wk]
            }
            if (copy.address === addr) {
                copy.workspace = workspaceId
                found = true
            }
            next.push(copy)
        }

        if (!found) return false
        mockWindows = next

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "moved",
                address: addr,
                workspace: workspaceId
            })
        }
        return true
    }

    function focusWindow(address) {
        focusedWindowAddress = address
        if (logger) logger.info("MockBridge", "Simulating window focus: %1".arg(address))

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "focused",
                address: address
            })
        }
    }

    function toggleFullscreen(address) {
        var nextFs = !(shellState && shellState.hasFullscreenApp)
        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "fullscreen",
                address: address || focusedWindowAddress,
                fullscreen: nextFs
            })
        }
        if (logger) logger.info("MockBridge", "Fullscreen toggled: %1".arg(nextFs))
    }

    function addMockWindow(title, appClass, workspaceId) {
        var addr = "0x" + Math.floor(Math.random() * 0xFFFF).toString(16)
        var win = {
            address: addr,
            title: title || "New Window",
            appClass: appClass || "app",
            workspace: workspaceId || currentWorkspace,
            monitor: focusedMonitorIndex,
            floating: true,
            fullscreen: false,
            maximized: false,
            minimized: false,
            focused: true
        }
        var next = mockWindows.slice()
        next.push(win)
        mockWindows = next
        if (eventBus) {
            eventBus.emit("window", { source: "bridge", type: "created", window: win })
        }
        focusWindow(addr)
    }

    function getMonitorCount() {
        return connected ? mockMonitors.length : 0
    }

    // =========================================================
    // Teardown
    // =========================================================

    function teardown() {
        var wasConnected = connected
        connected = false
        focusedMonitorIndex = 0
        if (wasConnected && logger) logger.info("MockBridge", "Mock simulation stopped.")
    }
}
