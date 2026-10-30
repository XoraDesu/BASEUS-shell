// BASEUS — Central Shell State
// Copyright (c) 2026 xoradesu — MIT License
//
// Central state singleton that owns authoritative shell-wide state.
// Surfaces consume state from here rather than maintaining their own copies.
//
// State domains:
//   - Shell lifecycle state (delegated to Lifecycle.qml)
//   - Active workspace (per-monitor, owned by WorkspaceModel.qml)
//   - Shell mode (normal, fullscreen-app, overview, etc.)
//   - Transient feedback state
//
// Design principles (per AGENTS.md §11, TASKS.md §10):
//   - Single source of truth for each state domain
//   - Clear read/update boundaries
//   - Derived state computed, not duplicated
//   - Transient vs persistent distinction
//   - Deterministic initialization

import QtQuick

QtObject {
    id: shellState

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null

    // =========================================================
    // Shell Mode
    // =========================================================
    // Represents the broad interaction context.
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
    // Active Monitor
    // =========================================================
    // Which monitor currently has user focus.
    property int activeMonitorIndex: 0

    // =========================================================
    // Fullscreen State
    // =========================================================
    // Whether a fullscreen application is active on the focused monitor.
    // Shell surfaces should recede when this is true.
    property bool hasFullscreenApp: false

    // =========================================================
    // Transient Feedback
    // =========================================================
    // Brief transient states (OSD visible, notification visible, etc.)
    // These are runtime-only and never persisted.
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
            } else if (ev.type === "synced" && typeof ev.focusedIndex === "number") {
                activeMonitorIndex = ev.focusedIndex
            }
        })

        eventBus.subscribe("ShellState", "window", function(ev) {
            if (!ev) return
            if (ev.type === "fullscreen" && typeof ev.fullscreen === "boolean") {
                hasFullscreenApp = ev.fullscreen
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
        osdVisible = false
        notificationVisible = false
        if (logger) logger.debug("ShellState", "State reset to defaults.")
    }
}
