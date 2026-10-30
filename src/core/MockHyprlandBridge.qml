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
//   - "workspace": switched, activated
//   - "window": synced, created, destroyed, focused, fullscreen

import QtQuick

QtObject {
    id: mockBridge

    // =========================================================
    // Dependencies (injected by Shell.qml)
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null

    // =========================================================
    // Simulation State
    // =========================================================
    readonly property bool isMock: true
    property bool connected: false
    property string lastError: ""
    property int currentWorkspace: 1
    property string focusedWindowAddress: "0x1a2b"

    property var mockWindows: []

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
                focused: false
            }
        ]
    }

    // =========================================================
    // Initialization
    // =========================================================

    function initialize() {
        if (logger) logger.info("MockBridge", "Starting offline Hyprland simulation...")

        currentWorkspace = 1
        focusedWindowAddress = "0x1a2b"
        mockWindows = _defaultMockWindows()

        if (eventBus) {
            eventBus.emit("monitor", {
                source: "bridge",
                type: "synced",
                focusedIndex: 0,
                monitors: [{
                    index: 0,
                    name: "SIM-1",
                    width: 1920,
                    height: 1080,
                    x: 0,
                    y: 0,
                    scale: 1.0,
                    active: true
                }]
            })

            eventBus.emit("workspace", {
                source: "bridge",
                type: "activated",
                monitorIndex: 0,
                previous: 1,
                current: currentWorkspace,
                label: "MAIN"
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
        if (logger) logger.info("MockBridge", "Simulation active (10 workspaces, %1 sample windows).".arg(mockWindows.length))
        return true
    }

    // =========================================================
    // Workspace Simulation (DEC-010: Exactly 10 workspaces)
    // =========================================================

    function getActiveWorkspaceId(monitorIndex) {
        if (monitorIndex !== 0) return 1
        return currentWorkspace
    }

    function switchWorkspace(workspaceId) {
        if (workspaceId < 1 || workspaceId > 10) {
            if (logger) logger.warn("MockBridge",
                "Invalid workspace ID: %1 (must be 1–10)".arg(workspaceId))
            return false
        }

        var previous = currentWorkspace
        currentWorkspace = workspaceId

        if (logger) logger.info("MockBridge",
            "Simulating workspace switch: %1 → %2".arg(previous).arg(workspaceId))

        if (eventBus) {
            eventBus.emit("workspace", {
                source: "bridge",
                type: "activated",
                monitorIndex: 0,
                previous: previous,
                current: workspaceId,
                label: workspaceId === 1 ? "MAIN" : (workspaceId === 2 ? "DEV" : "WS" + workspaceId)
            })
        }
        return true
    }

    // =========================================================
    // Window Simulation
    // =========================================================

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
            monitor: 0,
            floating: true,
            fullscreen: false,
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
        return connected ? 1 : 0
    }

    // =========================================================
    // Teardown
    // =========================================================

    function teardown() {
        var wasConnected = connected
        connected = false
        if (wasConnected && logger) logger.info("MockBridge", "Mock simulation stopped.")
    }
}
