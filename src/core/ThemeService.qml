// BASEUS — Dynamic Theme & Visual State Service
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by DEC-012, DEC-037, and MASTER.md §23–26:
//   - Theme is VISUAL STATE ONLY (wallpaper, 4-color palette, widget layout, surface styling)
//   - Theme switching MUST NOT alter gestures, shortcuts, window behavior, notification timeouts, or Dock triggers
//   - Daily Theme Snapshot (MASTER.md §26) representing current daily visual state
//   - Visual transition tokens (circle_wipe, wavy_wipe, bubble_ripple, fade) without UI scaling
//   - Theme serialization and persistence

pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: themeService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var config: null
    property var theme: null
    property var paletteService: null
    property var wallpaperService: null
    property var desktopHost: null

    // =========================================================
    // Theme State
    // =========================================================
    property string activeThemeName: "wabi-sabi-indigo"
    property string activeTransition: "circle_wipe"
    readonly property var supportedTransitions: ["fade", "circle_wipe", "wavy_wipe", "bubble_ripple"]

    // Saved Themes Dictionary: themeName -> themeObject
    property var savedThemes: ({})

    // Daily Theme Snapshot (MASTER.md §26)
    property var dailySnapshot: null
    property string dailySnapshotDate: ""

    // =========================================================
    // Built-in Wabi-Sabi & Cyberpunk Presets
    // =========================================================
    readonly property var builtinThemes: ({
        "wabi-sabi-indigo": {
            "name": "wabi-sabi-indigo",
            "displayName": "Wabi-Sabi Indigo (Default)",
            "palette": {
                "dominant": "#7aa2f7",
                "secondary": "#bb9af7",
                "accent": "#7dcfff",
                "neutral": "#1a1b26",
                "surfaceSolid": "#1f2335",
                "surfaceHighlight": "#292e42",
                "surfaceRecessed": "#13131a",
                "borderSubtle": "#292e42",
                "textPrimary": "#c0caf5",
                "textSecondary": "#9aa5ce"
            },
            "wallpaper": {
                "mode": "static",
                "workspaceWallpapers": {},
                "globalLiveWallpaper": ""
            },
            "widgetLayout": {
                "mediaWidgetEnabled": false
            },
            "iconTheme": "default",
            "transitionType": "fade"
        },
        "tokyo-slate": {
            "name": "tokyo-slate",
            "displayName": "Tokyo Slate",
            "palette": {
                "dominant": "#7aa2f7",
                "secondary": "#2ac3de",
                "accent": "#ff9e64",
                "neutral": "#1f2335",
                "surfaceSolid": "#24283b",
                "surfaceHighlight": "#2f3549",
                "surfaceRecessed": "#16161e",
                "borderSubtle": "#292e42",
                "textPrimary": "#c0caf5",
                "textSecondary": "#9aa5ce"
            },
            "wallpaper": {
                "mode": "static",
                "workspaceWallpapers": {},
                "globalLiveWallpaper": ""
            },
            "widgetLayout": {
                "mediaWidgetEnabled": false
            },
            "iconTheme": "tokyo-night",
            "transitionType": "circle_wipe"
        },
        "cyber-sand": {
            "name": "cyber-sand",
            "displayName": "Cyber Sand",
            "palette": {
                "dominant": "#e0af68",
                "secondary": "#ff9e64",
                "accent": "#7dcfff",
                "neutral": "#1b1917",
                "surfaceSolid": "#292524",
                "surfaceHighlight": "#44403c",
                "surfaceRecessed": "#0c0a09",
                "borderSubtle": "#44403c",
                "textPrimary": "#f5f5f4",
                "textSecondary": "#a8a29e"
            },
            "wallpaper": {
                "mode": "static",
                "workspaceWallpapers": {},
                "globalLiveWallpaper": ""
            },
            "widgetLayout": {
                "mediaWidgetEnabled": false
            },
            "iconTheme": "sand",
            "transitionType": "wavy_wipe"
        },
        "obsidian-ember": {
            "name": "obsidian-ember",
            "displayName": "Obsidian Ember",
            "palette": {
                "dominant": "#f7768e",
                "secondary": "#ff9e64",
                "accent": "#bb9af7",
                "neutral": "#16161e",
                "surfaceSolid": "#1f1d2e",
                "surfaceHighlight": "#26233a",
                "surfaceRecessed": "#121019",
                "borderSubtle": "#2a273f",
                "textPrimary": "#e0def4",
                "textSecondary": "#908caa"
            },
            "wallpaper": {
                "mode": "static",
                "workspaceWallpapers": {},
                "globalLiveWallpaper": ""
            },
            "widgetLayout": {
                "mediaWidgetEnabled": false
            },
            "iconTheme": "ember",
            "transitionType": "bubble_ripple"
        }
    })

    // =========================================================
    // Lifecycle
    // =========================================================

    function initialize() {
        _initDailySnapshot()
        if (logger) logger.info("ThemeService", "ThemeService initialized with activeTheme=" + activeThemeName)
    }

    function teardown() {
        if (logger) logger.info("ThemeService", "ThemeService torn down.")
    }

    // =========================================================
    // Daily Snapshot Mechanics (MASTER.md §26)
    // =========================================================

    function _getTodayDateString() {
        var d = new Date()
        var yyyy = d.getFullYear()
        var mm = String(d.getMonth() + 1).padStart(2, "0")
        var dd = String(d.getDate()).padStart(2, "0")
        return yyyy + "-" + mm + "-" + dd
    }

    function _initDailySnapshot() {
        var today = _getTodayDateString()
        dailySnapshotDate = today
        dailySnapshot = {
            "name": "daily_snapshot_" + today,
            "displayName": "Daily Snapshot (" + today + ")",
            "isDailySnapshot": true,
            "createdAt": new Date().toISOString(),
            "palette": paletteService ? paletteService.getPalette() : builtinThemes["wabi-sabi-indigo"].palette,
            "wallpaper": wallpaperService ? wallpaperService.getSnapshot(0) : builtinThemes["wabi-sabi-indigo"].wallpaper,
            "widgetLayout": {
                "mediaWidgetEnabled": desktopHost ? desktopHost.mediaWidgetEnabled : false
            },
            "iconTheme": "default",
            "transitionType": "fade"
        }
    }

    function updateDailySnapshot() {
        var today = _getTodayDateString()
        dailySnapshotDate = today
        dailySnapshot = {
            "name": "daily_snapshot_" + today,
            "displayName": "Daily Snapshot (" + today + ")",
            "isDailySnapshot": true,
            "updatedAt": new Date().toISOString(),
            "palette": paletteService ? paletteService.getPalette() : builtinThemes["wabi-sabi-indigo"].palette,
            "wallpaper": wallpaperService ? wallpaperService.getSnapshot(0) : builtinThemes["wabi-sabi-indigo"].wallpaper,
            "widgetLayout": {
                "mediaWidgetEnabled": desktopHost ? desktopHost.mediaWidgetEnabled : false
            },
            "iconTheme": "default",
            "transitionType": activeTransition
        }
        return dailySnapshot
    }

    function dailySnapshotState() {
        if (!dailySnapshot) {
            _initDailySnapshot()
        }
        return dailySnapshot
    }

    // =========================================================
    // Theme Management API
    // =========================================================

    function saveCurrentTheme(name) {
        if (!name || typeof name !== "string") {
            if (logger) logger.warn("ThemeService", "saveCurrentTheme called without valid name.")
            return null
        }

        var themeData = {
            "name": name,
            "displayName": name,
            "isDailySnapshot": false,
            "createdAt": new Date().toISOString(),
            "palette": paletteService ? paletteService.getPalette() : builtinThemes["wabi-sabi-indigo"].palette,
            "wallpaper": wallpaperService ? wallpaperService.getSnapshot(0) : builtinThemes["wabi-sabi-indigo"].wallpaper,
            "widgetLayout": {
                "mediaWidgetEnabled": desktopHost ? desktopHost.mediaWidgetEnabled : false
            },
            "iconTheme": "default",
            "transitionType": activeTransition
        }

        var updated = Object.assign({}, savedThemes)
        updated[name] = themeData
        savedThemes = updated

        if (logger) {
            logger.info("ThemeService", "Saved theme '" + name + "'.")
        }

        if (eventBus) {
            eventBus.emit("theme", {
                type: "theme_saved",
                name: name,
                theme: themeData
            })
        }

        return themeData
    }

    function getTheme(name) {
        if (!name) return null
        if (savedThemes && savedThemes[name]) {
            return savedThemes[name]
        }
        if (builtinThemes && builtinThemes[name]) {
            return builtinThemes[name]
        }
        if (dailySnapshot && (name === "daily_snapshot" || name === dailySnapshot.name)) {
            return dailySnapshot
        }
        return null
    }

    function applyTheme(name) {
        var targetTheme = getTheme(name)
        if (!targetTheme) {
            if (logger) logger.warn("ThemeService", "Cannot apply unknown theme: '" + name + "'")
            return false
        }

        activeThemeName = targetTheme.name
        if (targetTheme.transitionType) {
            activeTransition = targetTheme.transitionType
        }

        var prevAutoExtract = false
        if (wallpaperService) {
            prevAutoExtract = wallpaperService.autoExtractPalette
            wallpaperService.autoExtractPalette = false
        }

        // 1. Apply Wallpaper (DEC-013, DEC-014)
        if (targetTheme.wallpaper && wallpaperService) {
            var wp = targetTheme.wallpaper
            if (wp.mode === "live" && wp.globalLiveWallpaper) {
                wallpaperService.setGlobalLiveWallpaper(wp.globalLiveWallpaper)
            } else {
                wallpaperService.setMode("static")
                if (wp.workspaceWallpapers) {
                    var keys = Object.keys(wp.workspaceWallpapers)
                    for (var i = 0; i < keys.length; i++) {
                        var wsNum = parseInt(keys[i], 10)
                        if (!isNaN(wsNum)) {
                            wallpaperService.setWorkspaceWallpaper(wsNum, wp.workspaceWallpapers[keys[i]])
                        }
                    }
                }
            }
        }

        // 2. Apply Palette (DEC-011) — stored visual state wins (MASTER.md §24)
        if (targetTheme.palette && paletteService) {
            paletteService.applyPalette(targetTheme.palette)
        }

        if (wallpaperService) {
            wallpaperService.autoExtractPalette = prevAutoExtract
        }

        // 3. Apply Widget Layout (VISUAL ONLY — DEC-012, DEC-037)
        if (targetTheme.widgetLayout && desktopHost) {
            if (typeof targetTheme.widgetLayout.mediaWidgetEnabled === "boolean") {
                desktopHost.mediaWidgetEnabled = targetTheme.widgetLayout.mediaWidgetEnabled
            }
        }

        // Update Daily Snapshot
        updateDailySnapshot()

        if (logger) {
            logger.info("ThemeService", "Applied theme '" + name + "' with transition '" + activeTransition + "'. (Interactions and shortcuts preserved per DEC-012/DEC-037).")
        }

        if (eventBus) {
            eventBus.emit("theme", {
                type: "theme_applied",
                name: activeThemeName,
                transition: activeTransition,
                theme: targetTheme
            })
        }

        return true
    }

    function listThemes() {
        var list = []

        // Top: Daily snapshot (MASTER.md §26)
        if (dailySnapshot) {
            list.push({
                "name": dailySnapshot.name,
                "displayName": dailySnapshot.displayName,
                "isDailySnapshot": true,
                "dominantColor": dailySnapshot.palette ? dailySnapshot.palette.dominant : "#7aa2f7",
                "transitionType": dailySnapshot.transitionType || "fade"
            })
        }

        // Builtin themes
        var builtins = Object.keys(builtinThemes)
        for (var b = 0; b < builtins.length; b++) {
            var bt = builtinThemes[builtins[b]]
            list.push({
                "name": bt.name,
                "displayName": bt.displayName,
                "isDailySnapshot": false,
                "dominantColor": bt.palette ? bt.palette.dominant : "#7aa2f7",
                "transitionType": bt.transitionType || "fade"
            })
        }

        // User saved themes
        var userThemes = Object.keys(savedThemes)
        for (var u = 0; u < userThemes.length; u++) {
            var ut = savedThemes[userThemes[u]]
            list.push({
                "name": ut.name,
                "displayName": ut.displayName || ut.name,
                "isDailySnapshot": false,
                "dominantColor": ut.palette ? ut.palette.dominant : "#7aa2f7",
                "transitionType": ut.transitionType || "fade"
            })
        }

        return list
    }
}
