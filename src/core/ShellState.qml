// BASEUS — Central Shell State
// Copyright (c) 2026 xoradesu — MIT License
//
// Central state singleton that owns authoritative shell-wide state.
// Surfaces consume state from here rather than maintaining their own copies.
//
// State domains:
//   - Shell lifecycle state (delegated to Lifecycle.qml)
//   - Active workspace (per-monitor, owned by WorkspaceModel.qml)
//   - Shell mode ("desktop", "fullscreen", "overview", etc.)
//   - Per-monitor native fullscreen tracking (DEC-023: distinct from maximize)
//   - Transient feedback state

import QtQuick

QtObject {
    id: shellState

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var workspaceModel: null
    property var windowModel: null

    // =========================================================
    // Shell Mode
    // =========================================================
    // Broad interaction context.
    // Possible values: "desktop", "fullscreen", "overview", "command-center",
    //                  "app-drawer", "power-menu"
    property string mode: "desktop"

    function setMode(newMode) {
        if (mode === newMode) return
        var oldMode = mode
        mode = newMode
        if (logger) logger.debug("ShellState",
            "Mode changed: %1 → %2".arg(oldMode).arg(newMode))
    }

    // =========================================================
    // Active Monitor & Per-Monitor Native Fullscreen State
    // =========================================================
    property int activeMonitorIndex: 0

    // Per DEC-023: true ONLY when a non-minimized native compositor fullscreen
    // window occupies the active workspace on the focused monitor (never on maximize).
    property bool hasFullscreenApp: false

    // Map of monitorIndex -> bool indicating active native fullscreen per monitor
    property var fullscreenMonitors: ({})

    function isMonitorFullscreen(monitorIndex) {
        if (typeof monitorIndex !== "number" || isNaN(monitorIndex)) return false
        return Boolean(fullscreenMonitors[Math.floor(monitorIndex)])
    }

    function _recomputeFullscreenState() {
        if (!windowModel) return

        var nextMap = {}
        if (workspaceModel && workspaceModel.activeWorkspaces) {
            for (var monKey in workspaceModel.activeWorkspaces) {
                var monIdx = parseInt(monKey, 10)
                if (isNaN(monIdx)) continue
                var activeWs = workspaceModel.activeWorkspaces[monKey]
                nextMap[monIdx] = windowModel.hasFullscreenWindow(monIdx, activeWs)
            }
        }

        var focusedWs = workspaceModel
            ? workspaceModel.getActiveWorkspace(activeMonitorIndex)
            : undefined
        var activeFs = windowModel.hasFullscreenWindow(activeMonitorIndex, focusedWs)
        nextMap[activeMonitorIndex] = activeFs

        fullscreenMonitors = nextMap
        hasFullscreenApp = activeFs

        if (activeFs) {
            if (mode === "desktop") {
                setMode("fullscreen")
            }
        } else if (mode === "fullscreen") {
            setMode("desktop")
        }
    }

    // =========================================================
    // Transient Feedback
    // =========================================================
    property bool osdVisible: false
    property bool notificationVisible: false

    // =========================================================
    // Lifecycle & Event Subscriptions
    // =========================================================

    function initialize() {
        reset()
        if (!eventBus) return

        eventBus.subscribe("ShellState", "monitor", function(ev) {
            if (!ev) return
            if (ev.type === "focused" && typeof ev.index === "number") {
                activeMonitorIndex = ev.index
                _recomputeFullscreenState()
            } else if (ev.type === "synced" && typeof ev.focusedIndex === "number") {
                activeMonitorIndex = ev.focusedIndex
                _recomputeFullscreenState()
            }
        })

        eventBus.subscribe("ShellState", "workspace", function(ev) {
            if (!ev) return
            if (ev.source === "model" || ev.type === "synced") {
                _recomputeFullscreenState()
            }
        })

        eventBus.subscribe("ShellState", "window", function(ev) {
            if (!ev) return
            if (windowModel) {
                if (ev.source === "model") {
                    _recomputeFullscreenState()
                }
            } else if (ev.type === "fullscreen" && typeof ev.fullscreen === "boolean") {
                hasFullscreenApp = ev.fullscreen
                var fallbackMap = {}
                fallbackMap[activeMonitorIndex] = ev.fullscreen
                fullscreenMonitors = fallbackMap
                setMode(ev.fullscreen ? "fullscreen" : "desktop")
            }
        })

        if (logger) logger.info("ShellState", "Shell state initialized.")
    }

    function teardown() {
        if (eventBus) {
            eventBus.unsubscribeAll("ShellState")
        }
    }

    function reset() {
        mode = "desktop"
        activeMonitorIndex = 0
        hasFullscreenApp = false
        fullscreenMonitors = ({})
        osdVisible = false
        notificationVisible = false
        if (logger) logger.debug("ShellState", "State reset to defaults.")
    }
}
