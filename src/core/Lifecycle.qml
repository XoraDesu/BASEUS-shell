pragma ComponentBehavior: Bound

// BASEUS — Shell Lifecycle Management
// Copyright (c) 2026 xoradesu — MIT License
//
// Manages the deterministic shell lifecycle:
//   initialize → running → teardown
//
// Responsibilities:
//   - Deterministic initialization sequence
//   - Teardown/cleanup behavior
//   - Restart behavior (no duplicate subscriptions)
//   - State initialization timing
//   - Failure diagnosis during init

import QtQuick

QtObject {
    id: lifecycle

    // =========================================================
    // Dependencies (injected from Shell.qml)
    // =========================================================
    property var logger: null
    property var config: null
    property var eventBus: null

    // Optional callbacks wired by composition root (Shell.qml) so
    // initialize / teardown / restart orchestrate all subsystems deterministically.
    property var onInitializeSubsystems: null
    property var onTeardownSubsystems: null

    // =========================================================
    // Lifecycle State
    // =========================================================

    // Possible states: "uninitialized", "initializing", "running",
    //                  "tearing_down", "terminated", "error"
    readonly property string state: _state
    property string _state: "uninitialized"

    // Tracks whether initialization completed successfully
    readonly property bool initialized: _state === "running"

    // Consecutive failed initialization counter — detects crash/restart loops
    // without blocking clean restarts.
    property int _consecutiveFailures: 0
    readonly property int maxInitAttempts: 5
    property int restartCount: 0
    property real startupDurationMs: 0
    property real _initStartTime: 0

    // =========================================================
    // Initialization
    // =========================================================

    function initialize() {
        if (_state !== "uninitialized" && _state !== "terminated" && _state !== "error") {
            if (logger) logger.warn("Lifecycle",
                "initialize() called in state '%1' — ignoring".arg(_state))
            return false
        }

        if (_consecutiveFailures >= maxInitAttempts) {
            _state = "error"
            if (logger) logger.error("Lifecycle",
                "Maximum consecutive initialization failures (%1) reached. Aborting to prevent restart loop."
                    .arg(maxInitAttempts))
            return false
        }

        _state = "initializing"
        _initStartTime = Date.now()
        if (logger) logger.info("Lifecycle", "Initialization started.")

        // Step 1: Load configuration and sync logger verbosity
        if (config) {
            try {
                config.load()
                if (logger) {
                    logger.level = config.logLevel
                    if (restartCount === 0) {
                        logger.logBanner()
                    }
                    logger.info("Lifecycle", "Configuration loaded (logLevel=%1, simulation=%2)."
                        .arg(config.logLevel).arg(config.simulationEnabled))
                }
            } catch (e) {
                _consecutiveFailures++
                _state = "error"
                if (logger) logger.error("Lifecycle",
                    "Configuration load failed (failure %1/%2): %3"
                        .arg(_consecutiveFailures).arg(maxInitAttempts).arg(e.message || String(e)))
                return false
            }
        }

        // Step 2: Initialize state, event subscriptions, and bridge via composition root
        if (typeof onInitializeSubsystems === "function") {
            try {
                onInitializeSubsystems()
            } catch (subErr) {
                _consecutiveFailures++
                _state = "error"
                if (logger) logger.error("Lifecycle",
                    "Subsystem initialization failed (failure %1/%2): %3"
                        .arg(_consecutiveFailures).arg(maxInitAttempts).arg(subErr.message || String(subErr)))
                return false
            }
        }

        // Step 3: Mark running and reset consecutive failure counter
        _consecutiveFailures = 0
        _state = "running"
        startupDurationMs = Date.now() - _initStartTime
        if (logger) logger.info("Lifecycle",
            "Shell lifecycle is now RUNNING (initialized in %1 ms).".arg(startupDurationMs))
        if (eventBus) {
            eventBus.emit("lifecycle", {
                type: "started",
                restartCount: restartCount,
                startupDurationMs: startupDurationMs
            })
        }
        return true
    }

    // =========================================================
    // Teardown
    // =========================================================

    function teardown() {
        if (_state === "terminated" || _state === "tearing_down" || _state === "uninitialized") {
            if (logger) logger.warn("Lifecycle",
                "teardown() called in state '%1' — ignoring".arg(_state))
            return false
        }

        _state = "tearing_down"
        if (logger) logger.info("Lifecycle", "Teardown started.")

        if (eventBus) {
            eventBus.emit("lifecycle", { type: "stopping" })
        }

        if (typeof onTeardownSubsystems === "function") {
            try {
                onTeardownSubsystems()
            } catch (e) {
                if (logger) logger.error("Lifecycle",
                    "Error during subsystem teardown: %1".arg(e.message || String(e)))
            }
        }

        _state = "terminated"
        if (logger) logger.info("Lifecycle", "Teardown complete.")
        return true
    }

    // =========================================================
    // Restart
    // =========================================================

    function restart() {
        if (logger) logger.info("Lifecycle", "Restart requested.")
        restartCount++
        if (_state === "running" || _state === "error") {
            teardown()
        }
        return initialize()
    }
}
