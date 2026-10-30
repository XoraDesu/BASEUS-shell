// BASEUS — Configuration Manager
// Copyright (c) 2026 xoradesu — MIT License
//
// Manages configuration loading, defaults, and validation.
// Per TASKS.md §13:
//   - Clear static configuration boundary
//   - Runtime state is NOT configuration
//   - Theme visual state is NOT behavior configuration
//   - Defaults must be usable
//   - Invalid configuration has a predictable failure path
//   - Safe fallback behavior
//
// Configuration loading order:
//   1. Built-in defaults (hardcoded)
//   2. System/project config (config/baseus.json if present)
//   3. User config (~/.config/baseus/baseus.json or $BASEUS_CONFIG_PATH)
//   4. Runtime environment overrides (not persisted)

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: config

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null

    // =========================================================
    // File Readers (Quickshell.Io)
    // =========================================================
    property FileView _systemFile: FileView {
        blockLoading: true
        blockAllReads: true
        watchChanges: false
        printErrors: false
    }

    property FileView _userFile: FileView {
        blockLoading: true
        blockAllReads: true
        watchChanges: false
        printErrors: false
    }

    // =========================================================
    // Configuration State
    // =========================================================
    property bool loaded: false
    property string configPath: ""
    property string lastError: ""
    property bool usedFallback: false

    // =========================================================
    // Default Configuration Values
    // =========================================================
    // These are the built-in defaults. User configuration overrides
    // individual values, not the entire structure.

    // Shell (DEC-010: Fixed ten-workspace model)
    readonly property int workspaceCount: 10

    // Dock
    property int dockTriggerHeight: 2          // pixels
    property int dockRevealDuration: 200       // ms
    property bool dockShowLauncher: true

    // Top Island
    property int topIslandIdleTimeout: 2000    // ms before secondary info hides

    // Notifications
    property int notificationTimeout: 3000     // ms — approximately 3 seconds per MASTER.md §30
    property string notificationPosition: "top-left"

    // Command Center
    property string commandCenterPrefix: ""    // no prefix = app search
    property string commandCenterActionPrefix: ">"

    // Workspace
    property var workspaceLabels: ({})         // user-defined workspace labels (MASTER.md §7)
    property var workspaceTags: ({})           // user-defined workspace tags (MASTER.md §7)

    // Performance
    property bool reducedMotion: false
    property int animationDuration: 250        // ms — default animation duration

    // Logging
    property string logLevel: "info"           // debug, info, warn, error

    // Simulation / Mock Mode (for offline UI design development without live Hyprland)
    property bool simulationEnabled: false

    // =========================================================
    // Internal Helpers
    // =========================================================

    function _applyDefaults() {
        dockTriggerHeight = 2
        dockRevealDuration = 200
        dockShowLauncher = true
        topIslandIdleTimeout = 2000
        notificationTimeout = 3000
        notificationPosition = "top-left"
        commandCenterPrefix = ""
        commandCenterActionPrefix = ">"
        workspaceLabels = ({})
        workspaceTags = ({})
        reducedMotion = false
        animationDuration = 250
        logLevel = "info"
        simulationEnabled = false
    }

    function _resolveUserConfigPath() {
        var customPath = String(Quickshell.env("BASEUS_CONFIG_PATH") || "")
        if (customPath.length > 0) {
            return customPath
        }
        var xdgConfig = String(Quickshell.env("XDG_CONFIG_HOME") || "")
        if (xdgConfig.length > 0) {
            return xdgConfig + "/baseus/baseus.json"
        }
        var home = String(Quickshell.env("HOME") || "")
        if (home.length > 0) {
            return home + "/.config/baseus/baseus.json"
        }
        return ""
    }

    function _mergeLayer(parsed, sourceLabel) {
        if (!parsed || typeof parsed !== "object") {
            lastError = "Invalid configuration root in " + sourceLabel
            usedFallback = true
            if (logger) logger.warn("Config", lastError + " — keeping fallback defaults.")
            return
        }

        var root = (parsed.baseus && typeof parsed.baseus === "object") ? parsed.baseus : parsed

        // Reject / ignore visual theme state inside behavioral config (DEC-012, TASKS.md §13)
        if (root.theme !== undefined) {
            if (logger) logger.warn("Config",
                "Ignoring 'theme' block in %1 — visual theme state belongs outside behavioral config (DEC-012)."
                    .arg(sourceLabel))
        }

        if (root.shell && typeof root.shell === "object") {
            if (typeof root.shell.logLevel === "string") logLevel = root.shell.logLevel
        }

        if (root.simulation && typeof root.simulation === "object") {
            if (typeof root.simulation.enabled === "boolean") simulationEnabled = root.simulation.enabled
        }

        if (root.dock && typeof root.dock === "object") {
            if (typeof root.dock.triggerHeight === "number") dockTriggerHeight = Math.round(root.dock.triggerHeight)
            if (typeof root.dock.revealDuration === "number") dockRevealDuration = Math.round(root.dock.revealDuration)
            if (typeof root.dock.showLauncher === "boolean") dockShowLauncher = root.dock.showLauncher
        }

        if (root.topIsland && typeof root.topIsland === "object") {
            if (typeof root.topIsland.idleTimeout === "number") topIslandIdleTimeout = Math.round(root.topIsland.idleTimeout)
        }

        if (root.notifications && typeof root.notifications === "object") {
            if (typeof root.notifications.timeout === "number") notificationTimeout = Math.round(root.notifications.timeout)
            if (typeof root.notifications.position === "string") notificationPosition = root.notifications.position
        }

        if (root.commandCenter && typeof root.commandCenter === "object") {
            if (typeof root.commandCenter.defaultPrefix === "string") commandCenterPrefix = root.commandCenter.defaultPrefix
            if (typeof root.commandCenter.actionPrefix === "string") commandCenterActionPrefix = root.commandCenter.actionPrefix
        }

        if (root.workspaces && typeof root.workspaces === "object") {
            if (root.workspaces.count !== undefined && root.workspaces.count !== 10) {
                if (logger) logger.warn("Config",
                    "Ignoring 'workspaces.count' in %1 — BASEUS enforces a fixed 10-workspace model (DEC-010)."
                        .arg(sourceLabel))
            }
            if (root.workspaces.labels && typeof root.workspaces.labels === "object") {
                workspaceLabels = root.workspaces.labels
            }
            if (root.workspaces.tags && typeof root.workspaces.tags === "object") {
                workspaceTags = root.workspaces.tags
            }
        }

        if (root.performance && typeof root.performance === "object") {
            if (typeof root.performance.reducedMotion === "boolean") reducedMotion = root.performance.reducedMotion
            if (typeof root.performance.animationDuration === "number") animationDuration = Math.round(root.performance.animationDuration)
        }
    }

    function _loadFileLayer(fileView, path, isOptional) {
        if (!path || path.length === 0) return false
        fileView.path = path
        fileView.reload()
        fileView.waitForJob()
        var raw = fileView.text()
        if (!raw || raw.trim().length === 0) {
            if (!isOptional && logger) {
                logger.warn("Config", "Configuration file empty or missing at '%1' — using built-in defaults.".arg(path))
            }
            return false
        }

        try {
            var parsed = JSON.parse(raw)
            _mergeLayer(parsed, path)
            return true
        } catch (e) {
            lastError = "Malformed JSON in '%1': %2".arg(path).arg(e.message || String(e))
            usedFallback = true
            if (logger) logger.error("Config", lastError + " — falling back to safe defaults.")
            return false
        }
    }

    function _sanitizeInvalidValues() {
        var check = validate()
        if (check.valid) return

        usedFallback = true
        lastError = check.issues.join("; ")
        if (logger) logger.warn("Config",
            "Configuration validation issues (%1) — reverting invalid fields to defaults.".arg(lastError))

        if (dockTriggerHeight < 1 || dockTriggerHeight > 10) dockTriggerHeight = 2
        if (dockRevealDuration < 0 || dockRevealDuration > 5000) dockRevealDuration = 200
        if (topIslandIdleTimeout < 250 || topIslandIdleTimeout > 30000) topIslandIdleTimeout = 2000
        if (notificationTimeout < 1000 || notificationTimeout > 30000) notificationTimeout = 3000
        if (animationDuration < 0 || animationDuration > 5000) animationDuration = 250
        if (["debug", "info", "warn", "error"].indexOf(logLevel) === -1) logLevel = "info"
    }

    // =========================================================
    // Load
    // =========================================================

    function load() {
        _applyDefaults()
        lastError = ""
        usedFallback = false

        // 1. Project/system defaults (config/baseus.json)
        var projectConfigPath = String(Quickshell.shellDir || "")
        if (projectConfigPath.length > 0) {
            _loadFileLayer(_systemFile, projectConfigPath + "/config/baseus.json", true)
        }

        // 2. User configuration (~/.config/baseus/baseus.json or $BASEUS_CONFIG_PATH)
        var explicitCustom = String(Quickshell.env("BASEUS_CONFIG_PATH") || "")
        var userPath = _resolveUserConfigPath()
        configPath = userPath
        if (userPath.length > 0) {
            var loadedUser = _loadFileLayer(_userFile, userPath, explicitCustom.length === 0)
            if (explicitCustom.length > 0 && !loadedUser && lastError.length === 0) {
                lastError = "Explicit config path not found or empty: " + explicitCustom
                usedFallback = true
            }
        }

        // 3. Runtime environment overrides (not persisted)
        var envSim = String(Quickshell.env("BASEUS_SIMULATION") || "").toLowerCase()
        if (envSim === "1" || envSim === "true") {
            simulationEnabled = true
        } else if (envSim === "0" || envSim === "false") {
            simulationEnabled = false
        }

        var envLog = String(Quickshell.env("BASEUS_LOG_LEVEL") || "").toLowerCase()
        if (envLog.length > 0) {
            logLevel = envLog
        }

        // 4. Validate and apply safe fallbacks for any out-of-range fields
        _sanitizeInvalidValues()

        loaded = true
        if (eventBus) {
            eventBus.emit("config", {
                type: "reloaded",
                usedFallback: usedFallback,
                simulationEnabled: simulationEnabled,
                logLevel: logLevel
            })
        }
    }

    // =========================================================
    // Get with Fallback
    // =========================================================

    function get(key, fallback) {
        if (Object.prototype.hasOwnProperty.call(config, key)) {
            return config[key]
        }
        return fallback
    }

    // =========================================================
    // Validation
    // =========================================================

    function validate() {
        var issues = []

        if (dockTriggerHeight < 1 || dockTriggerHeight > 10)
            issues.push("dockTriggerHeight out of range (1–10)")

        if (dockRevealDuration < 0 || dockRevealDuration > 5000)
            issues.push("dockRevealDuration out of range (0–5000)")

        if (topIslandIdleTimeout < 250 || topIslandIdleTimeout > 30000)
            issues.push("topIslandIdleTimeout out of range (250–30000)")

        if (notificationTimeout < 1000 || notificationTimeout > 30000)
            issues.push("notificationTimeout out of range (1000–30000)")

        if (animationDuration < 0 || animationDuration > 5000)
            issues.push("animationDuration out of range (0–5000)")

        if (workspaceCount !== 10)
            issues.push("workspaceCount must be exactly 10")

        if (["debug", "info", "warn", "error"].indexOf(logLevel) === -1)
            issues.push("logLevel must be one of: debug, info, warn, error")

        return {
            valid: issues.length === 0,
            issues: issues
        }
    }

    // =========================================================
    // Reset
    // =========================================================

    function reset() {
        _applyDefaults()
        lastError = ""
        usedFallback = false
        loaded = false
    }

    Component.onCompleted: {
        // Configuration object created — not yet loaded.
        // load() is called by Lifecycle during initialization.
    }
}
