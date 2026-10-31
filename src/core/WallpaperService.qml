// BASEUS — Wallpaper Engine Service
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by DEC-013, DEC-014, and MASTER.md §27–28:
//   - Static wallpapers are workspace-specific (independent per workspace 1..10)
//   - Live wallpaper is global across the desktop
//   - DEC-014: Live wallpaper palette extraction is bounded, sampled once, and cached (strictly NO continuous extraction loops)
//   - Event-driven coordination via EventBus ("workspace", "wallpaper")
//   - Multi-monitor wallpaper layout adaptation

pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: wallpaperService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var config: null
    property var workspaceModel: null
    property var monitorModel: null
    property var paletteService: null

    // =========================================================
    // Engine State
    // =========================================================
    // Mode: "static" (per-workspace) | "live" (global)
    property string mode: "static"

    // Static wallpaper mapping: workspace index (1..10) -> image path
    property var workspaceWallpapers: ({})

    // Global live wallpaper path / uri
    property string globalLiveWallpaper: ""

    // Default static wallpaper fallback
    property string defaultWallpaper: ""

    // Automatically trigger palette extraction on wallpaper switch
    property bool autoExtractPalette: true

    // Active wallpaper per monitor: monitorIndex (int) -> path (string)
    property var monitorWallpapers: ({})

    // Signal when active wallpaper changes for a monitor
    signal wallpaperChanged(int monitorIndex, int workspace, string path, bool isLive)

    // =========================================================
    // Lifecycle & Subscriptions
    // =========================================================

    function initialize() {
        // Read default wallpapers from config if available
        if (config && config.raw && config.raw.wallpaper) {
            var wpConf = config.raw.wallpaper
            if (wpConf.defaultPath) defaultWallpaper = wpConf.defaultPath
            if (wpConf.mode) mode = wpConf.mode
            if (wpConf.workspaces) workspaceWallpapers = wpConf.workspaces
            if (wpConf.livePath) globalLiveWallpaper = wpConf.livePath
        }

        if (eventBus) {
            eventBus.unsubscribeAll("WallpaperService")

            // Listen to workspace changes to update per-workspace static wallpaper
            eventBus.subscribe("WallpaperService", "workspace", function(eventData) {
                if (!eventData || mode !== "static") return
                var mon = (typeof eventData.monitorIndex === "number") ? eventData.monitorIndex : 0
                var ws = (typeof eventData.current === "number") ? eventData.current : 1
                _updateMonitorWallpaper(mon, ws)
            })

            // Listen to monitor configuration changes
            eventBus.subscribe("WallpaperService", "monitor", function(eventData) {
                if (!eventData) return
                _refreshAllMonitors()
            })

            if (logger) logger.debug("WallpaperService", "Subscribed to workspace and monitor events.")
        }

        _refreshAllMonitors()
        if (logger) logger.info("WallpaperService", "WallpaperService initialized (mode=" + mode + ").")
    }

    function teardown() {
        if (eventBus) {
            eventBus.unsubscribeAll("WallpaperService")
        }
        monitorWallpapers = ({})
        if (logger) logger.info("WallpaperService", "WallpaperService torn down.")
    }

    // =========================================================
    // Internal Helpers
    // =========================================================

    function _resolveWallpaperForWorkspace(wsIndex) {
        var key = String(wsIndex)
        if (workspaceWallpapers && workspaceWallpapers[key] && workspaceWallpapers[key].length > 0) {
            return workspaceWallpapers[key]
        }
        return defaultWallpaper
    }

    function _updateMonitorWallpaper(monIndex, wsIndex) {
        var targetPath = (mode === "live")
            ? (globalLiveWallpaper.length > 0 ? globalLiveWallpaper : defaultWallpaper)
            : _resolveWallpaperForWorkspace(wsIndex)

        var current = monitorWallpapers[monIndex] || ""
        if (current !== targetPath) {
            var updated = Object.assign({}, monitorWallpapers)
            updated[monIndex] = targetPath
            monitorWallpapers = updated

            wallpaperChanged(monIndex, wsIndex, targetPath, mode === "live")

            if (eventBus) {
                eventBus.emit("wallpaper", {
                    type: "wallpaper_changed",
                    monitorIndex: monIndex,
                    workspace: wsIndex,
                    path: targetPath,
                    isLive: (mode === "live")
                })
            }

            // Trigger palette extraction if enabled and path exists
            if (autoExtractPalette && paletteService && targetPath.length > 0) {
                paletteService.extractPalette(targetPath)
            }
        }
    }

    function _refreshAllMonitors() {
        var monCount = 1
        if (monitorModel && typeof monitorModel.getMonitorCount === "function") {
            monCount = monitorModel.getMonitorCount()
        }
        for (var i = 0; i < monCount; i++) {
            var ws = 1
            if (workspaceModel && typeof workspaceModel.getActiveWorkspace === "function") {
                ws = workspaceModel.getActiveWorkspace(i)
            }
            _updateMonitorWallpaper(i, ws)
        }
    }

    // =========================================================
    // Public API Methods
    // =========================================================

    function setWorkspaceWallpaper(workspaceId, path) {
        if (typeof workspaceId !== "number" || workspaceId < 1 || workspaceId > 10) {
            if (logger) logger.warn("WallpaperService", "Invalid workspaceId: " + workspaceId + " (must be 1..10)")
            return false
        }

        var key = String(workspaceId)
        var updated = Object.assign({}, workspaceWallpapers)
        updated[key] = path || ""
        workspaceWallpapers = updated

        if (logger) {
            logger.info("WallpaperService", "Set static wallpaper for workspace " + workspaceId + ": " + path)
        }

        // If in static mode, refresh any monitor currently displaying this workspace
        if (mode === "static") {
            var monCount = monitorModel && typeof monitorModel.getMonitorCount === "function"
                ? monitorModel.getMonitorCount()
                : 1
            for (var i = 0; i < monCount; i++) {
                var curWs = workspaceModel && typeof workspaceModel.getActiveWorkspace === "function"
                    ? workspaceModel.getActiveWorkspace(i)
                    : 1
                if (curWs === workspaceId) {
                    _updateMonitorWallpaper(i, workspaceId)
                }
            }
        }

        if (eventBus) {
            eventBus.emit("wallpaper", {
                type: "workspace_wallpaper_set",
                workspace: workspaceId,
                path: path
            })
        }

        return true
    }

    function setGlobalLiveWallpaper(path) {
        mode = "live"
        globalLiveWallpaper = path || ""

        if (logger) {
            logger.info("WallpaperService", "Set global live wallpaper: " + path)
        }

        // Enforce DEC-014: Sample and extract palette ONCE; never continuously loop
        if (autoExtractPalette && paletteService && globalLiveWallpaper.length > 0) {
            paletteService.extractPalette(globalLiveWallpaper)
        }

        _refreshAllMonitors()

        if (eventBus) {
            eventBus.emit("wallpaper", {
                type: "live_wallpaper_set",
                path: path
            })
        }

        return true
    }

    function setMode(newMode) {
        if (newMode !== "static" && newMode !== "live") {
            if (logger) logger.warn("WallpaperService", "Invalid wallpaper mode: " + newMode)
            return false
        }
        mode = newMode
        _refreshAllMonitors()

        if (eventBus) {
            eventBus.emit("wallpaper", {
                type: "wallpaper_mode_changed",
                mode: mode
            })
        }

        return true
    }

    function getWallpaperForWorkspace(workspaceId) {
        return _resolveWallpaperForWorkspace(workspaceId)
    }

    function getWallpaperForMonitor(monitorIndex) {
        var mon = (typeof monitorIndex === "number" && monitorIndex >= 0) ? monitorIndex : 0
        if (monitorWallpapers && monitorWallpapers[mon]) {
            return monitorWallpapers[mon]
        }
        var curWs = 1
        if (workspaceModel && typeof workspaceModel.getActiveWorkspace === "function") {
            curWs = workspaceModel.getActiveWorkspace(mon)
        }
        return (mode === "live")
            ? (globalLiveWallpaper.length > 0 ? globalLiveWallpaper : defaultWallpaper)
            : _resolveWallpaperForWorkspace(curWs)
    }

    function getSnapshot(monitorIndex) {
        var mon = (typeof monitorIndex === "number" && monitorIndex >= 0) ? monitorIndex : 0
        return {
            mode: mode,
            currentPath: getWallpaperForMonitor(mon),
            workspaceWallpapers: workspaceWallpapers,
            globalLiveWallpaper: globalLiveWallpaper,
            defaultWallpaper: defaultWallpaper,
            monitorWallpapers: monitorWallpapers
        }
    }
}
